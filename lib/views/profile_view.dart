// lib/views/profile_view.dart
import 'package:flutter/material.dart';

class ProfileView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 50),
          SizedBox(height: 20),
          Text('Profile Screen'),
        ],
      ),
    );
  }
}