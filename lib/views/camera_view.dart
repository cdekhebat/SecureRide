import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:secureride/services/camera_service.dart';
import 'package:camera/camera.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_background/flutter_background.dart';
import 'package:secureride/views/preview_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class CameraView extends StatefulWidget {
  const CameraView({super.key});

  @override
  State<CameraView> createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  final CameraService _cameraService = CameraService();
  bool _isInitialized = false;
  bool _shouldRestartRecording = false;

  @override
  void initState() {
    super.initState();
    _loadRecordingState();
    _initializeCameraAndPermissions();
    _initializeNotifications();
    _enableBackgroundExecution();
  }

  Future<void> _loadRecordingState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shouldRestartRecording = prefs.getBool('is_recording') ?? false;
    });
  }

  Future<void> _saveRecordingState(bool isRecording) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_recording', isRecording);
  }

  Future<void> _enableBackgroundExecution() async {
    const androidConfig = FlutterBackgroundAndroidConfig(
      notificationTitle: "SecureRide Dashcam",
      notificationText: "SecureRide is recording in the background",
      notificationIcon: AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
    );

    final initialized = await FlutterBackground.initialize(androidConfig: androidConfig);
    if (initialized) {
      await FlutterBackground.enableBackgroundExecution();
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings androidSettings =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initSettings =
    InitializationSettings(android: androidSettings);

    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  Future<void> _initializeCameraAndPermissions() async {
    await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    try {
      await _cameraService.initializeCamera();

      // Restart recording if it was active before
      if (_shouldRestartRecording) {
        await _cameraService.startLoopRecording();
      }

      setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  void _onToggleChanged(bool value) async {
    if (value) {
      await _cameraService.startLoopRecording();
      _showNotification("Recording Started", "Loop recording is now active");
    } else {
      await _cameraService.stopLoopRecording();
      _showNotification("Recording Stopped", "Loop recording has been paused");
    }
    _saveRecordingState(value);
    setState(() {});
  }

  Future<void> _showNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'recording_channel',
      'Recording Status',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await flutterLocalNotificationsPlugin.show(0, title, body, platformDetails);
  }

  Future<void> _onSavePressed() async {
    debugPrint("🟡 Save button pressed");

    if (!_cameraService.isRecording) {
      debugPrint("🔴 Not recording, can't save");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please start recording first")),
      );
      return;
    }

    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text("Saving video..."),
            ],
          ),
          duration: Duration(seconds: 3),
        ),
      );

      final savedPath = await _cameraService.saveManualRecording();
      debugPrint("📦 Returned path from saveManualRecording: $savedPath");

      if (savedPath != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Video saved successfully!")),
        );
        _showNotification("Video Saved", "Manual recording saved to gallery");
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save video")),
        );
      }
    } catch (e) {
      debugPrint("❌ Save error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Save failed: $e")),
        );
      }
    }
  }


  void _onPreviewPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const PreviewView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _cameraService.controller;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: !_isInitialized || controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreview(controller),
          Positioned(
            top: 50,
            left: 20,
            child: const Text(
              "SecureRide Dashcam",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: screenHeight * 0.25,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Loop Recording",
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 12),
                  FlutterSwitch(
                    value: _cameraService.isRecording,
                    onToggle: _onToggleChanged,
                    activeColor: Colors.red,
                    inactiveColor: Colors.grey,
                    width: 70,
                    height: 35,
                    toggleSize: 30,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _onSavePressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Save Current Video", style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _onPreviewPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text("View Gallery", style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
          if (!_cameraService.isRecording)
            Positioned(
              top: 100,
              left: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.black54,
                child: const Text(
                  "Recording not active\nCrash videos won't be saved",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
