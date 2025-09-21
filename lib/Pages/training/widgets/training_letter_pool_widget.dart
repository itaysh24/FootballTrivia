// lib/pages/training/widgets/training_letter_pool_widget.dart
import 'package:flutter/material.dart';

class PoolLetter {
  final String char;
  bool used;
  PoolLetter(this.char) : used = false;
}

class TrainingLetterPoolWidget extends StatelessWidget {
  final List<dynamic> pool; // Accept dynamic to work with _PoolLetter
  final double screenWidth;
  final Function(int) onLetterSelected;
  final bool inputDisabled;

  const TrainingLetterPoolWidget({
    super.key,
    required this.pool,
    required this.screenWidth,
    required this.onLetterSelected,
    required this.inputDisabled,
  });

  @override
  Widget build(BuildContext context) {
    const maxRows = 3;
    final availableWidth = screenWidth - 20; // Reduced padding for more space
    
    // Calculate optimal distribution across max 3 rows
    final lettersPerRow = (pool.length / maxRows).ceil();
    final actualRows = (pool.length / lettersPerRow).ceil();
    final finalRows = actualRows > maxRows ? maxRows : actualRows;
    final finalLettersPerRow = (pool.length / finalRows).ceil();
    
    // Calculate button size to fit within screen bounds - bigger letters
    final buttonSize = (availableWidth / finalLettersPerRow - 6).clamp(30.0, 50.0);
    final fontSize = (buttonSize * 0.45).clamp(12.0, 20.0);
    
    // Split pool into rows
    final rows = <List<dynamic>>[];
    for (int i = 0; i < pool.length; i += finalLettersPerRow) {
      final endIndex = (i + finalLettersPerRow).clamp(0, pool.length);
      rows.add(pool.sublist(i, endIndex));
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: rows.asMap().entries.map((rowEntry) {
          final rowIndex = rowEntry.key;
          final row = rowEntry.value;
          
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final globalIndex = rowIndex * finalLettersPerRow + index;
                
                // Access properties dynamically
                final char = item.char as String;
                final used = item.used as bool;
                
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  child: _buildLetterButton(
                    char: char,
                    used: used,
                    size: buttonSize,
                    fontSize: fontSize,
                    onPressed: () => onLetterSelected(globalIndex),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLetterButton({
    required String char,
    required bool used,
    required double size,
    required double fontSize,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Button background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: used
                    ? [
                        Colors.grey.withOpacity(0.3),
                        Colors.grey.withOpacity(0.1),
                      ]
                    : [
                        Colors.orange,
                        Colors.orange.shade700,
                      ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: used
                    ? Colors.white.withOpacity(0.2)
                    : Colors.orange.shade300,
                width: 1,
              ),
              boxShadow: used
                  ? []
                  : [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.3),
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
          ),
          // Button content
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: (used || inputDisabled) ? null : onPressed,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                child: Text(
                  char,
                  style: TextStyle(
                    color: used ? Colors.white38 : Colors.white,
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    shadows: used
                        ? []
                        : [
                            const Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 1),
                              blurRadius: 2,
                            ),
                          ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}