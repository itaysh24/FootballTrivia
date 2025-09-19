// ignore_for_file: unnecessary_breaks

import 'dart:ui';
import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'Pages/profile/profile_page.dart';
import 'Pages/leaderboard/leaderboard_page.dart';
import 'Pages/coregame/game_screen.dart';
// ignore: unused_import
import 'package:cloud_firestore/cloud_firestore.dart';




void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("✅ Firebase initialized!");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
          // Content overlay (not blurred)
          page,
          // Navigation bar overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
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
        ],
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
            ElevatedButton(
              onPressed: () {
                // Add your play now logic here
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GameScreen()),
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
              
              // Quick blur control
            ],
          ),
        ),
      ),
    );
  }
}



class GameModesPage extends StatelessWidget {
 @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Game modes Page'),
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

