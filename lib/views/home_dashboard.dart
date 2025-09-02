import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'preview_view.dart';
import '../services/camera_service.dart';
import 'crash_video_list_view.dart';

class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  double _currentSpeed = 0.0;
  int _crashCount = 0;
  bool _isCameraReady = false;
  final CameraService _cameraService = CameraService();
  Timer? _speedTimer;
  List<double> _speedHistory = [];

  // Test mode variables
  bool testingCrash = false;
  Timer? testTimer;
  bool crashSimulated = false;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
  }

  Future<void> _initializeServices() async {
    await _loadCrashCount();
    await _cameraService.initializeCamera();
    await _cameraService.startLoopRecording();
    setState(() {
      _isCameraReady = true;
    });
    _startSpeedMonitoring();
  }

  Future<void> _loadCrashCount() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _crashCount = prefs.getInt('crashCount') ?? 0;
    });
  }

  Future<void> _saveCrashCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crashCount', _crashCount);
  }

  void _startSpeedMonitoring() {
    if (testingCrash) {
      _startCrashTest();
      return;
    }

    _speedTimer?.cancel();
    _speedTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.bestForNavigation,
        );

        setState(() {
          _currentSpeed = position.speed * 3.6;
          _speedHistory.add(_currentSpeed);
          if (_speedHistory.length > 10) _speedHistory.removeAt(0);
        });

        _checkForCrash();
      } catch (e) {
        debugPrint('Speed monitoring error: $e');
      }
    });
  }

  // -------------------
  // Test Mode Simulation
  // -------------------
  void _startCrashTest() {
    crashSimulated = false;
    _speedHistory.clear();

    testTimer?.cancel();
    testTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (!crashSimulated && timer.tick == 5) {
          // 🚨 Force crash at 5s
          _speedHistory.add(_currentSpeed);
          _currentSpeed = 35; // drop speed
          crashSimulated = true;
          _checkForCrash();
        } else {
          _currentSpeed = Random().nextDouble() * 60 + 30; // 30–90
        }

        _speedHistory.add(_currentSpeed);
        if (_speedHistory.length > 3) _speedHistory.removeAt(0);
      });
    });
  }

  void _stopCrashTest() {
    testTimer?.cancel();
    testTimer = null;
    testingCrash = false;
  }

  void _checkForCrash() {
    if (_speedHistory.length < 2) return;

    final double previousSpeed = _speedHistory[_speedHistory.length - 2];
    final double currentSpeed = _speedHistory.last;

    if ((previousSpeed - currentSpeed) >= 50) {
      _handleCrashDetected();
    }
  }

  Future<void> _handleCrashDetected() async {
    if (!_isCameraReady) return;

    try {
      final videoPath = await _cameraService.stopLoopRecording();
      if (videoPath == null) return;

      final appDir = await getApplicationDocumentsDirectory();
      final crashDir = Directory(p.join(appDir.path, 'crash_videos'));
      if (!await crashDir.exists()) await crashDir.create();

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final crashPath = p.join(crashDir.path, 'crash_$timestamp.mp4');
      await File(videoPath).copy(crashPath);

      setState(() {
        _crashCount++;
      });
      await _saveCrashCount();
      await _cameraService.startLoopRecording();

      // 🚨 Update crash status in Firestore
      await _setCrashStatus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(testingCrash
                ? '✅ Test crash detected! Video saved.'
                : '🚨 Crash detected! Video saved.'),
            backgroundColor: testingCrash ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint('Crash handling error: $e');
    }
  }

  /// 🚨 Update crash status for 2 hours
  Future<void> _setCrashStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final userDoc =
    FirebaseFirestore.instance.collection('users').doc(currentUser.uid);

    // Mark status = alert with crashAt timestamp
    await userDoc.update({
      'status': 'alert',
      'crashAt': FieldValue.serverTimestamp(),
    });

    // Reset to "online" after 2 hours (local timer safeguard)
    Future.delayed(const Duration(hours: 2), () async {
      final snap = await userDoc.get();
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final crashAt = (data['crashAt'] as Timestamp?)?.toDate();
      if (crashAt != null) {
        final diff = DateTime.now().difference(crashAt);
        if (diff.inHours >= 2) {
          await userDoc.update({'status': 'online'});
        }
      }
    });
  }

  void _resetCrashCount() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('crashCount', 0);
    setState(() {
      _crashCount = 0;
    });
  }

  @override
  void dispose() {
    _speedTimer?.cancel();
    testTimer?.cancel();
    _cameraService.stopLoopRecording();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RIDE DASHBOARD'),
        actions: [
          IconButton(
            icon: Icon(
              testingCrash ? Icons.stop : Icons.science,
              color: testingCrash ? Colors.red : Colors.yellow,
            ),
            tooltip: testingCrash ? 'Stop Crash Test' : 'Start Crash Test',
            onPressed: () {
              setState(() {
                testingCrash = !testingCrash;
              });
              if (testingCrash) {
                _stopCrashTest();
                _startCrashTest();
              } else {
                _stopCrashTest();
                _startSpeedMonitoring();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.video_library),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PreviewView()),
            ),
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
                  pointers: [NeedlePointer(value: _currentSpeed)],
                  annotations: [
                    GaugeAnnotation(
                      positionFactor: 0.8,
                      angle: 90,
                      widget: Text(
                        '${_currentSpeed.toStringAsFixed(0)} km/h',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    const Text('CRASHES DETECTED'),
                    Text(
                      '$_crashCount',
                      style: const TextStyle(
                        fontSize: 32,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _resetCrashCount,
                      child: const Text('Reset', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CrashVideoListView()),
                  ),
                  child: const Text('VIEW CRASH VIDEOS'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
