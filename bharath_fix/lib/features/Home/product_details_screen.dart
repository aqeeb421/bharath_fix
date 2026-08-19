import '../../services/theme_service.dart';
import 'package:bharath_fix/features/Home/product_checkout_screen.dart';
import 'package:bharath_fix/models/ProductSaleModel.dart';
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
  final ProductSaleModel? product;

  const ProductDetailsScreen({
    super.key,
    required this.productName,
    required this.productPrice,
    required this.productImage,
    required this.productSubCategory,
    this.product,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  String _resolveDescription() {
    if (widget.product?.description.isNotEmpty == true) {
      return widget.product!.description;
    }
    final sub = widget.productSubCategory.toLowerCase();
    if (sub.contains('ac') || sub.contains('air conditioner')) {
      return 'Experience rapid cooling and energy savings with the brand new ${widget.productName}. Built with inverter technology, 100% copper condenser coils, and heavy-duty dust filters.';
    } else if (sub.contains('wash') || sub.contains('laundry')) {
      return 'Get powerful stain removal and fabric care with the brand new ${widget.productName}. Equipped with smart inverter motor and eco-bubble wash technology.';
    } else if (sub.contains('refrigerator') || sub.contains('fridge')) {
      return 'Keep food fresh for days with the brand new ${widget.productName}. Features multi-airflow cooling, digital inverter technology, and spill-proof toughened glass shelves.';
    }
    return 'Get 100% authentic and high-performance performance with the brand new ${widget.productName}. Tailored for Indian households with comprehensive manufacturer backing.';
  }

  Map<String, String> _resolveSpecs() {
    if (widget.product?.specifications.isNotEmpty == true) {
      return widget.product!.specifications;
    }
    final sub = widget.productSubCategory.toLowerCase();
    if (sub.contains('ac') || sub.contains('air conditioner')) {
      return {
        'Capacity': '1.5 Ton 5-Star Inverter',
        'Coil Material': '100% Inner Grooved Copper',
        'Refrigerant': 'Eco-Friendly R32',
        'Warranty': '1 Year Product + 10 Years Compressor',
      };
    } else if (sub.contains('wash') || sub.contains('laundry')) {
      return {
        'Washing Capacity': '7.5 Kg Fully Automatic',
        'Spin Speed': '1200 RPM Fast Drying',
        'Motor Type': 'Direct Drive Inverter Motor',
        'Warranty': '2 Years Product + 10 Years Motor',
      };
    }
    return {
      'Category': widget.productSubCategory,
      'Condition': 'Brand New Factory Sealed',
      'Installation': 'Free Technician Setup',
      'Warranty': widget.product?.warrantyPeriod ?? '1 Year Comprehensive Warranty',
    };
  }

  @override
  Widget build(BuildContext context) {
    final specs = _resolveSpecs();
    final description = _resolveDescription();
    final isOutOfStock = (widget.product?.stockQuantity ?? 10) <= 0;
    final warrantyText = widget.product?.warrantyPeriod ?? '1 Year Comprehensive Warranty';

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
                    padding: EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            widget.productSubCategory,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        SizedBox(height: AppSpacing.small),
                        Text(widget.productName, style: AppTextStyle.mainTitle.copyWith(fontSize: 22)),
                        SizedBox(height: AppSpacing.small),

                        Row(
                          children: [
                            Icon(Icons.gpp_good_rounded, color: AppColors.primary, size: 18),
                            SizedBox(width: 6),
                            Text(
                              warrantyText,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: AppSpacing.large),

                        Text('Description', style: AppTextStyle.sectionHeader),
                        SizedBox(height: AppSpacing.small),
                        Text(
                          description,
                          style: AppTextStyle.subtitle.copyWith(fontSize: 14, height: 1.4, color: AppColors.title),
                        ),
                        SizedBox(height: AppSpacing.large),

                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(AppSpacing.medium),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(AppRadius.large),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                        SizedBox(height: AppSpacing.large),

                        Text("Technical Specifications", style: AppTextStyle.sectionHeader),
                        SizedBox(height: AppSpacing.medium),
                        ...specs.entries.map((e) => _buildSpecItem(e.key, e.value)).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildStickyBottomActionBar(isOutOfStock),
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
              fit: BoxFit.contain,
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.small),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 18),
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
      padding: EdgeInsets.only(bottom: AppSpacing.medium),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 2,
            child: Text(
              label,
              style: AppTextStyle.subtitle.copyWith(fontSize: 14),
            ),
          ),
          SizedBox(width: AppSpacing.medium),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyle.bodyBold.copyWith(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStickyBottomActionBar(bool isOutOfStock) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      decoration: BoxDecoration(
        color: AppColors.card,
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
                Text('Product Price', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle, fontWeight: FontWeight.w500)),
                SizedBox(height: 2),
                Text(widget.productPrice, style: AppTextStyle.mainTitle.copyWith(fontSize: 22, color: AppColors.primary)),
              ],
            ),
            InkWell(
              onTap: isOutOfStock
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductCheckoutScreen(
                            productName: widget.productName,
                            priceString: widget.productPrice,
                            productImage: widget.productImage,
                            productId: widget.product?.id,
                          ),
                        ),
                      );
                    },
              borderRadius: BorderRadius.circular(AppRadius.button),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                decoration: BoxDecoration(
                  color: isOutOfStock ? Colors.grey : AppColors.primary,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Text(
                  isOutOfStock ? 'Out of Stock' : 'Buy now',
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