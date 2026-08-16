import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/bike_provider.dart';

class AddEditBikeScreen extends StatefulWidget {
  const AddEditBikeScreen({super.key});

  @override
  State<AddEditBikeScreen> createState() => _AddEditBikeScreenState();
}

class _AddEditBikeScreenState extends State<AddEditBikeScreen> {
  final _nameCtrl = TextEditingController();
  final _makeCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();
  final _regCtrl = TextEditingController();
  final _yearCtrl = TextEditingController(text: "2024");
  final _odoCtrl = TextEditingController(text: "0");
  String _trackingMode = "balanced";
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _makeCtrl.dispose();
    _modelCtrl.dispose();
    _regCtrl.dispose();
    _yearCtrl.dispose();
    _odoCtrl.dispose();
    super.dispose();
  }

  void _saveBike() async {
    final name = _nameCtrl.text.trim();
    final make = _makeCtrl.text.trim();
    final model = _modelCtrl.text.trim();
    final reg = _regCtrl.text.trim();
    final year = int.tryParse(_yearCtrl.text.trim()) ?? 2024;
    final odo = double.tryParse(_odoCtrl.text.trim()) ?? 0.0;

    if (name.isEmpty || make.isEmpty || model.isEmpty || reg.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in motorcycle name, make, model and registration.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    final prov = Provider.of<BikeProvider>(context, listen: false);
    final success = await prov.addBike(
      name: name,
      manufacturer: make,
      model: model,
      registrationNumber: reg,
      year: year,
      odometerKm: odo,
      isActive: true,
    );

    setState(() => _isSaving = false);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Add Motorcycle", style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("CUSTOM NICKNAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: "e.g., Street Triple RS or Track Duke"),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MANUFACTURER", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _makeCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: "Triumph, Ducati..."),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("MODEL", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _modelCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: "Street Triple 765"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("REGISTRATION PLATE", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _regCtrl,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: "KA-01-AB-1234"),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("YEAR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _yearCtrl,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: const InputDecoration(hintText: "2024"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              const Text("ODOMETER READING (KM)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _odoCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: "0"),
              ),
              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveBike,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : const Text("SAVE TO GARAGE"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
