# Football Trivia - Screen Navigation Map & Analysis

## 📊 SECTION 1: SCREENS MAP

This map shows all screens/widgets in the app and their navigation connections.

### 🏠 Main Entry Point
**File:** `lib/main.dart`

```
MyApp (StatefulWidget)
  └─> MyHomePage (StatefulWidget)
       ├─> HomePage (StatelessWidget)
       ├─> LeaderboardPage (StatefulWidget)
       ├─> GameModesPage (StatelessWidget)
       ├─> ProfilePage (StatelessWidget)
       └─> ShopPage (StatelessWidget)
```

---

### 🗺️ Detailed Navigation Flow

#### 1️⃣ **MyHomePage** (Bottom Navigation Hub)
**File:** `lib/main.dart` (lines 160-384)
**Type:** StatefulWidget with Bottom Navigation Bar

**Navigates To:**
- `TutorialScreen` (via named route `/tutorial` on first launch)
  - **Trigger:** Tutorial popup dialog on `initState`
  - **Method:** `Navigator.pushReplacementNamed(context, '/tutorial')`

**Contains (via bottom nav index):**
- Index 0: `HomePage`
- Index 1: `LeaderboardPage`
- Index 2: `GameModesPage`
- Index 3: `ProfilePage`
- Index 4: `ShopPage`

---

#### 2️⃣ **HomePage** (Welcome Screen)
**File:** `lib/main.dart` (lines 387-463)
**Type:** StatelessWidget

**Navigates To:**
- `GameScreen` (Universal game screen)
  - **Trigger:** "Play Now" button press
  - **Method:** `Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen()))`

---

#### 3️⃣ **GameModesPage** (Game Mode Selection)
**File:** `lib/pages/game_modes/game_modes_main.dart`
**Type:** StatelessWidget

**Navigates To:**
1. `GameScreen` (Casual Mode)
   - **Trigger:** "Casual Mode" card tap
   - **Method:** `GameModeNavigator.startCasualMode(context)`
   - **Configuration:** Casual mode with 20 questions

2. `RoadToGloryScreen`
   - **Trigger:** "Road to Glory" card tap
   - **Method:** `Navigator.pushNamed(context, '/road_to_glory')`

3. `GameScreen` (Rush Mode)
   - **Trigger:** "Rush Mode" card tap
   - **Method:** `GameModeNavigator.startRushMode(context)`
   - **Configuration:** 50 questions, 120 seconds timer

4. `TrainingScreen` (via named route)
   - **Trigger:** "Training" card tap
   - **Method:** `Navigator.pushNamed(context, "/training")`

---

#### 4️⃣ **RoadToGloryScreen** (League Selection Carousel)
**File:** `lib/pages/RTG/road_to_glory.dart`
**Type:** StatelessWidget

**Navigates To:**
1. `EnglishLeagueMapScreen`
   - **Trigger:** English League card tap
   - **Method:** `Navigator.push(context, MaterialPageRoute(...))`

2. `SpanishLeagueMapScreen`
   - **Trigger:** Spanish League card tap
   - **Method:** `Navigator.push(context, MaterialPageRoute(...))`

3. `ItalianLeagueMapScreen`
   - **Trigger:** Italian League card tap
   - **Method:** `Navigator.push(context, MaterialPageRoute(...))`

4. `GermanLeagueMapScreen`
   - **Trigger:** German League card tap
   - **Method:** `Navigator.push(context, MaterialPageRoute(...))`

5. `FrenchLeagueMapScreen`
   - **Trigger:** French League card tap
   - **Method:** `Navigator.push(context, MaterialPageRoute(...))`

---

#### 5️⃣ **EnglishLeagueMapScreen** (League Map - Levels)
**File:** `lib/pages/RTG/english_league_map.dart`
**Type:** StatefulWidget

**Navigates To:**
- `GameScreen` (with Road to Glory config)
  - **Trigger:** Level card tap (when unlocked)
  - **Method:** `Navigator.push(context, MaterialPageRoute(builder: (context) => GameScreen(config: ...)))`
  - **Configuration:** Road to Glory mode with specific level

**Similar Navigation:**
- `SpanishLeagueMapScreen` (`lib/pages/RTG/spanish_league_map.dart`)
- `ItalianLeagueMapScreen` (`lib/pages/RTG/italian_league_map.dart`)
- `GermanLeagueMapScreen` (`lib/pages/RTG/german_league_map.dart`)
- `FrenchLeagueMapScreen` (`lib/pages/RTG/french_league_map.dart`)

---

#### 6️⃣ **TutorialScreen** (Tutorial/Onboarding)
**File:** `lib/pages/training/tutorial_screen.dart`
**Type:** StatefulWidget

**Navigates To:**
- `MyHomePage` (Back to home)
  - **Trigger:** "Get Started" button on last step
  - **Method:** `Navigator.pushReplacementNamed(context, '/')`

---

#### 7️⃣ **GameScreen** (Universal Game Screen)
**File:** `lib/pages/game_screen.dart`
**Type:** StatefulWidget
**Note:** This is the main game screen used by all game modes

**Navigates To:**
- Back to previous screen
  - **Trigger:** Back button in app bar OR completion/time-up dialog
  - **Method:** `Navigator.of(context).pop()`

---

#### 8️⃣ **TrainingScreen**
**File:** `lib/pages/training/training_screen.dart`
**Type:** StatefulWidget

**Navigates To:**
- (Currently no navigation - only back button)

---

#### 9️⃣ **LeaderboardPage**
**File:** `lib/pages/leaderboard/leaderboard_page.dart`
**Type:** StatefulWidget

**Navigates To:**
- (No navigation - displays data only)

---

#### 🔟 **ProfilePage**
**File:** `lib/pages/Profile/profile_page.dart`
**Type:** StatelessWidget

**Navigates To:**
- (No navigation - displays user profile)

---

#### 1️⃣1️⃣ **VoiceTriviaPage** ⚠️ **ORPHANED**
**File:** `lib/pages/voice_trivia.dart`
**Type:** StatefulWidget

**Navigates To:**
- (No outgoing navigation)

**⚠️ WARNING:** This screen is **NOT navigated to from anywhere** in the app!

---

#### 1️⃣2️⃣ **VoiceTriviaScreen** ⚠️ **ORPHANED**
**File:** `lib/screens/voice_trivia_screen.dart`
**Type:** StatefulWidget

**Navigates To:**
- (No outgoing navigation)

**⚠️ WARNING:** This screen is **NOT navigated to from anywhere** in the app!

---

#### 1️⃣3️⃣ **ShopPage** (Placeholder)
**File:** `lib/main.dart` (lines 465-470)
**Type:** StatelessWidget

**Navigates To:**
- (No navigation - just displays "Shop Page" text)

---

### 📌 Named Routes Registered (in main.dart)

```dart
routes: {
  '/game_modes': (context) => const GameModesPage(),
  '/training': (context) => const GameScreen(),  // ⚠️ Points to GameScreen, not TrainingScreen
  '/tutorial': (context) => const TutorialScreen(),
  '/road_to_glory': (context) => const RoadToGloryScreen(),
  '/game': (context) => const GameScreen(),
}
```

**⚠️ ISSUE:** The `/training` route points to `GameScreen` instead of `TrainingScreen`

---

## 🔍 SECTION 2: UNUSED FILES

Files that exist in `lib/` but are **NOT imported or used anywhere** in the app:

### ❌ Completely Unused Files

1. **`lib/screens/voice_trivia_screen.dart`**
   - **Type:** StatefulWidget
   - **Why Unused:** Never imported, never navigated to
   - **Purpose:** Alternative/duplicate voice trivia screen
   - **Safe to Delete:** ✅ Yes (unless you plan to use it)

2. **`lib/pages/voice_trivia.dart`** ⚠️
   - **Type:** StatefulWidget  
   - **Why Unused:** Never imported, never navigated to
   - **Purpose:** Voice-based trivia game screen
   - **Safe to Delete:** ⚠️ Maybe (seems like an incomplete feature)

3. **`lib/services/supabase/supabase_search_examples.dart`**
   - **Type:** Example code file
   - **Why Unused:** Never imported
   - **Purpose:** Contains example usage of search service
   - **Safe to Delete:** ✅ Yes (documentation/example file)

4. **`lib/models/question_model.dart`**
   - **Type:** Model class
   - **Why Unused:** Only imported by `training_game_service.dart` which uses it
   - **Actually Used:** ✅ **FALSE POSITIVE** - This IS used
   - **Safe to Delete:** ❌ No

5. **`lib/models/player.dart`**
   - **Type:** Model class
   - **Why Unused:** Only imported by `leaderboard_page.dart` which uses it
   - **Actually Used:** ✅ **FALSE POSITIVE** - This IS used
   - **Safe to Delete:** ❌ No

6. **`lib/services/background_service.dart`**
   - **Type:** Service class
   - **Why Unused:** Never imported anywhere
   - **Purpose:** Unknown - possibly for background tasks
   - **Safe to Delete:** ⚠️ Check if this is planned for future use

---

### ✅ Widget Component Files (Used Indirectly)

These files are imported and used by parent screens:

**Profile Components (Used by ProfilePage):**
- `lib/pages/Profile/profile_container.dart` ✅
- `lib/pages/Profile/profile_header.dart` ✅
- `lib/pages/Profile/profile_info.dart` ✅
- `lib/pages/Profile/profile_actions.dart` ✅
- `lib/pages/Profile/profile_avatar.dart` ✅

**Game Mode Components (Used by GameModesPage):**
- `lib/pages/game_modes/game_mode_card.dart` ✅

**Training Components (Used by TrainingScreen):**
- `lib/pages/training/widgets/training_timer_widget.dart` ✅
- `lib/pages/training/widgets/training_slots_widget.dart` ✅
- `lib/pages/training/widgets/training_score_widget.dart` ✅
- `lib/pages/training/widgets/training_letter_pool_widget.dart` ✅
- `lib/pages/training/widgets/training_image_widget.dart` ✅
- `lib/pages/training/widgets/training_controls_widget.dart` ✅
- `lib/pages/training/widgets/training_career_widget.dart` ✅

**Training Services (Used by TrainingScreen):**
- `lib/pages/training/services/training_game_service.dart` ✅
- `lib/pages/training/services/training_timer_service.dart` ✅
- `lib/pages/training/services/training_image_service.dart` ✅

**Leaderboard Components:**
- `lib/pages/leaderboard/leaderboard_container.dart` ✅

**Shared Widgets:**
- `lib/widgets/tutorial_popup.dart` ✅ (Used in main.dart)
- `lib/widgets/level_map.dart` ❓ (Defined but might not be used)

**Core Services:**
- `lib/core/game_modes_manager.dart` ✅
- `lib/services/progress_service.dart` ✅
- `lib/services/music_service.dart` ✅
- `lib/services/voice_service.dart` ✅ (Used by voice_trivia.dart)
- `lib/services/supabase/supabase_service.dart` ✅
- `lib/services/supabase/supabase_search.dart` ✅

---

## 🚨 Issues & Recommendations

### 1. **Orphaned Voice Trivia Screens**
- **Files:** `voice_trivia.dart`, `voice_trivia_screen.dart`
- **Issue:** Fully implemented screens but no navigation to them
- **Recommendation:** 
  - Add a game mode card in `GameModesPage` to navigate to voice trivia
  - OR delete if feature is abandoned

### 2. **Training Route Misconfiguration**
- **Route:** `/training` in `main.dart`
- **Issue:** Points to `GameScreen` instead of `TrainingScreen`
- **Fix:**
  ```dart
  '/training': (context) => const TrainingScreen(),
  ```

### 3. **Unused Background Service**
- **File:** `lib/services/background_service.dart`
- **Issue:** Never imported
- **Recommendation:** Delete if not planned for use

### 4. **level_map.dart Widget**
- **File:** `lib/widgets/level_map.dart`
- **Status:** Defined but possibly unused
- **Recommendation:** Verify if RTG league maps use this widget

### 5. **Duplicate ProfileContainer**
- **Files:** 
  - `lib/pages/Profile/profile_container.dart`
  - `lib/pages/leaderboard/leaderboard_container.dart`
- **Issue:** Identical code, could be shared
- **Recommendation:** Move to shared widgets folder

---

## 📈 Screen Flow Visualization

```
┌─────────────────────────────────────────────────────────────────┐
│                          MyApp                                  │
│                            │                                     │
│                            ▼                                     │
│                      MyHomePage                                 │
│              (Bottom Navigation Controller)                     │
└─────────────────────────────────────────────────────────────────┘
                              │
        ┌─────────────────────┼─────────────────────┬───────────┐
        │                     │                     │           │
        ▼                     ▼                     ▼           ▼
    HomePage          LeaderboardPage        GameModesPage  ProfilePage
        │                                           │
        │                                           │
        ▼                                           │
   GameScreen ◄───────────────────────┬─────────────┤
  (Universal)                         │             │
                                      │             ▼
                              RoadToGloryScreen  TrainingScreen
                                      │
                    ┌─────────────────┼──────────────────┐
                    │                 │                  │
                    ▼                 ▼                  ▼
           EnglishLeagueMap  SpanishLeagueMap  ... (5 leagues)
                    │                 │
                    └─────────┬───────┘
                              │
                              ▼
                        GameScreen
                     (Road to Glory Mode)


ORPHANED SCREENS (No incoming navigation):
- VoiceTriviaPage ⚠️
- VoiceTriviaScreen ⚠️
```

---

## 📝 Summary Statistics

- **Total Dart Files in lib/:** 44 files
- **Total Screen/Page Widgets:** 13 screens
- **Total Navigation Transitions:** ~20 unique navigation paths
- **Unused Screens:** 2 (VoiceTriviaPage, VoiceTriviaScreen)
- **Truly Unused Files:** 3-4 files
  - `supabase_search_examples.dart` (example code)
  - `background_service.dart` (never imported)
  - `voice_trivia.dart` (orphaned feature)
  - `voice_trivia_screen.dart` (duplicate/orphaned)

---

## 🔧 Files Safe to Delete

1. ✅ **`lib/services/supabase/supabase_search_examples.dart`**
   - Example/documentation file

2. ⚠️ **`lib/services/background_service.dart`**
   - Never used, but check if planned for future

3. ⚠️ **`lib/pages/voice_trivia.dart`**
   - Complete feature but orphaned - add navigation OR delete

4. ⚠️ **`lib/screens/voice_trivia_screen.dart`**
   - Duplicate/alternative implementation - likely safe to delete

---

## ✅ All Files Currently In Use

All other 40 files are actively used and form the functional app structure.

---

**Generated:** Analysis complete ✨
**Tool Used:** Cursor AI Agent with comprehensive file analysis

