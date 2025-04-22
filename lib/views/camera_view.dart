<<<<<<< HEAD
import 'package:flutter/material.dart';

class CameraView extends StatelessWidget {
  const CameraView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
=======
// lib/views/camera_view.dart
import 'package:flutter/material.dart';

class CameraView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
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