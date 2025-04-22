import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class CrashDetector {
  final Function onCrashDetected;
  final double gForceThreshold;
  StreamSubscription<AccelerometerEvent>? _accelSubscription;

  CrashDetector({
    required this.onCrashDetected,
    this.gForceThreshold = 20.0, // 🔧 Customize based on test (approx >2g)
  });

  void startMonitoring() {
    _accelSubscription = accelerometerEvents.listen((event) {
      final gForce = _calculateGForce(event.x, event.y, event.z);
      if (gForce > gForceThreshold) {
        print('🚨 Potential crash detected! G-Force: $gForce');
        onCrashDetected();
      }
    });
  }

  void stopMonitoring() {
    _accelSubscription?.cancel();
  }

  double _calculateGForce(double x, double y, double z) {
    const gravity = 9.8;
    return (sqrt(x * x + y * y + z * z) - gravity).abs();
  }
}
