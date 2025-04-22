import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:path_provider/path_provider.dart';

class TestCrashScreen extends StatefulWidget {
  const TestCrashScreen({super.key});

  @override
  State<TestCrashScreen> createState() => _TestCrashScreenState();
}

class _TestCrashScreenState extends State<TestCrashScreen> {
  // Test parameters (lowered for easier testing)
  static const double speedDropThreshold = 15.0; // km/h drop to trigger
  static const double gForceThreshold = 1.2; // Lower G-force threshold
  static const Duration checkInterval = Duration(seconds: 1);

  // State variables
  double currentSpeed = 0.0;
  int crashCount = 0;
  bool isTesting = false;
  List<double> speedHistory = [];
  DateTime? lastCrashTime;

  // Controllers
  Timer? testTimer;
  StreamSubscription<AccelerometerEvent>? sensorSub;

  @override
  void initState() {
    super.initState();
    _initSensors();
  }

  @override
  void dispose() {
    _stopTest();
    sensorSub?.cancel();
    super.dispose();
  }

  void _initSensors() {
    sensorSub = accelerometerEvents.listen((event) {
      final gForce = _calculateGForce(event.x, event.y, event.z);
      if (gForce > gForceThreshold && isTesting) {
        _handleCrash('High G-force: ${gForce.toStringAsFixed(1)}G');
      }
    });
  }

  double _calculateGForce(double x, double y, double z) {
    return sqrt(x * x + y * y + z * z) / 9.8;
  }

  void _toggleTest() {
    setState(() {
      isTesting = !isTesting;
      if (isTesting) {
        _startTest();
      } else {
        _stopTest();
      }
    });
  }

  void _startTest() {
    testTimer = Timer.periodic(checkInterval, (timer) {
      setState(() {
        // Simulate speed changes between 0-40 km/h
        currentSpeed = Random().nextDouble() * 40;
        speedHistory.add(currentSpeed);

        // Keep last 3 readings
        if (speedHistory.length > 3) speedHistory.removeAt(0);

        _checkForCrash();
      });
    });
  }

  void _stopTest() {
    testTimer?.cancel();
    currentSpeed = 0.0;
    speedHistory.clear();
  }

  void _checkForCrash() {
    if (speedHistory.length >= 2) {
      final prev = speedHistory[speedHistory.length - 2];
      final curr = speedHistory.last;

      // ✅ Adjusted logic: significant drop from >=50 to <=40 within 1s
      if (prev >= 50 && curr <= 40) {
        debugPrint("⚠️ Crash Detected: $prev ➜ $curr");
        _handleCrash('Speed dropped from $prev to $curr');
      }
    }
  }



  Future<void> _handleCrash(String reason) async {
    // Prevent multiple detections within 5 seconds
    if (lastCrashTime != null &&
        DateTime.now().difference(lastCrashTime!) < Duration(seconds: 5)) {
      return;
    }

    lastCrashTime = DateTime.now();
    setState(() => crashCount++);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🚨 Crash: $reason'),
        backgroundColor: Colors.red,
      ),
    );

    await _saveTestRecord(reason);
  }

  Future<void> _saveTestRecord(String reason) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final crashDir = Directory('${dir.path}/test_crashes');
      if (!await crashDir.exists()) await crashDir.create();

      final file = File('${crashDir.path}/crash_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString('''
Crash at: ${DateTime.now()}
Reason: $reason
Speed: ${currentSpeed.toStringAsFixed(1)} km/h
''');
      print('Saved test record: ${file.path}');
    } catch (e) {
      print('Error saving record: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crash Test')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Speed Display
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.speed, size: 40, color: Colors.blue),
                  SizedBox(height: 10),
                  Text(
                    '${currentSpeed.toStringAsFixed(1)} km/h',
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    isTesting ? 'Testing Active' : 'Testing Inactive',
                    style: TextStyle(
                      color: isTesting ? Colors.green : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Crash Counter
            Text('Crashes Detected:', style: TextStyle(fontSize: 18)),
            Text(
              '$crashCount',
              style: TextStyle(
                fontSize: 40,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 30),

            // Control Buttons
            ElevatedButton(
              onPressed: _toggleTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: isTesting ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: Text(isTesting ? 'STOP TEST' : 'START TEST'),
            ),
          ],
        ),
      ),
    );
  }
}