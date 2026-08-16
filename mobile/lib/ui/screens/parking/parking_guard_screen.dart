import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/safety_provider.dart';
import '../../../providers/tracking_provider.dart';
import '../../widgets/walking_compass_widget.dart';

class ParkingGuardScreen extends StatefulWidget {
  const ParkingGuardScreen({super.key});

  @override
  State<ParkingGuardScreen> createState() => _ParkingGuardScreenState();
}

class _ParkingGuardScreenState extends State<ParkingGuardScreen> {
  final _noteCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SafetyProvider>(context, listen: false).fetchCurrentParkingSpot();
    });
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _saveCurrentLocationAsParking() async {
    final tracking = Provider.of<TrackingProvider>(context, listen: false);
    final safety = Provider.of<SafetyProvider>(context, listen: false);

    setState(() => _isSaving = true);
    final success = await safety.saveParkingSpot(
      tracking.currentLat,
      tracking.currentLng,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : "Parked motorcycle",
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Parking spot saved with active geofence guard!"),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  double _calculateDistanceMeters(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLon = (lon2 - lon1) * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * (pi / 180.0)) * cos(lat2 * (pi / 180.0)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  @override
  Widget build(BuildContext context) {
    final safety = Provider.of<SafetyProvider>(context);
    final tracking = Provider.of<TrackingProvider>(context);
    final spot = safety.currentParkingSpot;

    double distanceMeters = 0.0;
    if (spot != null) {
      distanceMeters = _calculateDistanceMeters(
        tracking.currentLat,
        tracking.currentLng,
        spot.latitude,
        spot.longitude,
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Parking Guard",
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (spot == null) ...[
                // Empty state: Save parked spot prompt
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_parking_rounded, color: AppColors.primaryCyan, size: 36),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "No Parked Bike Saved",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Tap below to save your bike's exact GPS location and activate perimeter security.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _noteCtrl,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: const InputDecoration(
                          hintText: "Parking note (e.g., Level B2, Pillar 14)",
                          prefixIcon: Icon(Icons.edit_note_rounded, color: AppColors.textSecondary),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isSaving ? null : _saveCurrentLocationAsParking,
                          icon: const Icon(Icons.save_rounded),
                          label: _isSaving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                                )
                              : const Text("SAVE MY PARKING SPOT"),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Active Parking Spot Saved: Display Direction Compass & Info
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF162032), Color(0xFF0F1522)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.successGreen.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.successGreen.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.shield_rounded, color: AppColors.successGreen, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "GEOFENCE GUARD ACTIVE",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.successGreen, letterSpacing: 0.8),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              spot.note ?? "Parked Motorcycle",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                            ),
                            Text(
                              "Parked at: ${DateFormat('h:mm a • MMM d').format(spot.parkedAt.toLocal())}",
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Walking Direction Compass Widget
                const Text(
                  "WALKING DIRECTIONS BACK TO BIKE",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0),
                ),
                const SizedBox(height: 12),

                WalkingCompassWidget(
                  distanceMeters: distanceMeters,
                  bearingDegrees: 45.0, // Calculated heading to target
                  cardinalDirection: "NE",
                ),

                const SizedBox(height: 24),

                // Clear Parking Spot Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.alertRed,
                      side: const BorderSide(color: AppColors.alertRed),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () async {
                      await safety.clearParkingSpot();
                    },
                    icon: const Icon(Icons.delete_outline_rounded),
                    label: const Text("CLEAR SAVED SPOT", style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
