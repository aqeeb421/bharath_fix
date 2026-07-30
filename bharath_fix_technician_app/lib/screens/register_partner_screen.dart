import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';
import 'pending_verification_screen.dart';

class RegisterPartnerScreen extends StatefulWidget {
  const RegisterPartnerScreen({super.key});

  @override
  State<RegisterPartnerScreen> createState() => _RegisterPartnerScreenState();
}

class _RegisterPartnerScreenState extends State<RegisterPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _cityController = TextEditingController(text: "Hassan");
  
  // KYC Controllers
  final _aadhaarController = TextEditingController();
  final _panController = TextEditingController();

  // Bank Controllers
  final _bankNameController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _accountNoController = TextEditingController();
  final _ifscController = TextEditingController();

  // Experience & Radius
  final _expController = TextEditingController(text: "3");
  double _operatingRadiusKm = 15.0;

  // Selected Skills
  final Map<String, bool> _skillsMap = {
    'Refrigerator': true,
    'Washing Machine': true,
    'Water Purifier': false,
    'AC Repair': false,
    'Kitchen Chimney': false,
    'Air Cooler': false,
    'Geyser': false,
    'Microwave Oven': false,
  };

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _cityController.dispose();
    _aadhaarController.dispose();
    _panController.dispose();
    _bankNameController.dispose();
    _accountNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    _expController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmitRegistration() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedSkills = _skillsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select at least one appliance service skill."),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Auth Account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      final uid = credential.user!.uid;

      // 2. Save complete KYC & Partner profile to Firestore providers collection
      await FirebaseFirestore.instance.collection('providers').doc(uid).set({
        'id': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'city': _cityController.text.trim(),
        'status': 'pending_verification', // Locked until Admin approves
        'isOnline': false,
        'kyc': {
          'aadhaarNumber': _aadhaarController.text.trim(),
          'panNumber': _panController.text.trim().toUpperCase(),
          'aadhaarProof': 'https://upload.wikimedia.org/wikipedia/commons/c/cf/Aadhaar_Logo.svg',
          'panProof': 'https://upload.wikimedia.org/wikipedia/commons/d/d7/PAN_Card_Logo.png',
        },
        'bankDetails': {
          'bankName': _bankNameController.text.trim(),
          'accountHolder': _accountNameController.text.trim(),
          'accountNumber': _accountNoController.text.trim(),
          'ifscCode': _ifscController.text.trim().toUpperCase(),
        },
        'skills': selectedSkills,
        'experienceYears': int.tryParse(_expController.text) ?? 3,
        'operatingRadiusKm': _operatingRadiusKm,
        'earnings': 0.0,
        'completedJobs': 0,
        'rating': 5.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PendingVerificationScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Registration Error: ${e.toString()}"),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Partner Onboarding Registration"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Service Partner Information", style: AppTextStyle.mainTitle.copyWith(fontSize: 22)),
                const SizedBox(height: 4),
                Text("Fill your details to apply as a certified BharathFix Service Technician.", style: AppTextStyle.subtitle),
                const SizedBox(height: 24),

                // 1. Personal Info Section
                _buildSectionHeader("1. Personal & Contact Details"),
                _buildTextField(_nameController, "Full Name", "e.g. Ramesh Kumar", Icons.person_outline),
                _buildTextField(_emailController, "Email Address", "e.g. ramesh@gmail.com", Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                _buildTextField(_phoneController, "Phone Number", "+91 9876543210", Icons.phone_android_outlined, keyboardType: TextInputType.phone),
                _buildTextField(_passwordController, "Desired Password", "At least 6 characters", Icons.lock_outline, obscureText: true),
                _buildTextField(_cityController, "Operating District / City", "e.g. Hassan", Icons.location_city_outlined),

                const SizedBox(height: 24),

                // 2. KYC Section
                _buildSectionHeader("2. Identity Verification (KYC)"),
                _buildTextField(_aadhaarController, "Aadhaar Card Number (12 digits)", "1234 5678 9012", Icons.badge_outlined, keyboardType: TextInputType.number),
                _buildTextField(_panController, "PAN Card Number", "ABCDE1234F", Icons.credit_card_outlined),

                const SizedBox(height: 24),

                // 3. Banking Section
                _buildSectionHeader("3. Payout Bank Account Details"),
                _buildTextField(_bankNameController, "Bank Name", "e.g. State Bank of India", Icons.account_balance_outlined),
                _buildTextField(_accountNameController, "Account Holder Name", "Full name as in passbook", Icons.person_outline),
                _buildTextField(_accountNoController, "Account Number", "e.g. 123456789012", Icons.numbers_outlined, keyboardType: TextInputType.number),
                _buildTextField(_ifscController, "IFSC Code", "e.g. SBIN0001234", Icons.code_rounded),

                const SizedBox(height: 24),

                // 4. Skills & Working Radius
                _buildSectionHeader("4. Professional Skills & Operating Radius"),
                Text("Select Appliance Skills You Service:", style: AppTextStyle.cardTitle),
                const SizedBox(height: 8),

                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _skillsMap.keys.map((skill) {
                    final isSelected = _skillsMap[skill] ?? false;
                    return FilterChip(
                      label: Text(skill),
                      selected: isSelected,
                      selectedColor: AppColors.primary.withValues(alpha: 0.15),
                      checkmarkColor: AppColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.title,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        setState(() {
                          _skillsMap[skill] = val;
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),
                _buildTextField(_expController, "Years of Appliance Experience", "e.g. 4", Icons.work_history_outlined, keyboardType: TextInputType.number),

                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Operating Service Radius:", style: AppTextStyle.cardTitle),
                    Text("${_operatingRadiusKm.toInt()} km", style: AppTextStyle.cardTitle.copyWith(color: AppColors.primary, fontSize: 16)),
                  ],
                ),
                Slider(
                  value: _operatingRadiusKm,
                  min: 5.0,
                  max: 50.0,
                  divisions: 9,
                  activeColor: AppColors.primary,
                  label: "${_operatingRadiusKm.toInt()} km",
                  onChanged: (val) => setState(() => _operatingRadiusKm = val),
                ),

                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleSubmitRegistration,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text("Submit Application for Verification", style: AppTextStyle.buttonText),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyle.sectionHeader.copyWith(color: AppColors.primary, fontSize: 16),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint,
    IconData icon, {
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyle.cardTitle),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.title),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
              prefixIcon: Icon(icon, color: AppColors.primary),
              fillColor: AppColors.card,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return "Please enter $label";
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
