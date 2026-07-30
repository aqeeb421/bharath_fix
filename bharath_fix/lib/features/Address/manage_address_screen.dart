// lib/Address/manage_address_screen.dart
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../../services/database_service.dart';

class ManageAddressScreen extends StatefulWidget {
  final bool isEditing;
  final Map<String, String>? addressData;

  const ManageAddressScreen({super.key, required this.isEditing, this.addressData});

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  final _houseController = TextEditingController();
  final _streetController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedTag = 'Home';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.addressData != null) {
      _selectedTag = widget.addressData!['tag'] ?? 'Home';
      final details = widget.addressData!['details'] ?? '';
      final parts = details.split(',').map((e) => e.trim()).toList();
      if (parts.isNotEmpty) _houseController.text = parts[0];
      if (parts.length > 1) _streetController.text = parts[1];
      if (parts.length > 2) _landmarkController.text = parts[2];
      if (parts.length > 3) _pincodeController.text = parts[3];
    }
  }

  @override
  void dispose() {
    _houseController.dispose();
    _streetController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _submitAddressForm() async {
    if (_isSaving) return;
    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
      setState(() => _isSaving = true);

      String house = _houseController.text.trim();
      String street = _streetController.text.trim();
      String landmark = _landmarkController.text.trim();
      String pincode = _pincodeController.text.trim();

      String consolidatedDetails = landmark.isNotEmpty
          ? '$house, $street, $landmark, $pincode'
          : '$house, $street, $pincode';

      String addressId = (widget.isEditing && widget.addressData != null)
          ? (widget.addressData!['id'] ?? 'bf_${DateTime.now().millisecondsSinceEpoch}')
          : 'bf_${DateTime.now().millisecondsSinceEpoch}';

      try {
        await DatabaseService().insertAddress(
          addressId,
          consolidatedDetails,
          _selectedTag,
        );
      } catch (e) {
        debugPrint('Address save error: $e');
      }

      Map<String, String> returnData = {
        'id': addressId,
        'tag': _selectedTag,
        'details': consolidatedDetails,
      };

      if (!mounted) return;
      Navigator.pop(context, returnData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isEditing ? 'Edit Address' : 'Add New Address', style: AppTextStyle.sectionHeader),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(AppSpacing.medium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Save address as', style: AppTextStyle.bodyBold),
                      const SizedBox(height: AppSpacing.small),
                      _buildTagSelectorRow(),
                      const SizedBox(height: AppSpacing.large),
                      CommonTextField(
                        label: 'House / Flat / Block No.',
                        hintText: 'e.g. Flat 302, 3rd Floor',
                        controller: _houseController,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      CommonTextField(
                        label: 'Street / Area / Colony',
                        hintText: 'e.g. Prestige Falcon City',
                        controller: _streetController,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      CommonTextField(
                        label: 'Landmark (Optional)',
                        hintText: 'e.g. Near Metro Station',
                        controller: _landmarkController,
                      ),
                      const SizedBox(height: AppSpacing.medium),
                      CommonTextField(
                        label: 'Pincode',
                        hintText: 'e.g. 560062',
                        controller: _pincodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: CommonButton(
                label: widget.isEditing ? 'Update Address' : 'Save Address',
                onPressed: _submitAddressForm,
              ),
            ),
          ],
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
          padding: const EdgeInsets.only(right: AppSpacing.small),
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