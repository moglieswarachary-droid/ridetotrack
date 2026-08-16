import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/tracking_point.dart';

enum TrackingQuality { batterySaver, balanced, highAccuracy }

class LocationTrackerService {
  StreamSubscription<Position>? _positionStreamSub;
  final Battery _battery = Battery();
  Function(TrackingPoint point)? onPointCaptured;
  bool isTracking = false;

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<void> startTracking({
    TrackingQuality quality = TrackingQuality.balanced,
    required Function(TrackingPoint) onPoint,
  }) async {
    onPointCaptured = onPoint;
    isTracking = true;

    LocationSettings locationSettings;
    switch (quality) {
      case TrackingQuality.batterySaver:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 15, // Update every 15m
        );
        break;
      case TrackingQuality.highAccuracy:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2, // Update every 2m
        );
        break;
      case TrackingQuality.balanced:
      default:
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5m
        );
        break;
    }

    _positionStreamSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position pos) async {
      if (!isTracking) return;

      int? batteryPct;
      try {
        batteryPct = await _battery.batteryLevel;
      } catch (_) {}

      final connectivity = await Connectivity().checkConnectivity();
      final isOnline = connectivity != ConnectivityResult.none;

      // Convert speed from m/s to km/h
      final speedKmh = pos.speed * 3.6;

      final point = TrackingPoint(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        speedKmh: speedKmh > 0 ? speedKmh : 0.0,
        heading: pos.heading >= 0 ? pos.heading : null,
        accuracyM: pos.accuracy,
        batteryPct: batteryPct,
        networkStatus: isOnline ? "online" : "offline_queued",
        timestamp: pos.timestamp,
      );

      onPointCaptured?.call(point);
    });
  }

  void stopTracking() {
    isTracking = false;
    _positionStreamSub?.cancel();
    _positionStreamSub = null;
  }
}
