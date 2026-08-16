import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CrashCountdownModal extends StatefulWidget {
  final double impactG;
  final VoidCallback onCancel;
  final VoidCallback onTimeout;

  const CrashCountdownModal({
    super.key,
    required this.impactG,
    required this.onCancel,
    required this.onTimeout,
  });

  @override
  State<CrashCountdownModal> createState() => _CrashCountdownModalState();
}

class _CrashCountdownModalState extends State<CrashCountdownModal> {
  int _remainingSeconds = 15;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 1) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _countdownTimer?.cancel();
        widget.onTimeout();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: AppColors.alertRed, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Glowing Alert Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.alertRed.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.alertRed),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.alertRed,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "POSSIBLE CRASH DETECTED",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Severe impact (${widget.impactG.toStringAsFixed(1)}G) recorded. If you do not cancel, your emergency contacts will be notified automatically with your live location.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),

            // Giant Countdown Number
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.alertRed.withOpacity(0.5), width: 3),
              ),
              alignment: Alignment.center,
              child: Text(
                "$_remainingSeconds",
                style: const TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 44,
                  fontWeight: FontWeight.w900,
                  color: AppColors.alertRed,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Cancel Hero Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.successGreen,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  _countdownTimer?.cancel();
                  widget.onCancel();
                },
                child: const Text(
                  "I'M OKAY — CANCEL ALERT",
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
