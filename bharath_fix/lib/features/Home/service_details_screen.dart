import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import 'checkout_screen.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final String serviceTitle;
  final String servicePrice;
  final String bannerImage;
  final String intentMode;

  const ServiceDetailsScreen({
    super.key,
    required this.serviceTitle,
    required this.servicePrice,
    required this.bannerImage,
    required this.intentMode,
  });

  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    final bool isInstallation = widget.intentMode == 'Installation';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImmersiveImageHeader(context),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.serviceTitle, style: AppTextStyle.mainTitle.copyWith(fontSize: 22)),
                        const SizedBox(height: AppSpacing.small),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              isInstallation ? 'Verified Installation Pack' : 'Verified Inspection Pack',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.large),
                        Text(
                          isInstallation ? 'About this Installation' : 'About this Service',
                          style: AppTextStyle.sectionHeader,
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          isInstallation
                              ? 'Secure a professional doorstep visit for seamless equipment setup. Our expert technician will assess the layout parameters, safely mount or unmount the unit, and configure structural settings optimally.'
                              : 'Secure a professional doorstep visit. Our expert technician will diagnose your appliance defect and issue a localized cost quotation transparently over the provider application framework.',
                          style: AppTextStyle.subtitle.copyWith(fontSize: 14, height: 1.4, color: AppColors.title),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Dynamic Pricing Terms Quote Box
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.medium),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isInstallation ? 'Installation Flow Information' : 'Inspection Flow Information',
                                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.title),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      isInstallation
                                          ? 'The current flat charge covers the initial doorstep visit, site evaluation, and base tool setup configuration metrics.'
                                          : 'The current flat charge covers the expert technician doorstep visit and multi-point parameter fault diagnostics only.',
                                      style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),
                        const Text("What's included", style: AppTextStyle.sectionHeader),
                        const SizedBox(height: AppSpacing.medium),

                        // Conditionals matching the selected intent
                        if (isInstallation) ...[
                          _buildIncludedCheckItem('Doorstep background-verified installation technician visit'),
                          _buildIncludedCheckItem('Complete drill alignment, masking, and mounting setup'),
                          _buildIncludedCheckItem('Post-installation safety checks & operation run metrics'),
                          _buildIncludedCheckItem('Zero hidden final checkout dispatch fees'),
                        ] else ...[
                          _buildIncludedCheckItem('Doorstep background-verified technician visit'),
                          _buildIncludedCheckItem('Complete internal system diagnostics & tracking'),
                          _buildIncludedCheckItem('On-the-spot localized digital repair quotation summary'),
                          _buildIncludedCheckItem('Zero hidden final checkout dispatch fees'),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildStickyBottomActionBar(isInstallation),
        ],
      ),
    );
  }

  Widget _buildImmersiveImageHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 240,
          width: double.infinity,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: NetworkImage(widget.bannerImage),
              fit: BoxFit.cover,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.small),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 18),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIncludedCheckItem(String checkText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, color: Colors.white, size: 12),
          ),
          const SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Text(
              checkText,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.title, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar(bool isInstallation) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isInstallation ? 'Installation Fee' : 'Inspection Fee',
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Text(
                      '₹499',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        color: AppColors.subtitle,
                        decoration: TextDecoration.lineThrough,
                        decorationColor: AppColors.subtitle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.servicePrice,
                      style: AppTextStyle.mainTitle.copyWith(fontSize: 22, color: AppColors.primary),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SAVE ₹300',
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
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CheckoutScreen(
                      serviceTitle: widget.serviceTitle,
                      priceString: widget.servicePrice,
                      bannerImage: widget.bannerImage,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Text(
                  'Book now',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}