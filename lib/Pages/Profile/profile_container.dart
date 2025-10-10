import 'package:flutter/material.dart';

class ProfileContainer extends StatelessWidget {
  final Widget child;

  const ProfileContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color.fromARGB(200, 33, 43, 31),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color.fromARGB(139, 255, 168, 38),
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
    );
  }
}
