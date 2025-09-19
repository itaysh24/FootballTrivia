import 'package:flutter/material.dart';
import '../leaderboard/leaderboard_container.dart';

/// Player model (kept here for now, can move to models folder later)
class Player {
  final String displayName;
  final int score;

  Player({required this.displayName, required this.score});
}

// Fake leaderboard data for now
final List<Player> fakeLeaderboard = [
  Player(displayName: "Itay", score: 1300),
  Player(displayName: "David", score: 1150),
  Player(displayName: "Maya", score: 980),
  Player(displayName: "Sofia", score: 930),
  Player(displayName: "Leo", score: 900),
  Player(displayName: "Alex", score: 850),
  Player(displayName: "Itay", score: 1200),
  Player(displayName: "David", score: 1150),
  Player(displayName: "Maya", score: 980),
  Player(displayName: "Sofia", score: 930),
  Player(displayName: "Leo", score: 900),
  Player(displayName: "Alex", score: 850),
];

class LeaderboardPage extends StatelessWidget {
  const LeaderboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 65), // Space for navigation bar
        child: Center(
          child: ProfileContainer(
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Leaderboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: fakeLeaderboard.length,
                    itemBuilder: (context, index) {
                      final player = fakeLeaderboard[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        color: const Color.fromARGB(100, 255, 168, 38), // Semi-transparent orange
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFFFFA726),
                            child: Text(
                              "#${index + 1}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          title: Text(
                            player.displayName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          trailing: Text(
                            player.score.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
