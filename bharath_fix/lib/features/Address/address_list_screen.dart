import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import '../../models/AddressModel.dart';
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
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  List<AddressModel> _addresses = [];
  bool _isLoading = true;
  String _profileName = "Location details";

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    _loadSavedAddresses();
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  Future<void> _loadSavedAddresses() async {
    final list = await DatabaseService().fetchAddresses();
    final profile = await DatabaseService().fetchProfile();
    if (mounted) {
      setState(() {
        _addresses = list;
        if (profile != null && (profile['name'] ?? '').trim().isNotEmpty) {
          _profileName = profile['name']!;
        }
        _isLoading = false;
      });
    }
  }

  void _deleteAddress(int index) async {
    final addressId = _addresses[index].id;
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.isSelectionMode ? 'Select Delivery Address' : 'Saved Addresses',
          style: AppTextStyle.sectionHeader,
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: _addresses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: EdgeInsets.all(AppSpacing.medium),
                          itemCount: _addresses.length,
                          itemBuilder: (context, index) {
                            final item = _addresses[index];
                            return Container(
                              margin: EdgeInsets.only(bottom: AppSpacing.medium),
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.large),
                                border: Border.all(
                                  color: item.isDefault ? AppColors.primary : AppColors.border,
                                  width: item.isDefault ? 1.5 : 1,
                                ),
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(AppRadius.large),
                                onTap: () {
                                  if (widget.isSelectionMode) {
                                    Navigator.pop(context, item.details);
                                  }
                                },
                                child: Padding(
                                  padding: EdgeInsets.all(AppSpacing.medium),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: AppColors.accentGreen,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          item.tag.isNotEmpty ? item.tag : 'Address',
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: AppSpacing.medium),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  item.tag == 'Home' ? _profileName : item.tag,
                                                  style: AppTextStyle.bodyBold,
                                                ),
                                                if (item.isDefault) ...[
                                                  SizedBox(width: 8),
                                                  Container(
                                                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: AppColors.primary.withOpacity(0.1),
                                                      borderRadius: BorderRadius.circular(4),
                                                    ),
                                                    child: Text(
                                                      'Default',
                                                      style: TextStyle(
                                                        fontFamily: 'Plus Jakarta Sans',
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: AppColors.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              item.details,
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
                                                  addressModel: item,
                                                ),
                                              ),
                                            );
                                            if (result != null) {
                                              _loadSavedAddresses();
                                            }
                                          } else if (value == 'delete') {
                                            _deleteAddress(index);
                                          }
                                        },
                                        icon: Icon(Icons.more_vert_rounded, color: AppColors.subtitle),
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
                  padding: EdgeInsets.all(AppSpacing.medium),
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
                        if (result != null) {
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
          Icon(Icons.location_off_rounded, size: 56, color: Colors.grey),
          SizedBox(height: AppSpacing.medium),
          Text('No saved addresses yet', style: AppTextStyle.sectionHeader),
          SizedBox(height: 4),
          Text('Add an address to speed up checkout.', style: AppTextStyle.subtitle),
        ],
      ),
    );
  }
}