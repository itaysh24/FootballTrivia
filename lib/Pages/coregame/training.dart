// lib/pages/game/game_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:football_trivia/models/question_model.dart';
import '../../main.dart'; // Import to access global music service

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _PoolLetter {
  final String char;
  bool used;
  _PoolLetter(this.char) : used = false;
}

class _GameScreenState extends State<GameScreen> {
  List<Question> questions = [];
  int currentIndex = 0;
  List<String> availableImages = [];

  late String correctAnswer;
  late List<String?> slots;
  late List<int?> slotAssignedPoolIndex;
  late List<_PoolLetter> pool;
  late String firstName;
  late String lastName;
  late int firstNameLength;
  late int lastNameLength;
  int score = 0;

  late int secondsLeft;
  Timer? _timer;

  bool inputDisabled = false;
  String currentImage = '';
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    musicService.stopLooping(); // Stop music when entering game
    _initializeGame();
  }

  Future<void> _initializeGame() async {
    await Future.wait([
      loadQuestions(),
      loadRandomImages(),
    ]);
    
   
    if (questions.isNotEmpty) {
      _prepareQuestion();
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    musicService.startLooping(); // Resume music when leaving game
    super.dispose();
  }

  Future<void> loadQuestions() async {
    try {
      final String response = await rootBundle.loadString('assets/questions.json');
      final data = json.decode(response) as List;
      setState(() {
        questions = data.map((q) => Question.fromJson(q)).toList();
      });
    } catch (e) {
      print('Error loading questions: $e');
    }
  }

  Future<void> loadRandomImages() async {
    try {
      // Dynamically discover all images in the QuestionsFrames folder
      final manifestContent = await DefaultAssetBundle.of(context).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      
      // Filter for images in the QuestionsFrames folder
      final imageKeys = manifestMap.keys
          .where((String key) => key.startsWith('assets/images/QuestionsFrames/'))
          .where((String key) => key.toLowerCase().endsWith('.jpg') || 
                                 key.toLowerCase().endsWith('.jpeg') || 
                                 key.toLowerCase().endsWith('.png'))
          .toList();
      
      setState(() {
        availableImages = imageKeys;
        availableImages.shuffle(_rnd);
      });
      
      print('Found ${availableImages.length} images in QuestionsFrames folder');
    } catch (e) {
      print('Error loading images: $e');
      // Fallback to empty list if scanning fails
      setState(() {
        availableImages = [];
      });
    }
  }

  String _normalize(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');

  void _prepareQuestion() {
    if (questions.isEmpty) return;
    
    final current = questions[currentIndex];
    correctAnswer = _normalize(current.answer);

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

    pool = <_PoolLetter>[];
    for (final ch in correctAnswer.split('')) {
      pool.add(_PoolLetter(ch));
    }

    const poolSize = 14;
    const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    while (pool.length < poolSize) {
      pool.add(_PoolLetter(letters[_rnd.nextInt(letters.length)]));
    }

    pool.shuffle(_rnd);

    if (availableImages.isNotEmpty) {
      currentImage = availableImages[_rnd.nextInt(availableImages.length)];
      print('Selected image for question ${currentIndex + 1}: $currentImage');
    } else {
      currentImage = '';
      print('Warning: No images available for question ${currentIndex + 1}');
    }

    inputDisabled = false;
  }

  void _startTimer({int start = 60}) {
    _timer?.cancel();
    secondsLeft = start;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        if (secondsLeft > 0) {
          secondsLeft--;
          if (secondsLeft == 0) {
            inputDisabled = true;
            _onTimeUp();
          }
        }
      });
    });
  }

  void _onTimeUp() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Time is up'),
        content: const Text('You ran out of time.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetQuestion();
            },
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }

  void _resetQuestion() {
    setState(() {
      currentIndex = (currentIndex + 1) % questions.length;
      _prepareQuestion();
      _startTimer();
    });
  }

  void _onLetterSelected(int poolIndex) {
    if (inputDisabled) return;
    if (poolIndex < 0 || poolIndex >= pool.length) return;
    final item = pool[poolIndex];
    if (item.used) return;

    final slotIndex = slots.indexWhere((s) => s == null);
    if (slotIndex == -1) return;

    setState(() {
      slots[slotIndex] = item.char;
      slotAssignedPoolIndex[slotIndex] = poolIndex;
      item.used = true;
    });

    _checkIfComplete();
  }

  void _onSlotTapped(int slotIndex) {
    if (inputDisabled) return;
    final assignedPool = slotAssignedPoolIndex[slotIndex];
    if (assignedPool != null) {
      setState(() {
        pool[assignedPool].used = false;
        slots[slotIndex] = null;
        slotAssignedPoolIndex[slotIndex] = null;
      });
    }
  }

  void _checkIfComplete() {
    if (slots.any((s) => s == null)) return;

    final assembled = slots.map((s) => s!).join();
    if (_normalize(assembled) == correctAnswer) {
      final gained = 10 + (secondsLeft);
      setState(() {
        score += gained;
        inputDisabled = true;
      });

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Correct!'),
          content: Text('You scored $gained points.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetQuestion();
              },
              child: const Text('Next'),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not correct — try again!'), duration: Duration(seconds: 1)),
      );
    }
  }

  String _formatTime(int seconds) {
    final s = seconds % 60;
    final m = seconds ~/ 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final screenW = MediaQuery.of(context).size.width;
    
    // Define a safe zone for placeholders (90% of screen width)
    final safeZoneWidth = screenW;
    final safeZonePadding = (screenW - safeZoneWidth); // Center the zone
    
    // Find the row that needs the most space (longest name)
    final maxNameLength = max(firstNameLength, lastNameLength);
    
    // Calculate slot size to fit within the safe zone
    // Account for margins between slots (2px each side = 4px per slot)
    final slotSize = (safeZoneWidth - (maxNameLength * 4)) / maxNameLength;
    
    // Clamp to reasonable bounds - smaller minimum for very long names
    final finalSlotSize = slotSize.clamp(15.0, 50.0);

    return Scaffold(
      
      backgroundColor: const Color.fromARGB(221, 170, 123, 21),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          _formatTime(secondsLeft),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.yellow),
                        const SizedBox(width: 8),
                        Text(
                          '$score',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              // Image section
              Center(
                child: Container(
                  width: min(200, screenW * 0.5),
                  height: min(200, screenW * 0.5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                    color: Colors.black26,
                  ),
                  child: currentImage.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.asset(currentImage, fit: BoxFit.cover, errorBuilder: (_, _, _) {
                            return const Center(child: Icon(Icons.image_not_supported, color: Colors.white30));
                          }),
                        )
                      : const Center(child: Icon(Icons.image, color: Colors.white30)),
                ),
              ),
              const SizedBox(height: 16),
              // Career path section - under the image
              _buildCareerPath(),
              const SizedBox(height: 28),
              // Answer slots with safe zone constraint
              Container(
                width: safeZoneWidth,
                margin: EdgeInsets.symmetric(horizontal: safeZonePadding),
                decoration: BoxDecoration(
                  // Optional: Visual border to show safe zone (remove in production)
                  // border: Border.all(color: Colors.red.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  children: [
                    // First name row
                    if (firstNameLength > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(firstNameLength, (i) {
                          return GestureDetector(
                            onTap: () => _onSlotTapped(i),
                            child: _buildSlot(i, finalSlotSize),
                          );
                        }),
                      ),
                      const SizedBox(height: 8),
                    ],
                    // Last name row
                    if (lastNameLength > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(lastNameLength, (i) {
                          final idx = firstNameLength + i;
                          return GestureDetector(
                            onTap: () => _onSlotTapped(idx),
                            child: _buildSlot(idx, finalSlotSize),
                          );
                        }),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Letter pool without card - direct layout like placeholders
              _buildLetterPoolDirect(screenW),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  OutlinedButton.icon(
                    onPressed: _resetQuestion,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text('Skip', style: TextStyle(color: Colors.white)),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      final lastFilled = slots.lastIndexWhere((s) => s != null);
                      if (lastFilled != -1) _onSlotTapped(lastFilled);
                    },
                    icon: const Icon(Icons.backspace, color: Colors.white),
                    label: const Text('Back', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(int idx, double slotSize) {
    final content = slots[idx];
    final fontSize = (slotSize * 0.5).clamp(8.0, 20.0); // Even smaller font for very small slots
    
    // Use even smaller margins for very small slots
    final margin = slotSize < 30 ? 1.0 : 2.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      width: slotSize,
      height: slotSize * 1.2, // Slightly taller than wide
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: content == null ? Colors.white10 : Colors.white24,
        borderRadius: BorderRadius.circular(slotSize < 30 ? 3 : 4), // Smaller radius for very small slots
        border: Border.all(color: Colors.orange, width: slotSize < 30 ? 0.5 : 1.0), // Thinner border for very small slots
      ),
      child: Text(
        content ?? '',
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildCareerPath() {
    final careerPath = questions.isNotEmpty ? questions[currentIndex].careerPath : [];
    final isLongCareer = careerPath.length > 6; // Use 2 columns if more than 6 items
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Career', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        if (isLongCareer) ...[
          // Two columns for long career paths
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: careerPath.take((careerPath.length / 2).ceil()).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  )).toList(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: careerPath.skip((careerPath.length / 2).ceil()).map((c) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 1),
                    child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 15)),
                  )).toList(),
                ),
              ),
            ],
          ),
        ] else ...[
          // Single column for short career paths
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: careerPath.map((c) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(c, style: const TextStyle(color: Colors.white, fontSize: 15)),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLetterPoolDirect(double screenWidth) {
    const maxRows = 2; // Restrict to 2 rows maximum
    final availableWidth = screenWidth - 28; // Account for padding
    
    // Calculate optimal distribution across max 2 rows
    final lettersPerRow = (pool.length / maxRows).ceil();
    final actualRows = (pool.length / lettersPerRow).ceil();
    final finalRows = actualRows > maxRows ? maxRows : actualRows;
    final finalLettersPerRow = (pool.length / finalRows).ceil();
    
    // Calculate button size to fit within screen bounds - smaller for better fit
    final buttonSize = (availableWidth / finalLettersPerRow - 8).clamp(30.0, 50.0);
    final fontSize = (buttonSize * 0.4).clamp(10.0, 18.0);
    
    // Split pool into rows
    final rows = <List<_PoolLetter>>[];
    for (int i = 0; i < pool.length; i += finalLettersPerRow) {
      final endIndex = (i + finalLettersPerRow).clamp(0, pool.length);
      rows.add(pool.sublist(i, endIndex));
    }
    
    // Direct layout without card - just like placeholders
    return Column(
      children: rows.map((row) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final globalIndex = rows.indexOf(row) * finalLettersPerRow + index;
            
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: SizedBox(
                width: buttonSize,
                height: buttonSize,
                child: ElevatedButton(
                  onPressed: item.used || inputDisabled ? null : () => _onLetterSelected(globalIndex),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.used ? Colors.white10 : Colors.orange,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    item.char,
                    style: TextStyle(
                      color: item.used ? Colors.white38 : Colors.black,
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      )).toList(),
    );
  }
}
