import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'dart:async';
import 'dart:ui';
import '../core/game_modes_manager.dart';

/// ============================================================================
/// GAME SCREEN - Universal Question-Answer Screen
/// ============================================================================
/// This screen serves as the universal game screen for all game modes.
/// Features:
/// - Fetches questions dynamically from Supabase 'players' table
/// - Supports both typed and voice answers using speech_to_text
/// - Validates answers with partial case-insensitive matching
/// - Automatically loads next question after correct answer
/// - Supports multiple game modes through GameConfiguration
/// ============================================================================

class GameScreen extends StatefulWidget {
  /// Optional category filter for fetching specific questions (legacy)
  final String? categoryFilter;

  /// Game configuration for mode-specific behavior
  final GameConfiguration? config;

  const GameScreen({super.key, this.categoryFilter, this.config});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  // ============================================================================
  // STATE VARIABLES
  // ============================================================================

  /// Current player/question data from Supabase
  Map<String, dynamic>? _currentPlayer;

  /// Loading state for question fetching
  bool _isLoading = false;

  /// Voice recording state
  bool _isListening = false;

  /// Answer text controller
  final TextEditingController _answerController = TextEditingController();

  /// Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Speech to text instance
  final SpeechToText _speechToText = SpeechToText();

  /// Speech available flag
  bool _speechAvailable = false;

  /// Score tracking
  int _score = 0;

  /// Total questions answered
  int _totalAnswered = 0;

  /// Timer for Rush mode
  Timer? _gameTimer;

  /// Remaining time in seconds (for Rush mode)
  int? _remainingSeconds;

  /// List of all questions for the current game
  List<Map<String, dynamic>> _allQuestions = [];

  /// Current question index
  int _currentQuestionIndex = 0;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeSpeech();
    _initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _gameTimer?.cancel();
    super.dispose();
  }

  /// Initialize the game based on configuration
  Future<void> _initializeGame() async {
    if (widget.config != null) {
      // Use configuration-based question fetching
      await _fetchQuestionsFromConfig();

      // Start timer if this is Rush mode
      if (widget.config!.timeLimitSeconds != null) {
        _startTimer(widget.config!.timeLimitSeconds!);
      }
    } else {
      // Legacy mode - fetch random question
      await _fetchRandomQuestion();
    }
  }

  /// Fetch all questions for the game session using configuration
  Future<void> _fetchQuestionsFromConfig() async {
    if (widget.config == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      _allQuestions = await widget.config!.questionFetcher(_supabase);

      if (_allQuestions.isEmpty) {
        _showErrorDialog('No questions available for this game mode.');
        return;
      }

      // Load the first question
      setState(() {
        _currentPlayer = _allQuestions[_currentQuestionIndex];
        _answerController.clear();
      });
    } catch (e) {
      _showErrorDialog('Error loading questions: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Start countdown timer for Rush mode
  void _startTimer(int seconds) {
    setState(() {
      _remainingSeconds = seconds;
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds != null && _remainingSeconds! > 0) {
          _remainingSeconds = _remainingSeconds! - 1;
        } else {
          // Time's up!
          _gameTimer?.cancel();
          _showTimeUpDialog();
        }
      });
    });
  }

  /// Load next question from the pre-fetched list
  void _loadNextQuestion() {
    if (_allQuestions.isEmpty) {
      // Legacy mode - fetch random question
      _fetchRandomQuestion();
      return;
    }

    _currentQuestionIndex++;

    // Check if we've reached the end
    if (_currentQuestionIndex >= _allQuestions.length) {
      if (widget.config?.showCompletionDialog == true) {
        _showCompletionDialog();
      } else {
        // No more questions - could loop back or show a message
        _currentQuestionIndex = 0;
      }
    }

    setState(() {
      _currentPlayer = _allQuestions[_currentQuestionIndex];
      _answerController.clear();
    });
  }

  // ============================================================================
  // SPEECH TO TEXT INITIALIZATION
  // ============================================================================

  /// Initialize speech recognition using speech_to_text package
  Future<void> _initializeSpeech() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();

      if (status.isGranted) {
        // Initialize speech to text
        _speechAvailable = await _speechToText.initialize(
          onStatus: (status) => debugPrint('Speech status: $status'),
          onError: (error) => debugPrint('Speech error: $error'),
        );

        if (_speechAvailable) {
          debugPrint('Speech recognition initialized successfully');
        } else {
          debugPrint('Speech recognition not available on this device');
        }
      } else {
        _showErrorDialog(
          'Microphone permission is required for voice input. '
          'Please enable it in app settings.',
        );
      }
    } catch (e) {
      debugPrint('Error initializing speech: $e');
    }
  }

  // ============================================================================
  // SUPABASE - QUESTION FETCHING LOGIC
  // ============================================================================

  /// Fetch a random player/question from Supabase
  Future<void> _fetchRandomQuestion() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Build query based on optional category filter
      PostgrestFilterBuilder query = _supabase
          .from('players')
          .select('id, firstname, lastname, career_path, answer, Category');

      // Apply category filter if provided
      if (widget.categoryFilter != null && widget.categoryFilter!.isNotEmpty) {
        query = query.eq('Category', widget.categoryFilter!);
      }

      // Fetch one random record
      // Note: Supabase doesn't have a built-in random() function in all versions
      // This is a workaround - fetch all matching records and pick one randomly
      final response = await query.limit(50); // Fetch 50 to randomize from

      if (response.isEmpty) {
        _showErrorDialog('No questions available for this category.');
        return;
      }

      // Pick a random question from the results
      final randomIndex =
          DateTime.now().millisecondsSinceEpoch % response.length;
      setState(() {
        _currentPlayer = response[randomIndex] as Map<String, dynamic>;
        _answerController.clear();
      });
    } catch (e) {
      _showErrorDialog('Error fetching question: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ============================================================================
  // VOICE RECOGNITION LOGIC
  // ============================================================================

  /// Start listening for voice input using speech_to_text
  Future<void> _startListening() async {
    // Check if speech is available
    if (!_speechAvailable) {
      _showErrorDialog(
        'Speech recognition is not available on this device. '
        'Please try typing your answer instead.',
      );
      return;
    }

    // Check microphone permission
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      final newStatus = await Permission.microphone.request();
      if (!newStatus.isGranted) {
        _showErrorDialog('Microphone permission denied.');
        return;
      }
    }

    setState(() {
      _isListening = true;
    });

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _answerController.text = result.recognizedWords;
              _isListening = false;
            });
          }
        },
        listenFor: const Duration(seconds: 15), // Max listening time
        pauseFor: const Duration(seconds: 3), // Stop after 3s of silence
        partialResults: false, // Only show final results
        localeId: 'en_US', // English (US)
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
    } catch (e) {
      _showErrorDialog('Error during voice recognition: $e');
      setState(() {
        _isListening = false;
      });
    }
  }

  /// Stop listening for voice input
  void _stopListening() {
    _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  // ============================================================================
  // ANSWER VALIDATION LOGIC
  // ============================================================================

  /// Validate the user's answer against the correct answer
  void _validateAnswer() {
    if (_currentPlayer == null) {
      return;
    }

    final userAnswer = _answerController.text.trim();
    if (userAnswer.isEmpty) {
      _showErrorDialog('Please enter an answer or use voice input.');
      return;
    }

    // Get the correct answer from the current player
    final correctAnswer = _currentPlayer!['answer']?.toString() ?? '';

    // Perform case-insensitive partial match
    final isCorrect =
        userAnswer.toLowerCase().contains(correctAnswer.toLowerCase()) ||
        correctAnswer.toLowerCase().contains(userAnswer.toLowerCase());

    setState(() {
      _totalAnswered++;
      if (isCorrect) {
        _score++;
      }
    });

    if (isCorrect) {
      // Show success dialog and load next question
      _showSuccessDialog(correctAnswer);
    } else {
      // Show retry prompt with hint
      _showRetryDialog(correctAnswer);
    }
  }

  // ============================================================================
  // UI DIALOG METHODS
  // ============================================================================

  /// Show success dialog when answer is correct
  void _showSuccessDialog(String correctAnswer) {
    // Call onLevelComplete callback if provided (for Road to Glory progress)
    if (widget.config?.onLevelComplete != null && widget.config?.level != null) {
      widget.config!.onLevelComplete!(true, widget.config!.level!);
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(200, 33, 43, 31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 32),
              SizedBox(width: 12),
              Text('Correct!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'The answer was: $correctAnswer\n\n'
            'Score: $_score / $_totalAnswered',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _loadNextQuestion(); // Load next question
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Next Question',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show completion dialog when all questions are answered (Rush mode)
  void _showCompletionDialog() {
    _gameTimer?.cancel();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(200, 33, 43, 31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.emoji_events, color: Color(0xFFFFA726), size: 32),
              SizedBox(width: 12),
              Text('Game Complete!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'You finished the game!\n\n'
            'Final Score: $_score / $_totalAnswered\n'
            'Accuracy: ${(_score / _totalAnswered * 100).toStringAsFixed(1)}%',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to main screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Back to Main Screen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show time up dialog when timer expires (Rush mode)
  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(200, 33, 43, 31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.timer_off, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Time\'s Up!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'The timer has expired!\n\n'
            'Final Score: $_score / $_totalAnswered\n'
            'Accuracy: ${_totalAnswered > 0 ? (_score / _totalAnswered * 100).toStringAsFixed(1) : 0}%',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(); // Return to main screen
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Back to Main Screen',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show retry dialog when answer is incorrect
  void _showRetryDialog(String correctAnswer) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(200, 33, 43, 31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.close_rounded, color: Colors.red, size: 32),
              SizedBox(width: 12),
              Text('Try Again!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Not quite right!',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 12),
              Text(
                'Hint: ${_getHint()}',
                style: const TextStyle(
                  color: Color(0xFFFFA726),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Try Again',
                style: TextStyle(color: Colors.white70),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.red.withOpacity(0.6),
                    Colors.redAccent.withOpacity(0.4),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showSuccessDialog(correctAnswer);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  'Show Answer',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color.fromARGB(200, 33, 43, 31),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.2), width: 1),
          ),
          title: const Row(
            children: [
              Icon(Icons.error_outline, color: Color(0xFFFFA726), size: 32),
              SizedBox(width: 12),
              Text('Error', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(message, style: const TextStyle(color: Colors.white70)),
          actions: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
                ),
              ),
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get hint based on current player data
  String _getHint() {
    if (_currentPlayer == null) return 'Try again!';

    // Provide hint from career path or category
    if (_currentPlayer!['career_path'] != null &&
        _currentPlayer!['career_path'].toString().isNotEmpty) {
      return _currentPlayer!['career_path'];
    }

    if (_currentPlayer!['Category'] != null) {
      return 'Category: ${_currentPlayer!['Category']}';
    }

    return 'Think about famous football players!';
  }

  // ============================================================================
  // UI BUILD METHOD
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background with image, gradient, and blur
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000), // Black with 0.6 opacity
                    Color(0x00000000), // Transparent
                  ],
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Glass morphism header with back button and score
                _buildGlassHeader(context),

                // Game content
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFA726),
                          ),
                        )
                      : _currentPlayer == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No question loaded',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton(
                                onPressed: _fetchRandomQuestion,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFFA726),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  'Load Question',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Question card
                              _buildQuestionCard(),

                              const SizedBox(height: 30),

                             
 
                              const SizedBox(height: 30),

                              // Hint section (career path or category)
                              _buildHintSection(),

                              const SizedBox(height: 30),

                              // Answer input section
                              _buildAnswerInputSection(),

                              const SizedBox(height: 30),

                              // Submit button
                              _buildSubmitButton(),

                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build glass morphism header with back button, timer, and score
  Widget _buildGlassHeader(BuildContext context) {
    return Container(
      height: 60,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(120, 33, 43, 31), // Semi-transparent dark
            const Color.fromARGB(60, 33, 43, 31), // More transparent
            Colors.transparent, // Fully transparent at bottom
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(20)),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  // Back button
                  IconButton(
                    onPressed: () {
                      _gameTimer?.cancel();
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white,
                    iconSize: 24,
                  ),
                  const SizedBox(width: 12),
                  // Title
                  Expanded(
                    child: Text(
                      widget.config?.title ?? 'Game Mode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Timer (if Rush mode)
                  if (_remainingSeconds != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingSeconds! < 30
                            ? Colors.red.withOpacity(0.3)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _remainingSeconds! < 30
                              ? Colors.red.withOpacity(0.6)
                              : Colors.blue.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timer,
                            color: _remainingSeconds! < 30
                                ? Colors.red
                                : Colors.blue,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_remainingSeconds! ~/ 60}:${(_remainingSeconds! % 60).toString().padLeft(2, '0')}',
                            style: TextStyle(
                              color: _remainingSeconds! < 30
                                  ? Colors.red
                                  : Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Score display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFFFA726).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: Color(0xFFFFA726),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$_score / $_totalAnswered',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  // ============================================================================
  // UI WIDGET BUILDERS
  // ============================================================================

  /// Build question display card with glass morphism
  Widget _buildQuestionCard() {
    final question = _buildQuestionText();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color.fromARGB(120, 33, 43, 31),
            const Color.fromARGB(60, 33, 43, 31),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.question_mark_rounded,
                  color: Color(0xFFFFA726),
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build question text from player data
  String _buildQuestionText() {
    if (_currentPlayer == null) return 'Loading...';

    final careerPath = _currentPlayer!['career_path']?.toString() ?? '';

    if (careerPath.isNotEmpty) {
      return 'Which player had this career path?\n$careerPath';
    }

    return 'Who is this famous football player?';
  }


  /// Build hint section with glass morphism
  Widget _buildHintSection() {
    final category = _currentPlayer!['Category']?.toString();

    if (category == null || category.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFA726).withOpacity(0.3),
            const Color(0xFFFFA726).withOpacity(0.1),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white.withOpacity(0.1),
              border: Border.all(
                color: const Color(0xFFFFA726).withOpacity(0.5),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.lightbulb_outline,
                  color: Color(0xFFFFA726),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Category: $category',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build answer input section with text field and microphone button
  Widget _buildAnswerInputSection() {
    return Row(
      children: [
        // Text input field with glass morphism
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(80, 33, 43, 31),
                  const Color.fromARGB(40, 33, 43, 31),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.white.withOpacity(0.1),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _answerController,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                    ),
                    onSubmitted: (_) => _validateAnswer(),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Microphone button with glass morphism
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: _isListening
                  ? [
                      Colors.red.withOpacity(0.8),
                      Colors.redAccent.withOpacity(0.6),
                    ]
                  : [
                      const Color(0xFFFFA726).withOpacity(0.8),
                      const Color(0xFFFF8A00).withOpacity(0.6),
                    ],
            ),
            boxShadow: [
              BoxShadow(
                color: (_isListening ? Colors.red : const Color(0xFFFFA726))
                    .withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isListening ? _stopListening : _startListening,
                  customBorder: const CircleBorder(),
                  child: Center(
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build submit button with glass morphism
  Widget _buildSubmitButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFA726).withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: ElevatedButton(
            onPressed: _validateAnswer,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_outline, size: 24),
                SizedBox(width: 12),
                Text(
                  'Submit Answer',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
