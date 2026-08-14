import '../../services/theme_service.dart';
import 'dart:async';

import 'package:bharath_fix/ui/theme/app_colors.dart';
import 'package:bharath_fix/ui/theme/app_text_style.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:flutter/material.dart';

import '../../utils/LocalStorage.dart';
import '../../services/database_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    super.initState();
    appStartFlow();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 110,
              width: 110,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: AppColors.primary, width: 2),
                boxShadow: [BoxShadow(
                    color: Color(0x1F000062),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Icon(
                  Icons.handyman_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),

            SizedBox(height: 30),

            Text(
              "BharathFix",
              style: AppTextStyle.heading,
            ),

            SizedBox(height: 8),

            Text(
              "Trusted Home Services",
              style: AppTextStyle.subtitle,
            )
          ],
        ),
      ),
    );
  }

  Future<void> appStartFlow() async {
    LocalStorage local = await LocalStorage.getInstance();
    final firstUse = await local.getString(LocalStorage.firstUse) ?? "true";
    final currentUser = FirebaseAuth.instance.currentUser;
    final isFirebaseUserLoggedIn = currentUser != null;

    if (!isFirebaseUserLoggedIn && firstUse == "true") {
      Timer(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.welcome,
            );
          }
        },
      );
      return;
    }

    if (!isFirebaseUserLoggedIn) {
      Timer(
        const Duration(seconds: 2),
        () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context,
              AppRoutes.login,
            );
          }
        },
      );
      return;
    }

    // User is logged in: load existing profile from Firestore/SQLite
    final profile = await DatabaseService().fetchUserProfile();
    Timer(
      const Duration(seconds: 2),
      () {
        if (!mounted) return;
        if (profile != null && profile.name.trim().isNotEmpty) {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
          );
        } else if (firstUse == "true") {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.register,
            arguments: {
              'phone': currentUser.phoneNumber ?? '',
            },
          );
        } else {
          Navigator.pushReplacementNamed(
            context,
            AppRoutes.dashboard,
          );
        }
      },
    );
  }
}