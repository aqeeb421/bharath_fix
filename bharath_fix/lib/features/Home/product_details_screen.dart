// lib/Home/product_details_screen.dart
import 'package:bharath_fix/features/Home/product_checkout_screen.dart';
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productName;
  final String productPrice;
  final String productImage;
  final String productSubCategory;

  const ProductDetailsScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productSubCategory,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  @override
  Widget build(BuildContext context) {
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
                        // Sub-category badge + Product Name
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.productSubCategory,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.small),
                        Text(widget.productName, style: AppTextStyle.mainTitle.copyWith(fontSize: 22)),
                        const SizedBox(height: AppSpacing.small),

                        Row(
                          children: const [
                            Icon(Icons.gpp_good_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              '1 Year Comprehensive Warranty',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.large),

                        const Text('Description', style: AppTextStyle.sectionHeader),
                        const SizedBox(height: AppSpacing.small),
                        Text(
                          'Get 100% safe and pure drinking water with the brand new ${widget.productName}. Features multi-stage RO + UV purification technology with an active mineral infusion layer tailored perfectly for Indian households.',
                          style: AppTextStyle.subtitle.copyWith(fontSize: 14, height: 1.4, color: AppColors.title),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        // Free Delivery & Installation Highlight Box
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
                              const Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text(
                                      'BharathFix Delivery Promise',
                                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.title),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Price includes free home delivery and complete unboxing & installation by our certified technician within 24-48 hours.',
                                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, height: 1.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.large),

                        const Text("Technical Specifications", style: AppTextStyle.sectionHeader),
                        const SizedBox(height: AppSpacing.medium),
                        _buildSpecItem('Purification Flow', 'RO + UV + Copper + Minerals'),
                        _buildSpecItem('Storage Capacity', '7.5 Liters clear tank'),
                        _buildSpecItem('Installation Type', 'Wall Mounted / Counter Top'),
                        _buildSpecItem('Filters Included', 'Pre-Filter, Sediment, Carbon, RO Membrane'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildStickyBottomActionBar(),
        ],
      ),
    );
  }

  Widget _buildImmersiveImageHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 260,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.card,
            image: DecorationImage(
              image: NetworkImage(widget.productImage),
              fit: BoxFit.contain, // Fits consumer products better than full cropping cover
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

  Widget _buildSpecItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // Aligns elements neatly if wrapping happens
        children: [
          // Constrains the left label side
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyle.subtitle.copyWith(fontSize: 14),
            ),
          ),
          const SizedBox(width: AppSpacing.medium), // Prevents texts from touching

          // Constrains the right value side and allows text wrapping
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end, // Keeps values aligned to the right edge
              style: AppTextStyle.bodyBold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar() {
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
                const Text('Product Price', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(widget.productPrice, style: AppTextStyle.mainTitle.copyWith(fontSize: 22, color: AppColors.primary)),
              ],
            ),
            InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductCheckoutScreen(
                      productName: widget.productName,
                      priceString: widget.productPrice,
                      productImage: widget.productImage,
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
                  'Buy now',
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