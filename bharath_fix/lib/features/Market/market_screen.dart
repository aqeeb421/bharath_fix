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
import 'market_category_products_screen.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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

  // Fallback categories list (in case offline or before initial sync)
  final List<Map<String, dynamic>> _defaultCategories = const [
    {
      'id': 'water_purifier',
      'name': 'Water Purifier',
      'icon': 'water_drop_rounded',
      'description': 'Advanced RO, UV & Copper alkaline purification systems',
      'accent': Color(0xFF0284C7),
    },
    {
      'id': 'cctv_security_cameras',
      'name': 'CCTV Security Cameras',
      'icon': 'videocam_rounded',
      'description': 'Smart Wi-Fi outdoor, indoor & multi-camera kits',
      'accent': Color(0xFF7C3AED),
    },
    {
      'id': 'chimney',
      'name': 'Chimney',
      'icon': 'soup_kitchen_rounded',
      'description': 'Auto-clean, motion-sensor filterless kitchen chimneys',
      'accent': Color(0xFFEA580C),
    },
    {
      'id': 'voltage_stabilizers',
      'name': 'Voltage Stabilizers',
      'icon': 'electric_bolt_rounded',
      'description': 'Digital cutoff stabilizers for ACs & mainline protection',
      'accent': Color(0xFFD97706),
    },
    {
      'id': 'water_purifier_spare_parts',
      'name': 'Water Purifier Spare Parts',
      'icon': 'build_circle_rounded',
      'description': 'Certified RO membranes, filters, booster pumps & kits',
      'accent': Color(0xFF0D9488),
    },
    {
      'id': 'geysers',
      'name': 'Geysers (Gas & Electric)',
      'icon': 'whatshot_rounded',
      'description': 'Instant & storage water heaters for high-pressure flats',
      'accent': Color(0xFFDC2626),
    },
    {
      'id': 'solars',
      'name': 'Solar Solutions',
      'icon': 'solar_power_rounded',
      'description': 'Rooftop on-grid/off-grid solar inverters & panels',
      'accent': Color(0xFFCA8A04),
    },
  ];

  // Curated catalog fallback aligned with presentation overview
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

  IconData _resolveCategoryIcon(String? iconName, String categoryName) {
    switch (iconName) {
      case 'water_drop_rounded':
        return Icons.water_drop_rounded;
      case 'videocam_rounded':
        return Icons.videocam_rounded;
      case 'soup_kitchen_rounded':
        return Icons.soup_kitchen_rounded;
      case 'electric_bolt_rounded':
        return Icons.electric_bolt_rounded;
      case 'build_circle_rounded':
        return Icons.build_circle_rounded;
      case 'whatshot_rounded':
        return Icons.whatshot_rounded;
      case 'solar_power_rounded':
        return Icons.solar_power_rounded;
    }
    final lower = categoryName.toLowerCase();
    if (lower.contains('water') && lower.contains('spare')) return Icons.build_circle_rounded;
    if (lower.contains('water') || lower.contains('purifier') || lower.contains('ro')) return Icons.water_drop_rounded;
    if (lower.contains('cctv') || lower.contains('camera')) return Icons.videocam_rounded;
    if (lower.contains('chimney')) return Icons.soup_kitchen_rounded;
    if (lower.contains('stabilizer') || lower.contains('voltage') || lower.contains('inverter')) return Icons.electric_bolt_rounded;
    if (lower.contains('geyser') || lower.contains('water heater')) return Icons.whatshot_rounded;
    if (lower.contains('solar')) return Icons.solar_power_rounded;
    if (lower.contains('cooler') || lower.contains('ac')) return Icons.ac_unit_rounded;
    return Icons.widgets_rounded;
  }

  Color _resolveCategoryAccent(String categoryName) {
    final lower = categoryName.toLowerCase();
    if (lower.contains('water') && lower.contains('spare')) return const Color(0xFF0D9488);
    if (lower.contains('water') || lower.contains('purifier')) return const Color(0xFF0284C7);
    if (lower.contains('cctv') || lower.contains('camera')) return const Color(0xFF7C3AED);
    if (lower.contains('chimney')) return const Color(0xFFEA580C);
    if (lower.contains('stabilizer') || lower.contains('voltage')) return const Color(0xFFD97706);
    if (lower.contains('geyser')) return const Color(0xFFDC2626);
    if (lower.contains('solar')) return const Color(0xFFCA8A04);
    return const Color(0xFF2563EB);
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
        builder: (context, prodSnapshot) {
          // Parse products
          List<ProductSaleModel> products = [];
          if (prodSnapshot.hasData && prodSnapshot.data!.docs.isNotEmpty) {
            products = prodSnapshot.data!.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return ProductSaleModel.fromMap(data);
            }).toList();
          }
          if (products.isEmpty) {
            products = _fallbackProducts;
          }

          // Count products per category
          final Map<String, int> productCounts = {};
          for (var p in products) {
            final key = p.subCategory.trim();
            productCounts[key] = (productCounts[key] ?? 0) + 1;
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('market_categories')
                .where('isActive', isEqualTo: true)
                .snapshots(),
            builder: (context, catSnapshot) {
              // Parse categories
              List<Map<String, dynamic>> categories = [];
              if (catSnapshot.hasData && catSnapshot.data!.docs.isNotEmpty) {
                // Sort by 'order'
                final docs = catSnapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final orderA = (a.data()['order'] as num?)?.toInt() ?? 99;
                  final orderB = (b.data()['order'] as num?)?.toInt() ?? 99;
                  return orderA.compareTo(orderB);
                });

                categories = docs.map((doc) {
                  final data = doc.data();
                  final name = (data['name'] ?? doc.id).toString();
                  return {
                    'id': doc.id,
                    'name': name,
                    'icon': data['icon']?.toString(),
                    'description': data['description']?.toString() ?? '$name appliances and accessories',
                    'accent': _resolveCategoryAccent(name),
                  };
                }).toList();
              }

              // Fallback if collection is empty
              if (categories.isEmpty) {
                categories = _defaultCategories;
              }

              // Search filtering
              final query = _searchQuery.toLowerCase().trim();
              final filteredCategories = categories.where((c) {
                if (query.isEmpty) return true;
                final name = (c['name'] ?? '').toString().toLowerCase();
                final desc = (c['description'] ?? '').toString().toLowerCase();
                return name.contains(query) || desc.contains(query);
              }).toList();

              // Filtered products for quick search preview
              final filteredProducts = query.isNotEmpty
                  ? products.where((p) {
                      return p.name.toLowerCase().contains(query) ||
                          p.subCategory.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query);
                    }).toList()
                  : <ProductSaleModel>[];

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

                    // 2. Value Proposition Banner
                    _buildValuePropsBanner(),
                    const SizedBox(height: AppSpacing.large),

                    // If user is actively searching and there are direct product matches
                    if (query.isNotEmpty && filteredProducts.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Direct Product Matches',
                              style: AppTextStyle.sectionHeader,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${filteredProducts.length} Found', style: AppTextStyle.subtitle),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildQuickProductGrid(filteredProducts),
                      const SizedBox(height: AppSpacing.large),
                    ],

                    // 3. Category Hub Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Shop By Category',
                                style: AppTextStyle.sectionHeader,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a category to browse appliances & spare parts',
                                style: AppTextStyle.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${filteredCategories.length} Categories',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.medium),

                    // 4. Category Grid (Tier 1 Hub)
                    if (filteredCategories.isEmpty)
                      _buildNoCategoriesFound()
                    else
                      _buildCategoryHubGrid(filteredCategories, productCounts),

                    const SizedBox(height: AppSpacing.large),

                    // 5. Featured Appliances & Overview (Sample Overview)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Featured Appliances Overview',
                            style: AppTextStyle.sectionHeader,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified_rounded, size: 12, color: Colors.green.shade800),
                              const SizedBox(width: 4),
                              Text(
                                'Certified Doorstep Setup',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Explore sample top-tier appliances across each category',
                      style: AppTextStyle.subtitle,
                    ),
                    const SizedBox(height: AppSpacing.medium),
                    _buildOverviewProductList(products),
                    const SizedBox(height: 30),
                  ],
                ),
              );
            },
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
        style: TextStyle(color: AppColors.title, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'Search RO, CCTV, chimney, stabilizer, solar, geysers...',
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
            AppColors.primary.withValues(alpha: 0.88),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 10,
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.verified_outlined, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'BharathFix Certified Retail & Delivery',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Get 100% genuine brand appliances delivered with same-visit certified technician unboxing, mounting, and demo.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: Colors.white70,
              fontSize: 12,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildValuePill('⚡ 1-2 Day Delivery'),
              _buildValuePill('🛠️ Bundled Setup Kit'),
              _buildValuePill('🛡️ Doorstep Warranty'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValuePill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Tier 1 Category Hub Grid
  Widget _buildCategoryHubGrid(
    List<Map<String, dynamic>> categories,
    Map<String, int> productCounts,
  ) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.88,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final cat = categories[index];
        final name = (cat['name'] ?? '').toString();
        final iconStr = cat['icon']?.toString();
        final desc = (cat['description'] ?? '').toString();
        final accent = (cat['accent'] as Color?) ?? _resolveCategoryAccent(name);
        final iconData = _resolveCategoryIcon(iconStr, name);

        // Calculate count by fuzzy/exact match
        int count = productCounts[name] ?? 0;
        if (count == 0) {
          final catLower = name.toLowerCase();
          for (var entry in productCounts.entries) {
            final keyLower = entry.key.toLowerCase();
            if (keyLower.contains(catLower) || catLower.contains(keyLower)) {
              count += entry.value;
            }
          }
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MarketCategoryProductsScreen(
                  categoryName: name,
                  categoryDescription: desc,
                  iconData: iconData,
                  accentColor: accent,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top row with Icon badge and Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(iconData, size: 24, color: accent),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        count > 0 ? '$count Item${count > 1 ? 's' : ''}' : 'Explore',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: accent,
                        ),
                      ),
                    ),
                  ],
                ),

                // Name and Description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.title,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      desc,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        color: AppColors.subtitle,
                        height: 1.25,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),

                // Bottom action strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browse items',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewProductList(List<ProductSaleModel> items) {
    return SizedBox(
      height: 240,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final prod = items[index];
          final accent = _resolveCategoryAccent(prod.subCategory);

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
              width: 160,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
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
                        if (prod.discountPercentage > 0)
                          Positioned(
                            top: 6,
                            left: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE53935),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${prod.discountPercentage}% OFF',
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

                  // Info
                  Expanded(
                    flex: 10,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
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
                              const SizedBox(height: 2),
                              Text(
                                prod.name,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.title,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                prod.price,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: accent,
                                ),
                              ),
                              Icon(Icons.arrow_forward_rounded, size: 14, color: accent),
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
        },
      ),
    );
  }

  Widget _buildQuickProductGrid(List<ProductSaleModel> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.65,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final prod = items[index];
        final accent = _resolveCategoryAccent(prod.subCategory);

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
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: AppCachedImage(
                    imageUrl: prod.image,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.large - 1)),
                    errorWidget: const Center(child: Icon(Icons.image_not_supported_rounded, color: Colors.grey)),
                  ),
                ),
                Expanded(
                  flex: 9,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prod.name,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.title,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          prod.price,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoCategoriesFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.search_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              'No categories match "$_searchQuery"',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Text('Clear search'),
            ),
          ],
        ),
      ),
    );
  }
}
