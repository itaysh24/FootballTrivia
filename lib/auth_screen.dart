import 'package:flutter/material.dart';
import 'main.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  void _simulateLogin(BuildContext context) {
    // Simulate successful login and navigate to main screen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/Gemini_Generated_Image_p7lysbp7lysbp7ly.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x66000000), // Semi-transparent black overlay
                Color(0x99000000), // Darker at bottom
              ],
            ),
          ),
          child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo
                Center(
                  child: Image.asset(
                    "assets/images/Logo.png",
                    height: 200,
                    width: 200,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.sports_soccer,
                        size: 100,
                        color: Color(0xFFFFA726),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                
                // App Title
                const Text(
                  'GUESS THE PLAYER',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Subtitle
                const Text(
                  'Test your football knowledge',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 60),
                
                // Login with Google Button
                ElevatedButton.icon(
                  onPressed: () => _simulateLogin(context),
                  icon: Image.asset(
                    'assets/images/google_icon.png',
                    height: 24,
                    width: 24,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.login,
                        color: Colors.black,
                      );
                    },
                  ),
                  label: const Text(
                    'Login with Google',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 24,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Guest/Skip Button
                TextButton(
                  onPressed: () => _simulateLogin(context),
                  child: const Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: Color(0xB3FFFFFF),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                
                // Info text
                const Text(
                  'By continuing, you agree to our Terms of Service and Privacy Policy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0x80FFFFFF),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

