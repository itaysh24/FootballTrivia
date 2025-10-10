import 'dart:ui';
import 'package:flutter/material.dart';

class GameModeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool locked;
  final VoidCallback? onTap;

  const GameModeCard({
    super.key,
    required this.title,
    required this.description,
    this.locked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: locked ? null : onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (!locked)
              BoxShadow(
                color: Colors.orange.withOpacity(0.5),
                blurRadius: 25,
                offset: const Offset(0, 10),
                spreadRadius: 2,
              ),
            if (!locked)
              BoxShadow(
                color: const Color(0xFFFF7043).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 5),
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: locked
                    ? LinearGradient(
                        colors: [
                          Colors.grey.withOpacity(0.3),
                          Colors.black54.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          const Color(0xFFFFA726).withOpacity(0.8),
                          const Color(0xFFFF7043).withOpacity(0.7),
                          const Color(0xFFFF5722).withOpacity(0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: locked
                      ? Colors.white.withOpacity(0.1)
                      : Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  locked ? Icons.lock : Icons.sports_esports,
                  color: Colors.white,
                  size: 30,
                ),
                title: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.6),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
                subtitle: Text(
                  description,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                trailing: locked
                    ? const Icon(Icons.lock_outline, color: Colors.white54)
                    : const Icon(Icons.arrow_forward_ios, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
