import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/bike_provider.dart';
import '../../../providers/tracking_provider.dart';
import '../../../providers/ride_history_provider.dart';
import '../tracking/live_ride_hud_screen.dart';
import '../history/ride_history_screen.dart';
import '../garage/my_bikes_screen.dart';
import '../parking/parking_guard_screen.dart';
import '../safety/safety_hub_screen.dart';
import '../analytics/analytics_screen.dart';
import '../settings/settings_screen.dart';
import '../../widgets/battery_gps_badge.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BikeProvider>(context, listen: false).fetchBikes();
      Provider.of<RideHistoryProvider>(context, listen: false).fetchRides();
    });
  }

  void _handleStartRide() async {
    final bikeProv = Provider.of<BikeProvider>(context, listen: false);
    final trackingProv = Provider.of<TrackingProvider>(context, listen: false);

    if (bikeProv.bikes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a motorcycle to your garage first.")),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBikesScreen()));
      return;
    }

    final bikeId = bikeProv.activeBike?.id ?? bikeProv.bikes.first.id;
    final success = await trackingProv.startRide(bikeId);

    if (success && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LiveRideHudScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      _buildDashboardHome(),
      const RideHistoryScreen(),
      const AnalyticsScreen(),
      const MyBikesScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.primaryCyan,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.speed_rounded),
              label: "Cockpit",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: "History",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: "Analytics",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.two_wheeler_rounded),
              label: "Garage",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              label: "Settings",
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome() {
    final auth = Provider.of<AuthProvider>(context);
    final bikeProv = Provider.of<BikeProvider>(context);
    final historyProv = Provider.of<RideHistoryProvider>(context);
    final trackingProv = Provider.of<TrackingProvider>(context);

    final activeBike = bikeProv.activeBike;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header: User Greeting & Battery/GPS Telemetry Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "HELLO, ${auth.userName?.toUpperCase() ?? 'RIDER'}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryCyan,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Ready for the Ride",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                BatteryGpsBadge(
                  batteryPct: trackingProv.batteryLevel ?? 90,
                  accuracyM: trackingProv.gpsAccuracyM ?? 4.2,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Active Motorcycle Hero Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF162032), Color(0xFF0F1522)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.3)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryCyan.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "ACTIVE BIKE",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryCyan,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBikesScreen())),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 30)),
                        child: const Text(
                          "Switch",
                          style: TextStyle(color: AppColors.primaryCyan, fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeBike != null && activeBike.name.isNotEmpty ? activeBike.name : "No Bike Selected",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    activeBike != null && activeBike.manufacturer.isNotEmpty
                        ? "${activeBike.manufacturer} ${activeBike.model} • ${activeBike.registrationNumber}"
                        : "Tap Switch to add your motorcycle",
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildBikeStat("ODOMETER", "${activeBike?.odometerKm.toStringAsFixed(0) ?? '0'} km"),
                      const SizedBox(width: 24),
                      _buildBikeStat("GPS MODE", activeBike?.preferredTrackingMode.toUpperCase() ?? "BALANCED"),
                      const SizedBox(width: 24),
                      _buildBikeStat("TOTAL RIDES", "${historyProv.rides.length}"),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // GIANT START RIDE ACTION BUTTON
            SizedBox(
              width: double.infinity,
              height: 64,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryCyan,
                  foregroundColor: AppColors.background,
                  elevation: 6,
                  shadowColor: AppColors.primaryCyanGlow,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                onPressed: _handleStartRide,
                icon: const Icon(Icons.play_arrow_rounded, size: 32),
                label: const Text(
                  "START RIDE",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.0),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // Quick Tools Navigation Grid
            const Text(
              "RIDER SAFETY & TOOLS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),

            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildQuickTile(
                  icon: Icons.local_parking_rounded,
                  title: "Parking Guard",
                  subtitle: "Saved spot & compass",
                  iconColor: AppColors.primaryCyan,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParkingGuardScreen())),
                ),
                _buildQuickTile(
                  icon: Icons.health_and_safety_rounded,
                  title: "Safety Hub",
                  subtitle: "Crash & SOS contacts",
                  iconColor: AppColors.alertRed,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyHubScreen())),
                ),
                _buildQuickTile(
                  icon: Icons.share_location_rounded,
                  title: "Live Share",
                  subtitle: "Ephemeral live link",
                  iconColor: AppColors.warningAmber,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Start a ride first to share live telemetry link.")),
                    );
                  },
                ),
                _buildQuickTile(
                  icon: Icons.two_wheeler_rounded,
                  title: "My Garage",
                  subtitle: "${bikeProv.bikes.length} bikes stored",
                  iconColor: AppColors.successGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyBikesScreen())),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Recent Rides Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "RECENT TRIPS",
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: const Text(
                    "View All",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryCyan,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (historyProv.rides.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: const Center(
                  child: Column(
                    children: [
                      Icon(Icons.route_outlined, size: 36, color: AppColors.textMuted),
                      SizedBox(height: 8),
                      Text("No recorded rides yet.", style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                      SizedBox(height: 2),
                      Text("Tap 'Start Ride' to track your first motorcycle trip.", style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...historyProv.rides.take(3).map((r) => _buildRecentTripTile(r)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBikeStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildQuickTile({required IconData icon, required String title, required String subtitle, required Color iconColor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: iconColor, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 1),
                Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTripTile(dynamic ride) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.two_wheeler_rounded, color: AppColors.primaryCyan, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${ride.totalDistanceKm.toStringAsFixed(1)} km Ride",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  ),
                  Text(
                    "Avg: ${ride.averageSpeedKmh.toStringAsFixed(0)} km/h • Max: ${ride.maxSpeedKmh.toStringAsFixed(0)} km/h",
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
