import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/tracking_point.dart';
import '../models/ride.dart';
import '../services/location_tracker_service.dart';
import '../services/motion_crash_detector_service.dart';
import '../services/offline_sync_service.dart';
import '../services/socket_service.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class TrackingProvider extends ChangeNotifier {
  final LocationTrackerService _locationService = LocationTrackerService();
  final MotionCrashDetectorService _crashService = MotionCrashDetectorService();
  final OfflineSyncService _syncService = OfflineSyncService();
  final SocketService _socketService = SocketService();

  bool isTracking = false;
  bool isPaused = false;
  String? currentSessionId;
  String? activeBikeId;

  // Real-time telemetry
  double currentSpeedKmh = 0.0;
  double maxSpeedKmh = 0.0;
  double totalDistanceKm = 0.0;
  int elapsedSeconds = 0;
  int? batteryLevel;
  double? gpsAccuracyM;
  double? currentHeading;
  double currentLat = 12.971598;
  double currentLng = 77.594562;
  List<TrackingPoint> routePoints = [];

  // Crash detection trigger
  bool isCrashModalActive = false;
  double crashImpactG = 0.0;

  Timer? _timer;
  final List<TrackingPoint> _batchBuffer = [];

  Future<bool> startRide(String bikeId, {TrackingQuality quality = TrackingQuality.balanced}) async {
    final hasPermission = await _locationService.checkAndRequestPermissions();
    if (!hasPermission) return false;

    try {
      final res = await ApiClient.post(
        ApiConstants.trackingStart,
        body: {
          "bike_id": bikeId,
          "tracking_mode": quality.name,
        },
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        currentSessionId = data["id"];
        activeBikeId = bikeId;
        isTracking = true;
        isPaused = false;
        totalDistanceKm = 0.0;
        maxSpeedKmh = 0.0;
        currentSpeedKmh = 0.0;
        elapsedSeconds = 0;
        routePoints.clear();
        _batchBuffer.clear();

        // Start timer
        _startTimer();

        // Start real GPS tracker
        await _locationService.startTracking(
          quality: quality,
          onPoint: _onNewLocationPoint,
        );

        // Start crash sensor monitor
        _crashService.startMonitoring(
          onCandidate: (gForce, speed) {
            crashImpactG = gForce;
            isCrashModalActive = true;
            notifyListeners();
          },
        );

        // Connect WebSocket
        if (currentSessionId != null) {
          _socketService.connect(currentSessionId!, onMessage: (msg) {});
        }

        notifyListeners();
        return true;
      }
    } catch (_) {}

    return false;
  }

  void _onNewLocationPoint(TrackingPoint point) {
    currentLat = point.latitude;
    currentLng = point.longitude;
    currentSpeedKmh = point.speedKmh;
    currentHeading = point.heading;
    gpsAccuracyM = point.accuracyM;
    batteryLevel = point.batteryPct;

    if (point.speedKmh > maxSpeedKmh) {
      maxSpeedKmh = point.speedKmh;
    }

    _crashService.updateCurrentSpeed(point.speedKmh);
    routePoints.add(point);
    _batchBuffer.add(point);

    // If buffer reaches 5 points, flush to backend
    if (_batchBuffer.length >= 5 && currentSessionId != null) {
      _flushBuffer();
    }

    notifyListeners();
  }

  Future<void> _flushBuffer() async {
    if (_batchBuffer.isEmpty || currentSessionId == null) return;
    final pointsToSend = List<TrackingPoint>.from(_batchBuffer);
    _batchBuffer.clear();

    try {
      final res = await ApiClient.post(
        "/tracking/$currentSessionId/locations",
        body: {
          "points": pointsToSend.map((p) => p.toJson()).toList(),
        },
      );

      if (res.statusCode != 200) {
        // Queue for offline sync
        for (var p in pointsToSend) {
          _syncService.enqueuePoint(p);
        }
      }
    } catch (_) {
      for (var p in pointsToSend) {
        _syncService.enqueuePoint(p);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!isPaused && isTracking) {
        elapsedSeconds++;
        // Rough live distance calculation if moving
        if (currentSpeedKmh > 3.0) {
          totalDistanceKm += (currentSpeedKmh / 3600.0);
        }
        notifyListeners();
      }
    });
  }

  Future<void> pauseRide() async {
    if (currentSessionId == null) return;
    isPaused = true;
    await ApiClient.post("/tracking/$currentSessionId/pause");
    notifyListeners();
  }

  Future<void> resumeRide() async {
    if (currentSessionId == null) return;
    isPaused = false;
    await ApiClient.post("/tracking/$currentSessionId/resume");
    notifyListeners();
  }

  Future<Ride?> stopRide() async {
    if (currentSessionId == null) return null;

    _locationService.stopTracking();
    _crashService.stopMonitoring();
    _socketService.disconnect();
    _timer?.cancel();
    _timer = null;

    // Flush any remaining buffered points
    await _flushBuffer();

    try {
      final res = await ApiClient.post("/tracking/$currentSessionId/stop");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final ride = Ride.fromJson(data);
        isTracking = false;
        currentSessionId = null;
        notifyListeners();
        return ride;
      }
    } catch (_) {}

    isTracking = false;
    currentSessionId = null;
    notifyListeners();
    return null;
  }

  void dismissCrashModal() {
    isCrashModalActive = false;
    notifyListeners();
  }

  Future<void> reportVerifiedCrash() async {
    if (activeBikeId == null) return;
    isCrashModalActive = false;
    notifyListeners();

    try {
      await ApiClient.post(
        ApiConstants.crashReport,
        body: {
          "bike_id": activeBikeId,
          "session_id": currentSessionId,
          "latitude": currentLat,
          "longitude": currentLng,
          "impact_g": crashImpactG,
          "speed_before_impact_kmh": currentSpeedKmh,
          "cancellation_timed_out": true,
        },
      );
    } catch (_) {}
  }
}
