// lib/pages/training/widgets/training_slots_widget.dart
import 'dart:math';
import 'package:flutter/material.dart';

class TrainingSlotsWidget extends StatelessWidget {
  final String firstName;
  final String lastName;
  final List<String?> slots;
  final double screenWidth;
  final Function(int) onSlotTapped;
  final bool inputDisabled;

  const TrainingSlotsWidget({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.slots,
    required this.screenWidth,
    required this.onSlotTapped,
    required this.inputDisabled,
  });

  @override
  Widget build(BuildContext context) {
    final firstNameLength = firstName.length;
    final lastNameLength = lastName.length;
    
    // Define a safe zone for placeholders (85% of screen width) - more space
    final safeZoneWidth = screenWidth * 0.85;
    final safeZonePadding = (screenWidth - safeZoneWidth) / 2;
    
    // Find the row that needs the most space (longest name)
    final maxNameLength = max(firstNameLength, lastNameLength);
    
    // Calculate slot size to fit within the safe zone
    // Account for margins between slots (4px each side = 8px per slot)
    final slotSize = (safeZoneWidth - (maxNameLength * 8)) / maxNameLength;
    
    // Clamp to reasonable bounds
    final finalSlotSize = slotSize.clamp(18.0, 55.0);

    return Container(
      width: safeZoneWidth,
      margin: EdgeInsets.only(left: safeZonePadding - 20, right: safeZonePadding + 20),
      child: Column(
        children: [
          // First name row
          if (firstNameLength > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(firstNameLength, (i) {
                return GestureDetector(
                  onTap: inputDisabled ? null : () => onSlotTapped(i),
                  child: _buildSlot(i, finalSlotSize),
                );
              }),
            ),
            if (lastNameLength > 0) const SizedBox(height: 12),
          ],
          // Last name row
          if (lastNameLength > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(lastNameLength, (i) {
                final idx = firstNameLength + i;
                return GestureDetector(
                  onTap: inputDisabled ? null : () => onSlotTapped(idx),
                  child: _buildSlot(idx, finalSlotSize),
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSlot(int idx, double slotSize) {
    final content = slots[idx];
    final fontSize = (slotSize * 0.45).clamp(10.0, 24.0);
    final margin = slotSize < 35 ? 2.0 : 4.0;
    final borderRadius = slotSize < 35 ? 6.0 : 8.0;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: margin),
      width: slotSize,
      height: slotSize * 1.1,
      child: Stack(
        children: [
          // Background with glassmorphism effect
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: content == null
                    ? [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ]
                    : [
                        Colors.orange.withOpacity(0.3),
                        Colors.orange.withOpacity(0.15),
                      ],
              ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: content == null
                    ? Colors.white.withOpacity(0.3)
                    : Colors.orange.withOpacity(0.6),
                width: content == null ? 1.0 : 2.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
                if (content != null)
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 0),
                  ),
              ],
            ),
          ),
          // Content
          Center(
            child: Text(
              content ?? '',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.7),
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          // Tap indicator
          if (!inputDisabled && content != null)
            Positioned(
              top: 2,
              right: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }
}