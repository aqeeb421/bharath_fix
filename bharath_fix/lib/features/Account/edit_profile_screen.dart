import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/UserModel.dart';
import '../../services/database_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_appbar.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel? initialProfile;

  const EditProfileScreen({super.key, this.initialProfile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    final currentUser = FirebaseAuth.instance.currentUser;

    final name = profile?.name ?? '';
    final email = profile?.email ?? currentUser?.email ?? '';
    final phone = profile?.phone.isNotEmpty == true
        ? profile!.phone
        : (currentUser?.phoneNumber ?? '');

    _nameController = TextEditingController(text: name);
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final currentUser = FirebaseAuth.instance.currentUser;
    final uid = widget.initialProfile?.uid ?? currentUser?.uid ?? 'user_123';
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    final updatedModel = UserModel(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      photoUrl: widget.initialProfile?.photoUrl,
    );

    try {
      // 1. Save to local SQLite database
      await DatabaseService().saveUserProfile(updatedModel);

      // 2. Save to Firestore users collection
      if (currentUser != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .set({
              'uid': currentUser.uid,
              'name': name,
              'fullName': name,
              'email': email,
              'phone': phone,
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile details updated successfully! 🎉"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nameLetter = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()[0].toUpperCase()
        : 'U';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CommonAppBar(title: "Edit Full Profile"),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),

                // Avatar Display Header
                Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primary,
                        child: Text(
                          nameLetter,
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Full Name", style: AppTextStyle.bodyBold),
                    const SizedBox(height: 8),
                    CommonTextField(
                      controller: _nameController,
                      hintText: "Enter your full name",
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Email Address Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Email Address", style: AppTextStyle.bodyBold),
                    const SizedBox(height: 8),
                    CommonTextField(
                      controller: _emailController,
                      hintText: "Enter your email address",
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Phone Number Input Field (READ ONLY / DISABLED)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Text("Phone Number", style: AppTextStyle.bodyBold),
                        SizedBox(width: 6),
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.phone_rounded,
                            color: Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _phoneController.text.isNotEmpty
                                  ? _phoneController.text
                                  : "Not provided",
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.lock_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "🔒 Phone number is tied to your account verification and cannot be modified.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 36),

                // Save Changes Button
                CommonButton(
                  label: _isSaving
                      ? "Saving Changes..."
                      : "Save Profile Details",
                  onPressed: () {
                    if (!_isSaving) _handleSaveProfile();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
