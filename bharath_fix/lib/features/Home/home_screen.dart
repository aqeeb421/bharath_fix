import '../../services/theme_service.dart';
// lib/Home/home_screen.dart
import 'package:bharath_fix/features/Home/product_details_screen.dart';
import 'package:bharath_fix/features/Home/subcategory_selection_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/ProductSaleModel.dart';
import '../../models/MainCategoryModel.dart';
import '../../models/SubCategoryModel.dart';
import 'package:flutter/material.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/floating_cart_bar.dart';
import '../../services/database_service.dart';

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  final String detectedLocation;
  final bool isServiceable;
  final VoidCallback onRetryLocation;
  final VoidCallback? onProfileTap;

  const HomeScreen({
    super.key,
    required this.detectedLocation,
    required this.isServiceable,
    required this.onRetryLocation,
    this.onProfileTap,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  String _userName = "User";
  String _profileLetter = "U";

  // Dynamic collections variables loaded from Firestore
  List<MainCategoryModel> _categoriesList = [];
  List<Map<String, dynamic>> _bannerList = [];
  List<ProductSaleModel> _productsList = [];

  bool _isLoadingFirestore = true;
  StreamSubscription? _notifSub;

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    super.initState();
    _loadUserProfile();
    _loadFirestoreHomeData();
    _setupNotificationListener();
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    _notifSub?.cancel();
    super.dispose();
  }

  void _setupNotificationListener() {
    // Silent notification sync (System tray push notifications handled by FCM & local notifications)
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? 'guest_user';
    _notifSub = NotificationService.listenForInAppNotifications(
      userId: uid,
      onNewNotification: (title, body) {
        if (mounted) setState(() {});
      },
    );
  }

  void _showNotificationAlert(String title, String body) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF000062),
        content: Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.amber, size: 28),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 15,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    body,
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _loadUserProfile() async {
    final profile = await DatabaseService().fetchProfile();
    if (profile != null && mounted) {
      final name = profile['name'] ?? "User";
      setState(() {
        _userName = name;
        _profileLetter = name.isNotEmpty ? name[0].toUpperCase() : "A";
      });
    }
  }

  Future<void> _loadFirestoreHomeData() async {
    try {
      // 1. Fetch categories dynamically from Firestore
      final categoriesSnapshot = await FirebaseFirestore.instance
          .collection('categories')
          .get();
      if (categoriesSnapshot.docs.isNotEmpty) {
        final List<MainCategoryModel> fetchedCategories = [];
        for (var doc in categoriesSnapshot.docs) {
          final data = doc.data();
          final id = doc.id;
          final name = data['name'] as String? ?? '';
          final iconName = data['iconName'] as String? ?? 'settings';
          final subCatsRaw = data['subCategories'] as List<dynamic>? ?? [];

          final subCategories = subCatsRaw.map((sub) {
            final subMap = sub as Map<dynamic, dynamic>;
            return SubCategoryModel(
              id: subMap['id'] as String? ?? '',
              name: subMap['name'] as String? ?? '',
              placeholderImage:
                  subMap['image'] as String? ??
                  'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400',
            );
          }).toList();

          fetchedCategories.add(
            MainCategoryModel(
              id: id,
              name: name,
              iconData: _resolveIconFromString(iconName),
              assetPath: _resolveAssetIconFromString(name, iconName),
              subCategories: subCategories,
            ),
          );
        }

        if (mounted) {
          setState(() {
            _categoriesList = fetchedCategories;
          });
        }
      }

      // 2. Fetch promo banners dynamically from Firestore
      final bannersSnapshot = await FirebaseFirestore.instance
          .collection('banners')
          .get();
      if (bannersSnapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> fetchedBanners = [];
        for (var doc in bannersSnapshot.docs) {
          final data = doc.data();
          fetchedBanners.add({
            'title': data['title'] as String? ?? '',
            'subtitle': data['subtitle'] as String? ?? '',
            'image': data['image'] as String? ?? '',
          });
        }

        if (mounted) {
          setState(() {
            _bannerList = fetchedBanners;
          });
        }
      }

      // 3. Fetch products dynamically from Firestore
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      if (productsSnapshot.docs.isNotEmpty) {
        final List<ProductSaleModel> fetchedProducts = [];
        for (var doc in productsSnapshot.docs) {
          final data = doc.data();
          fetchedProducts.add(ProductSaleModel.fromMap(data));
        }

        if (mounted) {
          setState(() {
            _productsList = fetchedProducts;
          });
        }
      }
    } catch (e) {
      debugPrint("Error loading dynamic Firestore Home data: $e");
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingFirestore = false;
        });
      }
    }
  }

  IconData _resolveIconFromString(String iconName) {
    switch (iconName) {
      case 'kitchen_rounded':
      case 'kitchen':
        return Icons.kitchen_rounded;
      case 'local_laundry_service':
      case 'local_laundry_service_rounded':
        return Icons.local_laundry_service_rounded;
      case 'water_drop':
      case 'water_drop_rounded':
        return Icons.water_drop_rounded;
      case 'ac_unit':
      case 'ac_unit_rounded':
        return Icons.ac_unit_rounded;
      case 'blender':
      case 'blender_rounded':
        return Icons.blender_rounded;
      case 'wind_power':
      case 'wind_power_rounded':
        return Icons.wind_power_rounded;
      case 'hot_tub':
      case 'hot_tub_rounded':
        return Icons.hot_tub_rounded;
      case 'microwave':
      case 'microwave_rounded':
        return Icons.microwave_rounded;
      default:
        return Icons.settings_rounded;
    }
  }

  String _resolveAssetIconFromString(String name, String iconName) {
    final lowerName = name.toLowerCase().trim();

    if (lowerName.contains('purifier') ||
        lowerName.contains('water purifier')) {
      return 'assets/icons/water_purifer.png';
    } else if (lowerName.contains('washing') ||
        lowerName.contains('laundry') ||
        lowerName.contains('machine')) {
      return 'assets/icons/washing_machine.png';
    } else if (lowerName.contains('ac') ||
        lowerName.contains('air condition')) {
      return 'assets/icons/air_condition.png';
    } else if (lowerName.contains('cooler')) {
      return 'assets/icons/air_cooler.png';
    } else if (lowerName.contains('heater') || lowerName.contains('geyser')) {
      return 'assets/icons/water_heater.png';
    } else if (lowerName.contains('chimney')) {
      return 'assets/icons/chimney.png';
    } else if (lowerName.contains('microwave') || lowerName.contains('oven')) {
      return 'assets/icons/microwave.png';
    } else if (lowerName.contains('refrigerator') ||
        lowerName.contains('fridge')) {
      return 'assets/icons/refrigerator.png';
    }
    return 'assets/icons/air_condition.png';
  }

  @override
  Widget build(BuildContext context) {
    // Debug statement to trace exact location services state
    debugPrint(
      "HomeScreen configuration parameters -> detectedLocation: '${widget.detectedLocation}', isServiceable: ${widget.isServiceable}",
    );

    return Scaffold(
      bottomNavigationBar: const FloatingCartBar(),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBar(),
              SizedBox(height: AppSpacing.medium),
              Expanded(
                // TODO: Location restriction hidden for the time being
                // child: widget.isServiceable
                //     ? (_isLoadingFirestore ... )
                //     : _buildComingSoonBody(),
                child: _isLoadingFirestore
                    ? Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadFirestoreHomeData,
                        color: AppColors.primary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildAISearchBar(),
                              SizedBox(height: AppSpacing.medium),
                              _buildPromoBannerCarousel(),
                              SizedBox(height: AppSpacing.large),
                              Text(
                                'Service & Installation',
                                style: AppTextStyle.sectionHeader,
                              ),
                              SizedBox(height: AppSpacing.medium),
                              _buildCategoryGrid(),
                              SizedBox(height: AppSpacing.large),
                              Text(
                                'Buy New Water Purifier',
                                style: AppTextStyle.sectionHeader,
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Premium units ranging from ₹6,999 to ₹29,999',
                                style: AppTextStyle.subtitle,
                              ),
                              SizedBox(height: AppSpacing.medium),
                              _buildProductHorizontalLists(),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComingSoonBody() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_mvm84upg.json',
              height: 240,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.location_off_rounded,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Coming Soon to Your Area!',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12),
            Text(
              'BharathFix services are currently exclusive to Hassan District and its administrative taluks. Detected: "${widget.detectedLocation}". We are expanding quickly and will reach you soon!',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.subtitle,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: widget.onRetryLocation,
              icon: Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                'Retry Location Check',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hi, $_userName', style: AppTextStyle.mainTitle),
            SizedBox(height: AppSpacing.extraSmall),
            GestureDetector(
              onTap: widget.onRetryLocation,
              child: Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 14,
                    color: AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.extraSmall),
                  Text(widget.detectedLocation, style: AppTextStyle.subtitle),
                  SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.subtitle,
                  ),
                ],
              ),
            ),
          ],
        ),
        InkWell(
          onTap: widget.onProfileTap,
          borderRadius: BorderRadius.circular(22),
          child: CircleAvatar(
            radius: 22,
            backgroundColor: AppColors.primary,
            child: Text(
              _profileLetter,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAISearchBar() {
    return GestureDetector(
      onTap: () => _showAISearchBottomSheet(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [Icon(Icons.auto_awesome, color: Colors.grey, size: 18),
            SizedBox(width: AppSpacing.small),
            Text(
              'Describe your problem — AI will help...',
              style: AppTextStyle.subtitle,
            ),
          ],
        ),
      ),
    );
  }

  void _showAISearchBottomSheet() {
    final searchController = TextEditingController();
    final List<Map<String, String>> defaultSuggestions = [
      {'title': 'AC Service & Repair', 'catId': 'm4'},
      {'title': 'AC Installation & Uninstallation', 'catId': 'm4'},
      {'title': 'AC Gas Leakage Check', 'catId': 'm4'},
      {'title': 'Water Purifier Service', 'catId': 'm2'},
      {'title': 'Washing Machine Repair', 'catId': 'm3'},
      {'title': 'Refrigerator Repair', 'catId': 'm1'},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.large),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final text = searchController.text.toLowerCase().trim();
            final matches = defaultSuggestions.where((item) {
              if (text.isEmpty) return true;
              return item['title']!.toLowerCase().contains(text);
            }).toList();

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Search & Instant AI Suggestions',
                          style: AppTextStyle.sectionHeader,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.small),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: AppColors.title,
                      ),
                      onChanged: (val) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search service e.g. "AC", "Purifier", "Fridge"...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          borderSide: BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium),
                    Text(
                      'Matching Services:',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.subtitle,
                      ),
                    ),
                    SizedBox(height: 8),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: matches.length,
                        itemBuilder: (context, idx) {
                          final match = matches[idx];
                          return ListTile(
                            dense: true,
                            leading: Icon(Icons.build_circle_outlined, color: AppColors.primary, size: 22),
                            title: Text(
                              match['title']!,
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                            onTap: () {
                              Navigator.pop(context);
                              final category = _categoriesList.firstWhere(
                                (cat) => cat.id == match['catId'],
                                orElse: () => _categoriesList.isNotEmpty ? _categoriesList.first : MainCategoryModel(id: 'm1', name: 'Service', iconData: Icons.build, assetPath: '', subCategories: []),
                              );
                              if (_categoriesList.isNotEmpty) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SubCategorySelectionScreen(mainCategory: category),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _handleAISearchDiagnostics(String query) {
    String message = "Describe your issue to get tailored assistance.";
    Widget? navigateScreen;

    if (query.contains('fridge') ||
        query.contains('refrigerator') ||
        query.contains('kitchen') ||
        query.contains('cool')) {
      message =
          "AI Diagnosis: Your issue appears related to refrigerator cooling or compression limits. Booking a Refrigerator Inspection is recommended.";
      final category = _categoriesList.firstWhere(
        (cat) => cat.id == 'm1',
        orElse: () => _categoriesList.first,
      );
      navigateScreen = SubCategorySelectionScreen(mainCategory: category);
    } else if (query.contains('washing') ||
        query.contains('laundry') ||
        query.contains('water') ||
        query.contains('machine')) {
      message =
          "AI Diagnosis: Wash cycle errors or pump defects detected. We recommend booking a Washing Machine diagnostic service.";
      final category = _categoriesList.firstWhere(
        (cat) => cat.id == 'm2',
        orElse: () => _categoriesList.first,
      );
      navigateScreen = SubCategorySelectionScreen(mainCategory: category);
    } else if (query.contains('ac') ||
        query.contains('split') ||
        query.contains('air conditioner')) {
      message =
          "AI Diagnosis: Low refrigerant or filter blockage suspected. We recommend booking an AC Repair check.";
      final category = _categoriesList.firstWhere(
        (cat) => cat.id == 'm4',
        orElse: () => _categoriesList.first,
      );
      navigateScreen = SubCategorySelectionScreen(mainCategory: category);
    } else {
      message =
          "AI Diagnosis: Could not isolate exact appliance issue. Booking a diagnostic visit is recommended.";
    }

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text('AI Diagnostics', style: AppTextStyle.sectionHeader),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              color: AppColors.title,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.subtitle),
              ),
            ),
            if (navigateScreen != null)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  if (!widget.isServiceable) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Booking disabled: BharathFix is only available in Hassan district.',
                        ),
                        backgroundColor: Colors.redAccent,
                      ),
                    );
                    return;
                  }
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => navigateScreen!),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
                child: Text(
                  'Book Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPromoBannerCarousel() {
    if (_bannerList.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 130,
      child: PageView.builder(
        itemCount: _bannerList.length,
        controller: PageController(viewportFraction: 0.95),
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final banner = _bannerList[index];
          final String title = banner['title'] as String? ?? '';
          final String subtitle = banner['subtitle'] as String? ?? '';
          final String image = banner['image'] as String? ?? '';

          return Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                // Image frame loader with fallback error state
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.large - 1),
                      child: Image.network(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey,
                                size: 32,
                              ),
                            ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title, style: AppTextStyle.cardTitle),
                      SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _categoriesList.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.95,
      ),
      itemBuilder: (context, index) {
        final category = _categoriesList[index];
        return GestureDetector(
          onTap: () {
            if (!widget.isServiceable) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Booking disabled: BharathFix is only available in Hassan district.',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    SubCategorySelectionScreen(mainCategory: category),
              ),
            );
          },
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Image.asset(
                    category.assetPath ??
                        _resolveAssetIconFromString(category.name, ''),
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.small),
              Text(
                category.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductHorizontalLists() {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _productsList.length,
        itemBuilder: (context, index) {
          final prod = _productsList[index];
          return GestureDetector(
            onTap: () {
              if (!widget.isServiceable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Purchasing disabled: Retail delivery is only available in Hassan district.',
                    ),
                    backgroundColor: Colors.redAccent,
                  ),
                );
                return;
              }
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
            child: Container(
              width: 140,
              margin: EdgeInsets.only(right: AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.large - 1),
                        ),
                      ),
                      child: Image.network(
                        prod.image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Center(
                              child: Icon(
                                Icons.broken_image_rounded,
                                color: Colors.grey,
                                size: 24,
                              ),
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prod.name,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.title,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2),
                        Text(
                          prod.subCategory,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            color: AppColors.subtitle,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          prod.price,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
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
      ),
    );
  }
}