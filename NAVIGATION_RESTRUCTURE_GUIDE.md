# Navigation Restructure Guide - Splash & Auth Implementation

## 🎯 Overview

The Flutter app has been successfully restructured to include a **SplashScreen** and **AuthScreen** before the main app. The navigation flow is now:

```
App Launch → SplashScreen → AuthScreen → MainScreen
              (2 seconds)   (if not     (main game app)
                            logged in)
```

---

## 📁 Files Created/Modified

### ✨ New Files Created

1. **`lib/splash_screen.dart`**
   - Entry point screen that shows on app launch
   - Displays app logo and loading indicator
   - Simulates authentication check (2-second delay)
   - Routes to AuthScreen or MainScreen based on login status

2. **`lib/auth_screen.dart`**
   - Login/authentication screen
   - Contains "Login with Google" button (placeholder)
   - Contains "Continue as Guest" button
   - Both buttons navigate to MainScreen

### 🔧 Files Modified

3. **`lib/main.dart`**
   - Added import for `splash_screen.dart`
   - Changed initial route from `MyHomePage()` to `const SplashScreen()`
   - Created new `MainScreen` class (wrapper for existing functionality)
   - Kept `MyHomePage` for backward compatibility

---

## 🔄 New Navigation Flow

### Flow Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        App Launch                           │
│                     (main() function)                       │
│                                                             │
│  • Initializes Supabase                                    │
│  • Preloads music tracks                                   │
│  • Sets home screen to SplashScreen                        │
└──────────────────────┬──────────────────────────────────────┘
                       │
                       ▼
┌─────────────────────────────────────────────────────────────┐
│                     SplashScreen                            │
│                  (lib/splash_screen.dart)                   │
│                                                             │
│  • Shows app logo                                          │
│  • Shows loading indicator                                 │
│  • Waits 2 seconds                                         │
│  • Checks login status (isLoggedIn variable)               │
│                                                             │
│  Current Setting: isLoggedIn = false                       │
└──────────────────────┬──────────────────────────────────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
    isLoggedIn = false      isLoggedIn = true
           │                       │
           ▼                       ▼
┌──────────────────────┐  ┌────────────────────┐
│    AuthScreen        │  │    MainScreen      │
│ (lib/auth_screen.dart│  │  (lib/main.dart)   │
│                      │  │                    │
│ • Login with Google  │  │ • Bottom Nav       │
│ • Continue as Guest  │  │ • Game Modes       │
│                      │  │ • All features     │
└──────────┬───────────┘  └────────────────────┘
           │                       ▲
           │ (both buttons)        │
           └───────────────────────┘
```

---

## 🛠️ How to Test

### Test 1: Splash → Auth → Main (Current Default)

**Current Configuration:**
```dart
// In lib/splash_screen.dart, line 16
bool isLoggedIn = false; // Default: shows auth screen
```

**Steps:**
1. Run the app: `flutter run`
2. **Expected:** SplashScreen appears with logo and loading indicator
3. **Wait 2 seconds**
4. **Expected:** AuthScreen appears with login buttons
5. **Click "Login with Google" or "Continue as Guest"**
6. **Expected:** MainScreen appears (the main app with bottom navigation)

---

### Test 2: Splash → Main Directly (Skip Auth)

**Configuration:**
```dart
// In lib/splash_screen.dart, line 16
bool isLoggedIn = true; // Skip auth screen
```

**Steps:**
1. Modify the `isLoggedIn` variable to `true`
2. Run the app: `flutter run`
3. **Expected:** SplashScreen appears
4. **Wait 2 seconds**
5. **Expected:** MainScreen appears directly (skip AuthScreen)

---

## 🎨 UI Features

### SplashScreen
- **Background:** Dark gradient (green to black)
- **Logo:** App logo from assets (with fallback to soccer icon)
- **Loading Indicator:** Orange circular progress indicator
- **Text:** "Loading..." message
- **Duration:** 2 seconds

### AuthScreen
- **Background:** Dark gradient (green to black)
- **Logo:** App logo centered
- **Title:** "GUESS THE PLAYER"
- **Subtitle:** "Test your football knowledge"
- **Primary Button:** "Login with Google" (white button with Google icon)
- **Secondary Button:** "Continue as Guest" (text button)
- **Footer:** Terms and Privacy Policy text

### MainScreen
- **Same as before:** Bottom navigation with all game features
- **No changes to functionality:** All existing features work as before

---

## 🔧 Customization Options

### 1. Change Splash Screen Duration

```dart
// In lib/splash_screen.dart, line 25
await Future.delayed(const Duration(seconds: 2)); // Change to 3, 4, etc.
```

### 2. Implement Real Authentication

Replace the simulated login with real auth logic:

```dart
// In lib/splash_screen.dart
Future<void> _checkAuthStatus() async {
  await Future.delayed(const Duration(seconds: 2));
  
  // TODO: Replace with real auth check
  // Example: Check Supabase session
  final session = Supabase.instance.client.auth.currentSession;
  bool isLoggedIn = session != null;
  
  if (!mounted) return;
  
  if (isLoggedIn) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  } else {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const AuthScreen()),
    );
  }
}
```

### 3. Add Google Sign-In

In `lib/auth_screen.dart`, replace the simulated login:

```dart
// Add google_sign_in package to pubspec.yaml
// Then implement real Google Sign-In

Future<void> _handleGoogleSignIn(BuildContext context) async {
  try {
    // TODO: Implement Google Sign-In with Supabase
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? account = await googleSignIn.signIn();
    
    if (account != null) {
      // Sign in to Supabase with Google credentials
      // Navigate to MainScreen on success
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  } catch (e) {
    // Show error dialog
    debugPrint('Google Sign-In Error: $e');
  }
}
```

---

## 📊 Code Structure

### Before Restructure
```
MyApp (entry point)
  └─> MyHomePage (bottom nav + all features)
```

### After Restructure
```
MyApp (entry point)
  └─> SplashScreen
       ├─> AuthScreen (if not logged in)
       │    └─> MainScreen
       └─> MainScreen (if already logged in)
```

---

## 🔍 Key Implementation Details

### 1. Navigator.pushReplacement vs Navigator.push

We use `pushReplacement` for authentication flow to prevent users from going back:

```dart
// In SplashScreen and AuthScreen
Navigator.pushReplacement(
  context,
  MaterialPageRoute(builder: (_) => const MainScreen()),
);
```

**Why?** 
- User can't press back button to return to splash/auth
- Clean navigation stack
- Better UX for authentication flow

### 2. MainScreen vs MyHomePage

- **MainScreen:** New class that wraps the main app (for external use)
- **MyHomePage:** Legacy class kept for backward compatibility
- Both use the same functionality (`_MainScreenState` and `_MyHomePageState`)

### 3. Const Constructors

All new screens use `const` constructors for better performance:

```dart
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key}); // const constructor
  
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}
```

---

## ✅ Testing Checklist

After implementing the changes, verify:

- [ ] App launches with SplashScreen
- [ ] SplashScreen displays for 2 seconds
- [ ] AuthScreen appears after splash (when `isLoggedIn = false`)
- [ ] "Login with Google" button navigates to MainScreen
- [ ] "Continue as Guest" button navigates to MainScreen
- [ ] MainScreen appears directly after splash (when `isLoggedIn = true`)
- [ ] All existing features work in MainScreen
- [ ] Bottom navigation works
- [ ] Game modes accessible
- [ ] No navigation back to splash/auth from MainScreen

---

## 🚨 Common Issues & Solutions

### Issue 1: "Can't find MainScreen"
**Solution:** MainScreen is defined in `lib/main.dart`. Make sure imports are correct:
```dart
import 'main.dart'; // In splash_screen.dart and auth_screen.dart
```

### Issue 2: "Asset not found" for logo
**Solution:** SplashScreen and AuthScreen have error builders that show fallback icons:
```dart
errorBuilder: (context, error, stackTrace) {
  return const Icon(Icons.sports_soccer, size: 100, color: Color(0xFFFFA726));
}
```

### Issue 3: Bottom navigation not showing
**Solution:** This is expected behavior. Bottom nav only appears in MainScreen, not in SplashScreen or AuthScreen.

---

## 📝 Future Enhancements

### Recommended Next Steps

1. **Implement Real Authentication**
   - Integrate Google Sign-In
   - Use Supabase Auth
   - Store user session

2. **Add Onboarding Flow**
   - Show tutorial on first launch
   - User profile setup
   - Permissions requests

3. **Improve Splash Screen**
   - Add animated logo
   - Add version number
   - Add progress indicator for downloads

4. **Enhanced Auth Screen**
   - Add email/password option
   - Add social login options (Facebook, Apple)
   - Add "Forgot Password" flow

5. **User Profile Integration**
   - Save user data after login
   - Display user info in profile page
   - Sync game progress to user account

---

## 🎯 Summary

✅ **Created:** SplashScreen with 2-second delay and auth check  
✅ **Created:** AuthScreen with login buttons  
✅ **Modified:** main.dart to start with SplashScreen  
✅ **Added:** MainScreen wrapper for the main app  
✅ **Preserved:** All existing functionality in the main app  
✅ **Navigation:** Clean flow using pushReplacement  

**Result:** The app now has a professional authentication flow ready for real implementation!

---

**Next Steps:**
1. Test the current flow with `isLoggedIn = false`
2. Test with `isLoggedIn = true` to skip auth
3. Implement real authentication when ready
4. Update documentation as needed

---

_Generated: Navigation Restructure Complete ✨_  
_Files Modified: 3 | Files Created: 2 | No Breaking Changes_

