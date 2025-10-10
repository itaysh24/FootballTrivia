// lib/pages/training/services/training_image_service.dart
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

class TrainingImageService {
  List<String> availableImages = [];
  final Random _rnd = Random();

  Future<void> loadImages(BuildContext context) async {
    try {
      // Dynamically discover all images in the QuestionsFrames folder
      final manifestContent = await DefaultAssetBundle.of(
        context,
      ).loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Filter for images in the QuestionsFrames folder
      final imageKeys = manifestMap.keys
          .where(
            (String key) => key.startsWith('assets/images/QuestionsFrames/'),
          )
          .where(
            (String key) =>
                key.toLowerCase().endsWith('.jpg') ||
                key.toLowerCase().endsWith('.jpeg') ||
                key.toLowerCase().endsWith('.png'),
          )
          .toList();

      availableImages = imageKeys;
      availableImages.shuffle(_rnd);

      print('Loaded ${availableImages.length} images for training');
    } catch (e) {
      print('Error loading images: $e');
      availableImages = [];
    }
  }

  String getRandomImage() {
    if (availableImages.isEmpty) return '';
    return availableImages[_rnd.nextInt(availableImages.length)];
  }

  List<String> getRandomImages(int count) {
    if (availableImages.isEmpty) return [];

    final shuffled = List<String>.from(availableImages);
    shuffled.shuffle(_rnd);

    return shuffled.take(count).toList();
  }

  bool hasImages() => availableImages.isNotEmpty;

  int get imageCount => availableImages.length;
}
