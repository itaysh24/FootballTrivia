import 'package:flutter/material.dart';
import 'profile_container.dart';
import 'profile_header.dart';
import 'profile_info.dart';
import 'profile_actions.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 65), // Space for navigation bar
        child: Center(
          child: ProfileContainer(
            child: Column(
              children: const [
                Expanded(flex: 2, child: ProfileHeader()),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        ProfileUserName(),
                        SizedBox(height: 16),
                        ProfileActions(),
                        SizedBox(height: 16),
                        ProfileInfoRow(),
                      ],
                    ),
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
