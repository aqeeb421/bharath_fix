import 'package:bharath_fix/ui/theme/app_colors.dart';
import 'package:bharath_fix/ui/theme/app_spacing.dart';
import 'package:bharath_fix/ui/widgets/common_button.dart';
import 'package:bharath_fix/ui/widgets/common_textfield.dart';
import 'package:bharath_fix/ui/widgets/page_padding.dart';
import 'package:bharath_fix/ui/widgets/title_section.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:bharath_fix/utils/app_strings.dart';
import 'package:flutter/material.dart';

import '../../utils/LocalStorage.dart';
import '../../services/database_service.dart';
import 'auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isValid = false;
  bool _isLoading = false;

  void validatePhone(String value) {
    setState(() {
      isValid = value.trim().length == 10;
    });
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _handlePhoneContinue() async {
    final phone = phoneController.text.trim();
    setState(() => _isLoading = true);

    try {
      await AuthService().verifyPhoneNumber(
        phoneNumber: phone,
        onCodeSent: (String verificationId, int? resendToken) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          Navigator.pushNamed(
            context,
            AppRoutes.otp,
            arguments: {
              'phone': phone,
              'verificationId': verificationId,
            },
          );
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          final msg = (e.message ?? '').toUpperCase();
          if (msg.contains('BILLING_NOT_ENABLED') || e.code == '17499') {
            _showBillingNotEnabledDialog(phone);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.message ?? 'Phone verification failed'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        final errStr = e.toString().toUpperCase();
        if (errStr.contains('BILLING_NOT_ENABLED') || errStr.contains('17499')) {
          _showBillingNotEnabledDialog(phone);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showBillingNotEnabledDialog(String phone) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Firebase Billing Required',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Firebase Phone SMS requires upgrading to the Blaze Plan in Firebase Console, OR adding +91$phone as a test number in Firebase Console.',
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                '• Free Test Mode: Firebase Console > Auth > Phone numbers for testing.\n• Real SMS: Firebase Console > Upgrade to Blaze Plan.',
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Colors.grey, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.otp,
                arguments: {
                  'phone': phone,
                  'verificationId': 'test_id_billing_bypass',
                },
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Proceed (Test Mode)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: PagePadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const TitleSection(
                  icon: Icons.handyman_rounded,
                  title: AppStrings.loginTitle,
                  subtitle: AppStrings.loginSubtitle,
                ),
                const SizedBox(height: AppSpacing.xl),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 17,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        border: Border.all(color: const Color(0xFFEAEAEA)),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Text(
                        "+91",
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF111111),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonTextField(
                        controller: phoneController,
                        hintText: "Mobile Number",
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        onChanged: validatePhone,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                const Text(
                  "By continuing you agree to our Terms & Privacy Policy.",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : CommonButton(
                        label: AppStrings.continueText,
                        onPressed: isValid ? _handlePhoneContinue : () {},
                      ),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}