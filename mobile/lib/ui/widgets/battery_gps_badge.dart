import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class BatteryGpsBadge extends StatelessWidget {
  final int? batteryPct;
  final double? accuracyM;

  const BatteryGpsBadge({
    super.key,
    this.batteryPct,
    this.accuracyM,
  });

  String _getGpsStatus(double? acc) {
    if (acc == null) return "Searching...";
    if (acc <= 5.0) return "GPS: Excellent (±${acc.toStringAsFixed(0)}m)";
    if (acc <= 15.0) return "GPS: Good (±${acc.toStringAsFixed(0)}m)";
    if (acc <= 30.0) return "GPS: Weak (±${acc.toStringAsFixed(0)}m)";
    return "GPS: Poor (±${acc.toStringAsFixed(0)}m)";
  }

  Color _getGpsColor(double? acc) {
    if (acc == null) return AppColors.textMuted;
    if (acc <= 5.0) return AppColors.successGreen;
    if (acc <= 15.0) return AppColors.primaryCyan;
    if (acc <= 30.0) return AppColors.warningAmber;
    return AppColors.alertRed;
  }

  @override
  Widget build(BuildContext context) {
    final gpsColor = _getGpsColor(accuracyM);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // GPS Accuracy Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: gpsColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: gpsColor.withOpacity(0.5),
                      blurRadius: 6,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _getGpsStatus(accuracyM),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: gpsColor,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 8),

        // Phone Battery Badge
        if (batteryPct != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  batteryPct! <= 20 ? Icons.battery_alert_rounded : Icons.battery_full_rounded,
                  size: 14,
                  color: batteryPct! <= 20 ? AppColors.alertRed : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  "$batteryPct%",
                  style: const TextStyle(
                    fontFamily: 'JetBrains Mono',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
