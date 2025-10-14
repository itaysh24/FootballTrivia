

// ignore_for_file: unused_element, dead_code

import 'package:flutter/material.dart';
import 'supabase_search.dart';
/// ============================================================================
/// FUZZY SEARCH USAGE EXAMPLES
/// ============================================================================
/// This file contains practical examples of using the SupabaseSearchService
/// in various scenarios within the Football Trivia app.
/// ============================================================================
/// Example 1: Basic Player Search
/// Use case: Search bar in a player browser screen
Future<void> exampleBasicSearch() async {
  final searchService = SupabaseSearchService();
  
  // Search for players with "ronaldo" in their name
  final results = await searchService.searchPlayers('ronaldo', limit: 10);
  
  for (final player in results) {
    print('${player.displayName} - Category: ${player.category}');
    if (player.similarity != null) {
      print('  Match: ${(player.similarity! * 100).toStringAsFixed(0)}%');
    }
  }
}

/// Example 2: Autocomplete Widget
/// Use case: Live suggestions as user types
class PlayerAutocompleteExample extends StatefulWidget {
  const PlayerAutocompleteExample({super.key});

  @override
  State<PlayerAutocompleteExample> createState() => _PlayerAutocompleteExampleState();
}

class _PlayerAutocompleteExampleState extends State<PlayerAutocompleteExample> {
  final TextEditingController _controller = TextEditingController();
  final SupabaseSearchService _searchService = SupabaseSearchService();
  List<PlayerSearchResult> _suggestions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() async {
    final query = _controller.text;
    
    if (query.isEmpty) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final results = await _searchService.searchPlayers(query, limit: 5);
    
    setState(() {
      _suggestions = results;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: _controller,
          decoration: const InputDecoration(
            hintText: 'Search for a player...',
          ),
        ),
        if (_isLoading)
          const CircularProgressIndicator()
        else if (_suggestions.isNotEmpty)
          ListView.builder(
            shrinkWrap: true,
            itemCount: _suggestions.length,
            itemBuilder: (context, index) {
              final suggestion = _suggestions[index];
              return ListTile(
                title: Text(suggestion.displayName),
                subtitle: Text(suggestion.category ?? ''),
                onTap: () {
                  _controller.text = suggestion.displayName;
                  setState(() {
                    _suggestions = [];
                  });
                },
              );
            },
          ),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Example 3: Answer Validation in Quiz
/// Use case: Check if user's answer is correct using fuzzy matching
class QuizAnswerValidator {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<bool> validateAnswer({
    required String userAnswer,
    required int correctPlayerId,
    required String correctPlayerName,
  }) async {
    // Try ID-based validation first
    final idMatch = await _searchService.isCorrectAnswer(
      userAnswer,
      correctPlayerId,
      threshold: 0.3,
    );

    if (idMatch) {
      return true;
    }

    // Try name-based validation as fallback
    final nameMatch = await _searchService.isCorrectAnswerByName(
      userAnswer,
      correctPlayerName,
      threshold: 0.3,
    );

    return nameMatch;
  }
}

/// Example 4: "Did You Mean?" Feature
/// Use case: Suggest correct spelling when no exact match found
class DidYouMeanExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<String?> getSuggestion(String query) async {
    // Get the best match for the query
    final bestMatch = await _searchService.findBestMatch(query);
    
    if (bestMatch == null) {
      return null;
    }

    // Only suggest if similarity is reasonable but not perfect
    if (bestMatch.similarity != null) {
      if (bestMatch.similarity! > 0.3 && bestMatch.similarity! < 0.9) {
        return bestMatch.displayName;
      }
    }

    return null;
  }

  Future<void> showSuggestionDialog(BuildContext context, String query) async {
    final suggestion = await getSuggestion(query);
    
    if (suggestion != null && context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Did you mean?'),
          content: Text(suggestion),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
    }
  }
}

/// Example 5: Batch Search
/// Use case: Pre-load multiple player searches for comparison
class BatchSearchExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<Map<String, List<PlayerSearchResult>>> batchSearch(
    List<String> queries,
  ) async {
    final results = <String, List<PlayerSearchResult>>{};

    // Perform searches in parallel
    await Future.wait(
      queries.map((query) async {
        final searchResults = await _searchService.searchPlayers(query);
        results[query] = searchResults;
      }),
    );

    return results;
  }
}

/// Example 6: Category-Filtered Search
/// Use case: Search within a specific category of players
class CategorySearchExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<List<PlayerSearchResult>> searchInCategory(
    String query,
    String category,
  ) async {
    // Get all results
    final results = await _searchService.searchPlayers(query, limit: 50);
    
    // Filter by category
    return results
        .where((player) => player.category?.toLowerCase() == category.toLowerCase())
        .toList();
  }
}

/// Example 7: Smart Retry Logic
/// Use case: Give user multiple attempts with helpful feedback
class SmartRetryExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();
  int _attemptCount = 0;
  
  Future<Map<String, dynamic>> validateWithFeedback({
    required String userAnswer,
    required String correctAnswer,
    required int correctPlayerId,
  }) async {
    _attemptCount++;

    // Check if answer is correct
    final isCorrect = await _searchService.isCorrectAnswer(
      userAnswer,
      correctPlayerId,
      threshold: 0.3,
    );

    if (isCorrect) {
      return {
        'correct': true,
        'message': 'Correct!',
      };
    }

    // Get suggestions for hints
    final suggestions = await _searchService.searchPlayers(userAnswer, limit: 3);
    
    String hint = 'Try again!';
    if (suggestions.isNotEmpty) {
      // Check if correct answer is in top suggestions
      final correctInSuggestions = suggestions.any(
        (s) => s.id == correctPlayerId,
      );
      
      if (correctInSuggestions) {
        hint = 'You\'re close! Check your spelling.';
      } else if (_attemptCount >= 2) {
        hint = 'Hint: ${correctAnswer.substring(0, 3)}...';
      }
    }

    return {
      'correct': false,
      'message': hint,
      'suggestions': suggestions.map((s) => s.displayName).take(3).toList(),
    };
  }
}

/// Example 8: Voice Input Integration
/// Use case: Process voice recognition results with fuzzy search
class VoiceInputExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<PlayerSearchResult?> processVoiceInput(String recognizedText) async {
    // Voice recognition may have errors, so use fuzzy search
    final results = await _searchService.searchPlayers(
      recognizedText,
      limit: 1,
    );

    // Return the best match if any
    return results.isNotEmpty ? results.first : null;
  }

  Future<bool> confirmVoiceMatch(
    BuildContext context,
    String recognizedText,
    PlayerSearchResult? match,
  ) async {
    if (match == null) {
      return false;
    }

    // Show confirmation dialog
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Player'),
          content: Text('Did you say "${match.displayName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );

      return confirmed ?? false;
    }

    return false;
  }
}

/// Example 9: Cache Management
/// Use case: Optimize performance by managing search cache
class CacheManagementExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  void demonstrateCacheUsage() {
    // Get cache statistics
    final stats = _searchService.getCacheStats();
    print('Cache size: ${stats['size']}/${stats['maxSize']}');
    print('Cached queries: ${stats['queries']}');

    // Clear cache when needed (e.g., on logout or data refresh)
    _searchService.clearCache();
  }

  Future<void> searchWithoutCache(String query) async {
    // Disable cache for one-time searches
    final results = await _searchService.searchPlayers(
      query,
      useCache: false,
    );
    print('Found ${results.length} results without using cache');
  }
}

/// Example 10: Custom Threshold Adjustment
/// Use case: Adjust matching strictness based on game difficulty
class ThresholdAdjustmentExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<bool> validateWithDifficulty({
    required String userAnswer,
    required int correctPlayerId,
    required String difficulty, // 'easy', 'medium', 'hard'
  }) async {
    // Adjust threshold based on difficulty
    double threshold;
    switch (difficulty) {
      case 'easy':
        threshold = 0.2; // Very lenient
      case 'medium':
        threshold = 0.3; // Moderate
      case 'hard':
        threshold = 0.6; // Strict
      default:
        threshold = 0.3;
    }

    return await _searchService.isCorrectAnswer(
      userAnswer,
      correctPlayerId,
      threshold: threshold,
    );
  }
}

/// Example 11: Error Handling
/// Use case: Gracefully handle search failures
class ErrorHandlingExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();

  Future<List<PlayerSearchResult>> safeSearch(String query) async {
    try {
      final results = await _searchService.searchPlayers(query);
      return results;
    } catch (e) {
      print('Search error: $e');
      
      // Return empty list on error
      // The UI should handle this gracefully
      return [];
    }
  }

  Future<bool> safeValidate({
    required String userAnswer,
    required String correctAnswer,
  }) async {
    try {
      return await _searchService.isCorrectAnswerByName(
        userAnswer,
        correctAnswer,
      );
    } catch (e) {
      print('Validation error: $e');
      
      // Fall back to simple string matching
      return userAnswer.toLowerCase().contains(correctAnswer.toLowerCase()) ||
          correctAnswer.toLowerCase().contains(userAnswer.toLowerCase());
    }
  }
}

/// Example 12: Performance Monitoring
/// Use case: Track search performance for optimization
class PerformanceMonitoringExample {
  final SupabaseSearchService _searchService = SupabaseSearchService();
  final List<Duration> _searchTimes = [];

  Future<List<PlayerSearchResult>> monitoredSearch(String query) async {
    final stopwatch = Stopwatch()..start();
    
    final results = await _searchService.searchPlayers(query);
    
    stopwatch.stop();
    _searchTimes.add(stopwatch.elapsed);
    
    print('Search took: ${stopwatch.elapsedMilliseconds}ms');
    print('Average search time: ${_averageSearchTime.inMilliseconds}ms');
    
    return results;
  }

  Duration get _averageSearchTime {
    if (_searchTimes.isEmpty) return Duration.zero;
    final total = _searchTimes.reduce((a, b) => a + b);
    return Duration(microseconds: total.inMicroseconds ~/ _searchTimes.length);
  }

  void clearPerformanceData() {
    _searchTimes.clear();
  }
}

