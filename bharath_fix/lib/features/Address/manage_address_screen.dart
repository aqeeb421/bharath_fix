import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import '../../models/AddressModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../../services/database_service.dart';

class ManageAddressScreen extends StatefulWidget {
  final bool isEditing;
  final AddressModel? addressModel;
  final Map<String, String>? addressData;

  const ManageAddressScreen({
    super.key,
    required this.isEditing,
    this.addressModel,
    this.addressData,
  });

  @override
  State<ManageAddressScreen> createState() => _ManageAddressScreenState();
}

class _ManageAddressScreenState extends State<ManageAddressScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

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
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    if (widget.isEditing) {
      if (widget.addressModel != null) {
        _selectedTag = widget.addressModel!.tag;
        _houseController.text = widget.addressModel!.house ?? '';
        _streetController.text = widget.addressModel!.street ?? '';
        _landmarkController.text = widget.addressModel!.landmark ?? '';
        _pincodeController.text = widget.addressModel!.pincode ?? '';

        if (_houseController.text.isEmpty && widget.addressModel!.details.isNotEmpty) {
          final parts = widget.addressModel!.details.split(',').map((e) => e.trim()).toList();
          if (parts.isNotEmpty) _houseController.text = parts[0];
          if (parts.length > 1) _streetController.text = parts[1];
          if (parts.length > 2) _landmarkController.text = parts[2];
          if (parts.length > 3) _pincodeController.text = parts[3];
        }
      } else if (widget.addressData != null) {
        _selectedTag = widget.addressData!['tag'] ?? 'Home';
        final details = widget.addressData!['details'] ?? '';
        final parts = details.split(',').map((e) => e.trim()).toList();
        if (parts.isNotEmpty) _houseController.text = parts[0];
        if (parts.length > 1) _streetController.text = parts[1];
        if (parts.length > 2) _landmarkController.text = parts[2];
        if (parts.length > 3) _pincodeController.text = parts[3];
      }
    }
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
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

      String addressId = widget.addressModel?.id ??
          widget.addressData?['id'] ??
          'bf_${DateTime.now().millisecondsSinceEpoch}';

      final model = AddressModel(
        id: addressId,
        details: consolidatedDetails,
        tag: _selectedTag,
        house: house,
        street: street,
        landmark: landmark,
        pincode: pincode,
        isDefault: widget.addressModel?.isDefault ?? false,
      );

      try {
        await DatabaseService().insertAddress(
          addressId,
          consolidatedDetails,
          _selectedTag,
          addressModel: model,
        );
      } catch (e) {
        debugPrint('Address save error: $e');
      }

      if (!mounted) return;
      Navigator.pop(context, model);
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
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
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Save address as', style: AppTextStyle.bodyBold),
                      SizedBox(height: AppSpacing.small),
                      _buildTagSelectorRow(),
                      SizedBox(height: AppSpacing.large),
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
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.medium),
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