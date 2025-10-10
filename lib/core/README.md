# Core Game Systems

This folder contains core game logic and configuration systems used throughout the Football Trivia app.

## Files

### `game_modes_manager.dart`
**Purpose:** Universal game mode configuration system

**Exports:**
- `GameMode` enum - Identifies different game modes
- `GameConfiguration` class - Configuration data for each mode
- `GameModeConfigurations` class - Factory methods for creating configurations
- `GameModeNavigator` class - Navigation helpers for launching game modes

**Usage Example:**
```dart
import 'package:football_trivia/core/game_modes_manager.dart';

// Launch Rush Mode
GameModeNavigator.startRushMode(context);

// Launch Casual Mode with custom category
GameModeNavigator.startCasualMode(context, category: 'Legends');

// Launch Road to Glory for specific level
GameModeNavigator.startRoadToGloryMode(context, level: 5);
```

### `GAME_MODES_ARCHITECTURE.md`
**Purpose:** Comprehensive architecture documentation

**Contents:**
- System overview and design patterns
- Detailed explanation of each game mode
- Code examples and usage patterns
- Guide for adding new game modes
- Testing checklist
- Troubleshooting guide

**Audience:** Developers working on game modes

## Quick Start

### Adding a New Game Mode

1. **Define the mode** in `GameMode` enum
2. **Create configuration** with `GameModeConfigurations.getYourMode()`
3. **Add navigation** with `GameModeNavigator.startYourMode()`
4. **Update UI** in `lib/pages/game_modes/game_modes_main.dart`

See `GAME_MODES_ARCHITECTURE.md` for detailed step-by-step instructions.

## Dependencies

- `flutter/material.dart` - UI framework
- `supabase_flutter` - Database queries
- `../pages/game_screen.dart` - Universal game screen

## Related Files

- `lib/pages/game_screen.dart` - Universal game screen implementation
- `lib/pages/game_modes/game_modes_main.dart` - Game mode selection menu
- `lib/pages/RTG/*.dart` - Road to Glory league maps
- `GAME_MODES_IMPLEMENTATION_SUMMARY.md` - Full implementation details (project root)

## Architecture Pattern

This system uses a **configuration-based approach** where:

1. Each game mode is defined by a `GameConfiguration` object
2. The universal `GameScreen` reads the configuration and adapts its behavior
3. Navigation is handled through static helper methods
4. Questions are fetched via Supabase using mode-specific queries

**Benefits:**
- No code duplication
- Easy to add new modes
- Centralized configuration
- Type-safe implementation

## Testing

Run Flutter analyze on this folder:
```bash
flutter analyze lib/core/
```

Expected output: "No issues found!"

## Maintenance Notes

- Keep league names in sync with database `Category` values
- Ensure sufficient questions exist in database for each mode
- Update `GAME_MODES_ARCHITECTURE.md` when adding new features
- Follow existing naming conventions for consistency

## Version History

- **v1.0** (Oct 10, 2025) - Initial implementation with Casual, Road to Glory, and Rush modes

---

For questions or support, see `GAME_MODES_ARCHITECTURE.md` or the main implementation summary in the project root.

