import 'package:flutter/material.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/network/api_client.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ServerConfigDialog(),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isTesting = false;
  bool? _testSuccess;
  String? _testMessage;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController(text: ApiClient.baseUrl);
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _setPreset(String url) {
    setState(() {
      _urlController.text = url;
      _testSuccess = null;
      _testMessage = null;
    });
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTesting = true;
      _testSuccess = null;
      _testMessage = null;
    });

    final targetUrl = _urlController.text.trim();
    final ok = await ApiClient.testConnection(targetUrl);

    if (mounted) {
      setState(() {
        _isTesting = false;
        _testSuccess = ok;
        _testMessage = ok
            ? "Successfully connected to RideTrack backend!"
            : "Connection failed. Check host IP, port 8000 & Wi-Fi.";
      });
    }
  }

  Future<void> _saveAndApply() async {
    final newUrl = _urlController.text.trim();
    if (newUrl.isNotEmpty) {
      await ApiClient.setBaseUrl(newUrl);
    }
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Server URL updated: ${ApiClient.baseUrl}"),
          backgroundColor: AppColors.successGreen,
        ),
      );
    }
  }

  Future<void> _resetDefault() async {
    await ApiClient.resetBaseUrl();
    setState(() {
      _urlController.text = ApiClient.baseUrl;
      _testSuccess = null;
      _testMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: 24 + bottomInset,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(
          top: BorderSide(color: AppColors.surfaceBorder, width: 1.5),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primaryCyan.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dns_rounded,
                        color: AppColors.primaryCyan,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Server Connection",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              "Configure API & WebSocket endpoint for local emulator, physical device on LAN, or remote production.",
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),

            // Quick Presets
            const Text(
              "QUICK PRESETS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildPresetChip("Android Emulator", ApiConstants.emulatorBaseUrl),
                _buildPresetChip("Localhost (PC/iOS)", ApiConstants.localhostBaseUrl),
                _buildPresetChip("Production Cloud", ApiConstants.productionBaseUrl),
              ],
            ),
            const SizedBox(height: 18),

            // Base URL Input Field
            const Text(
              "API BASE URL",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              keyboardType: TextInputType.url,
              style: const TextStyle(
                fontFamily: 'JetBrains Mono',
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: "http://192.168.1.50:8000/api/v1",
                prefixIcon: const Icon(Icons.link_rounded, color: AppColors.textSecondary, size: 20),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary, size: 18),
                  tooltip: "Reset to Platform Default",
                  onPressed: _resetDefault,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Connection Test Result Badge
            if (_testMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: (_testSuccess ?? false)
                      ? AppColors.successGreen.withOpacity(0.12)
                      : AppColors.alertRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (_testSuccess ?? false)
                        ? AppColors.successGreen.withOpacity(0.4)
                        : AppColors.alertRed.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (_testSuccess ?? false) ? Icons.check_circle_rounded : Icons.error_outline_rounded,
                      color: (_testSuccess ?? false) ? AppColors.successGreen : AppColors.alertRed,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: (_testSuccess ?? false) ? AppColors.successGreen : AppColors.alertRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: _isTesting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryCyan),
                          )
                        : const Icon(Icons.network_check_rounded, color: AppColors.primaryCyan, size: 18),
                    label: const Text(
                      "TEST PING",
                      style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _saveAndApply,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryCyan,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      "SAVE & APPLY",
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetChip(String label, String url) {
    final isSelected = _urlController.text.trim() == url;
    return ActionChip(
      label: Text(label),
      backgroundColor: isSelected ? AppColors.primaryCyan.withOpacity(0.2) : AppColors.surfaceElevated,
      side: BorderSide(
        color: isSelected ? AppColors.primaryCyan : AppColors.surfaceBorder,
      ),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? AppColors.primaryCyan : AppColors.textPrimary,
      ),
      onPressed: () => _setPreset(url),
    );
  }
}
