import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class LiveShareModal extends StatefulWidget {
  final String sessionId;

  const LiveShareModal({super.key, required this.sessionId});

  @override
  State<LiveShareModal> createState() => _LiveShareModalState();
}

class _LiveShareModalState extends State<LiveShareModal> {
  int _selectedHours = 6;
  bool _isCreating = false;
  String? _generatedShareUrl;

  void _createShareLink() async {
    setState(() => _isCreating = true);
    try {
      final res = await ApiClient.post(
        ApiConstants.shares,
        body: {
          "session_id": widget.sessionId,
          "duration_hours": _selectedHours,
          "recipient_label": "Family Live Tracking",
        },
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        setState(() {
          _generatedShareUrl = data["share_url"];
        });
      }
    } catch (_) {}
    setState(() => _isCreating = false);
  }

  void _copyToClipboard() {
    if (_generatedShareUrl == null) return;
    Clipboard.setData(ClipboardData(text: _generatedShareUrl!));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Live tracking link copied to clipboard!"),
        backgroundColor: AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Share Live Ride",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Generate a secure, temporary web link for family or friends to watch your motorcycle telemetry in real time. Automatically expires.",
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),

          if (_generatedShareUrl == null) ...[
            const Text(
              "SHARING DURATION",
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8),
            ),
            const SizedBox(height: 10),
            Row(
              children: [2, 6, 12, 24].map((hours) {
                final isSelected = _selectedHours == hours;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: ChoiceChip(
                      label: Text("${hours}h"),
                      selected: isSelected,
                      selectedColor: AppColors.primaryCyan,
                      backgroundColor: AppColors.surface,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.background : AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                      onSelected: (_) => setState(() => _selectedHours = hours),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createShareLink,
                icon: const Icon(Icons.link_rounded),
                label: _isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                      )
                    : const Text("GENERATE SECURE LINK"),
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.primaryCyan, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _generatedShareUrl!,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'JetBrains Mono',
                        fontSize: 12,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryCyan),
                onPressed: _copyToClipboard,
                icon: const Icon(Icons.copy_rounded),
                label: const Text("COPY LIVE LINK"),
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
