import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class MotionCrashDetectorService {
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  Function(double impactG, double currentSpeed)? onCrashCandidateDetected;
  bool isMonitoring = false;
  double lastSpeedKmh = 0.0;

  // Thresholds to avoid false positives (potholes, bumps)
  static const double crashThresholdG = 3.8; // >3.8G acceleration spike

  void startMonitoring({
    required Function(double impactG, double currentSpeed) onCandidate,
  }) {
    onCrashCandidateDetected = onCandidate;
    isMonitoring = true;

    _accelSub = userAccelerometerEventStream().listen((UserAccelerometerEvent event) {
      if (!isMonitoring) return;

      // Calculate total G-force magnitude
      final totalAcc = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final gForce = totalAcc / 9.81;

      if (gForce >= crashThresholdG && lastSpeedKmh >= 15.0) {
        onCrashCandidateDetected?.call(gForce, lastSpeedKmh);
      }
    });
  }

  void updateCurrentSpeed(double speedKmh) {
    lastSpeedKmh = speedKmh;
  }

  void stopMonitoring() {
    isMonitoring = false;
    _accelSub?.cancel();
    _accelSub = null;
  }
}
