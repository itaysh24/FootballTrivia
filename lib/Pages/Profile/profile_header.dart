import 'package:flutter/material.dart';
import 'profile_avatar.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment.bottomCenter,
          child: ProfileAvatar(),
        ),
      ],
    );
  }
}

class ProfileUserName extends StatelessWidget {
  const ProfileUserName({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 76, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(179, 212, 147, 61),
        borderRadius: BorderRadius.circular(80),
      ),
      child: Text(
        "Ohad Haim",
        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}