import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class PendingVerificationScreen extends StatelessWidget {
  const PendingVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const LoginScreen();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Application Status"),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('providers').doc(uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final data = snapshot.data?.data() ?? {};
          final status = data['status'] ?? 'pending_verification';
          final name = data['name'] ?? 'Partner';
          final kyc = data['kyc'] as Map<String, dynamic>? ?? {};
          final bank = data['bankDetails'] as Map<String, dynamic>? ?? {};
          final skills = (data['skills'] as List<dynamic>?) ?? [];

          // Auto-redirect if Admin has activated the partner account!
          if (status == 'Active') {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const DashboardScreen()),
              );
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.large),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.amber, width: 2),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 64,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text("Verification Under Review", style: AppTextStyle.mainTitle.copyWith(fontSize: 22)),
                  const SizedBox(height: 8),
                  Text(
                    "Hello $name, your partner registration & KYC documents have been submitted and are under review by the BharathFix Admin team.",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subtitle.copyWith(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 32),

                  // KYC Summary Card
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Submitted Document Verification", style: AppTextStyle.cardTitle),
                        const Divider(height: 20),
                        _buildStatusRow("Aadhaar Verification", kyc['aadhaarNumber'] ?? "Submitted", true),
                        _buildStatusRow("PAN Card Verification", kyc['panNumber'] ?? "Submitted", true),
                        _buildStatusRow("Bank Payout Info", bank['bankName'] ?? "Submitted", true),
                        _buildStatusRow("Service Skills", skills.join(', '), true),
                        _buildStatusRow("Admin Activation", "Pending Approval", false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: AppColors.primary),
                  const SizedBox(height: 12),
                  Text(
                    "This screen will automatically update as soon as your account is approved.",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusRow(String title, String val, bool isVerified) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppTextStyle.subtitle),
          Row(
            children: [
              Icon(
                isVerified ? Icons.check_circle_rounded : Icons.pending_rounded,
                size: 16,
                color: isVerified ? AppColors.success : Colors.amber,
              ),
              const SizedBox(width: 4),
              Text(
                val,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isVerified ? AppColors.title : Colors.amber,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
