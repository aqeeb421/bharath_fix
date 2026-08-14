// lib/Home/subcategory_selection_screen.dart
import 'package:flutter/material.dart';
import '../../models/MainCategoryModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import 'service_details_screen.dart';

class SubCategorySelectionScreen extends StatelessWidget {
  final MainCategoryModel mainCategory;

  const SubCategorySelectionScreen({super.key, required this.mainCategory});

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
        title: Text(mainCategory.name, style: AppTextStyle.sectionHeader),
      ),
      body: SafeArea(
        child: ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(AppSpacing.medium),
          itemCount: mainCategory.subCategories.length,
          itemBuilder: (context, index) {
            final subCategory = mainCategory.subCategories[index];
            return GestureDetector(
              onTap: () => _showIntentBottomSheet(context, subCategory.name, subCategory.placeholderImage),
              child: Container(
                margin: EdgeInsets.only(bottom: AppSpacing.medium),
                padding: EdgeInsets.all(AppSpacing.small),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Left Side: Subcategory Image Frame with Loader & Error Fallback
                    Container(
                      width: 80,
                      height: 80,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Image.network(
                        subCategory.placeholderImage,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.grey,
                            size: 28,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: AppSpacing.medium),

                    // Middle: Text Hierarchy
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            subCategory.name,
                            style: AppTextStyle.bodyBold.copyWith(fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Complete Diagnostics & Inspection',
                            style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                '₹499',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  color: AppColors.subtitle,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: AppColors.subtitle,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                '₹199',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE8F5E9),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '60% OFF',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Right Side: Minimal Action Pointer Arrow
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.small),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 14,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showIntentBottomSheet(BuildContext context, String subName, String image) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large))),
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(AppSpacing.medium),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subName, style: AppTextStyle.sectionHeader),
              SizedBox(height: AppSpacing.small),
              Text('Select service type (Inspection charge applies)', style: AppTextStyle.subtitle),
              SizedBox(height: AppSpacing.medium),
              _buildIntentOption(
                context,
                icon: Icons.build_rounded,
                title: 'Service / Repair Request',
                onTap: () => _navigateToDetails(context, '$subName Repair', image, 'Service'),
              ),
              Divider(color: AppColors.border),
              _buildIntentOption(
                context,
                icon: Icons.settings_suggest_rounded,
                title: 'Installation / Uninstallation',
                onTap: () => _navigateToDetails(context, '$subName Installation', image, 'Installation'),
              ),
              SizedBox(height: AppSpacing.medium),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIntentOption(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.primary),
      title: Text(title, style: AppTextStyle.bodyBold),
      trailing: Text('₹199', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.primary, fontWeight: FontWeight.bold)),
    );
  }

  void _navigateToDetails(BuildContext context, String title, String image, String mode) {
    Navigator.pop(context); // Close bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ServiceDetailsScreen(
          serviceTitle: title,
          servicePrice: '₹199',
          bannerImage: image,
          intentMode: mode,
        ),
      ),
    );
  }
}