import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/theme_service.dart';
import '../../models/ProductSaleModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../Home/product_details_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, dynamic>> _categories = [
    {'id': 'All', 'label': 'All Appliances', 'icon': Icons.apps_rounded},
    {'id': 'Water Purifier', 'label': 'Water Purifiers', 'icon': Icons.water_drop_rounded},
    {'id': 'CCTV', 'label': 'CCTV Security', 'icon': Icons.videocam_rounded},
    {'id': 'Inverter', 'label': 'Inverters & Power', 'icon': Icons.bolt_rounded},
    {'id': 'Chimney', 'label': 'Kitchen Chimneys', 'icon': Icons.soup_kitchen_rounded},
    {'id': 'Cooler', 'label': 'Air Coolers', 'icon': Icons.ac_unit_rounded},
  ];

  // Curated catalog fallback aligned with Client Presentation Slide 4
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
      subCategory: 'CCTV',
      price: '₹2,499',
      originalPrice: '₹3,999',
      discountPercentage: 37,
      image: 'https://images.unsplash.com/photo-1557597774-9d273605dfa9?w=500',
      description: 'Full-color night vision, 360-degree pan-tilt, AI human motion detection with 2-way talk. Certified technician installs & pairs with family smartphones.',
      stockQuantity: 2, // "Only 2 Left" tag as per Slide 4
      warrantyPeriod: '1 Year Doorstep Replacement Warranty',
      deliveryDays: 1,
      isInstallationNeeded: true,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
    ProductSaleModel(
      id: 'prod_inv_01',
      name: 'PowerVolt 1100VA Pure Sine Wave Home Inverter',
      subCategory: 'Inverter',
      price: '₹5,799',
      originalPrice: '₹7,999',
      discountPercentage: 27,
      image: 'https://images.unsplash.com/photo-1513836279014-a89f7a76ae86?w=500',
      description: 'Heavy duty copper transformer with intelligent bypass switch for complete home backup. Certified technician unboxing & battery mounting included.',
      stockQuantity: 5,
      warrantyPeriod: '2 Years Manufacturer Warranty',
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
      id: 'prod_cooler_01',
      name: 'DesertStorm 65L Heavy Air Cooler with Honeycomb Pads',
      subCategory: 'Cooler',
      price: '₹6,299',
      originalPrice: '₹8,999',
      discountPercentage: 30,
      image: 'https://images.unsplash.com/photo-1621905251918-48416bd8575a?w=500',
      description: 'Powerful 4-way air deflection with ice chamber for semi-urban climate. Unboxed, filled, and tested on delivery by our technician team.',
      stockQuantity: 6,
      warrantyPeriod: '1 Year Doorstep Warranty',
      deliveryDays: 1,
      isInstallationNeeded: false,
      isInstallationFree: true,
      installationFee: 'FREE',
    ),
  ];

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

  List<ProductSaleModel> _filterProducts(List<ProductSaleModel> allProducts) {
    return allProducts.where((p) {
      final matchesCategory = _selectedCategory == 'All' ||
          p.subCategory.toLowerCase().contains(_selectedCategory.toLowerCase()) ||
          p.name.toLowerCase().contains(_selectedCategory.toLowerCase());

      final matchesQuery = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.subCategory.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.description.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: Text('BharathFix Market', style: AppTextStyle.mainTitle),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          List<ProductSaleModel> products = [];

          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            products = snapshot.data!.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductSaleModel.fromMap(data);
            }).toList();
          }

          // Merge Firestore products with fallback catalog to guarantee rich UI
          if (products.isEmpty) {
            products = _fallbackProducts;
          }

          final filtered = _filterProducts(products);

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Certified Appliances • Same-Visit Bundled Installation',
                  style: AppTextStyle.subtitle,
                ),
                const SizedBox(height: AppSpacing.medium),

                // 1. Search Bar
                _buildSearchBar(),
                const SizedBox(height: AppSpacing.medium),

                // 2. Value Proposition Banner (Slide 4)
                _buildValuePropsBanner(),
                const SizedBox(height: AppSpacing.large),

                // 3. Category Section Header & Horizontal Pills
                Text(
                  'Browse Categories',
                  style: AppTextStyle.sectionHeader,
                ),
                const SizedBox(height: AppSpacing.small),
                _buildCategoryPills(),
                const SizedBox(height: AppSpacing.large),

                // 4. Products Header with Live Count & Same-Day badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedCategory == 'All'
                                ? 'Available Appliances'
                                : _selectedCategory,
                            style: AppTextStyle.sectionHeader,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${filtered.length} products available for doorstep setup',
                            style: AppTextStyle.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: Colors.orange.shade800),
                          const SizedBox(width: 4),
                          Text(
                            'Same-Day Install',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),

                // 5. Product Grid
                if (filtered.isEmpty)
                  _buildEmptyState()
                else
                  _buildProductGrid(filtered),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'Search RO, CCTV, inverters, chimneys...',
          hintStyle: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: AppColors.subtitle,
          ),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildValuePropsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.handyman_rounded, color: Color(0xFFFFD700), size: 18),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Zero Waiting for Installation! ⚡',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlike other e-commerce apps that deliver on Day 1 and install on Day 4, BharathFix certified technicians deliver, mount, test & demo on the exact same visit!',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white70,
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildMicroFeatureBadge('🛡️ 1-Yr Local Warranty'),
              const SizedBox(width: 8),
              _buildMicroFeatureBadge('📹 Live Demo & Handover'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMicroFeatureBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCategoryPills() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isSelected = _selectedCategory == cat['id'];

          return Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategory = cat['id']),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : AppColors.title,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.title,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProductGrid(List<ProductSaleModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.62,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final prod = items[index];
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
                // Product Image Container with Stock Indicator
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF8F9FA),
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(AppRadius.large - 1),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.large - 1),
                          ),
                          child: Image.network(
                            prod.image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                      // Stock Badge
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLowStock ? Colors.red.shade700 : const Color(0xFF2E7D32),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isLowStock ? '🔥 Only ${prod.stockQuantity} Left' : '✓ In Stock',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Bundled Installation Tag
                      Positioned(
                        bottom: 8,
                        left: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.handyman_rounded, color: Color(0xFFFFD700), size: 10),
                              SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Bundled Install',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Product Meta Information
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prod.name,
                        style: AppTextStyle.cardTitle.copyWith(
                          fontSize: 12.5,
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            prod.price,
                            style: AppTextStyle.mainTitle.copyWith(
                              fontSize: 15,
                              color: AppColors.primary,
                            ),
                          ),
                          if (prod.originalPrice.isNotEmpty) ...[
                            const SizedBox(width: 4),
                            Text(
                              prod.originalPrice,
                              style: AppTextStyle.subtitle.copyWith(
                                fontSize: 10,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Action Buy Button
                      Container(
                        width: double.infinity,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          'View & Order',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: AppColors.subtitle),
          const SizedBox(height: 12),
          Text(
            'No Appliances Found',
            style: AppTextStyle.sectionHeader.copyWith(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            'Try searching another appliance category or clear your search query.',
            textAlign: TextAlign.center,
            style: AppTextStyle.subtitle,
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedCategory = 'All';
                _searchController.clear();
                _searchQuery = '';
              });
            },
            child: const Text('Reset Category Filter'),
          ),
        ],
      ),
    );
  }
}
