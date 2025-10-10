import 'dart:ui';
import 'package:flutter/material.dart';

class VoiceTriviaScreen extends StatefulWidget {
  const VoiceTriviaScreen({super.key});

  @override
  State<VoiceTriviaScreen> createState() => _VoiceTriviaScreenState();
}

class _VoiceTriviaScreenState extends State<VoiceTriviaScreen> {
  bool _isListening = false;

  void _toggleListening() {
    setState(() {
      _isListening = !_isListening;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            "https://source.unsplash.com/random/800x1600?soccer",
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              // Fallback to a solid color if image fails to load
              return Container(
                color: const Color(0xFF1B2F1B), // Deep green fallback
              );
            },
          ),
          // Blur overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(color: Colors.black.withOpacity(0.3)),
          ),
          // Content
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Which club did this player join in 2015?",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32), // Deep green
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(Icons.mic, size: 50, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isListening ? "Listening..." : "Tap to Answer",
                    style: TextStyle(
                      fontSize: 16,
                      color: _isListening
                          ? Colors.green.shade300
                          : Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_isListening) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.green.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
