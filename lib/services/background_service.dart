import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class BackgroundService {
  static final Random _random = Random();
  static List<String> _backgrounds = [];

  /// Call this once when the app starts
  static Future<void> loadBackgrounds() async {
    // Load from AssetManifest.json (lists all assets declared in pubspec.yaml)
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    _backgrounds = manifestContent
        .split('\n')
        .where((path) => path.contains('assets/images/backgrounds/'))
        .toList();
  }

  /// Get a random background path
  static String getRandomBackground() {
    if (_backgrounds.isEmpty) return 'assets/images/backgrounds/default.jpg';
    return _backgrounds[_random.nextInt(_backgrounds.length)];
  }
}
