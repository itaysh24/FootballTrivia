import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/game_modes_manager.dart';
import '../../services/progress_service.dart';
import '../game_screen.dart';

class GermanLeagueMapScreen extends StatefulWidget {
  const GermanLeagueMapScreen({super.key});

  @override
  State<GermanLeagueMapScreen> createState() => _GermanLeagueMapScreenState();
}

class _GermanLeagueMapScreenState extends State<GermanLeagueMapScreen> {
  // Track which levels are unlocked
  Set<int> unlockedLevels = {};
  int currentPage = 0;
  final int levelsPerPage = 20;
  final int totalLevels = 100;
  late ProgressService _progressService;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _progressService = ProgressService();
    _loadProgress();
  }

  /// Load progress from SharedPreferences
  Future<void> _loadProgress() async {
    final levels = await _progressService.getUnlockedLevels('german');
    setState(() {
      unlockedLevels = levels;
      _isLoading = false;
    });
  }

  /// Refresh progress when returning from a level
  Future<void> _refreshProgress() async {
    await _loadProgress();
  }

  int get totalPages => (totalLevels / levelsPerPage).ceil();

  List<int> get currentPageLevels {
    final startLevel = currentPage * levelsPerPage + 1;
    final endLevel = (startLevel + levelsPerPage - 1).clamp(1, totalLevels);
    return List.generate(
      endLevel - startLevel + 1,
      (index) => startLevel + index,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'German League',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Background image with glassy effect
          Positioned.fill(
            child: Image.asset(
              "assets/images/maps/german_map.jpg",
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0x99000000), // Black with 0.6 opacity
                    const Color(0x00000000), // Transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 2.0, sigmaY: 2.0),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          // Content with glassy container
          Positioned(
            top: 170,
            left: 16,
            right: 16,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFFA726),
                    ),
                  )
                : Container(
              constraints: BoxConstraints(
                maxHeight:
                    MediaQuery.of(context).size.height -
                    300, // Max height constraint
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color.fromARGB(
                      120,
                      33,
                      43,
                      31,
                    ), // Semi-transparent dark
                    const Color.fromARGB(60, 33, 43, 31), // More transparent
                    Colors.transparent, // Fully transparent at bottom
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
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min, // Add this to minimize height
                        children: [
                          const Text(
                            'German League',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Flexible(
                            // Change from Expanded to Flexible
                            child: _buildLevelGrid(),
                          ),
                          const SizedBox(height: 10),
                          _buildPaginationControls(),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous page button
          GestureDetector(
            onTap: currentPage > 0
                ? () {
                    setState(() {
                      currentPage--;
                    });
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: currentPage > 0
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
              ),
              child: Icon(
                Icons.chevron_left,
                color: currentPage > 0 ? Colors.white : Colors.grey,
                size: 24,
              ),
            ),
          ),
          // Page indicator
          Text(
            'Page ${currentPage + 1} of $totalPages',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Next page button
          GestureDetector(
            onTap: currentPage < totalPages - 1
                ? () {
                    setState(() {
                      currentPage++;
                    });
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: currentPage < totalPages - 1
                    ? Colors.white.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.2),
              ),
              child: Icon(
                Icons.chevron_right,
                color: currentPage < totalPages - 1
                    ? Colors.white
                    : Colors.grey,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Row 1
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentPageLevels.take(5).map((levelNumber) {
              final isUnlocked = unlockedLevels.contains(levelNumber);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildLevelCard(levelNumber, isUnlocked),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Row 2
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentPageLevels.skip(5).take(5).map((levelNumber) {
              final isUnlocked = unlockedLevels.contains(levelNumber);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildLevelCard(levelNumber, isUnlocked),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Row 3
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentPageLevels.skip(10).take(5).map((levelNumber) {
              final isUnlocked = unlockedLevels.contains(levelNumber);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildLevelCard(levelNumber, isUnlocked),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // Row 4
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: currentPageLevels.skip(15).take(5).map((levelNumber) {
              final isUnlocked = unlockedLevels.contains(levelNumber);
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: _buildLevelCard(levelNumber, isUnlocked),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int levelNumber, bool isUnlocked) {
    return GestureDetector(
      onTap: () {
        if (isUnlocked) {
          _showLevelDialog(context, levelNumber);
        } else {
          _showLockedDialog(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isUnlocked
                ? [
                    const Color.fromARGB(120, 255, 255, 0), // Yellow
                    const Color.fromARGB(100, 255, 255, 0),
                  ]
                : [
                    const Color.fromARGB(80, 100, 100, 100), // Gray
                    const Color.fromARGB(60, 100, 100, 100),
                  ],
          ),
          border: Border.all(
            color: isUnlocked
                ? Colors.white.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.1),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.sports_soccer : Icons.lock,
                      color: isUnlocked ? Colors.white : Colors.grey,
                      size: 25,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$levelNumber',
                      style: TextStyle(
                        color: isUnlocked ? Colors.white : Colors.grey,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLevelDialog(BuildContext context, int levelNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Text('Level $levelNumber'),
        content: const Text('Ready to start this level?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // Navigate to game using GameConfiguration
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GameScreen(
                    config: GameModeConfigurations.getRoadToGloryMode(
                      level: levelNumber,
                      leagueName: 'Bundesliga',
                      leagueId: 'german',
                    ),
                  ),
                ),
              );
              // Refresh progress after returning from game
              _refreshProgress();
            },
            child: const Text('Start Level'),
          ),
        ],
      ),
    );
  }

  void _showLockedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: const Text('Level Locked'),
        content: const Text('Complete previous levels to unlock this one.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
