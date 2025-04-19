// lib/views/camera_view.dart
import 'package:flutter/material.dart';

class CameraView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.camera_alt, size: 50),
          SizedBox(height: 20),
          Text('Camera Screen'),
        ],
      ),
    );
  }
}