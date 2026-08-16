import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/emergency_contact.dart';
import '../../../providers/safety_provider.dart';
import '../../../providers/tracking_provider.dart';

class SafetyHubScreen extends StatefulWidget {
  const SafetyHubScreen({super.key});

  @override
  State<SafetyHubScreen> createState() => _SafetyHubScreenState();
}

class _SafetyHubScreenState extends State<SafetyHubScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _relationship = "spouse";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SafetyProvider>(context, listen: false).fetchEmergencyContacts();
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showAddContactModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Emergency Contact", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: "Contact Name (e.g. Sarah Rossi)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: "+1 415 555 0199"),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _relationship,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(hintText: "Relationship"),
              items: const [
                DropdownMenuItem(value: "spouse", child: Text("Spouse / Partner")),
                DropdownMenuItem(value: "parent", child: Text("Parent")),
                DropdownMenuItem(value: "sibling", child: Text("Sibling")),
                DropdownMenuItem(value: "riding_buddy", child: Text("Riding Buddy")),
                DropdownMenuItem(value: "friend", child: Text("Friend")),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _relationship = val);
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_nameCtrl.text.isNotEmpty && _phoneCtrl.text.isNotEmpty) {
                    final safety = Provider.of<SafetyProvider>(context, listen: false);
                    await safety.addEmergencyContact(_nameCtrl.text.trim(), _phoneCtrl.text.trim(), _relationship);
                    _nameCtrl.clear();
                    _phoneCtrl.clear();
                    if (mounted) Navigator.pop(ctx);
                  }
                },
                child: const Text("SAVE CONTACT"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _triggerSos() async {
    final tracking = Provider.of<TrackingProvider>(context, listen: false);
    final safety = Provider.of<SafetyProvider>(context, listen: false);

    final success = await safety.triggerSOS(
      tracking.currentLat,
      tracking.currentLng,
      message: "Rider requested immediate assistance via RideTrack emergency SOS broadcast.",
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Emergency SOS dispatched to configured contacts!"),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final safety = Provider.of<SafetyProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Safety & Emergency Hub", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emergency SOS Broadcast Hero Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.alertRed.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.alertRed.withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.sos_rounded, color: AppColors.alertRed, size: 32),
                        SizedBox(width: 10),
                        Text(
                          "ONE-TAP SOS BROADCAST",
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.alertRed, letterSpacing: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "In an urgent breakdown, flat tire, or incident, tap below to broadcast your live GPS coordinates to all configured emergency contacts.",
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.35),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.alertRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _triggerSos,
                        icon: const Icon(Icons.send_rounded),
                        label: const Text("SEND EMERGENCY SOS", style: TextStyle(fontWeight: FontWeight.w900)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Emergency Contacts List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "EMERGENCY CONTACTS",
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textSecondary, letterSpacing: 1.0),
                  ),
                  TextButton.icon(
                    onPressed: _showAddContactModal,
                    icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primaryCyan),
                    label: const Text("Add", style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (safety.emergencyContacts.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: const Center(
                    child: Text(
                      "No emergency contacts added yet.\nAdd family members or riding buddies to receive crash alerts.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ),
                ),
              ] else ...[
                ...safety.emergencyContacts.map((c) => _buildContactTile(c)),
              ],

              const SizedBox(height: 28),

              // Crash Detection Architecture Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.sensors_rounded, color: AppColors.primaryCyan, size: 22),
                        SizedBox(width: 10),
                        Text(
                          "IMU Crash Detection Engine",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Uses phone accelerometer and gyroscope to detect peak G-force impact combined with rapid deceleration. If triggered, a 15-second audible cancellation countdown starts before contacting your emergency contacts.",
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile(EmergencyContactModel contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryCyan.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.primaryCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contact.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                  Text("${contact.phoneNumber} • ${contact.relationshipType}", style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ],
          ),
          const Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 18),
        ],
      ),
    );
  }
}
