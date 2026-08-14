import '../../services/theme_service.dart';
// lib/Authentication/register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../../services/database_service.dart';
import '../../models/UserModel.dart';
import '../../utils/LocalStorage.dart';
import '../../utils/app_routes.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
  }

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // Address Controllers
  final TextEditingController _houseController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();

  String _selectedTag = 'Home';
  bool _initialized = false;
  bool _isSaving = false;

  File? _selectedImageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        if (args['phone'] != null && args['phone'].toString().isNotEmpty) {
          _phoneController.text = args['phone'].toString();
        }
        if (args['name'] != null && args['name'].toString().isNotEmpty) {
          _nameController.text = args['name'].toString();
        }
        if (args['email'] != null && args['email'].toString().isNotEmpty) {
          _emailController.text = args['email'].toString();
        }
      }
      _initialized = true;
    }
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (_isSaving) return;
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final phone = _phoneController.text.trim();

      try {
        final currentUser = FirebaseAuth.instance.currentUser;
        final uid = currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';

        // Save user profile model
        final userModel = UserModel(
          uid: uid,
          name: name,
          phone: phone,
          email: email,
          photoUrl: _selectedImageFile?.path,
        );
        await DatabaseService().saveUserProfile(userModel);

        // Save address if entered
        final house = _houseController.text.trim();
        final street = _streetController.text.trim();
        final landmark = _landmarkController.text.trim();
        final pincode = _pincodeController.text.trim();

        if (house.isNotEmpty || street.isNotEmpty) {
          String consolidatedDetails = landmark.isNotEmpty
              ? '$house, $street, $landmark, $pincode'
              : '$house, $street, $pincode';

          await DatabaseService().insertAddress(
            'bf_${DateTime.now().millisecondsSinceEpoch}',
            consolidatedDetails,
            _selectedTag,
          );
        }

        // Set first use completed
        LocalStorage local = await LocalStorage.getInstance();
        await local.setString(LocalStorage.firstUse, "false");

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile setup completed! 🎉')),
        );

        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.dashboard,
          (route) => false,
        );
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving profile: $e'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Upload Profile Picture',
                  style: AppTextStyle.sectionHeader,
                ),
                SizedBox(height: 20),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.card,
                    child: Icon(Icons.photo_camera_rounded, color: AppColors.primary),
                  ),
                  title: Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.card,
                    child: Icon(Icons.photo_library_rounded, color: AppColors.primary),
                  ),
                  title: Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.dashboard,
                (route) => false,
              );
            },
            child: Text(
              'Skip for Now',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.large),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Setup Profile',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                    color: AppColors.title,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: AppSpacing.extraSmall),
                Text(
                  'Complete your profile and address details',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    color: AppColors.subtitle,
                  ),
                ),
                SizedBox(height: AppSpacing.large),

                // Profile Image Upload Section
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 46,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        backgroundImage: _selectedImageFile != null ? FileImage(_selectedImageFile!) : null,
                        child: _selectedImageFile == null
                            ? Text(
                                _nameController.text.isNotEmpty
                                    ? _nameController.text[0].toUpperCase()
                                    : 'U',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showImagePickerOptions,
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.camera_alt_rounded,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.medium),
                Center(
                  child: TextButton.icon(
                    onPressed: _showImagePickerOptions,
                    icon: Icon(Icons.file_upload_outlined, size: 18, color: AppColors.primary),
                    label: Text(
                      'Upload Profile Picture',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.large),

                // Section 1: Personal Details
                Text('Personal Information', style: AppTextStyle.sectionHeader),
                SizedBox(height: AppSpacing.small),

                CommonTextField(
                  label: 'Full name',
                  hintText: 'e.g. Rahul Sharma',
                  controller: _nameController,
                ),
                SizedBox(height: AppSpacing.medium),
                CommonTextField(
                  label: 'Email Address',
                  hintText: 'you@example.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: AppSpacing.medium),
                CommonTextField(
                  label: 'Phone Number',
                  hintText: '+91 90000 00000',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: AppSpacing.extraLarge),

                // Section 2: Address Details
                Text('Address Details', style: AppTextStyle.sectionHeader),
                SizedBox(height: AppSpacing.small),
                Text('Save address as', style: AppTextStyle.bodyBold),
                SizedBox(height: AppSpacing.small),
                _buildTagSelectorRow(),
                SizedBox(height: AppSpacing.medium),

                CommonTextField(
                  label: 'House / Flat / Block No.',
                  hintText: 'e.g. Flat 302, 3rd Floor',
                  controller: _houseController,
                ),
                SizedBox(height: AppSpacing.medium),
                CommonTextField(
                  label: 'Street / Area / Colony',
                  hintText: 'e.g. Prestige Falcon City',
                  controller: _streetController,
                ),
                SizedBox(height: AppSpacing.medium),
                CommonTextField(
                  label: 'Landmark (Optional)',
                  hintText: 'e.g. Near Metro Station',
                  controller: _landmarkController,
                ),
                SizedBox(height: AppSpacing.medium),
                CommonTextField(
                  label: 'Pincode',
                  hintText: 'e.g. 560062',
                  controller: _pincodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                ),
                SizedBox(height: AppSpacing.extraLarge),

                _isSaving
                    ? Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : Column(
                        children: [
                          CommonButton(
                            label: 'Save & Continue',
                            onPressed: _handleSaveProfile,
                          ),
                          SizedBox(height: AppSpacing.medium),
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                try {
                                  final currentUser = FirebaseAuth.instance.currentUser;
                                  final uid = currentUser?.uid ?? 'user_${DateTime.now().millisecondsSinceEpoch}';
                                  final phone = _phoneController.text.trim().isNotEmpty
                                      ? _phoneController.text.trim()
                                      : (currentUser?.phoneNumber ?? '');
                                  final name = _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : 'User';
                                  final email = _emailController.text.trim();

                                  final defaultUser = UserModel(
                                    uid: uid,
                                    name: name,
                                    phone: phone,
                                    email: email,
                                  );
                                  await DatabaseService().saveUserProfile(defaultUser);
                                } catch (e) {
                                  debugPrint('Error saving default skipped profile: $e');
                                }

                                LocalStorage local = await LocalStorage.getInstance();
                                await local.setString(LocalStorage.firstUse, "false");
                                if (mounted) {
                                  Navigator.pushNamedAndRemoveUntil(
                                    context,
                                    AppRoutes.dashboard,
                                    (route) => false,
                                  );
                                }
                              },
                              child: Text(
                                "Skip for now (Explore App)",
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                SizedBox(height: AppSpacing.extraLarge),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagSelectorRow() {
    final tags = ['Home', 'Office', 'Other'];
    return Row(
      children: tags.map((tag) {
        final isSelected = _selectedTag == tag;
        return Padding(
          key: ValueKey(tag),
          padding: EdgeInsets.only(right: AppSpacing.small),
          child: ChoiceChip(
            label: Text(tag),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedTag = tag);
              }
            },
            selectedColor: AppColors.accentGreen,
            backgroundColor: AppColors.card,
            labelStyle: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppColors.primary : AppColors.subtitle,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: isSelected ? AppColors.primary : AppColors.border),
            ),
          ),
        );
      }).toList(),
    );
  }
}