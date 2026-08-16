import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../widgets/metric_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Map<String, dynamic>? _summaryData;
  Map<String, dynamic>? _intelligenceData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAnalytics();
  }

  Future<void> _fetchAnalytics() async {
    setState(() => _isLoading = true);
    try {
      final summaryRes = await ApiClient.get(ApiConstants.analyticsSummary);
      final intelRes = await ApiClient.get(ApiConstants.analyticsIntelligence);

      if (summaryRes.statusCode == 200) {
        _summaryData = jsonDecode(summaryRes.body);
      }
      if (intelRes.statusCode == 200) {
        _intelligenceData = jsonDecode(intelRes.body);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final dist = (_summaryData?["total_distance_km"] as num?)?.toDouble() ?? 0.0;
    final hours = (_summaryData?["total_duration_hours"] as num?)?.toDouble() ?? 0.0;
    final ridesCount = _summaryData?["total_rides_count"] ?? 0;
    final avgSpeed = (_summaryData?["average_speed_kmh"] as num?)?.toDouble() ?? 0.0;
    final maxSpeed = (_summaryData?["max_speed_kmh"] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Ride Intelligence", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryCyan))
          : RefreshIndicator(
              color: AppColors.primaryCyan,
              backgroundColor: AppColors.surface,
              onRefresh: _fetchAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lifetime Totals Grid
                    const Text("LIFETIME METRICS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: "Total Distance",
                            value: dist.toStringAsFixed(1),
                            unit: "km",
                            icon: Icons.map_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: "Saddle Time",
                            value: hours.toStringAsFixed(1),
                            unit: "hrs",
                            icon: Icons.hourglass_top_rounded,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            label: "Completed Rides",
                            value: "$ridesCount",
                            icon: Icons.two_wheeler_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: MetricCard(
                            label: "Max Speed",
                            value: maxSpeed.toStringAsFixed(0),
                            unit: "km/h",
                            icon: Icons.flash_on_rounded,
                            iconColor: AppColors.warningAmber,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // Speed Distribution Breakdown
                    const Text("SPEED DISTRIBUTION BREAKDOWN", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          _buildSpeedBucketBar("0-30 km/h (City / Filtering)", 0.25, AppColors.speedSlow),
                          const SizedBox(height: 14),
                          _buildSpeedBucketBar("30-60 km/h (Urban Cruising)", 0.40, AppColors.speedModerate),
                          const SizedBox(height: 14),
                          _buildSpeedBucketBar("60-90 km/h (Twisties & Highways)", 0.25, AppColors.speedFast),
                          const SizedBox(height: 14),
                          _buildSpeedBucketBar("90+ km/h (Open Highway)", 0.10, AppColors.speedExtreme),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Riding Pattern Insights
                    const Text("RIDING HABITS & PATTERNS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0)),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Column(
                        children: [
                          _buildPatternRow(Icons.wb_sunny_outlined, "Peak Riding Time", "Morning (06:00 - 09:30 AM)"),
                          const Divider(color: AppColors.surfaceBorder, height: 24),
                          _buildPatternRow(Icons.calendar_today_rounded, "Top Riding Days", "Saturday & Sunday"),
                          const Divider(color: AppColors.surfaceBorder, height: 24),
                          _buildPatternRow(Icons.eco_outlined, "Smooth Riding Score", "88 / 100 (Efficient Throttle)"),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSpeedBucketBar(String label, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            Text("${(fraction * 100).toInt()}%", style: const TextStyle(fontFamily: 'JetBrains Mono', fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 6,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: fraction,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatternRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryCyan.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryCyan, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            ],
          ),
        ),
      ],
    );
  }
}
