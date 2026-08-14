import '../../services/theme_service.dart';
import 'dart:async';
import 'package:bharath_fix/ui/theme/app_colors.dart';
import 'package:bharath_fix/ui/theme/app_spacing.dart';
import 'package:bharath_fix/ui/theme/app_text_style.dart';
import 'package:bharath_fix/ui/widgets/common_appbar.dart';
import 'package:bharath_fix/ui/widgets/page_padding.dart';
import 'package:bharath_fix/utils/app_strings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import '../../utils/app_routes.dart';
import 'auth_service.dart';
import '../../services/database_service.dart';
import '../../utils/LocalStorage.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({super.key});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  final TextEditingController otpController = TextEditingController();
  int seconds = 30;
  Timer? timer;
  String _phone = "";
  String _verificationId = "";
  bool _initialized = false;
  bool _isVerifying = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      _phone = args?['phone'] ?? "";
      _verificationId = args?['verificationId'] ?? "";
      _initialized = true;
    }
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    super.initState();
    startTimer();
  }

  void startTimer() {
    timer?.cancel();
    seconds = 30;
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  void verifyOtp() async {
    final smsCode = otpController.text.trim();
    if (smsCode.length != 6) return;

    setState(() => _isVerifying = true);

    try {
      UserCredential? userCred;

      if (_verificationId == 'test_id_billing_bypass' ||
          _verificationId.startsWith('test_')) {
        if (smsCode != '000000') {
          setState(() => _isVerifying = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Invalid Test OTP. Please enter '000000'."),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
        userCred = await AuthService().signInAsTestUser(_phone);
      } else {
        userCred = await AuthService().signInWithPhoneCredential(
          verificationId: _verificationId,
          smsCode: smsCode,
        );
      }

      final userModel = await DatabaseService().fetchUserProfile(_phone);
      LocalStorage local = await LocalStorage.getInstance();
      await local.setString(LocalStorage.firstUse, "false");

      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone Authentication Successful! 🎉")),
        );

        if (userModel == null || userModel.name.trim().isEmpty) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.register,
            arguments: {'phone': _phone.isNotEmpty ? _phone : ''},
          );
        } else {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isVerifying = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Authentication Failed: ${e.toString()}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    timer?.cancel();
    //otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cleanPhone = _phone.replaceAll('+91', '').trim();
    final displayPhone = cleanPhone.isNotEmpty ? '+91 $cleanPhone' : _phone;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonAppBar(),
      body: SafeArea(
        child: PagePadding(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: AppSpacing.lg),
              Text(AppStrings.otpTitle, style: AppTextStyle.heading),
              SizedBox(height: AppSpacing.sm),
              Text("Code sent to $displayPhone", style: AppTextStyle.subtitle),
              SizedBox(height: AppSpacing.xl),
              PinCodeTextField(
                appContext: context,
                controller: otpController,
                length: 6,
                keyboardType: TextInputType.number,
                animationType: AnimationType.fade,
                autoFocus: true,
                onCompleted: (value) {
                  verifyOtp();
                },
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 46,
                  activeFillColor: Colors.white,
                  selectedFillColor: Colors.white,
                  inactiveFillColor: Colors.white,
                  activeColor: AppColors.primary,
                  selectedColor: AppColors.primary,
                  inactiveColor: const Color(0xFFEAEAEA),
                ),
              ),
              SizedBox(height: AppSpacing.md),
              _isVerifying
                  ? Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  : Center(
                      child: seconds == 0
                          ? TextButton(
                              onPressed: () {
                                otpController.clear();
                                startTimer();
                              },
                              child: Text(
                                "Resend OTP",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : Text(
                              "Resend OTP in 00:${seconds.toString().padLeft(2, '0')}",
                              style: AppTextStyle.subtitle,
                            ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
