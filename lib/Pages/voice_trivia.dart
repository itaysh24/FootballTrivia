import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/voice_service.dart';

class VoiceTriviaPage extends StatefulWidget {
  const VoiceTriviaPage({super.key});

  @override
  State<VoiceTriviaPage> createState() => _VoiceTriviaPageState();
}

class _VoiceTriviaPageState extends State<VoiceTriviaPage> {
  final _supabase = Supabase.instance.client;
  final _voice = VoiceService();

  String? _question;
  String? _answer;
  String? _feedback;
  bool _loading = true;
  bool _isListening = false;
  int? _currentQuestionId;
  int? _totalQuestions;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  Future<void> _setup() async {
    await _voice.init();
    await _getTotalQuestions();
    await _loadQuestion();
  }

  Future<void> _getTotalQuestions() async {
    final countResponse = await _supabase.from('questions').select('id');

    _totalQuestions = countResponse.length;
  }

  Future<void> _loadQuestion() async {
    setState(() => _loading = true);

    if (_totalQuestions == null || _totalQuestions == 0) {
      setState(() => _loading = false);
      return;
    }

    // Generate a random question ID that's different from the current one
    int randomId;
    do {
      randomId = (DateTime.now().millisecondsSinceEpoch % _totalQuestions!) + 1;
    } while (randomId == _currentQuestionId && _totalQuestions! > 1);

    try {
      final response = await _supabase
          .from('questions')
          .select()
          .eq('id', randomId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _question = response['career_path'] as String;
          _answer = response['answer'] as String;
          _currentQuestionId = randomId;
          _loading = false;
          _feedback = null; // Clear previous feedback
        });
      } else {
        // If the specific ID doesn't exist, fall back to random selection
        await _loadRandomQuestion();
      }
    } catch (e) {
      // Fallback to random selection if there's an error
      await _loadRandomQuestion();
    }
  }

  Future<void> _loadRandomQuestion() async {
    final response = await _supabase
        .from('questions')
        .select()
        .order('id', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response != null) {
      setState(() {
        _question = response['career_path'] as String;
        _answer = response['answer'] as String;
        _currentQuestionId = response['id'] as int;
        _loading = false;
        _feedback = null;
      });
    }
  }

  bool validateAnswer(String userAnswer, String correctAnswer) {
    final normalizedUser = userAnswer.trim().toLowerCase();
    final normalizedCorrect = correctAnswer.trim().toLowerCase();

    // Split full name into parts
    final parts = normalizedCorrect.split(' ');

    // Valid if exact full match
    if (normalizedUser == normalizedCorrect) return true;

    // Valid if matches any part of the name
    if (parts.contains(normalizedUser)) return true;

    return false;
  }

  String formatQuestion(String? questionText) {
    if (questionText == null || questionText.isEmpty) {
      return "Loading question...";
    }

    try {
      // Try to parse as JSON
      final Map<String, dynamic> questionData = json.decode(questionText);

      // Extract teams if they exist
      if (questionData.containsKey('teams')) {
        final teams = questionData['teams'];
        if (teams is List) {
          final formattedTeams = teams.map((team) => '• $team').join('\n');
          return formattedTeams;
        }
      }

      // If no teams structure, return as is
      return questionText;
    } catch (e) {
      // If not valid JSON, try to format comma-separated values
      if (questionText.contains(',')) {
        final parts = questionText.split(',');
        return parts.map((part) => '• ${part.trim()}').join('\n');
      }

      // If no commas, return as is
      return questionText;
    }
  }

  Widget _buildFormattedQuestion() {
    if (_question == null || _question!.isEmpty) {
      return const Text(
        "Loading question...",
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
        textAlign: TextAlign.center,
      );
    }

    try {
      // Try to parse as JSON
      final Map<String, dynamic> questionData = json.decode(_question!);

      // Extract teams if they exist
      if (questionData.containsKey('teams')) {
        final teams = questionData['teams'];
        if (teams is List) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: teams
                .map<Widget>(
                  (team) => Text(
                    '• $team',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.visible,
                  ),
                )
                .toList(),
          );
        }
      }

      // If no teams structure, return as single text
      return Text(
        _question!,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
        textAlign: TextAlign.center,
      );
    } catch (e) {
      // If not valid JSON, try to format comma-separated values
      if (_question!.contains(',')) {
        final parts = _question!.split(',');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: parts
              .map<Widget>(
                (part) => Text(
                  '• ${part.trim()}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.1,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.visible,
                ),
              )
              .toList(),
        );
      }

      // If no commas, return as single text
      return Text(
        _question!,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: 1.1,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  void _toggleListening() {
    if (_isListening) {
      _voice.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _isListening = true;
        _feedback = null;
      });
      _voice.listen((spoken) {
        if (_answer != null && validateAnswer(spoken, _answer!)) {
          setState(() {
            _feedback = "✅ Correct! $spoken";
            _isListening = false;
          });
        } else {
          setState(() {
            _feedback = "❌ Wrong: $spoken";
            _isListening = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.network(
            "https://cdn.pixabay.com/photo/2020/01/12/16/57/stadium-4760441_1280.jpg",
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
            child: _loading
                ? const CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  )
                : Container(
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
                        // Question
                        _buildFormattedQuestion(),
                        const SizedBox(height: 40),

                        // Microphone button
                        GestureDetector(
                          onTap: _toggleListening,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: _isListening
                                  ? Colors.green.shade600
                                  : const Color(0xFF2E7D32), // Deep green
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.mic,
                              size: 50,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Status text
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

                        // Feedback
                        if (_feedback != null) ...[
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: _feedback!.startsWith('✅')
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _feedback!.startsWith('✅')
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _feedback!,
                              style: TextStyle(
                                fontSize: 16,
                                color: _feedback!.startsWith('✅')
                                    ? Colors.green.shade300
                                    : Colors.red.shade300,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],

                        // Next question button
                        if (_feedback != null) ...[
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: _loadQuestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFA726),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "Next Question",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
