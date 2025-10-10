# Game Modes Architecture Documentation

## Overview

This document explains the universal game mode architecture implemented in the Football Trivia app. The system allows multiple game modes (Casual, Road to Glory, Rush) to share the same game screen with different configurations.

## Architecture Pattern

### Core Components

1. **`GameMode` Enum** (`lib/core/game_modes_manager.dart`)
   - Defines all available game modes
   - Values: `casual`, `roadToGlory`, `rush`

2. **`GameConfiguration` Class** (`lib/core/game_modes_manager.dart`)
   - Holds all configuration data for a specific game mode
   - Properties:
     - `mode`: The game mode type
     - `title`: Display title
     - `description`: Mode description
     - `questionFetcher`: Function to fetch questions from Supabase
     - `timeLimitSeconds`: Optional timer (used in Rush mode)
     - `level`: Optional level number (used in Road to Glory)
     - `category`: Optional category filter (used in Casual mode)
     - `leagueName`: Optional league name (used in Road to Glory)
     - `maxQuestions`: Maximum number of questions
     - `showCompletionDialog`: Whether to show completion dialog

3. **`GameScreen` Widget** (`lib/pages/game_screen.dart`)
   - Universal game screen that adapts based on configuration
   - Supports both typed and voice answers
   - Validates answers with partial case-insensitive matching
   - Shows timer for Rush mode
   - Shows completion dialog when applicable

4. **`GameModeNavigator` Class** (`lib/core/game_modes_manager.dart`)
   - Helper class with navigation functions
   - Methods:
     - `startCasualMode(context, {category})`
     - `startRoadToGloryMode(context, {level})`
     - `startRushMode(context)`

## Game Modes

### 1. Casual Mode

**Description:** Relaxed gameplay with category-specific questions at your own pace.

**Configuration:**
- Category: 'Stars' (default, configurable)
- No timer
- 20 questions per session
- No completion dialog

**Question Fetching:**
```dart
SELECT * FROM players 
WHERE Category = 'Stars' 
LIMIT 20
```

**Usage:**
```dart
GameModeNavigator.startCasualMode(context);
// or with custom category:
GameModeNavigator.startCasualMode(context, category: 'Legends');
```

### 2. Road to Glory Mode

**Description:** Progressive league-based challenges where each level corresponds to a specific league.

**Configuration:**
- Level-based progression (1-100 per league)
- 1 question per level
- League-specific questions
- No timer
- No completion dialog (returns to level map after answering)

**League Mapping:**
- Level 1: Premier League
- Level 2: La Liga
- Level 3: Serie A
- Level 4: Bundesliga
- Level 5: Ligue 1
- Level 6+: Falls back to 'Stars'

**Question Fetching:**
```dart
SELECT * FROM players 
WHERE Category = <leagueName> 
LIMIT 10
// Then pick one random question
```

**Usage:**
```dart
GameModeNavigator.startRoadToGloryMode(context, level: 5);
```

**Integration with League Maps:**
All league map screens (English, Spanish, Italian, German, French) now automatically use the GameConfiguration system when a level is tapped.

### 3. Rush Mode

**Description:** Time-based challenge where players answer as many questions as possible in 2 minutes.

**Configuration:**
- 50 questions from all categories
- 2-minute (120 seconds) countdown timer
- Shows timer in header (turns red when < 30 seconds)
- Shows completion dialog with final score

**Timer Behavior:**
- Starts when the first question loads
- Counts down from 2:00 to 0:00
- Changes color to red when < 30 seconds remaining
- Stops when timer reaches zero
- Shows "Time's Up!" dialog with final score

**Question Fetching:**
```dart
SELECT * FROM players 
LIMIT 100
// Then shuffle and take 50
```

**Usage:**
```dart
GameModeNavigator.startRushMode(context);
```

**End Game Scenarios:**
1. Timer expires → Shows "Time's Up!" dialog with score
2. All 50 questions answered → Shows "Game Complete!" dialog with score
3. Player navigates back → Timer is cancelled, game ends

## Universal Game Screen Features

### Common Features (All Modes)

1. **Answer Input Methods:**
   - Text input field
   - Voice recognition using speech_to_text
   - Microphone button that animates when listening

2. **Answer Validation:**
   - Case-insensitive partial matching
   - Accepts variations of the correct answer
   - Example: "Messi", "Lionel Messi", or "L. Messi" all match

3. **Feedback Dialogs:**
   - Success dialog (correct answer)
   - Retry dialog (incorrect answer with hints)
   - Error dialogs for network/permission issues

4. **Score Tracking:**
   - Current score / Total answered
   - Displayed in header with star icon

5. **Glass Morphism UI:**
   - Modern glass-effect containers
   - Blur effects on background
   - Gradient overlays

### Mode-Specific Features

#### Rush Mode Only
- Countdown timer in header
- Timer color changes based on remaining time
- Completion/Time's Up dialogs with accuracy percentage
- Auto-returns to main menu when game ends

#### Road to Glory Mode Only
- Shows league name in header title
- Single question per level
- Returns to level map after answering
- Level progression tracking (in league map)

#### Casual Mode Only
- Custom category support
- Extended question pool
- No pressure, no time limit

## Adding New Game Modes

To add a new game mode, follow these steps:

### 1. Add to GameMode Enum
```dart
enum GameMode {
  casual,
  roadToGlory,
  rush,
  yourNewMode, // Add here
}
```

### 2. Create Configuration Method
```dart
static GameConfiguration getYourNewMode() {
  return GameConfiguration(
    mode: GameMode.yourNewMode,
    title: 'Your Mode Name',
    description: 'Mode description',
    timeLimitSeconds: null, // or set a timer
    maxQuestions: 20,
    showCompletionDialog: true,
    questionFetcher: (supabase) async {
      // Your custom query
      final response = await supabase
          .from('players')
          .select('id, firstname, lastname, career_path, answer, Category')
          .limit(20);
      
      return (response as List).cast<Map<String, dynamic>>();
    },
  );
}
```

### 3. Add Navigation Method
```dart
static void startYourNewMode(BuildContext context) {
  final config = GameModeConfigurations.getYourNewMode();
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GameScreen(config: config),
    ),
  );
}
```

### 4. Add to Game Modes Menu
In `lib/pages/game_modes/game_modes_main.dart`:
```dart
GameModeCard(
  title: "Your New Mode",
  description: "Mode description here.",
  locked: false,
  onTap: () {
    GameModeNavigator.startYourNewMode(context);
  },
),
```

## Database Schema

The app expects a `players` table in Supabase with the following columns:

- `id`: Primary key
- `firstname`: Player's first name
- `lastname`: Player's last name
- `career_path`: Career history text
- `answer`: The correct answer (usually full name)
- `Category`: Category/league classification (e.g., 'Stars', 'Premier League', 'La Liga')

## Testing Checklist

When testing the game modes system, verify:

- [ ] Casual mode loads 20 questions
- [ ] Rush mode timer counts down correctly
- [ ] Rush mode ends when timer expires
- [ ] Rush mode shows completion dialog
- [ ] Road to Glory levels launch correctly from league maps
- [ ] Partial answer matching works (e.g., "Messi" matches "Lionel Messi")
- [ ] Voice input works with microphone permission
- [ ] Score tracking is accurate
- [ ] Back button cancels timer and returns to previous screen
- [ ] Navigation between screens doesn't cause memory leaks
- [ ] Error dialogs show when Supabase queries fail
- [ ] All league maps (English, Spanish, Italian, German, French) launch games correctly

## Future Enhancements

Possible improvements to the system:

1. **Persistent Progress:**
   - Save scores to Supabase user profiles
   - Track personal bests for Rush mode
   - Save Road to Glory level progress

2. **Difficulty Levels:**
   - Add difficulty parameter to GameConfiguration
   - Implement hint reduction for harder levels
   - Time bonuses for quick answers

3. **Multiplayer:**
   - Head-to-head Rush mode
   - Leaderboards integration
   - Real-time competitive play

4. **Customization:**
   - Let users create custom categories
   - Adjustable timer lengths
   - Question pool size preferences

5. **Achievements:**
   - Unlock badges for milestones
   - Track streaks
   - Reward consistency

## Troubleshooting

### Questions Not Loading

**Symptom:** "No questions available" error  
**Solution:** Check that:
1. Supabase connection is active
2. Category names match database exactly (case-sensitive)
3. Database has players with the specified category

### Timer Not Working

**Symptom:** Timer doesn't count down in Rush mode  
**Solution:** 
1. Verify `timeLimitSeconds` is set in configuration
2. Check that `_startTimer` is called in `initState`
3. Ensure timer is cancelled in `dispose`

### Voice Input Not Working

**Symptom:** Microphone button does nothing  
**Solution:**
1. Check microphone permissions are granted
2. Verify speech_to_text plugin is installed
3. Test on a physical device (may not work on emulator)

### Memory Leaks

**Symptom:** App slows down after multiple games  
**Solution:**
1. Ensure timer is cancelled in `dispose`
2. Check that dialogs are properly popped
3. Verify listeners are removed

## File Structure

```
lib/
├── core/
│   ├── game_modes_manager.dart       # Main configuration system
│   └── GAME_MODES_ARCHITECTURE.md    # This file
├── pages/
│   ├── game_screen.dart              # Universal game screen
│   ├── game_modes/
│   │   ├── game_modes_main.dart      # Game mode selection menu
│   │   └── game_mode_card.dart       # UI card component
│   └── RTG/
│       ├── road_to_glory.dart        # League carousel
│       ├── english_league_map.dart   # English league levels
│       ├── spanish_league_map.dart   # Spanish league levels
│       ├── italian_league_map.dart   # Italian league levels
│       ├── german_league_map.dart    # German league levels
│       └── french_league_map.dart    # French league levels
```

## Contact & Support

For questions about this architecture or to report issues:
- Check the inline code comments in `game_modes_manager.dart`
- Review the example usage in `game_modes_main.dart`
- Test with the working implementations in the RTG league maps

---

**Last Updated:** October 10, 2025  
**Version:** 1.0  
**Author:** AI Assistant with User Collaboration

