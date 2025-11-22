import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================================
/// This service provides fuzzy player search functionality using Supabase RPC.
/// Features:
/// - Fuzzy search using PostgreSQL trigram similarity
/// - Configurable result limits
/// - Graceful error handling
/// - Caching for better performance
/// ============================================================================
/// Player search result model
class PlayerSearchResult {
  final int playerId;
  final String firstName;
  final String lastName;
  final String answer;
  final String? careerPath;
  final int? leagueId;
  final String? fullNameWiki;

  PlayerSearchResult({
    required this.playerId,
    required this.firstName,
    required this.lastName,
    required this.answer,
    this.careerPath,
    this.leagueId,
    this.fullNameWiki,
  });

  /// Create PlayerSearchResult from Supabase response map
  factory PlayerSearchResult.fromMap(Map<String, dynamic> map) {
    int parseRequiredInt(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      final parsed = int.tryParse(value?.toString() ?? '');
      if (parsed == null) {
        throw ArgumentError('player_id is required but was $value');
      }
      return parsed;
    }

    int? parseLeagueId(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is num) return value.toInt();
      return int.tryParse(value.toString());
    }

    return PlayerSearchResult(
      playerId: parseRequiredInt(map['player_id']),
      firstName: map['first_name']?.toString() ?? '',
      lastName: map['last_name']?.toString() ?? '',
      answer: map['answer']?.toString() ?? '',
      careerPath: map['career_path']?.toString(),
      leagueId: parseLeagueId(map['league_id']),
      fullNameWiki: map['full_name_wiki']?.toString(),
    );
  }

  /// Display label prioritizing the answer/known name
  String get displayName {
    if (answer.isNotEmpty) return answer;
    final combined = '$firstName $lastName'.trim();
    return combined.isNotEmpty ? combined : (fullNameWiki ?? '');
  }

  /// Secondary label for UI (wiki name, career path, or league identifier)
  String? get secondaryLabel {
    if (fullNameWiki != null && fullNameWiki!.trim().isNotEmpty) {
      return fullNameWiki;
    }
    if (careerPath != null && careerPath!.trim().isNotEmpty) {
      return careerPath;
    }
    if (leagueId != null) {
      return 'League $leagueId';
    }
    return null;
  }
}

/// Supabase search service for fuzzy player search
class SupabaseSearchService {
  final SupabaseClient _supabase;
  
  /// Cache for recent searches (optional optimization)
  final Map<String, List<PlayerSearchResult>> _searchCache = {};
  
  /// Maximum cache size
  static const int maxCacheSize = 50;

  SupabaseSearchService({SupabaseClient? supabaseClient})
      : _supabase = supabaseClient ?? Supabase.instance.client;

  /// Search for players using fuzzy matching via Supabase RPC
  /// 
  /// [query] - The search query string
  /// [limit] - Maximum number of results to return (default: 10)
  /// [useCache] - Whether to use cached results (default: true)
  /// 
  /// Returns a list of PlayerSearchResult objects sorted by similarity
  Future<List<PlayerSearchResult>> searchPlayers(
    String query, {
    int limit = 10,
    bool useCache = true,
  }) async {
    // Validate and normalize query
    final trimmedQuery = query.trim();
    
    // Return empty list for empty queries
    if (trimmedQuery.isEmpty) {
      return [];
    }

    // Check cache first
    if (useCache && _searchCache.containsKey(trimmedQuery)) {
      return _searchCache[trimmedQuery]!.take(limit).toList();
    }

    try {
      // Call the Supabase RPC function 'search_players'
      final response = await _supabase.rpc(
        'search_players',
        params: {
          'query_text': trimmedQuery,
          'limit_count': limit,
        },
      );

      // Handle null or empty response
      if (response == null) {
        return [];
      }

      // Parse response data
      final List<dynamic> data = response is List ? response : [response];
      
      if (data.isEmpty) {
        return [];
      }

    // Convert to PlayerSearchResult objects
    final results = data
        .map((item) => PlayerSearchResult.fromMap(item as Map<String, dynamic>))
        .toList();

      // Cache the results
      if (useCache) {
        _updateCache(trimmedQuery, results);
      }

      return results;
    } catch (e) {
      // Log error and return empty list
      print('Error searching players: $e');
      return [];
    }
  }

  /// Find the best match for a query
  /// 
  /// Returns the top result or null if no matches found
  Future<PlayerSearchResult?> findBestMatch(String query) async {
    final results = await searchPlayers(query, limit: 1);
    return results.isNotEmpty ? results.first : null;
  }

  /// Check if a query matches a specific player
  /// 
  /// [query] - The user's answer
  /// [playerId] - The ID of the correct player
  /// Returns true if the query matches the player by identifier
  Future<bool> isCorrectAnswer(
    String query,
    int playerId, {
    double threshold = 0.3,
  }) async {
    final results = await searchPlayers(query, limit: 5);
    
    // Check if any result matches the player ID
    return results.any((result) => result.playerId == playerId);
  }

  /// Check if a query matches a player by name
  /// 
  /// [query] - The user's answer
  /// [correctAnswer] - The correct player name
  /// [threshold] - Minimum similarity score to consider a match (0.0 to 1.0)
  /// 
  /// Returns true if the query closely matches the correct answer
  Future<bool> isCorrectAnswerByName(
    String query,
    String correctAnswer, {
    double threshold = 0.3,
  }) async {
    final results = await searchPlayers(query, limit: 5);
    
    // Normalize correct answer for comparison
    final normalizedCorrect = correctAnswer.toLowerCase().trim();
    
    // Check if any result matches the correct answer
    for (final result in results) {
      final normalizedResult = result.displayName.toLowerCase().trim();
      final normalizedAlt = '${result.firstName} ${result.lastName}'.toLowerCase().trim();
      
      // Exact or partial match
      final isDirectMatch = normalizedResult == normalizedCorrect ||
          normalizedResult.contains(normalizedCorrect) ||
          normalizedCorrect.contains(normalizedResult);
      final isAltMatch = normalizedAlt.isNotEmpty &&
          (normalizedAlt == normalizedCorrect ||
              normalizedAlt.contains(normalizedCorrect) ||
              normalizedCorrect.contains(normalizedAlt));
      
      if (isDirectMatch || isAltMatch) {
        return true;
      }
    }
    
    return false;
  }

  /// Update the search cache
  void _updateCache(String query, List<PlayerSearchResult> results) {
    // Remove oldest entries if cache is too large
    if (_searchCache.length >= maxCacheSize) {
      final keysToRemove = _searchCache.keys.take(_searchCache.length - maxCacheSize + 1);
      for (final key in keysToRemove) {
        _searchCache.remove(key);
      }
    }
    
    _searchCache[query] = results;
  }

  /// Clear the search cache
  void clearCache() {
    _searchCache.clear();
  }

  /// Get cache statistics (for debugging)
  Map<String, dynamic> getCacheStats() {
    return {
      'size': _searchCache.length,
      'maxSize': maxCacheSize,
      'queries': _searchCache.keys.toList(),
    };
  }
}

/// Global search service instance
final searchService = SupabaseSearchService();

