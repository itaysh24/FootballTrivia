// lib/pages/training/widgets/training_career_widget.dart
import 'package:flutter/material.dart';

class TrainingCareerWidget extends StatelessWidget {
  final List<String> careerPath;

  const TrainingCareerWidget({super.key, required this.careerPath});

  @override
  Widget build(BuildContext context) {
    if (careerPath.isEmpty) return const SizedBox.shrink();

    final isLongCareer = careerPath.length > 6;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: Colors.orange.shade300,
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                'Career Path',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black54,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (isLongCareer) ...[
            // Two columns for long career paths
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: careerPath
                        .take((careerPath.length / 2).ceil())
                        .map((career) => _buildCareerItem(career))
                        .toList(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: careerPath
                        .skip((careerPath.length / 2).ceil())
                        .map((career) => _buildCareerItem(career))
                        .toList(),
                  ),
                ),
              ],
            ),
          ] else ...[
            // Single column for short career paths
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: careerPath
                  .map((career) => _buildCareerItem(career))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCareerItem(String career) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 8, right: 8),
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.orange.shade300,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              career,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.3,
                shadows: [
                  Shadow(
                    color: Colors.black54,
                    offset: Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
