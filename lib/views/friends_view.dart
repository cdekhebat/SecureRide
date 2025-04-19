// lib/views/friends_view.dart
import 'package:flutter/material.dart';

class FriendsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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