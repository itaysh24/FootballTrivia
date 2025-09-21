// lib/pages/training/widgets/training_controls_widget.dart
import 'package:flutter/material.dart';

class TrainingControlsWidget extends StatelessWidget {
  final VoidCallback onSkip;
  final VoidCallback onRemoveLetter;

  const TrainingControlsWidget({
    super.key,
    required this.onSkip,
    required this.onRemoveLetter,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          onPressed: onSkip,
          colors: [
            Colors.blue.withOpacity(0.8),
            Colors.blue.shade700,
          ],
          borderColor: Colors.blue.shade300,
        ),
        _buildControlButton(
          icon: Icons.backspace_rounded,
          label: 'Undo',
          onPressed: onRemoveLetter,
          colors: [
            Colors.red.withOpacity(0.8),
            Colors.red.shade700,
          ],
          borderColor: Colors.red.shade300,
        ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required List<Color> colors,
    required Color borderColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
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
          ),
        ),
      ),
    );
  }
}