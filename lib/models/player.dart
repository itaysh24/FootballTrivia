class Player {
  final String displayName;
  final int score;

  Player({required this.displayName, required this.score});

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      displayName: map['display_name'] as String,
      score: map['score'] as int,
    );
  }
}
