import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/tracking_provider.dart';
import '../../../providers/bike_provider.dart';
import '../../widgets/speedometer_gauge.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/crash_countdown_modal.dart';
import '../../widgets/battery_gps_badge.dart';
import '../sharing/live_share_modal.dart';

class LiveRideHudScreen extends StatefulWidget {
  const LiveRideHudScreen({super.key});

  @override
  State<LiveRideHudScreen> createState() => _LiveRideHudScreenState();
}

class _LiveRideHudScreenState extends State<LiveRideHudScreen> {
  final MapController _mapController = MapController();
  bool _showMap = true;

  String _formatDuration(int totalSeconds) {
    final hours = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$hours:$minutes:$seconds";
  }

  void _confirmStopRide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Finish Ride?", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        content: const Text(
          "Are you sure you want to stop tracking? Your ride summary, statistics, and full route will be calculated and saved.",
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Keep Riding", style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.alertRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final trackingProv = Provider.of<TrackingProvider>(context, listen: false);
              final ride = await trackingProv.stopRide();
              if (mounted) {
                Navigator.pop(context); // Exit back to dashboard
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ride != null
                          ? "Ride saved! Distance: ${ride.totalDistanceKm.toStringAsFixed(1)} km"
                          : "Ride finished and saved to history.",
                    ),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              }
            },
            child: const Text("Finish & Save"),
          ),
        ],
      ),
    );
  }

  void _openLiveShareSheet() {
    final trackingProv = Provider.of<TrackingProvider>(context, listen: false);
    if (trackingProv.currentSessionId == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LiveShareModal(sessionId: trackingProv.currentSessionId!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tracking = Provider.of<TrackingProvider>(context);
    final bikeProv = Provider.of<BikeProvider>(context);
    final bikeName = bikeProv.activeBike?.name ?? "Motorcycle";

    final currentPosition = LatLng(tracking.currentLat, tracking.currentLng);
    final polylinePoints = tracking.routePoints.map((p) => LatLng(p.latitude, p.longitude)).toList();

    return Scaffold(
      body: Stack(
        children: [
          // Background: Fullscreen Interactive Map or Clean Dark HUD
          if (_showMap)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: currentPosition,
                initialZoom: 16.0,
                backgroundColor: AppColors.background,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/dark_all/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                ),
                if (polylinePoints.length > 1)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        strokeWidth: 5.0,
                        color: AppColors.primaryCyan,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: currentPosition,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryCyan,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryCyan.withOpacity(0.6),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(Icons.two_wheeler_rounded, color: AppColors.background, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Container(color: AppColors.background),

          // Top Header Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.surfaceBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: tracking.isPaused ? AppColors.warningAmber : AppColors.alertRed,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          tracking.isPaused ? "PAUSED" : "RECORDING",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: tracking.isPaused ? AppColors.warningAmber : AppColors.alertRed,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Battery and GPS accuracy
                  BatteryGpsBadge(
                    batteryPct: tracking.batteryLevel,
                    accuracyM: tracking.gpsAccuracyM,
                  ),

                  // Map Toggle Button
                  IconButton(
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.surface.withOpacity(0.9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                    ),
                    icon: Icon(_showMap ? Icons.dashboard_outlined : Icons.map_outlined, color: AppColors.primaryCyan),
                    onPressed: () => setState(() => _showMap = !_showMap),
                  ),
                ],
              ),
            ),
          ),

          // Central Speedometer & Live Gauges Overlay
          Positioned(
            left: 0,
            right: 0,
            top: MediaQuery.of(context).size.height * 0.12,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpeedometerGauge(currentSpeed: tracking.currentSpeedKmh),
                const SizedBox(height: 8),
                Text(
                  bikeName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Bottom HUD Telemetry Card & Ride Controls
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Metrics Grid
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.surfaceBorder),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 25,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              label: "Distance",
                              value: tracking.totalDistanceKm.toStringAsFixed(1),
                              unit: "km",
                              icon: Icons.straighten_rounded,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricCard(
                              label: "Duration",
                              value: _formatDuration(tracking.elapsedSeconds),
                              icon: Icons.timer_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: MetricCard(
                              label: "Top Speed",
                              value: tracking.maxSpeedKmh.toStringAsFixed(0),
                              unit: "km/h",
                              icon: Icons.flash_on_rounded,
                              iconColor: AppColors.warningAmber,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: MetricCard(
                              label: "Avg Speed",
                              value: tracking.elapsedSeconds > 0
                                  ? ((tracking.totalDistanceKm / (tracking.elapsedSeconds / 3600.0)).clamp(0, 200)).toStringAsFixed(0)
                                  : "0",
                              unit: "km/h",
                              icon: Icons.speed_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Controls Row (Live Share, Pause/Resume, Stop)
                Row(
                  children: [
                    // Live Share Button
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.share_location_rounded, color: AppColors.primaryCyan),
                        onPressed: _openLiveShareSheet,
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Pause / Resume Button
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: tracking.isPaused ? AppColors.successGreen : AppColors.surfaceElevated,
                            foregroundColor: tracking.isPaused ? AppColors.background : AppColors.textPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: tracking.isPaused ? Colors.transparent : AppColors.surfaceBorder,
                              ),
                            ),
                          ),
                          onPressed: () {
                            if (tracking.isPaused) {
                              tracking.resumeRide();
                            } else {
                              tracking.pauseRide();
                            }
                          },
                          icon: Icon(tracking.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                          label: Text(
                            tracking.isPaused ? "RESUME" : "PAUSE",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Finish / Stop Button
                    SizedBox(
                      height: 56,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertRed,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: _confirmStopRide,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text(
                          "FINISH",
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Crash Detection Overlay Modal
          if (tracking.isCrashModalActive)
            CrashCountdownModal(
              impactG: tracking.crashImpactG,
              onCancel: () => tracking.dismissCrashModal(),
              onTimeout: () => tracking.reportVerifiedCrash(),
            ),
        ],
      ),
    );
  }
}
