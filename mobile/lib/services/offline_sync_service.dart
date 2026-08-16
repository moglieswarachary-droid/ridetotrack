import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/tracking_point.dart';
import '../core/network/api_client.dart';

class OfflineSyncService {
  final List<TrackingPoint> _offlineQueue = [];
  bool isSyncing = false;

  void enqueuePoint(TrackingPoint point) {
    _offlineQueue.add(point);
  }

  int get queueCount => _offlineQueue.length;

  Future<void> flushQueueIfOnline(String sessionId) async {
    if (isSyncing || _offlineQueue.isEmpty) return;

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity == ConnectivityResult.none) return;

    isSyncing = true;
    try {
      final pointsToSend = List<TrackingPoint>.from(_offlineQueue);
      final payload = {
        "points": pointsToSend.map((p) => p.toJson()).toList(),
      };

      final response = await ApiClient.post(
        "/tracking/$sessionId/locations",
        body: payload,
      );

      if (response.statusCode == 200) {
        _offlineQueue.removeRange(0, pointsToSend.length);
      }
    } catch (_) {
      // Retain in queue for next flush attempt
    } finally {
      isSyncing = false;
    }
  }

  void clearQueue() {
    _offlineQueue.clear();
  }
}
