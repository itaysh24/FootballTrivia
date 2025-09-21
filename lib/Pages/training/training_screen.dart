// lib/pages/training/training_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:football_trivia/pages/training/services/training_game_service.dart';
import 'package:football_trivia/pages/training/services/training_image_service.dart';
import 'package:football_trivia/pages/training/services/training_timer_service.dart';
import 'package:football_trivia/pages/training/widgets/training_score_widget.dart';
import '../../main.dart';
import '../training/widgets/training_timer_widget.dart';
import '../training/widgets/training_career_widget.dart';
import '../training/widgets/training_slots_widget.dart';
import '../training/widgets/training_letter_pool_widget.dart';
import '../training/widgets/training_controls_widget.dart';

class TrainingScreen extends StatefulWidget {
  const TrainingScreen({super.key});

  @override
  State<TrainingScreen> createState() => _TrainingScreenState();
}

class _TrainingScreenState extends State<TrainingScreen> {
  late TrainingGameService _gameService;
  late TrainingTimerService _timerService;
  late TrainingImageService _imageService;
  
  @override
  void initState() {
    super.initState();
    musicService.stopLooping();
    _initializeServices();
    _initializeGame();
  }

  void _initializeServices() {
    _gameService = TrainingGameService();
    _timerService = TrainingTimerService(
      onTimeUp: _onTimeUp,
      onTimerUpdate: () => setState(() {}),
    );
    _imageService = TrainingImageService();
  }

  Future<void> _initializeGame() async {
    await _gameService.loadQuestions();
    // ignore: use_build_context_synchronously
    await _imageService.loadImages(context);
    
    if (!mounted) return;
    
    if (_gameService.questions.isNotEmpty) {
      _gameService.prepareQuestion(_imageService.getRandomImage());
      _timerService.startTimer();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _timerService.dispose();
    musicService.startLooping();
    super.dispose();
  }

  void _onTimeUp() {
    _gameService.disableInput();
    _showTimeUpDialog();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black.withOpacity(0.8),
                const Color.fromARGB(221, 170, 123, 21).withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.timer_off,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Time\'s Up!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'The correct answer was: ${_gameService.currentQuestion?.answer ?? ''}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _nextQuestion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue Training',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _showCorrectDialog(int pointsGained) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Container(
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.withOpacity(0.8),
                Colors.green.shade700.withOpacity(0.9),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Excellent!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You earned $pointsGained points!',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _nextQuestion();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.green.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Continue Training',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  void _nextQuestion() {
    _gameService.nextQuestion(_imageService.getRandomImage());
    _timerService.startTimer();
    setState(() {});
  }

  void _skipQuestion() {
    _nextQuestion();
  }

  void _removeLastLetter() {
    if (_gameService.removeLastLetter()) {
      setState(() {});
    }
  }

  void _onLetterSelected(int poolIndex) {
    if (_gameService.selectLetter(poolIndex)) {
      setState(() {});
      _checkAnswer();
    }
  }

  void _onSlotTapped(int slotIndex) {
    if (_gameService.clearSlot(slotIndex)) {
      setState(() {});
    }
  }

  void _checkAnswer() {
    final result = _gameService.checkAnswer(_timerService.secondsLeft);
    if (result.isCorrect) {
      _timerService.stop();
      _showCorrectDialog(result.pointsGained);
    } else if (result.showError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Not quite right - keep trying!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange.shade700,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gameService.questions.isEmpty) {
      return Scaffold(
        backgroundColor: const Color.fromARGB(221, 170, 123, 21),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromARGB(221, 170, 123, 21),
                Colors.black.withOpacity(0.8),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              _gameService.currentImage,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color.fromARGB(221, 170, 123, 21),
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
          ),
          
          // Game content overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                children: [
                // Header with timer and score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TrainingTimerWidget(
                      secondsLeft: _timerService.secondsLeft,
                    ),
                    TrainingScoreWidget(
                      score: _gameService.score,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                
                // Career path section
                TrainingCareerWidget(
                  careerPath: _gameService.currentQuestion?.careerPath ?? [],
                ),
                const SizedBox(height: 28),
                
                // Answer slots
                TrainingSlotsWidget(
                  firstName: _gameService.firstName,
                  lastName: _gameService.lastName,
                  slots: _gameService.slots,
                  screenWidth: MediaQuery.of(context).size.width,
                  onSlotTapped: _onSlotTapped,
                  inputDisabled: _gameService.inputDisabled,
                ),
                const SizedBox(height: 24),
                
                // Letter pool
                Expanded(
                  child: TrainingLetterPoolWidget(
                    pool: _gameService.pool,
                    screenWidth: MediaQuery.of(context).size.width,
                    onLetterSelected: _onLetterSelected,
                    inputDisabled: _gameService.inputDisabled,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Control buttons
                TrainingControlsWidget(
                  onSkip: _skipQuestion,
                  onRemoveLetter: _removeLastLetter,
                ),
              ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}