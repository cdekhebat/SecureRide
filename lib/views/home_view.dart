<<<<<<< HEAD
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
=======
// lib/views/home_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';  // Make sure this import exists
import '../controllers/esp32_controller.dart';

class HomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<ESP32Controller>(context, listen: true);

>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
<<<<<<< HEAD
          Text(
            isConnected ? 'Connected' : 'Disconnected',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          const Text(
=======
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        controller.isConnected ? Icons.wifi : Icons.wifi_off,
                        color: controller.isConnected ? Colors.green : Colors.red,
                        size: 30,
                      ),
                      SizedBox(width: 10),
                      Text(
                        controller.connectionStatus,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Current WiFi: ${controller.wifiName}\nIP: ${controller.wifiIP}',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(height: 20),
                  if (!controller.isConnected)
                    ElevatedButton(
                      onPressed: controller.connectViaWifi,
                      child: Text('Connect to ESP32'),
                    )
                  else
                    ElevatedButton(
                      onPressed: controller.disconnect,
                      child: Text('Disconnect'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
            'Auto-Recording',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
<<<<<<< HEAD
            title: const Text('Enable Auto-Recording'),
            value: isRecording,
            onChanged: isConnected ? onRecordingChanged : null,
          ),
          if (!isConnected)
            const Text(
              'Connect to ESP32 to enable recording',
              style: TextStyle(color: Colors.red),
            ),
=======
            title: Text('Enable Auto-Recording'),
            value: controller.isConnected, // Replace with actual recording state
            onChanged: controller.isConnected
                ? (value) {} // Add recording logic here
                : null,
          ),
>>>>>>> ba27ac7fd692d43f4d9b49f48682d275b2b5ce02
        ],
      ),
    );
  }
}