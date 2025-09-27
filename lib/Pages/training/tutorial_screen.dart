import 'package:flutter/material.dart';

class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  int _currentStep = 0;
  
  final List<TutorialStep> _steps = [
    TutorialStep(
      title: "Welcome to Football Trivia!",
      description: "Test your football knowledge with exciting trivia questions.",
      icon: Icons.sports_soccer,
    ),
    TutorialStep(
      title: "Game Modes",
      description: "Choose from different game modes including Training and Voice Trivia.",
      icon: Icons.games,
    ),
    TutorialStep(
      title: "Voice Trivia",
      description: "Answer questions using your voice for a hands-free experience.",
      icon: Icons.mic,
    ),
    TutorialStep(
      title: "Leaderboard",
      description: "Compete with other players and see your ranking.",
      icon: Icons.leaderboard,
    ),
    TutorialStep(
      title: "Ready to Play!",
      description: "You're all set! Start playing and have fun!",
      icon: Icons.play_arrow,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Progress indicator
              LinearProgressIndicator(
                value: (_currentStep + 1) / _steps.length,
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFA726)),
              ),
              const SizedBox(height: 40),
              
              // Tutorial content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _steps[_currentStep].icon,
                      size: 80,
                      color: const Color(0xFFFFA726),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      _steps[_currentStep].title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _steps[_currentStep].description,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xB3FFFFFF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Navigation buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentStep > 0)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _currentStep--;
                        });
                      },
                      child: const Text(
                        "Previous",
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  
                  if (_currentStep < _steps.length - 1)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _currentStep++;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Next"),
                    )
                  else
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA726),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Get Started"),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}
