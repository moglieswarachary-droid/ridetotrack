import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/bike.dart';
import '../../../providers/bike_provider.dart';
import 'add_edit_bike_screen.dart';

class MyBikesScreen extends StatelessWidget {
  const MyBikesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bikeProv = Provider.of<BikeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "My Garage",
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryCyan, size: 28),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddEditBikeScreen()),
              );
            },
          ),
        ],
      ),
      body: bikeProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : bikeProv.bikes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 54, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      const Text(
                        "Your Garage is Empty",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Add your motorcycle to start recording telemetry.",
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AddEditBikeScreen()),
                          );
                        },
                        icon: const Icon(Icons.add_rounded),
                        label: const Text("ADD MOTORCYCLE"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: bikeProv.bikes.length,
                  itemBuilder: (ctx, idx) {
                    final bike = bikeProv.bikes[idx];
                    return _buildBikeCard(context, bike, bikeProv);
                  },
                ),
    );
  }

  Widget _buildBikeCard(BuildContext context, Bike bike, BikeProvider prov) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: bike.isActive ? AppColors.primaryCyan : AppColors.surfaceBorder,
          width: bike.isActive ? 1.5 : 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: bike.isActive
                            ? AppColors.primaryCyan.withOpacity(0.15)
                            : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.two_wheeler_rounded,
                        color: bike.isActive ? AppColors.primaryCyan : AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bike.name,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                        Text(
                          "${bike.manufacturer} ${bike.model} (${bike.year})",
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
                if (bike.isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "ACTIVE",
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryCyan,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStat("REG NO", bike.registrationNumber),
                _buildStat("ODOMETER", "${bike.odometerKm.toStringAsFixed(0)} km"),
                _buildStat("TRACKING", bike.preferredTrackingMode.toUpperCase()),
              ],
            ),
            if (!bike.isActive) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 38,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primaryCyan,
                    side: const BorderSide(color: AppColors.primaryCyan),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => prov.setActiveBike(bike.id),
                  child: const Text("SET AS ACTIVE BIKE", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ],
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
        Text(value, style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ],
    );
  }
}
