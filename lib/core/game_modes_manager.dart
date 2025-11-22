import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../pages/game_screen.dart';
import '../services/progress_service.dart';

/// ============================================================================
/// GAME MODES MANAGER - Universal Configuration for All Game Modes
/// ============================================================================
/// This file defines the architecture for all game modes in the app.
/// Each mode (Casual, Road to Glory, Rush) uses the same universal game screen
/// but with different configurations for:
/// - Question fetching logic
/// - Timer settings
/// - Scoring rules
/// - UI customization
///
/// This pattern makes it easy to add new game modes in the future by simply
/// creating a new GameConfiguration object.
/// ============================================================================

/// Enum to identify different game modes
enum GameMode {
  /// Casual mode - relaxed gameplay with category-specific questions
  casual,

  /// Road to Glory - progressive league-based challenges
  roadToGlory,

  /// Rush mode - timed challenge with many questions
  rush,
}

/// ============================================================================
/// GAME CONFIGURATION MODEL
/// ============================================================================
/// Holds all configuration data for a specific game mode.
/// The universal game screen reads this configuration to customize its behavior.
/// ============================================================================
class GameConfiguration {
  /// The game mode type
  final GameMode mode;

  /// Display title for the game mode
  final String title;

  /// Description of the game mode
  final String description;

  /// Function that fetches questions from Supabase
  /// Takes a SupabaseClient and returns a list of player records
  final Future<List<Map<String, dynamic>>> Function(SupabaseClient supabase)
      questionFetcher;

  /// Optional time limit in seconds (used for Rush mode)
  final int? timeLimitSeconds;

  /// Optional level number (used for Road to Glory mode)
  final int? level;

  /// Optional category filter (used for Casual mode)
  final String? category;

  /// Optional league name (used for Road to Glory mode)
  final String? leagueName;

  /// Optional league identifier (used for Road to Glory progress tracking)
  final String? leagueId;

  /// Maximum number of questions for this mode
  final int? maxQuestions;

  /// Whether to show a completion dialog when all questions are answered
  final bool showCompletionDialog;

  /// Callback when a level is completed (used for Road to Glory progress)
  /// Parameters: success (bool), level (int)
  final Function(bool success, int level)? onLevelComplete;

  const GameConfiguration({
    required this.mode,
    required this.title,
    required this.description,
    required this.questionFetcher,
    this.timeLimitSeconds,
    this.level,
    this.category,
    this.leagueName,
    this.leagueId,
    this.maxQuestions,
    this.showCompletionDialog = false,
    this.onLevelComplete,
  });
}

/// ============================================================================
/// GAME MODE CONFIGURATIONS
/// ============================================================================
/// Predefined configurations for each game mode.
/// ============================================================================

class GameModeConfigurations {
  /// ========================================================================
  /// CASUAL MODE CONFIGURATION
  /// ========================================================================
  /// - Category: 'Stars' (famous football players)
  /// - No timer
  /// - No level system
  /// - Fetches 20 random questions from the Stars category
  /// ========================================================================
  static GameConfiguration getCasualMode({String category = '2'}) {
    return GameConfiguration(
      mode: GameMode.casual,
      title: 'Casual Mode',
      description: 'Relax and enjoy football trivia at your own pace',
      category: category,
      maxQuestions: 20,
      questionFetcher: (supabase) async {
        try {
          // Fetch random players from the specified category
          // Note: order by random() requires proper SQL function support
          final response = await supabase
              .from('players')
              .select('player_id, first_name, last_name, career_path, answer, league_id')
              .eq('league_id', category)
              .limit(20);

          if (response.isEmpty) {
            throw Exception('No questions available for category: $category');
          }

          // Shuffle the results for randomness
          final List<Map<String, dynamic>> questions =
              (response as List).cast<Map<String, dynamic>>();
          questions.shuffle();
          return questions;
        } catch (e) {
          debugPrint('Error fetching casual mode questions: $e');
          rethrow;
        }
      },
    );
  }

  /// ========================================================================
  /// ROAD TO GLORY MODE CONFIGURATION
  /// ========================================================================
  /// - Each level corresponds to a specific league/difficulty
  /// - Level progression system with persistent storage
  /// - Fetches 1 question per level from specific league
  /// - Automatically unlocks next level on completion
  /// ========================================================================
  static GameConfiguration getRoadToGloryMode({
    required int level,
    required String leagueName,
    required String leagueId,
    required int databaseLeagueId,
  }) {
    // Create progress service instance
    final progressService = ProgressService();

    // Create completion callback that unlocks next level
    void onLevelComplete(bool success, int completedLevel) {
      if (success) {
        progressService.completeLevel(leagueId, completedLevel);
      }
    }

    return GameConfiguration(
      mode: GameMode.roadToGlory,
      title: 'Road to Glory - $leagueName',
      description: 'Conquer $leagueName and advance to the next level',
      level: level,
      leagueName: leagueName,
      leagueId: leagueId,
      maxQuestions: 1, // One question per level
      onLevelComplete: onLevelComplete,
      questionFetcher: (supabase) async {
        try {
          // Fetch one random player from the specified league using numeric league_id
          final response = await supabase
              .from('players')
              .select('player_id, first_name, last_name, career_path, answer, league_id')
              .eq('league_id', databaseLeagueId)
              .limit(10); // Fetch 10 to have variety

          if (response.isEmpty) {
            throw Exception('No questions available for league: $leagueName (ID: $databaseLeagueId)');
          }

          // Pick a random question from the results
          final List<Map<String, dynamic>> questions =
              (response as List).cast<Map<String, dynamic>>();
          questions.shuffle();
          return [questions.first]; // Return only one question
        } catch (e) {
          debugPrint('Error fetching Road to Glory questions: $e');
          rethrow;
        }
      },
    );
  }

  /// ========================================================================
  /// RUSH MODE CONFIGURATION
  /// ========================================================================
  /// - 50 random questions from all categories
  /// - 2-minute (120 seconds) countdown timer
  /// - Score tracking for correct answers
  /// - Shows completion dialog when all questions answered or time expires
  /// ========================================================================
  static GameConfiguration getRushMode() {
    return GameConfiguration(
      mode: GameMode.rush,
      title: 'Rush Mode',
      description: 'Answer 50 questions in 2 minutes!',
      timeLimitSeconds: 120, // 2 minutes
      maxQuestions: 50,
      showCompletionDialog: true,
      questionFetcher: (supabase) async {
        try {
          // Fetch 50 random players from all categories
          final response = await supabase
              .from('players')
              .select('player_id, first_name, last_name, career_path, answer, league_id')
              .limit(100); // Fetch more to randomize from

          if (response.isEmpty) {
            throw Exception('No questions available for Rush mode');
          }

          // Shuffle and return 50 questions
          final List<Map<String, dynamic>> questions =
              (response as List).cast<Map<String, dynamic>>();
          questions.shuffle();
          return questions.take(50).toList();
        } catch (e) {
          debugPrint('Error fetching Rush mode questions: $e');
          rethrow;
        }
      },
    );
  }

  /// ========================================================================
  /// LEAGUE NAME MAPPING FOR ROAD TO GLORY
  /// ========================================================================
  /// Maps level numbers to league names.
  /// ========================================================================
  static String getLeagueNameForLevel(int level) {
    switch (level) {
      case 1:
        return 'Premier League';
      case 2:
        return 'La Liga';
      case 3:
        return 'Serie A';
      case 4:
        return 'Bundesliga';
      case 5:
        return 'Ligue 1';
      default:
        return 'Stars'; // Fallback to Stars category
    }
  }

  /// ========================================================================
  /// LEAGUE ID MAPPING FOR ROAD TO GLORY
  /// ========================================================================
  /// Maps league identifier strings to database league IDs.
  /// Database league IDs:
  /// - 1: Serie A (Italy)
  /// - 2: Premier League (England)
  /// - 3: Bundesliga (Germany)
  /// - 4: La Liga (Spain)
  /// - 5: Ligue 1 (France)
  /// ========================================================================
  static int getDatabaseLeagueId(String leagueId) {
    switch (leagueId.toLowerCase()) {
      case 'italian':
      case 'italy':
        return 1; // Serie A
      case 'english':
      case 'england':
        return 2; // Premier League
      case 'german':
      case 'germany':
        return 3; // Bundesliga
      case 'spanish':
      case 'spain':
        return 4; // La Liga
      case 'french':
      case 'france':
        return 5; // Ligue 1
      default:
        return 2; // Default to Premier League
    }
  }
}

/// ============================================================================
/// NAVIGATION FUNCTIONS
/// ============================================================================
/// Helper functions to navigate to the universal game screen with proper
/// configuration for each game mode.
/// ============================================================================

class GameModeNavigator {
  /// Navigate to Casual Mode
  static void startCasualMode(
    BuildContext context, {
    String category = "2",
  }) {
    final config = GameModeConfigurations.getCasualMode(category: category);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(config: config),
      ),
    );
  }

  /// Navigate to Road to Glory Mode
  /// [level] - The current level number
  /// [leagueId] - The league identifier for progress tracking
  static void startRoadToGloryMode(
    BuildContext context, {
    required int level,
    required String leagueId,
  }) {
    final leagueName = GameModeConfigurations.getLeagueNameForLevel(level);
    final databaseLeagueId = GameModeConfigurations.getDatabaseLeagueId(leagueId);
    final config = GameModeConfigurations.getRoadToGloryMode(
      level: level,
      leagueName: leagueName,
      leagueId: leagueId,
      databaseLeagueId: databaseLeagueId,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(config: config),
      ),
    );
  }

  /// Navigate to Rush Mode
  static void startRushMode(BuildContext context) {
    final config = GameModeConfigurations.getRushMode();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameScreen(config: config),
      ),
    );
  }
}

