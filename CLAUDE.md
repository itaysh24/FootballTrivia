# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run Commands

```bash
# Run the app (debug)
flutter run

# Build for specific platforms
flutter build apk          # Android
flutter build ios           # iOS
flutter build web           # Web
flutter build windows       # Windows

# Get dependencies
flutter pub get

# Run tests
flutter test
flutter test test/widget_test.dart   # Single test

# Analyze code
flutter analyze

# Generate native splash screen
dart run flutter_native_splash:create
```

## Architecture

This is a **Football Trivia** Flutter app (SDK ^3.8.0) using Supabase as the backend and Provider for state management. Players guess footballers from their career paths.

### Configuration-Based Game Mode System

The core architectural pattern is a **universal GameScreen** (`lib/pages/game_screen.dart`) driven by a **GameConfiguration** object (`lib/core/game_modes_manager.dart`). All game modes share the same screen but differ by configuration:

- **Casual**: 100 questions across 5 leagues, no timer
- **Road to Glory**: Level-based progression (1-100 levels per league, 5 leagues), 1 question per level
- **Rush**: 50 random questions with a 2-minute countdown timer
- **Training**: Dedicated practice mode with its own services/widgets in `lib/pages/training/`

Navigation to each mode goes through static methods on `GameModeNavigator` which build the appropriate `GameConfiguration` and push `GameScreen`.

### Key Services (lib/services/)

- **AuthService**: Google Sign-In + anonymous guest auth via Supabase. Guest sessions persist in SharedPreferences.
- **CoinService**: Local coin balance management via SharedPreferences (default: 100 coins).
- **MusicService**: Streams audio tracks from Supabase `soundtrack` table using just_audio. Shuffled looping with error recovery.
- **ProgressService**: Road to Glory level unlock/completion tracking per league via SharedPreferences.
- **SupabaseSearchService**: Fuzzy player autocomplete via `search_players` RPC function.

### Supabase Schema

- **players** table: `firstname`, `lastname`, `career_path`, `answer`, `Category`, `league_id` (1=Serie A, 2=Premier League, 3=Bundesliga, 4=La Liga, 5=Ligue 1)
- **leaderboard** table: `display_name`, `score`
- **soundtrack** table: `id`, `url`, `enabled`
- RPC: `search_players(query_text, limit_count)` for fuzzy search

### Navigation Structure

Bottom navigation bar with 5 tabs: Home, Leaderboard, Game Modes, Profile, Shop. Auth flow is handled by `AuthGate` widget which routes to `LoginScreen` or main screen based on Supabase auth state.

### UI Patterns

- Glass morphism with backdrop blur (sigmaX=10, sigmaY=5)
- Color scheme: Orange (#FFA726) primary, Teal (#26C6DA) secondary
- White text on dark/gradient backgrounds

## Linting

Uses `flutter_lints` with relaxed rules: `prefer_const_constructors`, `prefer_const_literals_to_create_immutables`, `use_key_in_widget_constructors` are all disabled. `avoid_print` is allowed. `use_build_context_synchronously` errors are ignored in analysis_options.yaml.
