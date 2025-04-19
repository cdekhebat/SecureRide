// lib/views/preview_view.dart
import 'package:flutter/material.dart';

class PreviewView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
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