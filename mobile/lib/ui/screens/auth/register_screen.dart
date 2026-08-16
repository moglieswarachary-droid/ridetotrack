import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import '../onboarding/permission_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _handleRegister() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final phone = _phoneCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (name.isEmpty || email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.register(
      email,
      pass,
      name,
      phone: phone.isNotEmpty ? phone : null,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const PermissionOnboardingScreen()),
      );
    } else if (mounted && auth.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.errorMessage!),
          backgroundColor: AppColors.alertRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Create Rider\nAccount",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Join RideTrack to start tracking rides, analyzing twisties, and protecting your motorcycle.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 28),

              // Full Name
              const Text("FULL NAME", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: "Valentino Rossi",
                  prefixIcon: Icon(Icons.person_outline_rounded, color: AppColors.textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // Email Address
              const Text("EMAIL ADDRESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: "rider@track.com",
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // Phone Number
              const Text("PHONE NUMBER (FOR SOS ALERTS)", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: "+1 415 555 2671",
                  prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 16),

              // Password
              const Text("PASSWORD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "Minimum 6 characters",
                  prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary, size: 20),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleRegister,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : const Text("CREATE ACCOUNT"),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
