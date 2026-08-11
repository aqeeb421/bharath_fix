import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';
import 'dashboard_screen.dart';
import 'pending_verification_screen.dart';
import 'register_partner_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  void _checkExistingSession() async {
    final user = _authService.currentUser;
    if (user != null && mounted) {
      final doc = await FirebaseFirestore.instance.collection('providers').doc(user.uid).get();
      if (!mounted) return;
      final statusRaw = (doc.data()?['status'] ?? 'pending_verification').toString().trim().toLowerCase();
      final bool isApproved = statusRaw == 'active' || statusRaw == 'approved' || statusRaw == 'verified';

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => isApproved ? const DashboardScreen() : const PendingVerificationScreen(),
        ),
      );
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final credential = await _authService.signInWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );

      final loggedInUser = credential?.user;

      if (loggedInUser != null && mounted) {
        final doc = await FirebaseFirestore.instance.collection('providers').doc(loggedInUser.uid).get();
        if (!mounted) return;
        final statusRaw = (doc.data()?['status'] ?? 'pending_verification').toString().trim().toLowerCase();
        final bool isApproved = statusRaw == 'active' || statusRaw == 'approved' || statusRaw == 'verified';

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => isApproved ? const DashboardScreen() : const PendingVerificationScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Authentication Failed: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      size: 64,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    "BharathFix Partner",
                    style: AppTextStyle.mainTitle.copyWith(fontSize: 26),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    "Technician Service Portal",
                    style: AppTextStyle.subtitle.copyWith(fontSize: 14),
                  ),
                ),
                const SizedBox(height: 40),

                Text("Email Address", style: AppTextStyle.cardTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: AppColors.title),
                  decoration: InputDecoration(
                    hintText: "Enter your assigned partner email",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.email_outlined, color: AppColors.primary),
                    fillColor: AppColors.card,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty || !val.contains('@')) {
                      return "Please enter a valid email address";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                Text("Password", style: AppTextStyle.cardTitle),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.title),
                  decoration: InputDecoration(
                    hintText: "Enter your password",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    fillColor: AppColors.card,
                    filled: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: const BorderSide(color: AppColors.primary),
                    ),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty || val.length < 5) {
                      return "Password must be at least 5 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Log In as Partner", style: AppTextStyle.buttonText),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPartnerScreen()),
                      );
                    },
                    icon: const Icon(Icons.assignment_ind_outlined, color: AppColors.primary),
                    label: const Text(
                      "Apply as New Service Partner",
                      style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
