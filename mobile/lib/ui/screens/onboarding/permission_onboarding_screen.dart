import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/location_tracker_service.dart';
import '../dashboard/dashboard_screen.dart';

class PermissionOnboardingScreen extends StatefulWidget {
  const PermissionOnboardingScreen({super.key});

  @override
  State<PermissionOnboardingScreen> createState() => _PermissionOnboardingScreenState();
}

class _PermissionOnboardingScreenState extends State<PermissionOnboardingScreen> {
  bool _isRequesting = false;

  void _requestPermissionsAndProceed() async {
    setState(() => _isRequesting = true);
    final locService = LocationTrackerService();
    await locService.checkAndRequestPermissions();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // Hero Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                ),
                child: const Text(
                  "SMARTPHONE-ONLY TRACKING",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryCyan,
                    letterSpacing: 0.8,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                "How RideTrack\nWorks",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                "RideTrack uses only your smartphone sensors. No OBD tracker or external hardware is required. To track accurately when screen is off, we need:",
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
              ),

              const SizedBox(height: 24),

              // Permissions List
              Expanded(
                child: ListView(
                  children: [
                    _buildPermissionTile(
                      icon: Icons.location_on_rounded,
                      title: "Location (Always Allow)",
                      desc: "Continuously records GPS coordinates, speed, and elevation deltas during active rides, even if phone is in your jacket or locked.",
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      icon: Icons.speed_rounded,
                      title: "Motion & Accelerometer",
                      desc: "Detects rapid deceleration events to power the 15-second Crash Detection countdown and overspeed alerts.",
                    ),
                    const SizedBox(height: 16),
                    _buildPermissionTile(
                      icon: Icons.notifications_active_rounded,
                      title: "Critical Notifications",
                      desc: "Displays persistent foreground ride tracking status and alerts if bike leaves a parking geofence.",
                    ),
                  ],
                ),
              ),

              // Disclaimer
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_outlined, color: AppColors.warningAmber, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tracking only works when your phone is with you. Never interact with your phone while operating a motorcycle.",
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Proceed Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _requestPermissionsAndProceed,
                  child: _isRequesting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : const Text("GRANT PERMISSIONS & CONTINUE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionTile({required IconData icon, required String title, required String desc}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primaryCyan.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primaryCyan, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
