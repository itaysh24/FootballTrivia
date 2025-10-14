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
  final int id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String? careerPath;
  final String? category;
  final double? similarity;

  PlayerSearchResult({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    this.careerPath,
    this.category,
    this.similarity,
  });

  /// Create PlayerSearchResult from Supabase response map
  factory PlayerSearchResult.fromMap(Map<String, dynamic> map) {
    return PlayerSearchResult(
      id: map['id'] as int,
      firstName: map['firstname']?.toString() ?? '',
      lastName: map['lastname']?.toString() ?? '',
      fullName: map['answer']?.toString() ?? '',
      careerPath: map['career_path']?.toString(),
      category: map['Category']?.toString(),
      similarity: map['similarity'] != null 
          ? (map['similarity'] as num).toDouble() 
          : null,
    );
  }

  /// Get display name (fullName or combined firstName + lastName)
  String get displayName {
    if (fullName.isNotEmpty) return fullName;
    return '$firstName $lastName'.trim();
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
  /// [threshold] - Minimum similarity score to consider a match (0.0 to 1.0)
  /// 
  /// Returns true if the query matches the player within the threshold
  Future<bool> isCorrectAnswer(
    String query,
    int playerId, {
    double threshold = 0.3,
  }) async {
    final results = await searchPlayers(query, limit: 5);
    
    // Check if any result matches the player ID
    for (final result in results) {
      if (result.id == playerId) {
        // If similarity is available, check threshold
        if (result.similarity != null) {
          return result.similarity! >= threshold;
        }
        // If no similarity score, accept the match
        return true;
      }
    }
    
    return false;
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
      
      // Exact or partial match
      if (normalizedResult == normalizedCorrect ||
          normalizedResult.contains(normalizedCorrect) ||
          normalizedCorrect.contains(normalizedResult)) {
        
        // If similarity is available, check threshold
        if (result.similarity != null) {
          return result.similarity! >= threshold;
        }
        // If no similarity score, accept the match
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

