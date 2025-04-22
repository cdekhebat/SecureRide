import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart'; // Added for debugPrint
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_background/flutter_background.dart' as fb;
import '../services/camera_service.dart';
import 'package:secureride/views/crash_video_list_view.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double currentSpeed = 0.0;
  int crashCount = 0;
  List<String> crashVideos = [];
  List<double> speedHistory = [];
  bool isTestingMode = false; // Set to true for testing
  Timer? _speedTimer;
  final CameraService _cameraService = CameraService();
  final Random _random = Random();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadCrashData();
    _startSpeedMonitoring();
    _setupBackgroundService();
  }

  Future<void> _setupBackgroundService() async {
    try {
      const androidConfig = fb.FlutterBackgroundAndroidConfig(
        notificationTitle: "SecureRide Monitor",
        notificationText: "Crash detection is active",
        notificationIcon: fb.AndroidResource(name: 'ic_launcher', defType: 'mipmap'),
      );

      final initialized = await fb.FlutterBackground.initialize(androidConfig: androidConfig);
      if (initialized) {
        await fb.FlutterBackground.enableBackgroundExecution();
      }
    } catch (e) {
      debugPrint("Background service setup error: $e");
    }
  }

  Future<void> _initializeCamera() async {
    try {
      await _cameraService.initializeCamera();
      setState(() => _isCameraInitialized = true);

      // Start recording automatically
      if (!_cameraService.isRecording) {
        await _cameraService.startLoopRecording();
      }
    } catch (e) {
      debugPrint("Camera initialization failed: $e");
    }
  }

  Future<void> _loadCrashData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      crashCount = prefs.getInt('crashCount') ?? 0;
      crashVideos = prefs.getStringList('crashVideos') ?? [];
    });
  }

  Future<void> _saveCrashData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crashCount', crashCount);
    await prefs.setStringList('crashVideos', crashVideos);
  }

  Future<void> _resetCrashData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('crashCount');
    await prefs.remove('crashVideos');

    final dir = await getApplicationDocumentsDirectory();
    final crashDir = Directory('${dir.path}/crash_videos');
    if (await crashDir.exists()) {
      for (var file in crashDir.listSync()) {
        if (file is File) await file.delete();
      }
    }

    setState(() {
      crashCount = 0;
      crashVideos = [];
      speedHistory = [];
    });
  }

  void _startSpeedMonitoring() async {
    if (!isTestingMode) await Geolocator.requestPermission();

    int tick = 0;
    _speedTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      tick++;

      if (isTestingMode) {
        // Simulate crash every 20 seconds (90 -> 0)
        if (tick % 20 == 0) {
          setState(() {
            currentSpeed = 90;
            speedHistory.add(currentSpeed);
          });
        } else if (tick % 20 == 1) {
          setState(() {
            currentSpeed = 0;
            speedHistory.add(currentSpeed);
          });
          _checkForCrash();
        } else {
          // Random speed fluctuations
          final fluctuations = [-10, -5, 0, 5, 10];
          double fluctuation = fluctuations[_random.nextInt(fluctuations.length)].toDouble();
          double newSpeed = (currentSpeed + fluctuation).clamp(0, 180);
          setState(() {
            currentSpeed = newSpeed;
            speedHistory.add(currentSpeed);
          });
        }

        if (speedHistory.length > 10) {
          speedHistory.removeAt(0);
        }
      } else {
        // Real speed monitoring
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
            distanceFilter: 5,
          ),
        ).listen((Position position) {
          double speedKmh = position.speed * 3.6;
          setState(() {
            currentSpeed = speedKmh;
            speedHistory.add(currentSpeed);
            if (speedHistory.length > 10) speedHistory.removeAt(0);
          });
          _checkForCrash();
        });
      }
    });
  }

  void _checkForCrash() {
    if (speedHistory.length >= 2) {
      final prev = speedHistory[speedHistory.length - 2];
      final curr = speedHistory.last;

      // Crash detection: significant drop from >=50 to <=40 within 1s
      if (prev >= 50 && curr <= 40) {
        debugPrint("⚠️ Crash Detected: $prev ➜ $curr");
        _handleCrashDetected();
      }
    }
  }

  Future<void> _handleCrashDetected() async {
    if (!_isCameraInitialized) {
      debugPrint("Camera not initialized, skipping crash save");
      return;
    }

    try {
      // Ensure camera service is recording
      if (!_cameraService.isRecording) {
        debugPrint("Starting loop recording for crash save");
        await _cameraService.startLoopRecording();
      }

      // Stop recording to save the current video
      final videoPath = await _cameraService.stopLoopRecording();
      if (videoPath == null || !File(videoPath).existsSync()) {
        debugPrint("No video available for crash");
        return;
      }

      final dir = await getApplicationDocumentsDirectory();
      final crashDir = Directory('${dir.path}/crash_videos');
      if (!await crashDir.exists()) await crashDir.create(recursive: true);

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final crashPath = path.join(crashDir.path, 'crash_$timestamp.mp4');
      await File(videoPath).copy(crashPath);

      setState(() {
        crashCount++;
        crashVideos.add(crashPath);
      });

      await _saveCrashData();
      await _updateCrashStatus();

      // Restart recording after saving crash video
      await _cameraService.startLoopRecording();

      debugPrint("✅ Crash video saved: $crashPath");
    } catch (e) {
      debugPrint("Crash save error: $e");
    }
  }

  Future<void> _updateCrashStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection('users').doc(uid).update({
      'status': 'crashed',
      'lastCrash': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDE DASHBOARD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetCrashData,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SfRadialGauge(
              axes: [
                RadialAxis(
                  minimum: 0,
                  maximum: 180,
                  ranges: [
                    GaugeRange(startValue: 0, endValue: 60, color: Colors.green),
                    GaugeRange(startValue: 60, endValue: 120, color: Colors.orange),
                    GaugeRange(startValue: 120, endValue: 180, color: Colors.red),
                  ],
                  pointers: [
                    NeedlePointer(value: currentSpeed),
                  ],
                  annotations: [
                    GaugeAnnotation(
                      widget: Text(
                        '${currentSpeed.toStringAsFixed(0)} km/h',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      angle: 90,
                      positionFactor: 0.8,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey[200]),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('CRASHES DETECTED'),
                    Text('$crashCount', style: const TextStyle(fontSize: 32, color: Colors.red)),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: crashVideos.isEmpty
                      ? null
                      : () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CrashVideoListView(videos: crashVideos),
                    ),
                  ),
                  icon: const Icon(Icons.video_library),
                  label: const Text('VIEW CRASHES'),
                ),
              ],
            ),
          ),
          if (!_isCameraInitialized)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                'Camera not initialized. Crash videos may not be saved.',
                style: TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }
}