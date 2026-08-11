import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';
import '../services/job_matching_service.dart';

class EditTechnicianProfileScreen extends StatefulWidget {
  const EditTechnicianProfileScreen({super.key});

  @override
  State<EditTechnicianProfileScreen> createState() =>
      _EditTechnicianProfileScreenState();
}

class _EditTechnicianProfileScreenState
    extends State<EditTechnicianProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _expController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _customSkillController = TextEditingController();

  // Bank fields
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNoController = TextEditingController();
  final TextEditingController _ifscController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  double _operatingRadiusKm = 15.0;

  // Available skills checklist
  final Map<String, bool> _skillsMap = {
    'Washing Machine': false,
    'Refrigerator': false,
    'Water Purifier': false,
    'AC Repair': false,
    'Kitchen Chimney': false,
    'Air Cooler': false,
    'Geyser': false,
    'Microwave Oven': false,
    'Electrician': false,
    'Plumbing': false,
  };

  final List<String> _customSkills = [];

  @override
  void initState() {
    super.initState();
    _loadExistingProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _expController.dispose();
    _addressController.dispose();
    _customSkillController.dispose();
    _bankNameController.dispose();
    _accountNoController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProfileData() async {
    final user = _auth.currentUser;

    try {
      DocumentSnapshot<Map<String, dynamic>>? doc;
      if (user != null) {
        doc = await _firestore.collection('providers').doc(user.uid).get();
        if (!doc.exists) {
          doc = await _firestore.collection('providers').doc(user.uid).get();
        }
      }

      final data = doc?.data() ?? {};

      // Pre-fill Name
      final rawName = data['name'] ?? user?.displayName;
      _nameController.text =
          (rawName != null && rawName.toString().trim().isNotEmpty)
          ? rawName.toString()
          : 'Ramesh Kumar (Master Partner)';

      // Pre-fill Email
      final rawEmail = data['email'] ?? user?.email;
      _emailController.text =
          (rawEmail != null && rawEmail.toString().trim().isNotEmpty)
          ? rawEmail.toString()
          : 'ramesh.technician@bharathfix.com';

      // Pre-fill Phone
      final rawPhone = data['phone'] ?? user?.phoneNumber;
      _phoneController.text =
          (rawPhone != null && rawPhone.toString().trim().isNotEmpty)
          ? rawPhone.toString()
          : '+91 9876543210';

      // Pre-fill Experience
      final rawExp = data['experience'] ?? data['experienceYears'];
      _expController.text =
          (rawExp != null && rawExp.toString().trim().isNotEmpty)
          ? rawExp.toString()
          : '5';

      // Pre-fill Address
      final rawAddr = data['address'] ?? data['city'];
      _addressController.text =
          (rawAddr != null && rawAddr.toString().trim().isNotEmpty)
          ? rawAddr.toString()
          : 'BM Road, Near City Bus Stand, Hassan, KA - 573201';

      // Pre-fill Operating Radius
      _operatingRadiusKm =
          (data['operatingRadiusKm'] as num?)?.toDouble() ?? 15.0;

      // Pre-fill Skills
      final List<dynamic> skillsRaw = data['skills'] as List<dynamic>? ?? [];
      final List<String> savedSkills = skillsRaw
          .map((e) => e.toString())
          .toList();
      final String category = (data['category'] ?? '').toString();

      if (category.isNotEmpty && !savedSkills.contains(category)) {
        savedSkills.add(category);
      }

      // Default pre-selected skills if new partner
      if (savedSkills.isEmpty) {
        savedSkills.addAll(['Washing Machine', 'Refrigerator']);
      }

      for (var key in _skillsMap.keys) {
        if (savedSkills.any(
          (s) => s.toLowerCase().contains(key.toLowerCase()),
        )) {
          _skillsMap[key] = true;
        }
      }

      // Custom skills
      for (var s in savedSkills) {
        bool isDefault = _skillsMap.keys.any(
          (k) => k.toLowerCase() == s.toLowerCase(),
        );
        if (!isDefault &&
            s.trim().isNotEmpty &&
            s != 'All Appliances Specialist') {
          if (!_customSkills.contains(s)) {
            _customSkills.add(s);
          }
        }
      }

      // Pre-fill Bank info
      final bankData = data['bankDetails'] as Map<String, dynamic>?;
      _bankNameController.text =
          bankData?['bankName'] ?? 'State Bank of India (Hassan Main Branch)';
      _accountNoController.text = bankData?['accountNo'] ?? bankData?['accountNumber'] ?? '384910294821';
      _ifscController.text = bankData?['ifsc'] ?? bankData?['ifscCode'] ?? 'SBIN0001234';
    } catch (e) {
      debugPrint("Error loading profile data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addCustomSkill() {
    final text = _customSkillController.text.trim();
    if (text.isEmpty) return;

    if (_customSkills.any((s) => s.toLowerCase() == text.toLowerCase()) ||
        _skillsMap.keys.any((k) => k.toLowerCase() == text.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Skill already exists in your list.")),
      );
      return;
    }

    setState(() {
      _customSkills.add(text);
      _customSkillController.clear();
    });
  }

  void _removeCustomSkill(String skill) {
    setState(() {
      _customSkills.remove(skill);
    });
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final selectedSkills = _skillsMap.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    selectedSkills.addAll(_customSkills);

    if (selectedSkills.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select or add at least one service skill."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final user = _auth.currentUser;
    if (user == null) return;

    final computedCategory = JobMatchingService.getCategoryDisplayLabel(
      selectedSkills,
      selectedSkills.first,
    );

    final expText = _expController.text.trim();
    final addrText = _addressController.text.trim();
    final bankNameText = _bankNameController.text.trim();
    final accNoText = _accountNoController.text.trim();
    final ifscText = _ifscController.text.trim().toUpperCase();

    final updatedData = {
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'experience': expText,
      'experienceYears': int.tryParse(expText) ?? 3,
      'address': addrText,
      'city': addrText,
      'operatingRadiusKm': _operatingRadiusKm,
      'category': computedCategory,
      'skills': selectedSkills,
      'bankDetails': {
        'bankName': bankNameText,
        'accountNo': accNoText,
        'accountNumber': accNoText,
        'ifsc': ifscText,
        'ifscCode': ifscText,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      // Write to both providers and technicians collections
      await _firestore
          .collection('providers')
          .doc(user.uid)
          .set(updatedData, SetOptions(merge: true));
     

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile & Skill expertise updated successfully! 🎉"),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text(
          "Edit Partner Profile & Skills",
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.title,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Basic Information
                    Text(
                      "Personal & Contact Details",
                      style: AppTextStyle.sectionHeader,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: "Full Name *",
                              prefixIcon: Icon(
                                Icons.person_outline_rounded,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 2) {
                                return "Please enter your full name.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              labelText: "Email Address *",
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null ||
                                  !val.contains('@') ||
                                  !val.contains('.')) {
                                return "Please enter a valid email address.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "Phone Number *",
                              prefixIcon: Icon(
                                Icons.phone_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              final clean = (val ?? '').replaceAll(
                                RegExp(r'[^\d]'),
                                '',
                              );
                              if (clean.length < 10) {
                                return "Please enter a valid 10-digit mobile number.";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _expController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: "Experience (Years) *",
                                    prefixIcon: Icon(
                                      Icons.workspace_premium_outlined,
                                      color: AppColors.primary,
                                    ),
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (val) {
                                    final numVal = int.tryParse(val ?? '');
                                    if (numVal == null ||
                                        numVal < 0 ||
                                        numVal > 50) {
                                      return "Enter valid years (0-50).";
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _addressController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: "Base Address / Station *",
                              prefixIcon: Icon(
                                Icons.home_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            validator: (val) {
                              if (val == null || val.trim().length < 5) {
                                return "Please enter your station address.";
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Appliance Expertise & Skills Selection
                    Text(
                      "Appliance Expertise & Skills",
                      style: AppTextStyle.sectionHeader,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Select all categories you are experienced in. You will only receive job requests matching your selected skills.",
                      style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                    ),
                    const SizedBox(height: 12),
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
                          ..._skillsMap.keys.map((skill) {
                            return CheckboxListTile(
                              activeColor: AppColors.primary,
                              dense: true,
                              title: Text(
                                skill,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              value: _skillsMap[skill],
                              onChanged: (val) {
                                setState(() {
                                  _skillsMap[skill] = val ?? false;
                                });
                              },
                            );
                          }),
                          const Divider(),
                          const SizedBox(height: 8),
                          const Text(
                            "Add Custom / Specialized Skill:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _customSkillController,
                                  decoration: InputDecoration(
                                    hintText:
                                        "e.g. Solar Geyser, Induction Stove",
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: _addCustomSkill,
                                icon: const Icon(
                                  Icons.add,
                                  size: 18,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  "Add",
                                  style: TextStyle(color: Colors.white),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_customSkills.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: _customSkills.map((s) {
                                return Chip(
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.12),
                                  label: Text(
                                    s,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  deleteIcon: const Icon(
                                    Icons.cancel,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  onDeleted: () => _removeCustomSkill(s),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 3: Operating Radius
                    Text(
                      "Operating Service Radius",
                      style: AppTextStyle.sectionHeader,
                    ),
                    const SizedBox(height: 12),
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Maximum Distance:"),
                              Text(
                                "${_operatingRadiusKm.toInt()} km",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Slider(
                            value: _operatingRadiusKm,
                            min: 5,
                            max: 50,
                            divisions: 9,
                            activeColor: AppColors.primary,
                            label: "${_operatingRadiusKm.toInt()} km",
                            onChanged: (val) {
                              setState(() => _operatingRadiusKm = val);
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Bank Account Details
                    Text(
                      "Bank Account & Payout Details",
                      style: AppTextStyle.sectionHeader,
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _bankNameController,
                            decoration: const InputDecoration(
                              labelText: "Bank Name",
                              prefixIcon: Icon(
                                Icons.account_balance_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _accountNoController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "Account Number",
                              prefixIcon: Icon(
                                Icons.credit_card_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _ifscController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: "IFSC Code",
                              prefixIcon: Icon(
                                Icons.qr_code_outlined,
                                color: AppColors.primary,
                              ),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving ? null : _saveProfileChanges,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.check_circle_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isSaving
                              ? "Saving Changes..."
                              : "Save & Update Profile",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }
}
