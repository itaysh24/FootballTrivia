# Fuzzy Player Search Implementation Guide

## Overview

This guide explains the fuzzy player search system implemented in the Football Trivia app. The system uses Supabase RPC with PostgreSQL trigram similarity to provide intelligent, typo-tolerant player name matching.

## Architecture

### Components

1. **SupabaseSearchService** (`lib/services/supabase_search.dart`)
   - Core service for fuzzy player search
   - Handles RPC calls to Supabase
   - Provides caching for performance optimization
   - Returns structured `PlayerSearchResult` objects

2. **Game Screen Integration** (`lib/pages/game_screen.dart`)
   - Real-time autocomplete as user types
   - Fuzzy validation of submitted answers
   - Voice input support with search integration
   - Visual feedback with similarity scores

## Features

### 1. Fuzzy Search

The system uses PostgreSQL's `pg_trgm` extension for trigram-based fuzzy matching:

```sql
-- Example Supabase RPC function (should exist in your database)
CREATE OR REPLACE FUNCTION search_players(query_text TEXT, limit_count INT DEFAULT 10)
RETURNS TABLE (
  id INT,
  firstname TEXT,
  lastname TEXT,
  answer TEXT,
  career_path TEXT,
  Category TEXT,
  similarity FLOAT
) AS $$
BEGIN
  RETURN QUERY
  SELECT 
    p.id,
    p.firstname,
    p.lastname,
    p.answer,
    p.career_path,
    p.Category,
    similarity(p.answer, query_text) as similarity
  FROM players p
  WHERE similarity(p.answer, query_text) > 0.3
  ORDER BY similarity DESC
  LIMIT limit_count;
END;
$$ LANGUAGE plpgsql;
```

### 2. Autocomplete UI

The autocomplete dropdown shows:
- **Player names** with matching similarity
- **Category** information for context
- **Similarity percentage** (0-100%)
- Glass morphism design matching app theme

### 3. Multi-Level Answer Validation

When validating answers, the system uses a three-tiered approach:

1. **Primary: ID-based matching** (most accurate)
   - Searches for player by ID
   - Checks if user's input matches within threshold

2. **Secondary: Name-based matching** (fallback)
   - Searches by player name
   - Compares against correct answer string

3. **Tertiary: Simple string matching** (final fallback)
   - Basic case-insensitive substring match
   - Ensures backwards compatibility

### 4. Performance Optimization

- **Debouncing**: 300ms delay before search triggers
- **Caching**: Recent searches stored in memory (max 50 entries)
- **Limit Control**: Configurable result limits (default: 5 for autocomplete, 10 for general search)

## Usage Examples

### Basic Search

```dart
import 'package:football_trivia/services/supabase_search.dart';

// Search for players
final results = await searchService.searchPlayers('ronaldo', limit: 5);

for (final player in results) {
  print('${player.displayName} - ${player.similarity}');
}
```

### Find Best Match

```dart
final bestMatch = await searchService.findBestMatch('mesi'); // typo: should be "messi"
if (bestMatch != null) {
  print('Did you mean: ${bestMatch.displayName}?');
}
```

### Validate Answer by ID

```dart
final isCorrect = await searchService.isCorrectAnswer(
  'cristianu ronaldu', // typo
  12345, // player ID
  threshold: 0.3, // 30% minimum similarity
);
```

### Validate Answer by Name

```dart
final isCorrect = await searchService.isCorrectAnswerByName(
  'messy', // typo
  'Lionel Messi', // correct answer
  threshold: 0.3,
);
```

## PlayerSearchResult Model

```dart
class PlayerSearchResult {
  final int id;              // Database ID
  final String firstName;    // First name
  final String lastName;     // Last name
  final String fullName;     // Full name (answer field)
  final String? careerPath;  // Career history
  final String? category;    // Player category
  final double? similarity;  // Match score (0.0 - 1.0)
  
  String get displayName;    // Best display name
}
```

## Integration in Game Screen

### Autocomplete

1. User types in answer field
2. `_onAnswerTextChanged()` triggers with 300ms debounce
3. `_performSearch()` calls Supabase RPC
4. Results displayed in dropdown below input field
5. User can click suggestion to auto-fill

### Voice Input

1. User taps microphone button
2. Speech recognition captures audio
3. Recognized text fills input field
4. `_performSearch()` automatically triggers
5. Suggestions shown for verification

### Answer Validation

1. User submits answer (tap button or Enter key)
2. `_validateAnswer()` called (async)
3. Three-tier validation process:
   - Try ID-based fuzzy match
   - Try name-based fuzzy match
   - Fall back to simple string match
4. Success/retry dialog shown based on result

## Configuration

### Search Thresholds

Default similarity threshold is **0.3** (30%), which allows for:
- Minor typos (1-2 characters)
- Missing spaces or special characters
- Phonetic variations
- Partial name matches

Adjust threshold in validation calls:

```dart
// More lenient (accepts more variations)
await searchService.isCorrectAnswer(userAnswer, playerId, threshold: 0.2);

// More strict (requires closer match)
await searchService.isCorrectAnswer(userAnswer, playerId, threshold: 0.5);
```

### Cache Management

```dart
// Clear cache manually
searchService.clearCache();

// Get cache statistics
final stats = searchService.getCacheStats();
print('Cache size: ${stats['size']}');
```

### Debounce Timing

Change debounce duration in `game_screen.dart`:

```dart
_debounceTimer = Timer(const Duration(milliseconds: 500), () {
  _performSearch(value);
});
```

## Error Handling

The service gracefully handles errors:

1. **Empty queries** → Returns empty list
2. **Network errors** → Returns empty list, logs error
3. **Null responses** → Returns empty list
4. **Invalid data** → Skips invalid records

All validation methods include fallback logic to ensure the game remains playable even if the RPC call fails.

## Database Requirements

### Required Supabase Setup

1. **PostgreSQL Extension**
   ```sql
   CREATE EXTENSION IF NOT EXISTS pg_trgm;
   ```

2. **RPC Function**
   - Name: `search_players`
   - Parameters: `query_text TEXT`, `limit_count INT`
   - Returns: Table with player data and similarity scores

3. **Index (recommended for performance)**
   ```sql
   CREATE INDEX players_answer_trgm_idx ON players USING gin (answer gin_trgm_ops);
   ```

## UI Components

### Autocomplete Dropdown Features

- ✅ Glass morphism design
- ✅ Scrollable list (max 200px height)
- ✅ Player icon for each result
- ✅ Category badges
- ✅ Similarity percentage badges
- ✅ Smooth animations
- ✅ Touch-friendly tap targets

### Clear Button

- Appears when text field has content
- Clears input and hides suggestions
- Clean, minimal design

## Testing

### Manual Testing Checklist

- [ ] Type partial player name → See autocomplete suggestions
- [ ] Type with typos → Still get relevant suggestions
- [ ] Select suggestion → Text auto-fills correctly
- [ ] Submit correct answer → Marked as correct
- [ ] Submit similar answer (typo) → Accepted via fuzzy match
- [ ] Submit wrong answer → Marked as incorrect
- [ ] Use voice input → Text fills and suggestions appear
- [ ] Clear button works
- [ ] Suggestions hide when appropriate

## Future Enhancements

Possible improvements:

1. **Weighted Search**
   - Prioritize matches on first/last name separately
   - Boost results matching career path or category

2. **Learning Algorithm**
   - Track common typos or variations
   - Adjust thresholds based on user patterns

3. **Offline Support**
   - Cache popular player names locally
   - Fuzzy matching without network

4. **Multi-language Support**
   - Handle player names in different scripts
   - Transliteration support

5. **Advanced Autocomplete**
   - Show player photos
   - Display career highlights
   - Group results by category

## Troubleshooting

### No suggestions appearing
- Check network connection
- Verify Supabase RPC function exists
- Check browser console for errors
- Verify `pg_trgm` extension is installed

### Incorrect matches
- Adjust similarity threshold (lower = more lenient)
- Check RPC function logic
- Verify player data quality in database

### Performance issues
- Add database indexes
- Reduce result limits
- Increase debounce duration
- Monitor cache hit rate

## Summary

The fuzzy search system provides:
- 🎯 **Accurate matching** even with typos
- ⚡ **Fast autocomplete** with caching
- 🎤 **Voice input support** with suggestions
- 🎨 **Beautiful UI** matching app theme
- 🛡️ **Robust error handling** with fallbacks
- 📱 **Mobile-friendly** design

This creates a seamless, forgiving user experience that accepts various forms of player name input while maintaining game integrity.

