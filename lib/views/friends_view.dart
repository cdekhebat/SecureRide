import 'package:flutter/material.dart';

class FriendsView extends StatelessWidget {
  const FriendsView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
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