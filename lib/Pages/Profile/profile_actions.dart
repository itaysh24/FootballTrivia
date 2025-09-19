import 'package:flutter/material.dart';

class ProfileActions extends StatelessWidget {
  const ProfileActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ProfileActionButton(
          label: "Add Friend",
          icon: Icons.person_add_alt_1,
          heroTag: 'Add Friend',
          onPressed: () {
            // Add friend logic here
          },
        ),
        const SizedBox(width: 16.0),
        ProfileActionButton(
          label: "Challenge",
          icon: Icons.sports_score,
          heroTag: 'Challenge',
          backgroundColor: Colors.red,
          onPressed: () {
            // Challenge logic here
          },
        ),
      ],
    );
  }
}

class ProfileActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final String heroTag;
  final Color? backgroundColor;
  final VoidCallback onPressed;

  const ProfileActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.heroTag,
    required this.onPressed,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      heroTag: heroTag,
      elevation: 0,
      backgroundColor: backgroundColor,
      label: Text(label),
      icon: Icon(icon),
    );
  }
}