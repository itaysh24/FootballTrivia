import 'package:flutter/material.dart';
import 'game_mode_card.dart';
import '../../core/game_modes_manager.dart';

class GameModesPage extends StatelessWidget {
  const GameModesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 65), // for nav bar space
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Game Modes',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    GameModeCard(
                      title: "Casual Mode",
                      description: "Relax and enjoy football trivia at your pace.",
                      locked: false,
                      onTap: () {
                        GameModeNavigator.startCasualMode(context);
                      },
                    ),
                    GameModeCard(
                      title: "Road to Glory",
                      description: "Embark on the ultimate career journey.",
                      locked: false,
                      onTap: () {
                        // Keep existing navigation to Road to Glory map
                        Navigator.pushNamed(context, '/road_to_glory');
                      },
                    ),
                    GameModeCard(
                      title: "Rush Mode",
                      description: "Answer 50 questions in 2 minutes!",
                      locked: false,
                      onTap: () {
                        GameModeNavigator.startRushMode(context);
                      },
                    ),
                    GameModeCard(
                      title: "Training",
                      description: "Practice and sharpen your trivia skills.",
                      locked: false,
                      onTap: () {
                        Navigator.pushNamed(context, "/training");
                      },
                    ),
                    
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
