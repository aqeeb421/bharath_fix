import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../login_screen.dart';

class ProfileTab extends StatelessWidget {
  final String techName;
  final String techCategory;
  final bool isOnline;

  final _authService = AuthService();

  ProfileTab({
    super.key,
    required this.techName,
    required this.techCategory,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    final email = _authService.currentUser?.email ?? "partner@bharathfix.com";

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2),
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 56,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(techName, style: AppTextStyle.mainTitle),
              const SizedBox(height: 4),
              Text(techCategory, style: AppTextStyle.subtitle),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isOnline ? AppColors.success.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isOnline ? AppColors.success : Colors.grey),
                ),
                child: Text(
                  isOnline ? "Active & Accepting Jobs" : "Offline",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isOnline ? AppColors.success : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        Text("Account Details", style: AppTextStyle.sectionHeader),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                title: const Text("Email Address"),
                subtitle: Text(email),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.verified_user_outlined, color: AppColors.primary),
                title: const Text("Partner Status"),
                subtitle: const Text("Verified Master Technician"),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.home_repair_service_outlined, color: AppColors.primary),
                title: const Text("Service District"),
                subtitle: const Text("Hassan & Surrounding Taluks"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () async {
              await _authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            label: const Text("Sign Out Partner Account", style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.error, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
            ),
          ),
        ),
      ],
    );
  }
}
