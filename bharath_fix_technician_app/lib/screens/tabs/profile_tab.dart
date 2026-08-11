import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../login_screen.dart';
import '../edit_technician_profile_screen.dart';
import '../../services/job_matching_service.dart';

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

  String _maskAccountNumber(String rawAcc) {
    final clean = rawAcc.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.length <= 4) return clean.isEmpty ? 'Not Provided' : clean;
    final last4 = clean.substring(clean.length - 4);
    return '•••• •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final uid = user?.uid ?? '';
    final defaultEmail = user?.email ?? 'partner@bharathfix.com';
    final defaultPhone = user?.phoneNumber ?? '+91 9876543210';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('providers')
          .doc(uid)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? {};

        final name =
            (data['name'] as String?) ??
            (techName.isNotEmpty ? techName : 'Master Technician');
        final email = (data['email'] as String?) ?? defaultEmail;
        final phone = (data['phone'] as String?) ?? defaultPhone;
        final experience = (data['experience'] ?? data['experienceYears'])?.toString() ?? '3';
        final address = (data['address'] ?? data['city'])?.toString() ?? 'Hassan, Karnataka';
        final radiusKm = (data['operatingRadiusKm'] as num?)?.toInt() ?? 15;
        final rating = (data['rating'] as num?)?.toDouble() ?? 5.0;
        final completedJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;

        // Bank details
        final bankData = data['bankDetails'] as Map<String, dynamic>?;
        final bankName =
            bankData?['bankName'] as String? ?? 'State Bank of India';
        final accountNo = (bankData?['accountNo'] ?? bankData?['accountNumber'])?.toString() ?? '';
        final ifsc = (bankData?['ifsc'] ?? bankData?['ifscCode'])?.toString() ?? '';

        // Skills
        final List<dynamic> skillsRaw = data['skills'] as List<dynamic>? ?? [];
        List<String> skills = skillsRaw.map((e) => e.toString()).toList();
        final String category = (data['category'] as String?) ?? techCategory;

        if (skills.isEmpty) {
          if (category.isNotEmpty) {
            skills = [category];
          } else {
            skills = ['Appliance Specialist'];
          }
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: [
            // Header Profile Banner Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0A000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      size: 52,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: AppTextStyle.mainTitle.copyWith(fontSize: 20),
                  ),
                  // const SizedBox(height: 4),
                  // Container(
                  //   padding: const EdgeInsets.symmetric(
                  //     horizontal: 10,
                  //     vertical: 3,
                  //   ),
                  //   decoration: BoxDecoration(
                  //     color: AppColors.primary.withValues(alpha: 0.1),
                  //     borderRadius: BorderRadius.circular(6),
                  //   ),
                  //   child: Text(
                  //     category,
                  //     style: const TextStyle(
                  //       fontFamily: 'Plus Jakarta Sans',
                  //       color: AppColors.primary,
                  //       fontWeight: FontWeight.bold,
                  //       fontSize: 12,
                  //     ),
                  //   ),
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    "⚡ $experience Years Experience  •  📍 $radiusKm km Radius",
                    style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.success.withValues(alpha: 0.1)
                          : Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isOnline ? AppColors.success : Colors.grey,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleAvatar(
                          radius: 4,
                          backgroundColor: isOnline
                              ? AppColors.success
                              : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? "ONLINE & ACCEPTING JOBS" : "OFFLINE",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isOnline ? AppColors.success : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditTechnicianProfileScreen(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.edit_note_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      label: const Text(
                        "Edit Profile & Manage Skills",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 1: Verified Appliance Skills & Expertise
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Verified Appliance Skills",
                  style: AppTextStyle.sectionHeader,
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditTechnicianProfileScreen(),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    size: 16,
                    color: AppColors.primary,
                  ),
                  label: const Text(
                    "Add Skills",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
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
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: skills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 14,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              skill,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "You will automatically receive job alerts matching these ${skills.length} categories.",
                    style: AppTextStyle.subtitle.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 2: Contact & Location Information
            Text(
              "Contact & Service Station",
              style: AppTextStyle.sectionHeader,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Phone Number",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(phone),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Email Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Station Address",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(address),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.radar_rounded,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Operating Service Radius",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text("$radiusKm km around base location"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 3: Bank Account & Payout Details
            Text(
              "Bank & Settlement Payout Account",
              style: AppTextStyle.sectionHeader,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.account_balance_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Bank Name",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      bankName.isNotEmpty ? bankName : "Not Configured",
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.credit_card_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "Account Number",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(
                      accountNo.isNotEmpty
                          ? _maskAccountNumber(accountNo)
                          : "Not Configured",
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(
                      Icons.qr_code_outlined,
                      color: AppColors.primary,
                    ),
                    title: const Text(
                      "IFSC Code",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text(ifsc.isNotEmpty ? ifsc : "Not Configured"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section 4: Partner Status & Compliance
            Text(
              "Partner Status & Verification",
              style: AppTextStyle.sectionHeader,
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: const [
                  ListTile(
                    leading: Icon(
                      Icons.verified_user_rounded,
                      color: AppColors.success,
                    ),
                    title: Text(
                      "Background & ID Verification",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text("Verified & Approved Partner 🏅"),
                  ),
                  Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.shield_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      "Service Coverage Zone",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    subtitle: Text("Hassan District & Surrounding Taluks"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Sign Out Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await _authService.signOut();
                  if (context.mounted) {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                label: const Text(
                  "Sign Out Partner Account",
                  style: TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }
}
