import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/theme_service.dart';
import '../../models/ProductSaleModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/app_cached_image.dart';
import '../Home/product_details_screen.dart';

class MarketCategoryProductsScreen extends StatefulWidget {
  final String categoryName;
  final String? categoryDescription;
  final IconData? iconData;
  final Color? accentColor;

  const MarketCategoryProductsScreen({
    super.key,
    required this.categoryName,
    this.categoryDescription,
    this.iconData,
    this.accentColor,
  });

  @override
  State<MarketCategoryProductsScreen> createState() => _MarketCategoryProductsScreenState();
}

class _MarketCategoryProductsScreenState extends State<MarketCategoryProductsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSort = 'Featured'; // 'Featured', 'LowToHigh', 'HighToLow'

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
    _searchController.dispose();
    super.dispose();
  }

  // Fallback products catalog for offline or before initial load
  final List<ProductSaleModel> _fallbackProducts = const [
    ProductSaleModel(
      id: 'prod_ro_01',
      name: 'AquaShield Pro 10L RO+UV Water Purifier',
      subCategory: 'Water Purifier',
      price: '₹7,999',
      originalPrice: '₹11,499',
      discountPercentage: 30,
      image: 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=500',
      description: 'Multi-stage RO+UV+Copper filtration with active mineralizer and 10-liter food-grade tank. Includes bundled same-day doorstep installation kit & demo.',
      stockQuantity: 4,
      warrantyPeriod: '1 Year Comprehensive Warranty',
      deliveryDays: 1,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_cctv_01',
      name: 'Guardian 4K Wi-Fi Outdoor CCTV Camera (Dual Lens)',
      subCategory: 'CCTV Security Cameras',
      price: '₹2,499',
      originalPrice: '₹3,999',
      discountPercentage: 37,
      image: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=500',
      description: 'Full-color night vision, 360-degree pan-tilt, AI human motion detection with 2-way talk. Certified technician installs & pairs with family smartphones.',
      stockQuantity: 2,
      warrantyPeriod: '1 Year Doorstep Replacement Warranty',
      deliveryDays: 1,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_chimney_01',
      name: 'AeroClean 60cm Filterless Auto-Clean Chimney (1200 m³/hr)',
      subCategory: 'Chimney',
      price: '₹8,499',
      originalPrice: '₹13,999',
      discountPercentage: 39,
      image: 'https://images.unsplash.com/photo-1556911220-e15b29be8c8f?w=500',
      description: 'Motion gesture sensor control with thermal auto-clean oil collector. Zero-waiting bundled technician ducting setup on the same visit.',
      stockQuantity: 3,
      warrantyPeriod: '1 Year Product + 5 Year Motor Warranty',
      deliveryDays: 1,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_stab_01',
      name: 'VoltGuard 4kVA Heavy Digital Voltage Stabilizer',
      subCategory: 'Voltage Stabilizers',
      price: '₹2,799',
      originalPrice: '₹3,999',
      discountPercentage: 30,
      image: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=500',
      description: 'Microcontroller-based intelligent high/low voltage cutoff for 1.5-ton ACs and mainline appliances.',
      stockQuantity: 12,
      warrantyPeriod: '3 Years Comprehensive Warranty',
      deliveryDays: 2,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_spares_01',
      name: 'Universal 80 GPD RO Membrane & Pre-Filter Complete Kit',
      subCategory: 'Water Purifier Spare Parts',
      price: '₹1,299',
      originalPrice: '₹1,999',
      discountPercentage: 35,
      image: 'https://images.unsplash.com/photo-1584992236310-6edddc08acff?w=500',
      description: 'Certified 80 GPD TFC Membrane + Sediment + Carbon Block filter cartridges. Includes verified technician replacement visit.',
      stockQuantity: 25,
      warrantyPeriod: '6 Months Replacement Warranty',
      deliveryDays: 1,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_geyser_01',
      name: 'ThermaFlow 15L 5-Star Storage Electric Geyser',
      subCategory: 'Geysers (Gas & Electric)',
      price: '₹5,999',
      originalPrice: '₹8,499',
      discountPercentage: 29,
      image: 'https://images.unsplash.com/photo-1585338107529-13afc5f02586?w=500',
      description: 'Glass-lined corrosion proof tank with whirl-flow heat retention and 8-bar pressure capability for high-rise buildings.',
      stockQuantity: 6,
      warrantyPeriod: '2 Years Comprehensive + 7 Years Tank Warranty',
      deliveryDays: 2,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_solar_01',
      name: 'SunPower 1kW Rooftop On-Grid Solar Power Inverter Kit',
      subCategory: 'Solar Solutions',
      price: '₹38,999',
      originalPrice: '₹52,000',
      discountPercentage: 25,
      image: 'https://images.unsplash.com/photo-1509391365360-2e959784a276?w=500',
      description: 'High-efficiency mono-perc solar setup with smart grid feed meter and certified engineer mounting & net-metering assistance.',
      stockQuantity: 2,
      warrantyPeriod: '5 Years Inverter + 25 Years Performance Warranty',
      deliveryDays: 3,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
  ];

  double _parsePrice(String priceStr) {
    final cleaned = priceStr.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(cleaned) ?? 0.0;
  }

  List<ProductSaleModel> _processProducts(List<ProductSaleModel> all) {
    final catLower = widget.categoryName.toLowerCase().trim();
    
    // Filter by category
    final inCategory = all.where((p) {
      final pCat = p.subCategory.toLowerCase().trim();
      if (pCat == catLower) return true;
      if (catLower.contains('water') && catLower.contains('spare') && pCat.contains('spare')) return true;
      if (catLower.contains('cctv') && pCat.contains('cctv')) return true;
      if (catLower.contains('geyser') && pCat.contains('geyser')) return true;
      if (catLower.contains('solar') && pCat.contains('solar')) return true;
      if (catLower.contains('stabilizer') && pCat.contains('stabilizer')) return true;
      if (catLower.contains('chimney') && pCat.contains('chimney')) return true;
      if (catLower.contains('water purifier') && !catLower.contains('spare') && pCat.contains('purifier') && !pCat.contains('spare')) return true;
      return false;
    }).toList();

    // If empty in Firestore, check fallback catalog
    final list = inCategory.isNotEmpty
        ? inCategory
        : _fallbackProducts.where((p) {
            final pCat = p.subCategory.toLowerCase().trim();
            if (pCat == catLower) return true;
            if (catLower.contains('cctv') && pCat.contains('cctv')) return true;
            if (catLower.contains('geyser') && pCat.contains('geyser')) return true;
            if (catLower.contains('solar') && pCat.contains('solar')) return true;
            if (catLower.contains('stabilizer') && pCat.contains('stabilizer')) return true;
            if (catLower.contains('chimney') && pCat.contains('chimney')) return true;
            if (catLower.contains('spare') && pCat.contains('spare')) return true;
            if (catLower.contains('water purifier') && !catLower.contains('spare') && pCat.contains('water purifier')) return true;
            return false;
          }).toList();

    // Filter by search query
    final query = _searchQuery.toLowerCase().trim();
    final searched = list.where((p) {
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query) ||
          p.subCategory.toLowerCase().contains(query);
    }).toList();

    // Apply sorting
    if (_selectedSort == 'LowToHigh') {
      searched.sort((a, b) => _parsePrice(a.price).compareTo(_parsePrice(b.price)));
    } else if (_selectedSort == 'HighToLow') {
      searched.sort((a, b) => _parsePrice(b.price).compareTo(_parsePrice(a.price)));
    }

    return searched;
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.primary;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.categoryName,
          style: AppTextStyle.mainTitle.copyWith(fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          List<ProductSaleModel> allProducts = [];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            allProducts = snapshot.data!.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductSaleModel.fromMap(data);
            }).toList();
          }

          final products = _processProducts(allProducts);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Header Info Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
                  child: _buildCategoryHeader(accent, products.length),
                ),
              ),

              // Search Bar & Filter Strip
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.medium, AppSpacing.small, AppSpacing.medium, AppSpacing.medium),
                  child: Column(
                    children: [
                      _buildSearchBar(accent),
                      const SizedBox(height: 12),
                      _buildSortChips(accent),
                    ],
                  ),
                ),
              ),

              // Products Grid or Empty State
              if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(accent),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.58,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildProductCard(products[index], accent),
                      childCount: products.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 40),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCategoryHeader(Color accent, int productCount) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              widget.iconData ?? Icons.category_rounded,
              size: 28,
              color: accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.categoryName,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.title,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$productCount Available',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  widget.categoryDescription ?? 'Certified brand models with doorstep setup kit & verified warranty.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: AppColors.subtitle,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.verified_rounded, size: 13, color: Colors.green.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Free Doorstep Inspection • Genuine Parts Guaranteed',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color accent) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        style: TextStyle(color: AppColors.title, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search in ${widget.categoryName}...',
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: AppColors.subtitle,
          ),
          prefixIcon: Icon(Icons.search_rounded, color: accent, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSortChips(Color accent) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          Text(
            'Sort:',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.subtitle,
            ),
          ),
          const SizedBox(width: 8),
          _buildChip('Featured', 'Featured', accent),
          const SizedBox(width: 6),
          _buildChip('Price: Low', 'LowToHigh', accent),
          const SizedBox(width: 6),
          _buildChip('Price: High', 'HighToLow', accent),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value, Color accent) {
    final isSelected = _selectedSort == value;
    return InkWell(
      onTap: () => setState(() => _selectedSort = value),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? accent : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.title,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(ProductSaleModel prod, Color accent) {
    final bool isLowStock = prod.stockQuantity <= 2 && prod.stockQuantity > 0;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(
              productName: prod.name,
              productPrice: prod.price,
              productImage: prod.image,
              productSubCategory: prod.subCategory,
              product: prod,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadius.large),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Stack
            Expanded(
              flex: 11,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large - 1)),
                    ),
                    child: AppCachedImage(
                      imageUrl: prod.image,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large - 1)),
                      errorWidget: const Center(
                        child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                      ),
                    ),
                  ),

                  // Discount Badge
                  if (prod.discountPercentage > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${prod.discountPercentage}% OFF',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // Low Stock / Stock indicator
                  if (isLowStock)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade800,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Only ${prod.stockQuantity} Left',
                          style: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details Container
            Expanded(
              flex: 13,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            prod.subCategory,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: accent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Title
                        Text(
                          prod.name,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.title,
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),

                    // Price and Installation Badge
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              prod.price,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: accent,
                              ),
                            ),
                            if (prod.originalPrice.isNotEmpty) ...[
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  prod.originalPrice,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: AppColors.subtitle,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),

                        // Bundled install indicator
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: prod.isInstallationFree
                                ? Colors.green.shade50
                                : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                prod.isInstallationFree
                                    ? Icons.handyman_rounded
                                    : Icons.local_shipping_rounded,
                                size: 10,
                                color: prod.isInstallationFree
                                    ? Colors.green.shade800
                                    : Colors.blue.shade800,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  prod.isInstallationFree
                                      ? 'FREE Bundled Install'
                                      : 'Install: ${prod.installationFee}',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: prod.isInstallationFree
                                        ? Colors.green.shade800
                                        : Colors.blue.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color accent) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.iconData ?? Icons.inventory_2_outlined,
                size: 48,
                color: accent,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching appliances found'
                  : 'No products listed in this category yet',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try searching with different keywords or clear the search filter.'
                  : 'We are updating our catalog for ${widget.categoryName}. Check back soon or contact support for special orders.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                color: AppColors.subtitle,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_searchQuery.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                icon: const Icon(Icons.clear_rounded, size: 16),
                label: const Text('Clear Search'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded, size: 16),
                label: const Text('Browse Other Categories'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
