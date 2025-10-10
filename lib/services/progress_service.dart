import 'package:shared_preferences/shared_preferences.dart';

/// ============================================================================
/// PROGRESS SERVICE - Road to Glory Level Progression Management
/// ============================================================================
/// Manages user progress for Road to Glory mode using SharedPreferences.
/// Each league has independent progress tracking with unlocked levels.
/// ============================================================================

class ProgressService {
  /// Storage key prefix for Road to Glory progress
  static const String _keyPrefix = 'rtg_progress_';

  /// Get all unlocked levels for a specific league
  /// Returns a Set of unlocked level numbers (always includes level 1)
  Future<Set<int>> getUnlockedLevels(String leagueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$leagueId';
      final progressString = prefs.getString(key);

      if (progressString == null || progressString.isEmpty) {
        // First time playing this league - only level 1 is unlocked
        return {1};
      }

      // Parse comma-separated list of level numbers
      final levels = progressString
          .split(',')
          .where((s) => s.isNotEmpty)
          .map((s) => int.tryParse(s))
          .whereType<int>()
          .toSet();

      // Ensure level 1 is always unlocked
      levels.add(1);

      return levels;
    } catch (e) {
      print('Error loading progress for $leagueId: $e');
      return {1}; // Fallback to level 1 unlocked
    }
  }

  /// Unlock a specific level for a league
  /// Saves the updated progress to SharedPreferences
  Future<void> unlockLevel(String leagueId, int level) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentLevels = await getUnlockedLevels(leagueId);
      
      // Add the new level to the set
      currentLevels.add(level);
      
      // Save back to storage
      final key = '$_keyPrefix$leagueId';
      final progressString = currentLevels.toList()..sort();
      await prefs.setString(key, progressString.join(','));
      
      print('Unlocked level $level for $leagueId');
    } catch (e) {
      print('Error unlocking level $level for $leagueId: $e');
    }
  }

  /// Complete a level and automatically unlock the next level
  /// Returns true if successful
  Future<bool> completeLevel(String leagueId, int level) async {
    try {
      final nextLevel = level + 1;
      
      // Unlock the next level (max 100 levels per league)
      if (nextLevel <= 100) {
        await unlockLevel(leagueId, nextLevel);
        print('Completed level $level for $leagueId, unlocked level $nextLevel');
        return true;
      } else {
        print('Level $level completed for $leagueId - final level!');
        return true;
      }
    } catch (e) {
      print('Error completing level $level for $leagueId: $e');
      return false;
    }
  }

  /// Reset progress for a specific league (for testing/debug)
  Future<void> resetLeagueProgress(String leagueId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$leagueId';
      await prefs.remove(key);
      print('Reset progress for $leagueId');
    } catch (e) {
      print('Error resetting progress for $leagueId: $e');
    }
  }

  /// Reset all Road to Glory progress (for testing/debug)
  Future<void> resetAllProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final allKeys = prefs.getKeys();
      
      // Remove all RTG progress keys
      for (final key in allKeys) {
        if (key.startsWith(_keyPrefix)) {
          await prefs.remove(key);
        }
      }
      
      print('Reset all Road to Glory progress');
    } catch (e) {
      print('Error resetting all progress: $e');
    }
  }

  /// Get the highest unlocked level for a league
  Future<int> getHighestUnlockedLevel(String leagueId) async {
    final levels = await getUnlockedLevels(leagueId);
    return levels.isEmpty ? 1 : levels.reduce((a, b) => a > b ? a : b);
  }

  /// Check if a specific level is unlocked
  Future<bool> isLevelUnlocked(String leagueId, int level) async {
    final levels = await getUnlockedLevels(leagueId);
    return levels.contains(level);
  }
}

