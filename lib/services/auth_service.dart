import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '979142015932-b8opphnnd0219c1v8275446eurtd4al4.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Getters
  User? get currentUser => _supabase.auth.currentUser;
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;
  bool get isAuthenticated => currentUser != null;
  bool get isGuest => currentUser?.isAnonymous ?? false;
  String? get userName => currentUser?.userMetadata?['full_name'] ?? 
                         currentUser?.userMetadata?['name'] ?? 
                         currentUser?.email;
  String? get userEmail => currentUser?.email;
  String? get userAvatar => currentUser?.userMetadata?['avatar_url'] ?? 
                           currentUser?.userMetadata?['picture'];

  /// Sign in with Google (Native Flow)
  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Missing Google tokens');
      }

      final AuthResponse response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      return response;
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  /// Sign in as Guest (Anonymous) with optional name
  /// If a guest session already exists for this device, restores it
  Future<AuthResponse> signInAsGuest({String? name}) async {
    try {
      // Check if there's an existing guest session for this device
      final prefs = await SharedPreferences.getInstance();
      final storedGuestToken = prefs.getString('guest_access_token');
      final storedGuestRefreshToken = prefs.getString('guest_refresh_token');
      final storedGuestUserId = prefs.getString('guest_user_id');
      
      // If we have stored tokens and user is not currently authenticated, try to restore session
      if (storedGuestToken != null && 
          storedGuestRefreshToken != null && 
          storedGuestUserId != null &&
          _supabase.auth.currentUser == null) {
        try {
          // Try to set the session with stored access token
          await _supabase.auth.setSession(storedGuestToken);
          
          // Verify the session was set correctly
          final currentSession = _supabase.auth.currentSession;
          final currentUser = _supabase.auth.currentUser;
          if (currentSession != null && currentUser != null && currentUser.isAnonymous) {
            print('Restored existing guest session for user: ${currentUser.id}');
            // Update stored tokens in case they were refreshed
            // ignore: unnecessary_non_null_assertion - tokens are non-null for valid sessions but type is nullable
            await prefs.setString('guest_access_token', currentSession.accessToken!);
            await prefs.setString('guest_refresh_token', currentSession.refreshToken!);
            // Return current auth state as AuthResponse
            return AuthResponse(
              session: currentSession,
              user: currentUser,
            );
          }
        } catch (e) {
          print('Failed to restore guest session, creating new one: $e');
          // If restoration fails (token expired), clear stored tokens and create new session
          await prefs.remove('guest_access_token');
          await prefs.remove('guest_refresh_token');
          await prefs.remove('guest_user_id');
        }
      }
      
      // Create new anonymous session
      final AuthResponse response = await _supabase.auth.signInAnonymously(
        data: name != null && name.isNotEmpty
            ? {'name': name, 'full_name': name}
            : null,
      );
      
      // Store the guest session tokens for device persistence
      final session = response.session;
      final user = response.user;
      if (session != null && user != null) {
        // ignore: unnecessary_non_null_assertion - tokens are non-null for valid sessions but type is nullable
        await prefs.setString('guest_access_token', session.accessToken!);
        await prefs.setString('guest_refresh_token', session.refreshToken!);
        await prefs.setString('guest_user_id', user.id);
      }
      
      return response;
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  /// Sign out
  /// Note: For guest users, we keep the session stored so they can be restored later
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      
      // If user is a guest, we don't clear the stored tokens
      // This allows them to resume their guest session later
      // Only clear if they're signing out from a Google account
      if (!isGuest) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('guest_access_token');
        await prefs.remove('guest_refresh_token');
        await prefs.remove('guest_user_id');
      }
      
      await _supabase.auth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Upgrade guest account to permanent Google account
  Future<bool> upgradeGuestToGoogle() async {
    try {
      if (!isGuest) {
        throw Exception('User is not a guest account');
      }

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw Exception('Failed to get Google tokens');
      }

      // Link Google identity to anonymous account
      // Note: This requires Supabase to be configured for identity linking
      // If this fails, you may need to sign out anonymous and sign in with Google instead
      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
      
      // If user was anonymous, Supabase should handle the linking automatically
      // If not, you may need to manually handle the account merge

      return true;
    } catch (e) {
      print('Error upgrading guest account: $e');
      rethrow;
    }
  }
}

