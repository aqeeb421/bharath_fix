import 'dart:io';
import 'package:bharath_fix/features/Support/support_screen.dart';
import 'package:bharath_fix/features/Support/about_screen.dart';
import 'offers_screen.dart';
import 'wallet_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../Address/address_list_screen.dart';
import '../../services/database_service.dart';
import '../../models/UserModel.dart';
import '../../utils/LocalStorage.dart';
import '../../utils/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = "User";
  String _userEmail = "user@bharathfix.in";
  String _userPhone = "+91 9000000000";
  String _profileLetter = "U";
  bool _isLoading = true;
  bool _isGuest = false;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _userPhotoUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileDetails();
  }

  Future<void> _loadProfileDetails() async {
    final userModel = await DatabaseService().fetchUserProfile();
    final currentUser = FirebaseAuth.instance.currentUser;
    if (userModel != null && currentUser != null && mounted) {
      final name = userModel.name.isNotEmpty ? userModel.name : "User";
      final phone = userModel.phone.isNotEmpty ? userModel.phone : (currentUser.phoneNumber ?? "");
      final email = userModel.email.isNotEmpty ? userModel.email : "user@bharathfix.in";

      setState(() {
        _userName = name;
        _userPhone = phone;
        _userEmail = email;
        _userPhotoUrl = userModel.photoUrl;
        _isGuest = false;
        _profileLetter = name.isNotEmpty ? name[0].toUpperCase() : "U";
        _nameController.text = name;
        _emailController.text = email;
        _phoneController.text = phone;
        _isLoading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _userName = "Guest User";
          _userEmail = "Explore services & sign in to book";
          _userPhone = "";
          _profileLetter = "G";
          _userPhotoUrl = null;
          _isGuest = true;
          _isLoading = false;
        });
      }
    }
  }

  void _showEditProfileModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Edit Profile Details', style: AppTextStyle.sectionHeader),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    final newName = _nameController.text.trim();
                    final newEmail = _emailController.text.trim();
                    final newPhone = _phoneController.text.trim();

                    if (newName.isNotEmpty) {
                      await DatabaseService().saveProfile(newName, newPhone, newEmail);
                      if (context.mounted) {
                        Navigator.pop(context);
                        _loadProfileDetails();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile updated successfully!')),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Save Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: AppSpacing.large),
              if (!_isGuest) ...[
                _buildWalletBalanceCard(),
                const SizedBox(height: AppSpacing.large),
              ],
              _buildNavigationRow(
                Icons.person_outline_rounded,
                _isGuest ? 'Login / Create Account' : 'Edit Profile Details',
                onTap: () {
                  if (_isGuest) {
                    Navigator.pushNamed(context, AppRoutes.login);
                  } else {
                    _showEditProfileModal();
                  }
                },
              ),
              if (!_isGuest) ...[
                _buildNavigationRow(
                  Icons.account_balance_wallet_outlined,
                  'Wallet',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const WalletScreen()),
                    );
                  },
                ),
                _buildNavigationRow(
                  Icons.local_offer_outlined,
                  'Offers & Coupons',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const OffersScreen()),
                    );
                  },
                ),
              ],
              _buildNavigationRow(
                Icons.location_on_outlined,
                'Saved addresses',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddressListScreen()),
                  );
                },
              ),
              _buildNavigationRow(
                Icons.help_outline_rounded,
                'Help & support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SupportScreen()),
                  );
                },
              ),
              _buildNavigationRow(
                Icons.info_outline_rounded,
                'About BharathFix',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutScreen()),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.large),
              TextButton(
                onPressed: () async {
                  LocalStorage local = await LocalStorage.getInstance();
                  await local.clear();
                  await DatabaseService().clearProfile();

                  if (mounted) {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  }
                },
                child: Text(
                  _isGuest ? 'Sign In' : 'Log out',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    File? localPhotoFile;
    if (_userPhotoUrl != null && _userPhotoUrl!.isNotEmpty) {
      final file = File(_userPhotoUrl!);
      if (file.existsSync()) {
        localPhotoFile = file;
      }
    }

    return Row(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: localPhotoFile != null ? FileImage(localPhotoFile) : null,
          child: localPhotoFile == null
              ? Text(
                  _profileLetter,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(width: AppSpacing.medium),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_userName, style: AppTextStyle.sectionHeader),
              const SizedBox(height: 4),
              Text(
                _userPhone.isNotEmpty && _userPhone != "guest_phone"
                    ? '$_userEmail • $_userPhone'
                    : _userEmail,
                style: AppTextStyle.subtitle,
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
          onPressed: _isGuest
              ? () => Navigator.pushNamed(context, AppRoutes.login)
              : _showEditProfileModal,
        ),
      ],
    );
  }

  Widget _buildWalletBalanceCard() {
    return StreamBuilder<double>(
      stream: DatabaseService().walletBalanceStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WalletScreen()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.accentGreen,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Wallet balance',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${balance.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Manage Wallet',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavigationRow(
    IconData leadingIcon,
    String labelText, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: () => onTap != null ? onTap() : {},
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.8),
          ),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(leadingIcon, color: Colors.black87, size: 22),
          title: Text(
            labelText,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: AppColors.title,
            ),
          ),
          trailing: const Icon(
            Icons.arrow_forward_ios_rounded,
            size: 12,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
