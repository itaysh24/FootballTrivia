import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

class ProfileActions extends StatefulWidget {
  const ProfileActions({super.key});

  @override
  State<ProfileActions> createState() => _ProfileActionsState();
}

class _ProfileActionsState extends State<ProfileActions> {
  final AuthService _authService = AuthService();
  bool _isUpgrading = false;

  Future<void> _handleSignOut() async {
    try {
      await _authService.signOut();
      // AuthGate will automatically redirect to login
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error signing out: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleUpgradeAccount() async {
    setState(() => _isUpgrading = true);
    try {
      final success = await _authService.upgradeGuestToGoogle();
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account upgraded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {}); // Refresh to update UI
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error upgrading account: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpgrading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = _authService.isGuest;

    return Column(
      children: [
        // Main action buttons row
        Row(
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
        ),
        const SizedBox(height: 16.0),
        // Reset tutorial button in separate row
        ProfileActionButton(
          label: "Reset Tutorial",
          icon: Icons.refresh,
          heroTag: 'Reset Tutorial',
          backgroundColor: Colors.orange,
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('skipTutorialPopup', false);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tutorial will show on next app launch'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
        // Guest upgrade button (only shown for guest users)
        if (isGuest) ...[
          const SizedBox(height: 16.0),
          ProfileActionButton(
            label: _isUpgrading ? "Upgrading..." : "Upgrade to Permanent Account",
            icon: Icons.upgrade,
            heroTag: 'Upgrade Account',
            backgroundColor: Colors.green,
            onPressed: _isUpgrading ? () {} : () => _handleUpgradeAccount(),
          ),
        ],
        const SizedBox(height: 16.0),
        // Sign out button
        ProfileActionButton(
          label: "Sign Out",
          icon: Icons.logout,
          heroTag: 'Sign Out',
          backgroundColor: Colors.grey.shade700,
          onPressed: _handleSignOut,
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
