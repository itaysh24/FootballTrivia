import 'package:flutter/material.dart';
import 'package:infinite_carousel/infinite_carousel.dart';
import 'english_league_map.dart';
import 'spanish_league_map.dart';
import 'italian_league_map.dart';
import 'german_league_map.dart';
import 'french_league_map.dart';

class RoadToGloryScreen extends StatelessWidget {
  const RoadToGloryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final leagues = [
      {"name": "English League", "image": "assets/images/Leagues/english.jpg"},
      {"name": "Spanish League", "image": "assets/images/Leagues/spanish.jpg"},
      {"name": "German League", "image": "assets/images/Leagues/german.jpg"},
      {"name": "Italian League", "image": "assets/images/Leagues/italian.png"},
      {"name": "French League", "image": "assets/images/Leagues/french.jpg"},
    ];

    return Scaffold(
      body: Stack(
        children: [
          // Background image from main.dart
          Positioned.fill(
            child: Image.asset(
              "assets/images/background.jpg",
              fit: BoxFit.cover,
            ),
          ),
          // Gradient overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.9)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // Content
          Center(
          child: Container(
            margin: const EdgeInsets.all(10.0),
            padding: const EdgeInsets.all(26.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SizedBox(
              height: 320, // Fixed height for the container
              child: InfiniteCarousel.builder(
                itemCount: leagues.length,
                itemExtent: 240,
                center: true,
                anchor: 0.0,
                velocityFactor: 0.8,
                loop: true,
                itemBuilder: (context, index, realIndex) {
                  final league = leagues[index];
                  return GestureDetector(
                    onTap: () {
                      switch (league['name']) {
                        case 'English League':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EnglishLeagueMapScreen(),
                            ),
                          );
                        case 'Spanish League':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SpanishLeagueMapScreen(),
                            ),
                          );
                        case 'Italian League':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ItalianLeagueMapScreen(),
                            ),
                          );
                        case 'German League':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GermanLeagueMapScreen(),
                            ),
                          );
                        case 'French League':
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FrenchLeagueMapScreen(),
                            ),
                          );
                        default:
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${league['name']} coming soon!'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                      }
                    },
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 15,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              league['image']!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7)
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  league['name']!,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }
}
