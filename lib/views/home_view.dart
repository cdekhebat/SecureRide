import 'package:flutter/material.dart';

class HomeView extends StatelessWidget {
  final bool isConnected;
  final bool isRecording;
  final Function(bool) onRecordingChanged;

  const HomeView({
    super.key,
    required this.isConnected,
    required this.isRecording,
    required this.onRecordingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
            'Auto-Recording',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text('Enable Auto-Recording'),
            value: isRecording,
            onChanged: isConnected ? onRecordingChanged : null,
          ),
          if (!isConnected)
            const Text(
              'Connect to ESP32 to enable recording',
              style: TextStyle(color: Colors.red),
            ),
        ],
      ),
    );
  }
}