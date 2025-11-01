# Flutter Football Trivia - Authentication Implementation Analysis

**Generated:** October 31, 2025
**Project Path:** c:\Users\Itay\Desktop\FootballTrivia\football_trivia

## EXECUTIVE SUMMARY

The Football Trivia app currently has:
- A mock authentication screen with simulated login
- Supabase configured but authentication methods NOT enabled
- Google Sign-In package imported but NOT integrated
- Hardcoded user data ("Ohad Haim" in profile)
- NO user management system
- Progress tracking uses local storage only (not user-specific)

---

## CURRENT AUTHENTICATION IMPLEMENTATION

### 1. Auth Screen (lib/auth_screen.dart)
**Lines: 1-143**

Current behavior:
- Displays app logo and two buttons
- "Login with Google" button (Line 79-111)
- "Continue as Guest" button (Line 115-124)
- Both buttons call _simulateLogin() which just navigates to MainScreen

Critical issue: No actual authentication logic implemented.

### 2. App Initialization (lib/main.dart)

**Supabase Setup (Lines 30-34):**
```
- URL: https://nuvbzopwnnyvovdohwao.supabase.co
- Anonymous Key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
- Database IS working for player queries
- Authentication methods NOT configured
```

**AuthChecker Widget (Lines 175-233):**
- Checks Supabase session (Line 191)
- Routes to AuthScreen if no session
- Routes to MainScreen if session exists
- Problem: Session always null (no auth configured)

### 3. User Profile System
**Hardcoded Values (lib/pages/Profile/profile_header.dart):**
- Line 30: User name = "Ohad Haim" (HARDCODED)
- profile_info.dart Lines 6-10: Stats hardcoded (12 wins, 1480 score, 16 streak)

---

## DEPENDENCIES & PACKAGES

**pubspec.yaml:**
```
google_sign_in: ^6.2.1       - IMPORTED but NOT USED
supabase_flutter: ^2.5.4     - Used for database only
shared_preferences: ^2.2.2   - Used for game progress (not auth)
```

---

## USER MODEL STRUCTURE

**Current Models:**
- Player.dart (Lines 1-13): Has displayName and score - ONLY for leaderboard

**Missing:**
- User model class
- User authentication provider
- Guest vs authenticated differentiation

---

## PROGRESS & DATA PERSISTENCE

### Local Storage (SharedPreferences)
**progress_service.dart:**
- Stores RTG progress by league ID (key: 'rtg_progress_' + leagueId)
- Format: comma-separated unlocked level numbers
- ISSUE: Not linked to user accounts

### Leaderboard Data (Supabase)
**leaderboard_page.dart (Lines 17-26):**
```
- Fetches from 'leaderboard' table
- No user filtering
- No user identification
- Shows all scores globally
```

---

## FIREBASE CONFIGURATION
**android/app/google-services.json:**
- Project ID: football-trivia-24
- Project Number: 309596549418
- Configured packages:
  - com.dev.football_trivia
  - com.romulusdev.football_trivia_game
- Status: Config exists but NOT actively used

---

## WHAT NEEDS IMPLEMENTATION

### Phase 1: User Model & Authentication
1. Create User class with id, email, displayName, photoUrl, isGuest flag
2. Create AuthProvider (ChangeNotifier) for state management
3. Implement real Supabase Auth configuration

### Phase 2: Google Sign-In
1. Enable Google OAuth in Supabase dashboard
2. Implement google_sign_in package integration
3. Exchange Google token for Supabase session

### Phase 3: Guest Mode
1. Generate unique guest ID
2. Store in local storage
3. Differentiate guest vs authenticated data

### Phase 4: Database Structure
Need new Supabase tables:
- users: id, email, display_name, photo_url, is_guest, created_at
- user_stats: user_id, total_wins, top_score, best_streak
- game_sessions: user_id, game_mode, score, played_at

### Phase 5: User Profile Integration
1. Fetch real user data from database
2. Update profile page to display dynamic data
3. Track user statistics per account

---

## CRITICAL FILES AFFECTED

1. lib/main.dart - AuthChecker logic (Lines 175-233)
2. lib/auth_screen.dart - Auth UI implementation
3. lib/pages/Profile/ - All profile-related files
4. lib/services/ - Need auth_service.dart
5. lib/models/ - Need user.dart model
6. lib/providers/ - Need auth_provider.dart (NEW)

---

## KEY FINDINGS

### Security Issues
- Supabase keys hardcoded in main.dart
- No user verification on scores
- No session persistence for guests

### Data Issues
- No user-score association
- Hardcoded profile data
- Progress not per-user
- No game history tracking

---

## RECOMMENDATIONS

1. Start with User model and AuthProvider classes
2. Enable Supabase Auth in project dashboard
3. Implement Google Sign-In integration
4. Create database tables for user management
5. Update all UI components to use AuthProvider
6. Implement proper session persistence

