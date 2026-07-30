// lib/Address/address_list_screen.dart
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import 'manage_address_screen.dart';
import '../../services/database_service.dart';

class AddressListScreen extends StatefulWidget {
  final bool isSelectionMode;

  const AddressListScreen({
    super.key,
    this.isSelectionMode = false,
  });

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<Map<String, String>> _addresses = [];
  bool _isLoading = true;
  String _profileName = "Location details";

  @override
  void initState() {
    super.initState();
    _loadSavedAddresses();
  }

  Future<void> _loadSavedAddresses() async {
    final list = await DatabaseService().fetchAddresses();
    final profile = await DatabaseService().fetchProfile();
    if (mounted) {
      setState(() {
        _addresses = list;
        if (profile != null) {
          _profileName = profile['name'] ?? "Location details";
        }
        _isLoading = false;
      });
    }
  }

  void _deleteAddress(int index) async {
    final addressId = _addresses[index]['id'] ?? '';
    await DatabaseService().deleteAddress(addressId);
    _loadSavedAddresses();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address deleted successfully'),
          backgroundColor: AppColors.primary,
        ),
      );
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
        title: Text(
          widget.isSelectionMode ? 'Select Delivery Address' : 'Saved Addresses',
          style: AppTextStyle.sectionHeader,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
          Expanded(
            child: _addresses.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.medium),
              itemCount: _addresses.length,
              itemBuilder: (context, index) {
                final item = _addresses[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    onTap: () {
                      // If opened from checkout, tapping the card drops the address string back to the checkout flow
                      if (widget.isSelectionMode) {
                        Navigator.pop(context, item['details']);
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.accentGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              item['tag'] ?? 'Address',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['tag'] == 'Home' ? _profileName : 'Location details',
                                  style: AppTextStyle.bodyBold,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['details'] ?? '',
                                  style: AppTextStyle.subtitle.copyWith(height: 1.3),
                                ),
                              ],
                            ),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'edit') {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageAddressScreen(
                                      isEditing: true,
                                      addressData: item,
                                    ),
                                  ),
                                );
                                if (result != null && result is Map) {
                                  _loadSavedAddresses();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Address updated successfully'),
                                        backgroundColor: AppColors.primary,
                                      ),
                                    );
                                  }
                                }
                              } else if (value == 'delete') {
                                _deleteAddress(index);
                              }
                            },
                            icon: const Icon(Icons.more_vert_rounded, color: AppColors.subtitle),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit')),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: SafeArea(
              top: false,
              child: CommonButton(
                label: 'Add New Address',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ManageAddressScreen(isEditing: false),
                    ),
                  );
                  if (result != null && result is Map) {
                    _loadSavedAddresses();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Address saved successfully'),
                          backgroundColor: AppColors.primary,
                        ),
                      );
                    }
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: AppSpacing.medium),
          const Text('No saved addresses yet', style: AppTextStyle.sectionHeader),
          const SizedBox(height: 4),
          Text('Add an address to speed up checkout.', style: AppTextStyle.subtitle),
        ],
      ),
    );
  }
}