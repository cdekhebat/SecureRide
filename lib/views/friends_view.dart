<<<<<<< HEAD
import 'package:flutter/material.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
=======
// lib/views/friends_view.dart
import 'package:flutter/material.dart';

class FriendsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 50),
          SizedBox(height: 20),
          Text('Friend List Screen'),
        ],
      ),
    );
  }
}