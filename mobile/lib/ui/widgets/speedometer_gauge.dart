import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SpeedometerGauge extends StatelessWidget {
  final double currentSpeed;
  final double maxSpeedDisplay;

  const SpeedometerGauge({
    super.key,
    required this.currentSpeed,
    this.maxSpeedDisplay = 160.0,
  });

  Color _getSpeedColor(double speed) {
    if (speed < 40) return AppColors.speedSlow;
    if (speed < 80) return AppColors.speedModerate;
    if (speed < 120) return AppColors.speedFast;
    return AppColors.speedExtreme;
  }

  @override
  Widget build(BuildContext context) {
    final speedColor = _getSpeedColor(currentSpeed);

    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Arc painter
          CustomPaint(
            size: const Size(240, 240),
            painter: _SpeedometerPainter(
              currentSpeed: currentSpeed,
              maxSpeed: maxSpeedDisplay,
              activeColor: speedColor,
            ),
          ),

          // Central Speed Digital Reading
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentSpeed.toStringAsFixed(0),
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.0,
                  shadows: [
                    Shadow(
                      color: speedColor.withOpacity(0.5),
                      blurRadius: 20,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "KM/H",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SpeedometerPainter extends CustomPainter {
  final double currentSpeed;
  final double maxSpeed;
  final Color activeColor;

  _SpeedometerPainter({
    required this.currentSpeed,
    required this.maxSpeed,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 16;

    // Track arc (240 degrees sweep from 150 deg to 390 deg)
    const startAngle = 135 * (pi / 180);
    const sweepAngle = 270 * (pi / 180);

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Active speed arc
    final progress = (currentSpeed / maxSpeed).clamp(0.0, 1.0);
    final activeSweep = sweepAngle * progress;

    if (activeSweep > 0) {
      final activePaint = Paint()
        ..color = activeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        activeSweep,
        false,
        activePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SpeedometerPainter oldDelegate) {
    return oldDelegate.currentSpeed != currentSpeed || oldDelegate.activeColor != activeColor;
  }
}
