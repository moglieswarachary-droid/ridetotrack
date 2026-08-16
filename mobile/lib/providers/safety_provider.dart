import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/emergency_contact.dart';
import '../models/parking_spot.dart';
import '../models/geofence.dart';
import '../models/alert_model.dart';
import '../core/constants/api_constants.dart';
import '../core/network/api_client.dart';

class SafetyProvider extends ChangeNotifier {
  List<EmergencyContactModel> emergencyContacts = [];
  List<GeofenceModel> geofences = [];
  List<AlertModel> alerts = [];
  ParkingSpot? currentParkingSpot;
  bool isLoading = false;

  Future<void> fetchEmergencyContacts() async {
    try {
      final res = await ApiClient.get(ApiConstants.emergencyContacts);
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        emergencyContacts = data.map((c) => EmergencyContactModel.fromJson(c)).toList();
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> addEmergencyContact(String name, String phone, String relationship) async {
    try {
      final res = await ApiClient.post(
        ApiConstants.emergencyContacts,
        body: {
          "name": name,
          "phone_number": phone,
          "relationship_type": relationship,
        },
      );
      if (res.statusCode == 201) {
        await fetchEmergencyContacts();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> fetchCurrentParkingSpot() async {
    try {
      final res = await ApiClient.get(ApiConstants.parkingCurrent);
      if (res.statusCode == 200 && res.body.isNotEmpty && res.body != "null") {
        currentParkingSpot = ParkingSpot.fromJson(jsonDecode(res.body));
        notifyListeners();
      }
    } catch (_) {}
  }

  Future<bool> saveParkingSpot(double lat, double lng, {String? note, String? address}) async {
    try {
      final res = await ApiClient.post(
        ApiConstants.parking,
        body: {
          "latitude": lat,
          "longitude": lng,
          "note": note,
          "address": address,
        },
      );
      if (res.statusCode == 201) {
        currentParkingSpot = ParkingSpot.fromJson(jsonDecode(res.body));
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> clearParkingSpot() async {
    if (currentParkingSpot == null) return false;
    try {
      final res = await ApiClient.delete("${ApiConstants.parking}/${currentParkingSpot!.id}");
      if (res.statusCode == 200) {
        currentParkingSpot = null;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> triggerSOS(double lat, double lng, {String? message}) async {
    try {
      final res = await ApiClient.post(
        ApiConstants.sosBroadcast,
        body: {
          "latitude": lat,
          "longitude": lng,
          "message": message ?? "Emergency SOS Alert triggered by rider on RideTrack",
        },
      );
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
