// lib/pages/training/services/training_game_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:football_trivia/models/question_model.dart';

class AnswerCheckResult {
  final bool isCorrect;
  final bool showError;
  final int pointsGained;

  AnswerCheckResult({
    required this.isCorrect,
    required this.showError,
    required this.pointsGained,
  });
}

class PoolLetter {
  final String char;
  bool used;
  PoolLetter(this.char) : used = false;
}

class TrainingGameService {
  List<Question> questions = [];
  int currentIndex = 0;
  int score = 0;
  bool inputDisabled = false;
  
  String currentImage = '';
  String correctAnswer = '';
  List<String?> slots = [];
  List<int?> slotAssignedPoolIndex = [];
  List<PoolLetter> pool = [];
  String firstName = '';
  String lastName = '';
  int firstNameLength = 0;
  int lastNameLength = 0;
  
  final Random _rnd = Random();
  
  Question? get currentQuestion => 
      questions.isNotEmpty ? questions[currentIndex] : null;

  Future<void> loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(response) as List;
      questions = data.map((q) => Question.fromJson(q)).toList();
      
      // Shuffle questions for training variety
      questions.shuffle(_rnd);
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  String _normalize(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  void prepareQuestion(String imagePath) {
    if (questions.isEmpty) return;
    
    final current = questions[currentIndex];
    correctAnswer = _normalize(current.answer);
    currentImage = imagePath;

    // Split the answer into words and create separate slots for first and last name
    final words = current.answer.trim().split(RegExp(r'\s+'));
    firstName = words.isNotEmpty ? words[0] : '';
    lastName = words.length > 1 ? words.sublist(1).join(' ') : '';
    firstNameLength = firstName.length;
    lastNameLength = lastName.length;
    
    // Create slots for first name and last name separately
    final firstNameSlots = List<String?>.filled(firstNameLength, null);
    final lastNameSlots = List<String?>.filled(lastNameLength, null);
    
    // Combine slots for the overall game logic
    slots = [...firstNameSlots, ...lastNameSlots];
    slotAssignedPoolIndex = List<int?>.filled(slots.length, null);

    // Create letter pool
    pool = <PoolLetter>[];
    for (final ch in correctAnswer.split('')) {
      pool.add(PoolLetter(ch));
    }

    // Add random letters to make it challenging
    const poolSize = 14;
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (pool.length < poolSize) {
      pool.add(PoolLetter(letters[_rnd.nextInt(letters.length)]));
    }

    pool.shuffle(_rnd);
    inputDisabled = false;
  }

  void nextQuestion([String? imagePath]) {
    currentIndex = (currentIndex + 1) % questions.length;
    prepareQuestion(imagePath ?? currentImage);
  }

  bool selectLetter(int poolIndex) {
    if (inputDisabled || poolIndex < 0 || poolIndex >= pool.length) return false;
    
    final item = pool[poolIndex];
    if (item.used) return false;

    final slotIndex = slots.indexWhere((s) => s == null);
    if (slotIndex == -1) return false;

    slots[slotIndex] = item.char;
    slotAssignedPoolIndex[slotIndex] = poolIndex;
    item.used = true;
    
    return true;
  }

  bool clearSlot(int slotIndex) {
    if (inputDisabled) return false;
    
    final assignedPool = slotAssignedPoolIndex[slotIndex];
    if (assignedPool != null) {
      pool[assignedPool].used = false;
      slots[slotIndex] = null;
      slotAssignedPoolIndex[slotIndex] = null;
      return true;
    }
    return false;
  }

  bool removeLastLetter() {
    final lastFilled = slots.lastIndexWhere((s) => s != null);
    if (lastFilled != -1) {
      return clearSlot(lastFilled);
    }
    return false;
  }

  AnswerCheckResult checkAnswer(int secondsLeft) {
    if (slots.any((s) => s == null)) {
      return AnswerCheckResult(
        isCorrect: false,
        showError: false,
        pointsGained: 0,
      );
    }

    final assembled = slots.map((s) => s!).join();
    if (_normalize(assembled) == correctAnswer) {
      final pointsGained = 10 + secondsLeft;
      score += pointsGained;
      inputDisabled = true;
      
      return AnswerCheckResult(
        isCorrect: true,
        showError: false,
        pointsGained: pointsGained,
      );
    } else {
      return AnswerCheckResult(
        isCorrect: false,
        showError: true,
        pointsGained: 0,
      );
    }
  }

  void disableInput() {
    inputDisabled = true;
  }
}