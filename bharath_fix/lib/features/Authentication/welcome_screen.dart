import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ui/theme/app_colors.dart';

import '../../ui/theme/app_spacing.dart';
import '../../ui/widgets/common_button.dart';
import '../../utils/app_routes.dart';
import '../../services/database_service.dart';
import '../Authentication/login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
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
    _checkExistingSession();
  }

  Future<void> _checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await DatabaseService().fetchUserProfile();
      if (profile != null && profile.name.trim().isNotEmpty && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.dashboard,
            (route) => false,
          );
        });
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Premium Interior Visual Layer
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.unsplash.com/photo-1600585154340-be6161a56a0c?auto=format&fit=crop&q=80&w=1000',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Dark Elegant Gradient Overlay for Typography Contrast
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.1),
                  Colors.black.withOpacity(0.4),
                  Colors.black.withOpacity(0.85),
                ],
              ),
            ),
          ),
          // Content Layout
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'BharathFix',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 40,
                      color: Colors.white,
                      letterSpacing: -1.0,
                    ),
                  ),
                  SizedBox(height: AppSpacing.small),
                  Text(
                    'Home services,\ndone right.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.medium),
                  Text(
                    'Book trusted pros for cleaning, AC, plumbing, salon and more — starting ₹199.',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 15,
                      color: Colors.white70,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: AppSpacing.extraLarge),
                  CommonButton(
                    label: 'Get Started',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.large),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/register');
                      },
                      child: Text(
                        'New here? Create an account',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.small),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}