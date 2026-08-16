import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class WalkingCompassWidget extends StatelessWidget {
  final double distanceMeters;
  final double bearingDegrees;
  final String cardinalDirection;

  const WalkingCompassWidget({
    super.key,
    required this.distanceMeters,
    required this.bearingDegrees,
    required this.cardinalDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          // Compass Rotating Dial
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surfaceBorder, width: 2),
                    color: AppColors.surfaceElevated,
                  ),
                ),

                // Rotating Arrow
                Transform.rotate(
                  angle: bearingDegrees * (pi / 180),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 16,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppColors.primaryCyan,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(8),
                            topRight: Radius.circular(8),
                          ),
                        ),
                      ),
                      Container(
                        width: 16,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.3),
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(8),
                            bottomRight: Radius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Center Pin
                Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Distance and Cardinal Direction Readout
          Text(
            distanceMeters >= 1000
                ? "${(distanceMeters / 1000).toStringAsFixed(2)} km"
                : "${distanceMeters.toStringAsFixed(0)} m",
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "Bearing: ${bearingDegrees.toStringAsFixed(0)}° ($cardinalDirection)",
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryCyan,
            ),
          ),
        ],
      ),
    );
  }
}
