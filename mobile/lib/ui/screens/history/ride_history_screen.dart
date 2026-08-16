import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/ride.dart';
import '../../../providers/ride_history_provider.dart';
import 'route_replay_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return "${h}h ${m}m";
    return "${m}m ${seconds % 60}s";
  }

  @override
  Widget build(BuildContext context) {
    final historyProv = Provider.of<RideHistoryProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Ride History",
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
      ),
      body: historyProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : historyProv.rides.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.route_outlined, size: 48, color: AppColors.textMuted),
                      SizedBox(height: 12),
                      Text("No recorded rides yet.", style: TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text("Completed rides will appear here with full stats.", style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppColors.primaryCyan,
                  backgroundColor: AppColors.surface,
                  onRefresh: () => historyProv.fetchRides(),
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: historyProv.rides.length,
                    itemBuilder: (ctx, idx) {
                      final ride = historyProv.rides[idx];
                      return _buildRideCard(context, ride, historyProv);
                    },
                  ),
                ),
    );
  }

  Widget _buildRideCard(BuildContext context, Ride ride, RideHistoryProvider prov) {
    final dateStr = DateFormat("EEEE, MMM d • h:mm a").format(ride.startedAt.toLocal());

    return Dismissible(
      key: Key(ride.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.alertRed.withOpacity(0.8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async {
        return await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.surfaceElevated,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: const Text("Delete Ride?", style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w700)),
            content: const Text("Are you sure you want to delete this ride and its GPS points?", style: TextStyle(color: AppColors.textSecondary)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel", style: TextStyle(color: AppColors.textSecondary))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.alertRed),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text("Delete"),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => prov.deleteRide(ride.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => RouteReplayScreen(rideId: ride.id, rideSummary: ride)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(dateStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryCyan.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${ride.totalDistanceKm.toStringAsFixed(1)} KM",
                          style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primaryCyan),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStat("DURATION", _formatDuration(ride.durationSeconds)),
                      _buildStat("AVG SPEED", "${ride.averageSpeedKmh.toStringAsFixed(0)} km/h"),
                      _buildStat("MAX SPEED", "${ride.maxSpeedKmh.toStringAsFixed(0)} km/h"),
                      _buildStat("ELEVATION", "+${ride.elevationGainM.toStringAsFixed(0)}m"),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
