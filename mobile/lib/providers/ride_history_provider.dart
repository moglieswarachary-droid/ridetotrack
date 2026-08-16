import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ride.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class RideHistoryProvider extends ChangeNotifier {
  List<Ride> rides = [];
  bool isLoading = false;

  Future<void> fetchRides() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.get(ApiConstants.rides);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        rides = data.map((r) => Ride.fromJson(r)).toList();
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<bool> deleteRide(String rideId) async {
    try {
      final res = await ApiClient.delete("${ApiConstants.rides}/$rideId");
      if (res.statusCode == 200) {
        rides.removeWhere((r) => r.id == rideId);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
