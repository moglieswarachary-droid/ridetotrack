import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/bike.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class BikeProvider extends ChangeNotifier {
  List<Bike> bikes = [];
  Bike? activeBike;
  bool isLoading = false;

  Future<void> fetchBikes() async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.get(ApiConstants.bikes);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        bikes = data.map((b) => Bike.fromJson(b)).toList();
        activeBike = bikes.firstWhere(
          (b) => b.isActive,
          orElse: () => bikes.isNotEmpty ? bikes.first : Bike(
            id: '',
            userId: '',
            name: 'No Bike Added',
            manufacturer: '',
            model: '',
            registrationNumber: '',
            year: 2024,
            odometerKm: 0,
            isActive: false,
            preferredTrackingMode: 'balanced',
          ),
        );
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addBike({
    required String name,
    required String manufacturer,
    required String model,
    String? variant,
    required String registrationNumber,
    required int year,
    double odometerKm = 0.0,
    bool isActive = true,
  }) async {
    isLoading = true;
    notifyListeners();

    try {
      final res = await ApiClient.post(
        ApiConstants.bikes,
        body: {
          "name": name,
          "manufacturer": manufacturer,
          "model": model,
          "variant": variant,
          "registration_number": registrationNumber,
          "year": year,
          "odometer_km": odometerKm,
          "is_active": isActive,
        },
      );

      if (res.statusCode == 201) {
        await fetchBikes();
        return true;
      }
    } catch (_) {}

    isLoading = false;
    notifyListeners();
    return false;
  }

  Future<bool> setActiveBike(String bikeId) async {
    try {
      final res = await ApiClient.put(
        "${ApiConstants.bikes}/$bikeId",
        body: {"is_active": true},
      );

      if (res.statusCode == 200) {
        await fetchBikes();
        return true;
      }
    } catch (_) {}
    return false;
  }
}
