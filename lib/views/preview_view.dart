<<<<<<< HEAD
import 'package:flutter/material.dart';

class PreviewView extends StatelessWidget {
  const PreviewView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
=======
// lib/views/preview_view.dart
import 'package:flutter/material.dart';

class PreviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.video_library, size: 50),
          SizedBox(height: 20),
          Text('Video Preview Screen'),
        ],
      ),
    );
  }
}