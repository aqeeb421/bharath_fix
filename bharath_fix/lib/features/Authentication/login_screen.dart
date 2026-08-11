import 'package:bharath_fix/ui/theme/app_colors.dart';
import 'package:bharath_fix/ui/theme/app_spacing.dart';
import 'package:bharath_fix/ui/widgets/common_button.dart';
import 'package:bharath_fix/ui/widgets/common_textfield.dart';
import 'package:bharath_fix/ui/widgets/page_padding.dart';
import 'package:bharath_fix/ui/widgets/title_section.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:bharath_fix/utils/app_strings.dart';
import 'package:flutter/material.dart';

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
            arguments: {'phone': phone, 'verificationId': verificationId},
          );
        },
        onError: (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          final msg = e.message ?? 'Phone verification failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                msg.contains('BILLING_NOT_ENABLED') || e.code == '17499'
                    ? 'Firebase Phone SMS requires Blaze Plan or adding +91$phone as a test number in Firebase Console.'
                    : msg,
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 4),
            ),
          );
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Phone Verification Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
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
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
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
