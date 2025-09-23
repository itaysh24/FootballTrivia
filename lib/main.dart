// ignore_for_file: unnecessary_breaks

import 'dart:ui';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'Pages/profile/profile_page.dart';
import 'pages/leaderboard/leaderboard_page.dart';
import 'pages/training/training_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/music_service.dart';
import 'pages/game_modes/game_modes_main.dart';
import 'pages/voice_trivia.dart';

// Global music service instance
final musicService = MusicService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
   await Supabase.initialize(
    url: 'https://nuvbzopwnnyvovdohwao.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im51dmJ6b3B3bm55dm92ZG9od2FvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTgyNjg0ODIsImV4cCI6MjA3Mzg0NDQ4Mn0.d0-9hnS7ahKNKRnZaFJaHQ4_teMMrUGtQnI3QDH24d8',
  );
  final musicService = MusicService();
  await musicService.preloadAllTracks();
  runApp(MyApp(musicService: musicService));
}

class MyApp extends StatefulWidget {
  final MusicService musicService;
  const MyApp({super.key, required this.musicService});
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(musicService: musicService),
    );
  }
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    musicService.startLooping(); // Start looping through all tracks
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    musicService.stop(); // Stop music when app is disposed
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        // Pause music when app goes to background
        musicService.pause();
        break;
      case AppLifecycleState.resumed:
        // Resume music when app comes back to foreground
        musicService.resume();
        break;
      case AppLifecycleState.detached:
        // Stop music only when app is completely closed
        musicService.stop();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Street Football',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFFA726), // Primary orange
            secondary: const Color(0xFF26C6DA), // Secondary teal
          ),
          textTheme: const TextTheme(
            headlineLarge: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            bodyLarge: TextStyle(
              color: Color(0xFFFFFFFF), // White text
            ),
            bodyMedium: TextStyle(
              color: Color(0xB3FFFFFF), // Semi-transparent white
            ),
          ),
        ),
        home: MyHomePage(),
        routes: {
      '/game_modes': (context) => const GameModesPage(),
      '/training': (context) => const TrainingScreen(), // your training mode
      '/voice_trivia': (context) => const VoiceTriviaPage(),
        },
      ),
    );
  }
}

// Icon list for the animated bottom navigation bar
final List<IconData> iconList = [
  Icons.home,
  Icons.leaderboard_rounded,
  Icons.sports_soccer_rounded,
  Icons.person,
  Icons.shopping_bag_rounded,
];

class MyAppState extends ChangeNotifier {
  var current = WordPair.random();
  double blurLevel = 2.0; // Default blur level (0.0 = no blur, 10.0 = heavy blur)
  
  void getNext() {
    current = WordPair.random();
    notifyListeners();
  }
  
  var favorites = <WordPair>[];

  void toggleFavorite() {
    if (favorites.contains(current)) {
      favorites.remove(current);
    } else {
      favorites.add(current);
    }
    notifyListeners();
  }
  
  void updateBlurLevel(double newLevel) {
    blurLevel = newLevel;
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  
  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = HomePage();
        break;
      case 1:
        page = LeaderboardPage();
        break;
      case 2:
        page = GameModesPage();
        break;
      case 3:
        page = ProfilePage();
        break;
      case 4:
        page = ShopPage();
        break;
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: Stack(
        children: [
          // Background with image, gradient, and blur
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/background.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x99000000), // Black with 0.6 opacity
                    Color(0x00000000), // Transparent
                  ],
                ),
              ),
              child: appState.blurLevel > 0
                  ? BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: appState.blurLevel,
                        sigmaY: appState.blurLevel,
                      ),
                      child: Container(
                        color: Colors.transparent,
                      ),
                    )
                  : Container(),
            ),
          ),
          // Content overlay (not blurred) with padding for glass header and navigation bar
          Positioned(
            top: 40, // Height of glass header
            left: 0,
            right: 0,
            bottom: 1, // Height of navigation bar + SafeArea
            child: page,
          ),
          // Glass header with SafeArea
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color.fromARGB(120, 33, 43, 31), // Semi-transparent dark
                      const Color.fromARGB(60, 33, 43, 31),  // More transparent
                      Colors.transparent, // Fully transparent at bottom
                    ],
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(20),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 5),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.circular(20),
                        ),
                        color: Colors.white.withOpacity(0.1),
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => musicService.nextSong(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange.withOpacity(0.8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text("Next Song"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Navigation bar overlay with SafeArea
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              child: AnimatedBottomNavigationBar(
              icons: iconList,
              activeIndex: selectedIndex,
              gapLocation: GapLocation.none,
              notchSmoothness: NotchSmoothness.verySmoothEdge,
              leftCornerRadius: 32,
              rightCornerRadius: 32,
              onTap: (index) {
                setState(() {
                  selectedIndex = index;
                });
              },
              activeColor: const Color(0xFFFFA726), // Primary orange
              inactiveColor: const Color.fromARGB(255, 156, 155, 155), // Gray for inactive items
              backgroundColor: const Color.fromARGB(230, 33, 43, 31), // Semi-transparent dark background
              splashColor: const Color(0xFFFFA726), // Orange splash effect
              iconSize: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  final MusicService? musicService; // Add this line
  const HomePage({super.key, this.musicService});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80), // Space for navigation bar
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 30),
              Image(
                image: AssetImage("assets/images/Logo.png"),
                height: 200,
                width: 200,
              ),
              const SizedBox(height: 10),
              Image(
                image: AssetImage("assets/images/Layer 3.png"),
                height: 30,
                width: 400,
              ),
              const SizedBox(height: 20),
              Image(
                image: AssetImage("assets/images/GUESS THE PLAYER.png"),
                height: 30,
                width: 350,
              ),
              const SizedBox(height: 219),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      // Add your play now logic here
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const TrainingScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA726), // Primary orange
                      foregroundColor: Colors.black, // Black text
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      'Play Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            
            ],
          ),
        ),
      ),
    );
  }
}



class ShopPage extends StatelessWidget {
 @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Shop Page'),
    );
  }
}

