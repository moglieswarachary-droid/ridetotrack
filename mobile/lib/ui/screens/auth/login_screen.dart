import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../providers/auth_provider.dart';
import 'register_screen.dart';
import '../onboarding/permission_onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in email and password.")),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final success = await auth.login(email, pass);
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Logo & App Name
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryCyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryCyan.withOpacity(0.4)),
                    ),
                    child: const Icon(
                      Icons.two_wheeler_rounded,
                      color: AppColors.primaryCyan,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "RideTrack",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              const Text(
                "Welcome back,\nRider.",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Turn your smartphone into a dedicated motorcycle tracking and safety hub.",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 36),

              // Email Input
              const Text("EMAIL ADDRESS", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  hintText: "rider@motorcycle.com",
                  prefixIcon: Icon(Icons.email_outlined, color: AppColors.textSecondary, size: 20),
                ),
              ),

              const SizedBox(height: 20),

              // Password Input
              const Text("PASSWORD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary, letterSpacing: 0.8)),
              const SizedBox(height: 8),
              TextField(
                controller: _passCtrl,
                obscureText: _obscurePassword,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: "••••••••",
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

              const SizedBox(height: 32),

              // Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: auth.isLoading ? null : _handleLogin,
                  child: auth.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.background),
                        )
                      : const Text("SIGN IN TO GARAGE"),
                ),
              ),

              const SizedBox(height: 24),

              // Register Switch
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                  },
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      children: [
                        TextSpan(
                          text: "Register Now",
                          style: TextStyle(color: AppColors.primaryCyan, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
