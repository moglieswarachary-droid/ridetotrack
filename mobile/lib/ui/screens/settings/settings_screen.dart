import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/storage/local_storage.dart';
import '../../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _trackingQuality = "balanced";
  double _overspeedThreshold = 120.0;
  bool _crashDetection = true;
  String _unitSystem = "metric";

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final quality = await LocalStorage.getTrackingQuality();
    setState(() {
      _trackingQuality = quality;
    });
  }

  void _updateQuality(String mode) async {
    await LocalStorage.setTrackingQuality(mode);
    setState(() => _trackingQuality = mode);
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Settings & Privacy", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          children: [
            // Rider Profile Header Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primaryCyan, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(auth.userName ?? "Rider", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                        Text(auth.userEmail ?? "", style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Tracking Quality Profile
            const Text("GPS TRACKING QUALITY PROFILE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            _buildQualityOption("balanced", "Balanced Mode (Recommended)", "3-second interval, 5m displacement filter. Street riding.", Icons.tune_rounded),
            const SizedBox(height: 8),
            _buildQualityOption("high_accuracy", "High Accuracy", "1-second interval, high precision GPS. Twisties & track.", Icons.gps_fixed_rounded),
            const SizedBox(height: 8),
            _buildQualityOption("battery_saver", "Battery Saver", "8-second interval, 15m filter. Extended highway touring.", Icons.battery_charging_full_rounded),

            const SizedBox(height: 24),

            // Safety Thresholds
            const Text("SAFETY & SENSORS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Overspeed Alert Threshold", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text("${_overspeedThreshold.toInt()} km/h", style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.warningAmber)),
                    ],
                  ),
                  Slider(
                    value: _overspeedThreshold,
                    min: 60,
                    max: 180,
                    divisions: 12,
                    activeColor: AppColors.warningAmber,
                    inactiveColor: Colors.white.withOpacity(0.1),
                    onChanged: (v) => setState(() => _overspeedThreshold = v),
                  ),
                  const Divider(color: AppColors.surfaceBorder, height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text("IMU Crash Detection", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: const Text("15s countdown before alerting emergency contacts", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    value: _crashDetection,
                    activeColor: AppColors.primaryCyan,
                    onChanged: (v) => setState(() => _crashDetection = v),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Unit System
            const Text("MEASUREMENT UNITS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 0.8)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Speed & Distance", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Row(
                    children: ["metric", "imperial"].map((u) {
                      final isSelected = _unitSystem == u;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        child: ChoiceChip(
                          label: Text(u == "metric" ? "KM / KM/H" : "MI / MPH"),
                          selected: isSelected,
                          selectedColor: AppColors.primaryCyan,
                          backgroundColor: AppColors.surfaceElevated,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.background : AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                          onSelected: (_) => setState(() => _unitSystem = u),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Logout & Account Actions
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
                  await auth.logout();
                  if (mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded),
                label: const Text("LOGOUT OF GARAGE", style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQualityOption(String mode, String title, String subtitle, IconData icon) {
    final isSelected = _trackingQuality == mode;
    return InkWell(
      onTap: () => _updateQuality(mode),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryCyan : AppColors.surfaceBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primaryCyan : AppColors.textSecondary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primaryCyan, size: 20),
          ],
        ),
      ),
    );
  }
}
