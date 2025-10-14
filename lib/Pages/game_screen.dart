import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:ui';
import '../core/game_modes_manager.dart';
import '../services/supabase/supabase_search.dart';

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

  /// Answer text controller
  final TextEditingController _answerController = TextEditingController();

  /// Supabase client instance
  final SupabaseClient _supabase = Supabase.instance.client;

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

  /// Search service instance for autocomplete functionality
  final SupabaseSearchService _searchService = searchService;

  /// Autocomplete suggestions (still used for UI but not for validation)
  List<PlayerSearchResult> _suggestions = [];

  /// Whether to show autocomplete dropdown
  bool _showSuggestions = false;

  /// Focus node for answer input
  final FocusNode _answerFocusNode = FocusNode();

  /// Debounce timer for search (still used for autocomplete UI)
  Timer? _debounceTimer;

  /// Selected player ID for validation (null if no valid selection made)
  int? _selectedPlayerId;

  // ============================================================================
  // LIFECYCLE METHODS
  // ============================================================================

  @override
  void initState() {
    super.initState();
    _initializeGame();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _answerFocusNode.dispose();
    _gameTimer?.cancel();
    _debounceTimer?.cancel();
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
      _selectedPlayerId = null; // Reset selected player for new question
    });
  }

  // ============================================================================
  // SPEECH TO TEXT INITIALIZATION
  // ============================================================================

  /// Initialize speech recognition using speech_to_text package

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
        _selectedPlayerId = null; // Reset selected player for new question
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

  // ============================================================================
  // AUTOCOMPLETE SEARCH LOGIC
  // ============================================================================

  /// Handle text change in answer field with debouncing
  void _onAnswerTextChanged(String value) {
    // Cancel previous debounce timer
    _debounceTimer?.cancel();

    // If empty, hide suggestions
    if (value.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    // Debounce search for 300ms to avoid too many requests
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(value);
    });
  }

  /// Perform fuzzy search for player suggestions
  Future<void> _performSearch(String query) async {
    try {
      final results = await _searchService.searchPlayers(
        query,
        limit: 3, // Show top 5 suggestions
      );

      setState(() {
        _suggestions = results;
        _showSuggestions = results.isNotEmpty;
      });
    } catch (e) {
      debugPrint('Error performing search: $e');
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
    }
  }

  /// Select a suggestion from the autocomplete dropdown
  /// Stores the player's ID for validation and auto-validates immediately
  void _selectSuggestion(PlayerSearchResult suggestion) {
    setState(() {
      _answerController.text = suggestion.displayName;
      _selectedPlayerId = suggestion.id; // Store the player's unique ID for validation
      _suggestions = [];
      _showSuggestions = false;
    });
    _answerFocusNode.unfocus();

    // Auto-validate the selected suggestion immediately using ID comparison
    _validateAnswer();
  }

  /// Hide autocomplete suggestions
  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
  }

  /// Build skip button (only visible in casual and rush modes)
  Widget _buildSkipButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _handleSkip,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.skip_next,
                  color: Colors.white70,
                  size: 16,
                ),
                SizedBox(width: 4),
                Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
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

  /// Handle skip button press - show correct answer and load next question
  Future<void> _handleSkip() async {
    if (_currentPlayer == null) return;

    // Show correct answer briefly
    await _showCorrectAnswerDialog(_currentPlayer!['answer']?.toString() ?? '');

    // Increment mistake count (wrong answer)
    setState(() {
      _totalAnswered++;
      // Note: _score is not incremented for skips (treats as wrong answer)
    });

    // Load next random question
    await _fetchRandomQuestion();
  }

  /// Show dialog revealing the correct answer for skipped questions
  Future<void> _showCorrectAnswerDialog(String correctAnswer) async {
    return showDialog(
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
              Icon(Icons.skip_next, color: Color(0xFFFFA726), size: 32),
              SizedBox(width: 12),
              Text('Skipped!', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: Text(
            'Correct answer: $correctAnswer',
            style: const TextStyle(color: Colors.white70, fontSize: 16),
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
                onPressed: () => Navigator.of(context).pop(),
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


  // ============================================================================
  // ANSWER VALIDATION LOGIC
  // ============================================================================

  /// Validate the user's answer by comparing selected player ID with current question's player ID
  /// This ensures exact matches using unique Supabase identifiers, preventing fuzzy mismatches
  Future<void> _validateAnswer() async {
    if (_currentPlayer == null) {
      return;
    }

    // Check if a player was selected from suggestions (required for validation)
    if (_selectedPlayerId == null) {
      _showErrorDialog('Please select a player from the list.');
      return;
    }

    // Hide suggestions when validating
    _hideSuggestions();

    // Get the current question's player ID for comparison
    final correctPlayerId = _currentPlayer!['id'] as int?;

    if (correctPlayerId == null) {
      _showErrorDialog('Error: Question data is invalid.');
      return;
    }

    // Compare the selected player ID with the current question's player ID
    // This guarantees exact matches and eliminates false positives from similar names
    final isCorrect = _selectedPlayerId == correctPlayerId;

    setState(() {
      _totalAnswered++;
      if (isCorrect) {
        _score++;
      }
      // Reset selected player ID for next question
      _selectedPlayerId = null;
    });

    if (isCorrect) {
      // Show success dialog and load next question
      final correctAnswer = _currentPlayer!['answer']?.toString() ?? '';
      _showSuccessDialog(correctAnswer);
    } else {
      // Show error message for incorrect answer
      _showIncorrectAnswerDialog();
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


  /// Show dialog for incorrect answer (strict validation)
  void _showIncorrectAnswerDialog() {
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
              Text('Incorrect', style: TextStyle(color: Colors.white)),
            ],
          ),
          content: const Text(
            'Incorrect – try again!',
            style: TextStyle(color: Colors.white70),
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
                  'Try Again',
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
          // Background with image and gradient (blur removed for performance)
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
                    Color(0xBB000000), // Slightly darker overlay to compensate for removed blur
                    Color(0x44000000), // Semi-transparent
                  ],
                ),
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

                             
 

                              // Answer input section
                              _buildAnswerInputSection(),

                              const SizedBox(height: 30),

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
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(20)),
          color: const Color.fromARGB(180, 33, 43, 31), // Solid color instead of blur
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
              // Score display and Skip button
              Row(
                children: [
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
                  // Skip button (only for casual and rush modes, disabled in Road to Glory)
                  if (widget.config?.mode != GameMode.roadToGlory) ...[
                    const SizedBox(width: 8),
                    _buildSkipButton(),
                  ],
                ],
              ),
            ],
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
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color.fromARGB(160, 33, 43, 31), // Solid color instead of blur
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
            const SizedBox(height: 20),
            // Career path timeline
            _buildCareerTimeline(),
          ],
        ),
      ),
    );
  }

  /// Build question text from player data
  String _buildQuestionText() {
    if (_currentPlayer == null) return 'Loading...';

    return 'Which player had this career path?';
  }

  /// Parse career path string into structured data for timeline display
  List<Map<String, String>> _parseCareerPath(String careerPath) {
    if (careerPath.trim().isEmpty) return [];

    // Split by semicolon and filter out empty entries
    final entries = careerPath.split(';')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return entries.map((entry) {
      // Extract club name and years from format like "Bayer 04 Leverkusen (2020–2025)"
      final regex = RegExp(r'(.+?)\s*\((\d+[^)]*)\)');
      final match = regex.firstMatch(entry);

      if (match != null) {
        return {
          'club': match.group(1)?.trim() ?? '',
          'years': match.group(2)?.trim() ?? '',
        };
      }

      // Fallback: if parsing fails, return the whole entry as club name
      return {
        'club': entry,
        'years': '',
      };
    }).toList();
  }

  /// Build career path timeline widget with vertical layout
  Widget _buildCareerTimeline() {
    if (_currentPlayer == null) return const SizedBox.shrink();

    final careerPath = _currentPlayer!['career_path']?.toString() ?? '';
    final careerEntries = _parseCareerPath(careerPath);

    if (careerEntries.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color.fromARGB(100, 33, 43, 31), // Semi-transparent background
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline entries
          ...careerEntries.asMap().entries.map((entry) {
            final careerEntry = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Timeline bullet/dot
                  Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 12, top: 2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFA726), Color(0xFFFF8A00)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFA726).withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  // Club info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Club name
                        Text(
                          careerEntry['club']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Years
                        if (careerEntry['years']!.isNotEmpty)
                          Text(
                            careerEntry['years']!,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Build answer input section with text field and autocomplete
  Widget _buildAnswerInputSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
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
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: const Color.fromARGB(120, 33, 43, 31), // Solid color instead of blur
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: TextField(
                    controller: _answerController,
                    focusNode: _answerFocusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Type your answer...',
                      hintStyle: const TextStyle(color: Colors.white38),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      suffixIcon: _answerController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.white54,
                              ),
                              onPressed: () {
                                _answerController.clear();
                                _hideSuggestions();
                              },
                            )
                          : null,
                    ),
                    onChanged: _onAnswerTextChanged,
                  ),
                ),
              ),
            ),

          ],
        ),

        // Autocomplete dropdown
        if (_showSuggestions && _suggestions.isNotEmpty)
          _buildAutocompleteDropdown(),
      ],
    );
  }

  /// Build autocomplete dropdown with suggestions
  Widget _buildAutocompleteDropdown() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(120, 33, 43, 31),
            const Color.fromARGB(80, 33, 43, 31),
          ],
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color.fromARGB(180, 33, 43, 31), // Solid color instead of blur
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: ListView.builder(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _suggestions.length,
          itemBuilder: (context, index) {
            final suggestion = _suggestions[index];
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectSuggestion(suggestion),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: index < _suggestions.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Color(0xFFFFA726),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              suggestion.displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (suggestion.category != null &&
                                suggestion.category!.isNotEmpty)
                              Text(
                                suggestion.category!,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ),
                      if (suggestion.similarity != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFA726).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(suggestion.similarity! * 100).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              color: Color(0xFFFFA726),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

}

