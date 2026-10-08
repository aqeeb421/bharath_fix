// lib/screens/tabs/catalog_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/image_storage_service.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _AdminGradientPreset {
  final String name;
  final int start;
  final int end;
  const _AdminGradientPreset(this.name, this.start, this.end);
}

class _CatalogTabState extends State<CatalogTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _service = FirebaseService();
  String _productSearchQuery = '';
  String? _selectedMarketCategory;
  bool _viewAllProductsMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'App Catalog & Operations Control',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Configure banner offers, service categories, retail products, and spare part rate cards.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: isMobile ? 12 : 13,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 18),
          
          // Tab bar headers
          TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: const Color(0xFF000062),
            labelColor: const Color(0xFF000062),
            unselectedLabelColor: const Color(0xFF757575),
            labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Home Banner Offers (Gradient)'),
              Tab(text: 'Service Categories'),
              Tab(text: 'Retail Products'),
              Tab(text: 'Spare Parts & Rate Cards'),
            ],
          ),
          const SizedBox(height: 24),

          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOffersPanel(),
                _buildCategoriesPanel(),
                _buildProductsPanel(),
                _buildRateCardsPanel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Image URL Live Preview Box
  Widget _buildImageUrlPreview(String url) {
    if (url.trim().isEmpty) return const SizedBox.shrink();
    final cleanUrl = url.trim();
    final isStorage = cleanUrl.contains('firebasestorage.googleapis.com');
    final isNetlify = cleanUrl.contains('netlify.app');

    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 90,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Image.network(
              cleanUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_rounded, color: Colors.orangeAccent, size: 24),
                    SizedBox(height: 4),
                    Text('Unreachable Image URL', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  ],
                ),
              ),
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.indigoAccent),
                );
              },
            ),
          ),
          Positioned(
            top: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isStorage
                    ? const Color(0xFF00C853).withValues(alpha: 0.85)
                    : isNetlify
                        ? const Color(0xFF1E88E5).withValues(alpha: 0.85)
                        : Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isStorage ? 'Cloud Storage' : isNetlify ? 'Netlify CDN' : 'Web URL',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper: Reusable Image Upload and URL Input Field
  Widget _buildImageUploadField({
    required BuildContext context,
    required TextEditingController controller,
    required StateSetter setDialogState,
    required String subFolder,
    String? itemName,
    String Function()? getItemName,
    String? categoryName,
    bool isDark = true,
    String label = 'Image Web URL',
    bool isRequired = false,
  }) {
    bool isUploading = false;
    return StatefulBuilder(
      builder: (context, setFieldState) {
        final resolvedItemName = getItemName != null ? getItemName() : itemName;
        final previewPath = resolvedItemName != null && resolvedItemName.isNotEmpty
            ? ImageStorageService.formatItemStoragePath(
                subFolder: subFolder,
                itemName: resolvedItemName,
                categoryName: categoryName,
              )
            : null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFA29EB6) : const Color(0xFF111111),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (previewPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '📁 $previewPath',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                            fontSize: 10,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: isUploading
                      ? null
                      : () async {
                          final currentItem = getItemName != null ? getItemName() : itemName;
                          final downloadUrl = await ImageStorageService.pickAndUploadImage(
                            context: context,
                            subFolder: subFolder,
                            itemName: currentItem,
                            categoryName: categoryName,
                            onLoadingChanged: (loading) {
                              setFieldState(() => isUploading = loading);
                              setDialogState(() {});
                            },
                          );
                          if (downloadUrl != null && downloadUrl.isNotEmpty) {
                            controller.text = downloadUrl;
                            setFieldState(() {});
                            setDialogState(() {});
                          }
                        },
                  icon: isUploading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.cloud_upload_rounded, size: 15),
                  label: Text(
                    isUploading ? 'Uploading...' : 'Upload Image',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: controller,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              onChanged: (_) => setDialogState(() {}),
              decoration: InputDecoration(
                hintText: 'Upload image above or paste image URL',
                hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          controller.clear();
                          setFieldState(() {});
                          setDialogState(() {});
                        },
                      )
                    : null,
              ),
              validator: isRequired ? (v) => v == null || v.trim().isEmpty ? 'Image is required' : null : null,
            ),
            _buildImageUrlPreview(controller.text),
          ],
        );
      },
    );
  }

  // Helper: Installation Badge
  Widget _buildInstallationBadge({
    required bool isNeeded,
    required bool isFree,
    required String fee,
  }) {
    if (!isNeeded) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline_rounded, size: 11, color: Colors.grey),
            SizedBox(width: 3),
            Text('No Installation', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    } else if (isFree) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F5E9),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFFA5D6A7)),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.build_rounded, size: 11, color: Color(0xFF2E7D32)),
            SizedBox(width: 3),
            Text('FREE Installation', style: TextStyle(color: Color(0xFF2E7D32), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    } else {
      final feeLabel = fee.isNotEmpty ? fee : '₹299';
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE3F2FD),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF90CAF9)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.build_rounded, size: 11, color: Color(0xFF1565C0)),
            const SizedBox(width: 3),
            Text('Installation: $feeLabel', style: const TextStyle(color: Color(0xFF1565C0), fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
  }

  // Helper: Warning/Confirmation Dialog before Deleting items
  Future<bool> _showDeleteConfirmationDialog({
    required String title,
    required String itemLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161230),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 28),
              SizedBox(width: 10),
              Text('Confirm Deletion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Are you sure you want to delete "$itemLabel"?\n\nThis action cannot be undone and will permanently remove it from the app catalog.',
            style: const TextStyle(color: Color(0xFFA29EB6), fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_forever_rounded, size: 16),
              label: const Text('Delete Permanently'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }


  // ==================== SPECIAL OFFERS & DEALS SUB-PANEL ====================

  static const List<_AdminGradientPreset> _adminGradientPresets = [
    _AdminGradientPreset('Sunset Orange', 0xFFE65100, 0xFFFF8F00),
    _AdminGradientPreset('Royal Sapphire', 0xFF0D47A1, 0xFF0288D1),
    _AdminGradientPreset('Emerald Mint', 0xFF1B5E20, 0xFF43A047),
    _AdminGradientPreset('Purple Orchid', 0xFF4A148C, 0xFF7B1FA2),
    _AdminGradientPreset('Crimson Ruby', 0xFFB71C1C, 0xFFE53935),
    _AdminGradientPreset('Midnight Indigo', 0xFF1A237E, 0xFF3F51B5),
    _AdminGradientPreset('Ocean Teal', 0xFF004D40, 0xFF00897B),
    _AdminGradientPreset('Rose Magenta', 0xFF880E4F, 0xFFD81B60),
    _AdminGradientPreset('Amber Gold', 0xFFD84315, 0xFFFFB300),
    _AdminGradientPreset('Charcoal Dark', 0xFF212121, 0xFF424242),
    _AdminGradientPreset('Electric Cyan', 0xFF006064, 0xFF00ACC1),
    _AdminGradientPreset('Neon Violet', 0xFF311B92, 0xFF6200EA),
  ];

  int _parseOfferAdminColor(dynamic val, int fallback) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is String) {
      String clean = val.trim().replaceAll('#', '').replaceAll('0x', '');
      if (clean.length == 6) clean = 'FF$clean';
      final parsed = int.tryParse(clean, radix: 16);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  IconData _resolveOfferAdminIcon(dynamic iconVal) {
    if (iconVal is IconData) return iconVal;
    if (iconVal is String) {
      switch (iconVal.toLowerCase()) {
        case 'flash_on':
        case 'flash':
        case 'bolt':
          return Icons.flash_on_rounded;
        case 'handyman':
        case 'tools':
        case 'repair':
          return Icons.handyman_rounded;
        case 'verified':
        case 'check':
        case 'shield':
          return Icons.verified_rounded;
        case 'wallet':
        case 'account_balance_wallet':
          return Icons.account_balance_wallet_rounded;
        case 'local_offer':
        case 'discount':
        case 'tag':
          return Icons.local_offer_rounded;
        case 'stars':
        case 'star':
          return Icons.stars_rounded;
        case 'celebration':
        case 'party':
          return Icons.celebration_rounded;
        case 'local_fire_department':
        case 'fire':
          return Icons.local_fire_department_rounded;
        default:
          return Icons.local_fire_department_rounded;
      }
    }
    return Icons.local_fire_department_rounded;
  }

  Widget _buildOffersPanel() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home Banner Offers & Deals (Gradient Cards)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Live promotional banner cards with custom background gradient colors for customer home screen.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: const Color(0xFF757575),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showOfferFormDialog(null),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: const Text('Add Banner Offer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000062),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.getOffersStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Failed to load offers',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.red.shade700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'No Special Offers Yet',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Create dynamic offer cards with gradient color background cards for the home screen.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showOfferFormDialog(null),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add First Offer'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000062),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = data['title'] as String? ?? 'Untitled Offer';
                  final subtitle = data['subtitle'] as String? ?? '';
                  final badge = data['badge'] as String? ?? 'DEAL';
                  final expiry = data['expiry'] as String? ?? 'Limited Period';
                  final coupon = data['couponCode'] as String? ?? '';
                  final cta = data['cta'] as String? ?? 'Explore Now';
                  final actionType = data['actionType'] as String? ?? 'market';
                  final iconName = data['icon'] as String? ?? 'flash_on';
                  final colorStart = _parseOfferAdminColor(data['gradientStart'], 0xFFE65100);
                  final colorEnd = _parseOfferAdminColor(data['gradientEnd'], 0xFFFF8F00);
                  final iconData = _resolveOfferAdminIcon(iconName);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(colorStart), Color(colorEnd)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Color(colorStart).withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(iconData, size: 13, color: Color(colorStart)),
                                        const SizedBox(width: 5),
                                        Text(
                                          badge,
                                          style: TextStyle(
                                            fontFamily: 'Plus Jakarta Sans',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: Color(colorStart),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      expiry,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                                    tooltip: 'Edit Offer & Gradient',
                                    onPressed: () => _showOfferFormDialog(doc),
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(alpha: 0.25),
                                      padding: const EdgeInsets.all(6),
                                      minimumSize: const Size(32, 32),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                                    tooltip: 'Delete Offer',
                                    onPressed: () async {
                                      final confirmed = await _showDeleteConfirmationDialog(
                                        title: 'Delete Special Offer',
                                        itemLabel: title,
                                      );
                                      if (confirmed) {
                                        try {
                                          await _service.deleteOffer(doc.id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('Special Offer deleted.'),
                                                backgroundColor: Color(0xFF00C853),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Failed to delete offer: $e'),
                                                backgroundColor: Colors.redAccent,
                                              ),
                                            );
                                          }
                                        }
                                      }
                                    },
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.redAccent.withValues(alpha: 0.7),
                                      padding: const EdgeInsets.all(6),
                                      minimumSize: const Size(32, 32),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            title,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 12.5,
                                color: Colors.white70,
                                height: 1.3,
                              ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  if (coupon.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.copy_rounded, size: 12, color: Colors.white),
                                          const SizedBox(width: 5),
                                          Text(
                                            'Code: $coupon',
                                            style: const TextStyle(
                                              fontFamily: 'Plus Jakarta Sans',
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'Target: $actionType',
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 10.5,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      cta,
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(colorStart),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, size: 12, color: Color(colorStart)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showOfferFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: doc != null ? doc['title'] : '');
    final subtitleController = TextEditingController(text: doc != null ? doc['subtitle'] : '');
    final badgeController = TextEditingController(text: doc != null ? doc['badge'] : 'SPECIAL OFFER');
    final expiryController = TextEditingController(text: doc != null ? doc['expiry'] : 'Limited Period');
    final couponController = TextEditingController(text: doc != null ? (doc['couponCode'] ?? '') : '');
    final ctaController = TextEditingController(text: doc != null ? (doc['cta'] ?? 'Explore Now') : 'Explore Now');
    String actionType = doc != null ? (doc['actionType'] ?? 'market') : 'market';
    String iconName = doc != null ? (doc['icon'] ?? 'flash_on') : 'flash_on';

    int selectedStart = doc != null ? _parseOfferAdminColor(doc['gradientStart'], 0xFFE65100) : 0xFFE65100;
    int selectedEnd = doc != null ? _parseOfferAdminColor(doc['gradientEnd'], 0xFFFF8F00) : 0xFFFF8F00;
    final startHexController = TextEditingController(
      text: selectedStart.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(),
    );
    final endHexController = TextEditingController(
      text: selectedEnd.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase(),
    );

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161230),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.style_rounded, color: Colors.amberAccent, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    doc == null ? 'Create Special Offer Card' : 'Edit Special Offer Card',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 580,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live Card Preview
                        const Text(
                          'LIVE APP CARD PREVIEW',
                          style: TextStyle(
                            color: Color(0xFFA29EB6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(selectedStart), Color(selectedEnd)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Color(selectedStart).withValues(alpha: 0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(_resolveOfferAdminIcon(iconName), size: 12, color: Color(selectedStart)),
                                        const SizedBox(width: 4),
                                        Text(
                                          badgeController.text.isNotEmpty ? badgeController.text : 'SPECIAL DEAL',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Color(selectedStart),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      expiryController.text.isNotEmpty ? expiryController.text : 'Limited Period',
                                      style: const TextStyle(fontSize: 10, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                titleController.text.isNotEmpty ? titleController.text : 'Offer Headline Title',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                subtitleController.text.isNotEmpty ? subtitleController.text : 'Short description detailing discount savings...',
                                style: const TextStyle(fontSize: 11, color: Colors.white70),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  if (couponController.text.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(5),
                                        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        'Code: ${couponController.text.toUpperCase()}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  else
                                    const SizedBox.shrink(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          ctaController.text.isNotEmpty ? ctaController.text : 'Explore Now',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(selectedStart),
                                          ),
                                        ),
                                        const SizedBox(width: 3),
                                        Icon(Icons.arrow_forward_rounded, size: 11, color: Color(selectedStart)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gradient background picker section
                        const Text(
                          'PICK GRADIENT BACKGROUND COLOR THEME',
                          style: TextStyle(
                            color: Color(0xFFA29EB6),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _adminGradientPresets.map((preset) {
                            final isSelected = selectedStart == preset.start && selectedEnd == preset.end;
                            return InkWell(
                              onTap: () {
                                setDialogState(() {
                                  selectedStart = preset.start;
                                  selectedEnd = preset.end;
                                  startHexController.text = preset.start.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
                                  endHexController.text = preset.end.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase();
                                });
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(preset.start), Color(preset.end)],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? Colors.white : Colors.white24,
                                    width: isSelected ? 2.2 : 0.8,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: Colors.white.withValues(alpha: 0.3),
                                            blurRadius: 6,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isSelected) ...[
                                      const Icon(Icons.check_circle_rounded, size: 13, color: Colors.white),
                                      const SizedBox(width: 4),
                                    ],
                                    Text(
                                      preset.name,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: startHexController,
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Gradient Start (#HEX)',
                                  labelStyle: const TextStyle(color: Color(0xFFA29EB6), fontSize: 12),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Color(selectedStart),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  hintText: 'E65100',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = _parseOfferAdminColor(val, selectedStart);
                                  setDialogState(() => selectedStart = parsed);
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextFormField(
                                controller: endHexController,
                                style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 13),
                                decoration: InputDecoration(
                                  labelText: 'Gradient End (#HEX)',
                                  labelStyle: const TextStyle(color: Color(0xFFA29EB6), fontSize: 12),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: Color(selectedEnd),
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                      ),
                                    ),
                                  ),
                                  hintText: 'FF8F00',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                onChanged: (val) {
                                  final parsed = _parseOfferAdminColor(val, selectedEnd);
                                  setDialogState(() => selectedEnd = parsed);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Form Inputs
                        TextFormField(
                          controller: titleController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Offer Title *',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: 'e.g. Save Flat ₹500 On First Appliance',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: subtitleController,
                          style: const TextStyle(color: Colors.white),
                          onChanged: (_) => setDialogState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Subtitle / Description',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: 'e.g. Water Purifiers, CCTV & Inverters with bundled installation.',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: badgeController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Badge Tag',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                  hintText: 'e.g. MEGA SALE • 40% OFF',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: expiryController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Expiry / Urgency Label',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                  hintText: 'e.g. ⏳ Ends Midnight',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: couponController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setDialogState(() {}),
                                textCapitalization: TextCapitalization.characters,
                                decoration: const InputDecoration(
                                  labelText: 'Coupon Promo Code (Optional)',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                  hintText: 'e.g. ROOFFER500',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: ctaController,
                                style: const TextStyle(color: Colors.white),
                                onChanged: (_) => setDialogState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Button CTA Text',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                  hintText: 'e.g. Claim in Market',
                                  hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: actionType,
                                dropdownColor: const Color(0xFF161230),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Click Action Target',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'market', child: Text('Store / Market Tab')),
                                  DropdownMenuItem(value: 'booking', child: Text('Bookings Tab')),
                                  DropdownMenuItem(value: 'wallet', child: Text('Customer Wallet')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => actionType = val);
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: iconName,
                                dropdownColor: const Color(0xFF161230),
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  labelText: 'Badge Icon',
                                  labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'flash_on', child: Text('⚡ Flash Deal')),
                                  DropdownMenuItem(value: 'handyman', child: Text('🔧 Service & Repair')),
                                  DropdownMenuItem(value: 'verified', child: Text('🛡️ Verified / Assured')),
                                  DropdownMenuItem(value: 'wallet', child: Text('💳 Wallet Perk')),
                                  DropdownMenuItem(value: 'local_offer', child: Text('🏷️ Discount Offer')),
                                  DropdownMenuItem(value: 'stars', child: Text('⭐ Star Special')),
                                  DropdownMenuItem(value: 'celebration', child: Text('🎉 Festive Pack')),
                                  DropdownMenuItem(value: 'local_fire_department', child: Text('🔥 Hot Deal')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setDialogState(() => iconName = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(dialogCtx);

                    final data = {
                      'title': titleController.text.trim(),
                      'subtitle': subtitleController.text.trim(),
                      'badge': badgeController.text.trim().isNotEmpty ? badgeController.text.trim() : 'SPECIAL OFFER',
                      'expiry': expiryController.text.trim().isNotEmpty ? expiryController.text.trim() : 'Limited Period',
                      'couponCode': couponController.text.trim().toUpperCase(),
                      'cta': ctaController.text.trim().isNotEmpty ? ctaController.text.trim() : 'Explore Now',
                      'actionType': actionType,
                      'icon': iconName,
                      'gradientStart': selectedStart,
                      'gradientEnd': selectedEnd,
                    };
                    final id = doc != null ? doc.id : 'offer_${DateTime.now().millisecondsSinceEpoch}';
                    try {
                      await _service.saveOffer(id, data);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(doc == null ? 'Special Offer created!' : 'Special Offer updated!'),
                            backgroundColor: const Color(0xFF00C853),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save offer: $e'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(doc == null ? 'Create Offer' : 'Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== CATEGORIES & SUBCATEGORIES SUB-PANEL ====================

  Widget _buildCategoriesPanel() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showCategoryFormDialog(null),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: _service.getCategoriesStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              if (docs.isEmpty) {
                return Center(
                  child: Text('No categories found.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 900 ? 2 : 1;

                  return GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 320,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final data = doc.data();
                      final name = data['name'] as String? ?? '';
                      final iconName = data['iconName'] as String? ?? '';
                      final catImage = data['image'] as String? ?? '';
                      final subCats = data['subCategories'] as List<dynamic>? ?? [];

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEAEAEA)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Header
                            Row(
                              children: [
                                if (catImage.isNotEmpty) ...[
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      catImage,
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.category_rounded, size: 28, color: Color(0xFF000062)),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                ] else ...[
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF000062).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.category_rounded, size: 24, color: Color(0xFF000062)),
                                  ),
                                  const SizedBox(width: 10),
                                ],
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text('Icon: $iconName • ${subCats.length} Subcategories', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                                  onPressed: () => _showCategoryFormDialog(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () async {
                                    final confirmed = await _showDeleteConfirmationDialog(
                                      title: 'Delete Main Category',
                                      itemLabel: name.isNotEmpty ? name : 'this category',
                                    );
                                    if (confirmed) {
                                      await _service.deleteCategory(doc.id);
                                    }
                                  },
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Text('Subcategories:', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 12)),
                            const SizedBox(height: 8),

                            // Subcategories List
                            Expanded(
                              child: subCats.isEmpty
                                  ? Center(child: Text('No subcategories yet', style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 12)))
                                  : ListView.separated(
                                      itemCount: subCats.length,
                                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                                      itemBuilder: (context, sIdx) {
                                        final sMap = subCats[sIdx] as Map<dynamic, dynamic>;
                                        final subName = sMap['name'] as String? ?? '';
                                        final subImg = (sMap['image'] ?? sMap['placeholderImage']) as String? ?? '';
                                        final catName = doc['name'] as String? ?? '';
                                        final catSlug = ImageStorageService.sanitizeSlug(catName);
                                        final subSlug = ImageStorageService.sanitizeSlug(subName);
                                        final imagePathTag = '$catSlug/$subSlug.png';

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9F9FB),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: const Color(0xFFEEEEEE)),
                                          ),
                                          child: Row(
                                            children: [
                                              if (subImg.isNotEmpty) ...[
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(6),
                                                  child: Image.network(
                                                    subImg,
                                                    width: 36,
                                                    height: 36,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 22, color: Colors.grey),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                              ] else ...[
                                                const Icon(Icons.image_outlined, size: 24, color: Colors.grey),
                                                const SizedBox(width: 10),
                                              ],
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            subName,
                                                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w600),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                                          decoration: BoxDecoration(
                                                            color: const Color(0xFFEEF2FF),
                                                            borderRadius: BorderRadius.circular(4),
                                                            border: Border.all(color: const Color(0xFFC7D2FE), width: 0.5),
                                                          ),
                                                          child: Text(
                                                            '📁 $imagePathTag',
                                                            style: const TextStyle(
                                                              color: Color(0xFF4338CA),
                                                              fontSize: 9.5,
                                                              fontFamily: 'monospace',
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 3),
                                                    _buildInstallationBadge(
                                                      isNeeded: sMap['isInstallationNeeded'] as bool? ?? false,
                                                      isFree: sMap['isInstallationFree'] as bool? ?? true,
                                                      fee: (sMap['installationFee'] ?? '').toString(),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF000062)),
                                                onPressed: () => _showSubCategoryDialog(doc, subIndex: sIdx, initialSub: sMap),
                                              ),
                                              IconButton(
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(4),
                                                icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.redAccent),
                                                onPressed: () async {
                                                  final confirmed = await _showDeleteConfirmationDialog(
                                                    title: 'Delete Subcategory',
                                                    itemLabel: subName.isNotEmpty ? subName : 'this subcategory',
                                                  );
                                                  if (confirmed) {
                                                    final updatedList = List<dynamic>.from(subCats)..removeAt(sIdx);
                                                    await _service.updateCategorySubcategories(doc.id, updatedList);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                            ),

                            const SizedBox(height: 8),

                            // Add Subcategory Button
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _showSubCategoryDialog(doc),
                                icon: const Icon(Icons.add_rounded, size: 14),
                                label: const Text('Add Subcategory', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF000062),
                                  side: const BorderSide(color: Color(0xFF000062)),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSubCategoryDialog(dynamic catDoc, {int? subIndex, Map<dynamic, dynamic>? initialSub}) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: initialSub != null ? (initialSub['name'] as String? ?? '') : '');
    final imageController = TextEditingController(text: initialSub != null ? ((initialSub['image'] ?? initialSub['placeholderImage']) as String? ?? '') : '');
    final descriptionController = TextEditingController(
      text: initialSub != null ? (initialSub['description'] as String? ?? '') : '',
    );
    final visitingFeeController = TextEditingController(
      text: initialSub != null ? (initialSub['visitingFee']?.toString() ?? initialSub['basePrice']?.toString() ?? '₹19') : '₹19',
    );
    final installationFeeController = TextEditingController(
      text: initialSub != null ? (initialSub['installationFee']?.toString() ?? '₹299') : '₹299',
    );

    bool isInstallationNeeded = initialSub != null && initialSub.containsKey('isInstallationNeeded')
        ? (initialSub['isInstallationNeeded'] == true)
        : false;

    bool isInstallationFree = initialSub != null && initialSub.containsKey('isInstallationFree')
        ? (initialSub['isInstallationFree'] == true)
        : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161230),
              title: Text(
                subIndex == null ? 'Add Subcategory / Service' : 'Edit Subcategory / Service',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Subcategory / Service Name',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: 'e.g. Front Load Repair / Split AC Servicing / RO Checkup',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                        ),
                        _buildImageUploadField(
                          context: context,
                          controller: imageController,
                          setDialogState: setDialogState,
                          subFolder: 'categories',
                          categoryName: catDoc != null ? (catDoc['name']?.toString() ?? '') : '',
                          getItemName: () => nameController.text.trim(),
                          label: 'Subcategory Image',
                          isRequired: true,
                          isDark: true,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Service Description & Scope',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: 'e.g. Comprehensive diagnosis, TDS test, and filter cleaning included.',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: visitingFeeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Doorstep Inspection / Visiting Fee',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: '₹19 (Promotional)',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const Divider(color: Colors.white24, height: 24),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Installation Settings (if applicable)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Is Installation Needed Toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Is Installation Required?', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 13)),
                            Switch(
                              value: isInstallationNeeded,
                              activeColor: const Color(0xFF000062),
                              onChanged: (v) => setDialogState(() => isInstallationNeeded = v),
                            ),
                          ],
                        ),
                        if (isInstallationNeeded) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Is Installation FREE?', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 13)),
                              Switch(
                                value: isInstallationFree,
                                activeColor: const Color(0xFF34A853),
                                onChanged: (v) => setDialogState(() => isInstallationFree = v),
                              ),
                            ],
                          ),
                          if (!isInstallationFree) ...[
                            TextFormField(
                              controller: installationFeeController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Installation Fee (e.g. ₹299 / ₹499)',
                                labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                              ),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    Map<String, dynamic> catData = {};
                    String docId = '';
                    if (catDoc is DocumentSnapshot) {
                      docId = catDoc.id;
                      catData = (catDoc.data() as Map<String, dynamic>?) ?? {};
                    } else if (catDoc is Map) {
                      docId = catDoc['id']?.toString() ?? '';
                      catData = Map<String, dynamic>.from(catDoc);
                    }

                    final currentSubCats = List<dynamic>.from(catData['subCategories'] as List<dynamic>? ?? []);
                    final newSubMap = {
                      'id': initialSub != null ? (initialSub['id'] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}') : 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameController.text.trim(),
                      'image': imageController.text.trim(),
                      'placeholderImage': imageController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'visitingFee': visitingFeeController.text.trim().isNotEmpty ? visitingFeeController.text.trim() : '₹19',
                      'basePrice': visitingFeeController.text.trim().isNotEmpty ? visitingFeeController.text.trim() : '₹19',
                      'isInstallationNeeded': isInstallationNeeded,
                      'isInstallationFree': isInstallationFree,
                      'installationFee': installationFeeController.text.trim(),
                    };

                    if (subIndex == null) {
                      currentSubCats.add(newSubMap);
                    } else {
                      if (subIndex < currentSubCats.length) {
                        currentSubCats[subIndex] = newSubMap;
                      } else {
                        currentSubCats.add(newSubMap);
                      }
                    }

                    if (docId.isNotEmpty) {
                      await _service.updateCategorySubcategories(docId, currentSubCats);
                    }
                  },
                  child: const Text('Save Subcategory'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> docData = {};
    String docId = '';
    if (doc is DocumentSnapshot) {
      docId = doc.id;
      docData = (doc.data() as Map<String, dynamic>?) ?? {};
    } else if (doc is Map) {
      docId = doc['id']?.toString() ?? '';
      docData = Map<String, dynamic>.from(doc);
    }

    final nameController = TextEditingController(text: docData['name']?.toString() ?? '');
    final iconController = TextEditingController(text: docData['iconName']?.toString() ?? 'kitchen_rounded');
    final imageController = TextEditingController(text: (docData['iconUrl'] ?? docData['imageUrl'] ?? docData['image'])?.toString() ?? '');
    final defaultVisitingFeeController = TextEditingController(
      text: (docData['defaultVisitingFee'] ?? docData['visitingFee'] ?? '₹19').toString(),
    );

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161230),
              title: Text(doc == null ? 'Create Category' : 'Edit Category', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 480,
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(labelText: 'Category Name', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: iconController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Material Icon Name',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: 'e.g. kitchen_rounded, water_drop_rounded, ac_unit_rounded, videocam_rounded',
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: defaultVisitingFeeController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Standard Doorstep Visiting Fee',
                            labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            hintText: '₹19',
                          ),
                        ),
                        _buildImageUploadField(
                          context: context,
                          controller: imageController,
                          setDialogState: setDialogState,
                          subFolder: 'category_icons',
                          getItemName: () => nameController.text.trim(),
                          label: 'Category Icon (Firebase Storage)',
                          isRequired: false,
                          isDark: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    final String name = nameController.text.trim();
                    final String icon = iconController.text.trim();
                    final String image = imageController.text.trim();
                    final String visitingFee = defaultVisitingFeeController.text.trim().isNotEmpty
                        ? defaultVisitingFeeController.text.trim()
                        : '₹19';

                    final data = {
                      'name': name,
                      'iconName': icon.isNotEmpty ? icon : 'kitchen_rounded',
                      'image': image,
                      'imageUrl': image,
                      'iconUrl': image,
                      'defaultVisitingFee': visitingFee,
                      'isActive': true,
                      'updatedAt': FieldValue.serverTimestamp(),
                    };

                    final id = docId.isNotEmpty ? docId : 'cat_${DateTime.now().millisecondsSinceEpoch}';
                    await _service.saveCategory(id, data);
                  },
                  child: const Text('Save Category'),
                )
              ],
            );
          },
        );
      },
    );
  }

  // ==================== PRODUCTS & MARKET CATEGORIES SUB-PANEL (TWO-TIER) ====================

  IconData _resolveMarketCategoryIcon(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'water_drop_rounded':
      case 'water_drop':
      case 'water':
        return Icons.water_drop_rounded;
      case 'videocam_rounded':
      case 'videocam':
      case 'cctv':
      case 'camera':
        return Icons.videocam_rounded;
      case 'soup_kitchen_rounded':
      case 'soup_kitchen':
      case 'chimney':
        return Icons.soup_kitchen_rounded;
      case 'bolt_rounded':
      case 'bolt':
      case 'stabilizer':
      case 'power':
        return Icons.bolt_rounded;
      case 'build_rounded':
      case 'build':
      case 'tools':
      case 'repair':
      case 'spares':
        return Icons.build_rounded;
      case 'local_fire_department_rounded':
      case 'local_fire_department':
      case 'fire':
      case 'geyser':
        return Icons.local_fire_department_rounded;
      case 'wb_sunny_rounded':
      case 'wb_sunny':
      case 'solar':
      case 'sun':
        return Icons.wb_sunny_rounded;
      case 'ac_unit_rounded':
      case 'ac_unit':
        return Icons.ac_unit_rounded;
      case 'kitchen_rounded':
      case 'kitchen':
        return Icons.kitchen_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  void _showMarketCategoryFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> docData = {};
    String docId = '';
    if (doc is DocumentSnapshot) {
      docId = doc.id;
      docData = (doc.data() as Map<String, dynamic>?) ?? {};
    } else if (doc is Map) {
      docId = doc['id']?.toString() ?? '';
      docData = Map<String, dynamic>.from(doc);
    }

    final nameController = TextEditingController(text: docData['name']?.toString() ?? '');
    final descController = TextEditingController(text: docData['description']?.toString() ?? '');
    final iconController = TextEditingController(text: docData['iconName']?.toString() ?? 'inventory_2_rounded');
    final orderController = TextEditingController(text: (docData['order'] ?? 10).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF161230),
        title: Text(
          doc == null ? 'Create Market Category' : 'Edit Market Category',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Form(
          key: formKey,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Category Name *',
                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                      hintText: 'e.g. Air Conditioners / Solar Solutions',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Description / Tagline',
                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                      hintText: 'e.g. Split, Inverter & Window Air Conditioners',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: iconController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Icon Name',
                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                      hintText: 'e.g. ac_unit_rounded, water_drop_rounded, bolt_rounded',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: orderController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Display Order',
                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                      hintText: '1, 2, 3...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(ctx);
              final id = docId.isNotEmpty ? docId : 'cat_${DateTime.now().millisecondsSinceEpoch}';
              final data = {
                'id': id,
                'name': nameController.text.trim(),
                'description': descController.text.trim(),
                'iconName': iconController.text.trim().isNotEmpty ? iconController.text.trim() : 'inventory_2_rounded',
                'order': int.tryParse(orderController.text.trim()) ?? 10,
                'isActive': true,
              };
              try {
                await _service.saveMarketCategory(id, data);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(doc == null ? 'Category created successfully!' : 'Category updated!'),
                      backgroundColor: const Color(0xFF00C853),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to save category: $e'), backgroundColor: Colors.redAccent),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062), foregroundColor: Colors.white),
            child: Text(doc == null ? 'Create Category' : 'Save Changes'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsPanel() {
    // If Admin toggled "View All Products", show flat catalog
    if (_viewAllProductsMode) {
      return _buildAllProductsFlatView();
    }

    // If Admin drilled into a specific category, show Tier 2 (Category Products Manager)
    if (_selectedMarketCategory != null) {
      return _buildTier2CategoryProductsView();
    }

    // Otherwise, show Tier 1 (Category Hub)
    return _buildTier1CategoryHubView();
  }

  // ==================== TIER 1: CATEGORY HUB VIEW ====================

  Widget _buildTier1CategoryHubView() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getMarketCategoriesStream(),
      builder: (context, catSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _service.getProductsStream(),
          builder: (context, prodSnapshot) {
            if (catSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
            }

            final catDocs = catSnapshot.data?.docs ?? [];
            final prodDocs = prodSnapshot.data?.docs ?? [];

            // Calculate product counts per category
            final Map<String, int> countsByCategory = {};
            for (var p in prodDocs) {
              final sub = (p.data()['subCategory'] as String? ?? '').trim();
              if (sub.isNotEmpty) {
                countsByCategory[sub.toLowerCase()] = (countsByCategory[sub.toLowerCase()] ?? 0) + 1;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title, Description, and Action Buttons
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 800;
                    final headerInfo = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                'Market Product Categories',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF111111),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8EAF6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Tier 1 Hub',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF000062),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Select any category to manage products, update pricing, or add new appliances.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13),
                        ),
                      ],
                    );

                    final actionButtons = Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => setState(() => _viewAllProductsMode = true),
                          icon: const Icon(Icons.list_alt_rounded, size: 16),
                          label: Text('All Products (${prodDocs.length})'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF000062),
                            side: const BorderSide(color: Color(0xFF000062)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _showMarketCategoryFormDialog(null),
                          icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                          label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF000062),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ],
                    );

                    if (isMobile) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          headerInfo,
                          const SizedBox(height: 12),
                          actionButtons,
                        ],
                      );
                    }

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(child: headerInfo),
                        const SizedBox(width: 16),
                        actionButtons,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Category Cards Grid
                if (catDocs.isEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.category_outlined, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No Categories Found',
                            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showMarketCategoryFormDialog(null),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Create First Category'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 1200 ? 3 : (width > 750 ? 2 : 1);

                        return GridView.builder(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            mainAxisExtent: 190,
                          ),
                          itemCount: catDocs.length,
                          itemBuilder: (context, index) {
                            final doc = catDocs[index];
                            final data = doc.data();
                            final catName = data['name'] as String? ?? 'Untitled';
                            final desc = data['description'] as String? ?? 'Appliances & equipment';
                            final iconName = data['iconName'] as String? ?? 'inventory_2_rounded';
                            final icon = _resolveMarketCategoryIcon(iconName);
                            final int count = countsByCategory[catName.toLowerCase()] ?? 0;

                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 10,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () => setState(() => _selectedMarketCategory = catName),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF000062).withValues(alpha: 0.08),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Icon(icon, color: const Color(0xFF000062), size: 24),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  catName,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                    color: const Color(0xFF111111),
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  desc,
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: const Color(0xFF757575),
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                          PopupMenuButton<String>(
                                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey),
                                            onSelected: (val) async {
                                              if (val == 'edit') {
                                                _showMarketCategoryFormDialog(doc);
                                              } else if (val == 'delete') {
                                                final conf = await _showDeleteConfirmationDialog(
                                                  title: 'Delete Category',
                                                  itemLabel: catName,
                                                );
                                                if (conf) {
                                                  await _service.deleteMarketCategory(doc.id);
                                                }
                                              }
                                            },
                                            itemBuilder: (ctx) => const [
                                              PopupMenuItem(value: 'edit', child: Text('Edit Category')),
                                              PopupMenuItem(value: 'delete', child: Text('Delete Category', style: TextStyle(color: Colors.red))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: count > 0 ? const Color(0xFFE8F5E9) : const Color(0xFFF3F4F6),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                count > 0 ? '$count Products' : '0 Products (Empty)',
                                                style: TextStyle(
                                                  color: count > 0 ? const Color(0xFF2E7D32) : Colors.grey.shade600,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                'Manage Products',
                                                style: GoogleFonts.plusJakartaSans(
                                                  color: const Color(0xFF000062),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.arrow_forward_rounded, size: 14, color: Color(0xFF000062)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== TIER 2: CATEGORY PRODUCTS VIEW ====================

  Widget _buildTier2CategoryProductsView() {
    final catName = _selectedMarketCategory!;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _service.getProductsStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));

        final allDocs = snapshot.data!.docs;

        // Filter products specifically belonging to this category
        final categoryDocs = allDocs.where((d) {
          final sub = (d.data()['subCategory'] as String? ?? '').trim().toLowerCase();
          return sub == catName.toLowerCase() || sub.contains(catName.toLowerCase());
        }).toList();

        final filteredDocs = _productSearchQuery.isEmpty
            ? categoryDocs
            : categoryDocs.where((d) {
                final name = (d.data()['name'] as String? ?? '').toLowerCase();
                return name.contains(_productSearchQuery);
              }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Breadcrumb Header & Action Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 850;

                final breadcrumbRow = Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF000062)),
                      tooltip: 'Back to All Categories',
                      onPressed: () => setState(() {
                        _selectedMarketCategory = null;
                        _productSearchQuery = '';
                      }),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _selectedMarketCategory = null),
                                child: Text(
                                  'Categories',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF757575),
                                    fontSize: 13,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                              const Text('  /  ', style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13)),
                              Flexible(
                                child: Text(
                                  catName,
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFF111111),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${categoryDocs.length} products listed in $catName',
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                );

                final searchField = SizedBox(
                  width: isMobile ? double.infinity : 220,
                  height: 40,
                  child: TextField(
                    style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    onChanged: (v) => setState(() => _productSearchQuery = v.toLowerCase().trim()),
                    decoration: InputDecoration(
                      hintText: 'Search $catName...',
                      hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey.shade500, fontSize: 12),
                      prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF000062))),
                    ),
                  ),
                );

                final addBtn = ElevatedButton.icon(
                  onPressed: () => _showProductFormDialog(null, preselectedCategory: catName),
                  icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
                  label: Text(
                    isMobile ? 'Add Product' : 'Add to $catName',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000062),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                );

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      breadcrumbRow,
                      const SizedBox(height: 12),
                      searchField,
                      const SizedBox(height: 8),
                      SizedBox(width: double.infinity, child: addBtn),
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: breadcrumbRow),
                    const SizedBox(width: 12),
                    searchField,
                    const SizedBox(width: 12),
                    addBtn,
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Products Grid
            if (filteredDocs.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _productSearchQuery.isEmpty ? 'No products in $catName yet' : 'No matching products found',
                        style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Click below to list the first item in this category.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _showProductFormDialog(null, preselectedCategory: catName),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text('Add Product to $catName'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062), foregroundColor: Colors.white),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: _buildProductsGridList(filteredDocs),
              ),
          ],
        );
      },
    );
  }

  // ==================== FLAT "ALL PRODUCTS" VIEW ====================

  Widget _buildAllProductsFlatView() {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 750;

            final backBtn = OutlinedButton.icon(
              onPressed: () => setState(() => _viewAllProductsMode = false),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Back to Category Hub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF000062),
                side: const BorderSide(color: Color(0xFF000062)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );

            final searchField = SizedBox(
              width: isMobile ? double.infinity : 260,
              height: 40,
              child: TextField(
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13),
                onChanged: (v) => setState(() => _productSearchQuery = v.toLowerCase().trim()),
                decoration: InputDecoration(
                  hintText: 'Search across all products...',
                  hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 12),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575), size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF000062))),
                ),
              ),
            );

            final addBtn = ElevatedButton.icon(
              onPressed: () => _showProductFormDialog(null),
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
              label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000062),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            );

            if (isMobile) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      backBtn,
                      addBtn,
                    ],
                  ),
                  const SizedBox(height: 12),
                  searchField,
                ],
              );
            }

            return Row(
              children: [
                backBtn,
                const SizedBox(width: 12),
                Expanded(child: searchField),
                const SizedBox(width: 12),
                addBtn,
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.getProductsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
              final allDocs = snapshot.data!.docs;
              final docs = _productSearchQuery.isEmpty
                  ? allDocs
                  : allDocs.where((d) {
                      final name = (d.data()['name'] as String? ?? '').toLowerCase();
                      final sub = (d.data()['subCategory'] as String? ?? '').toLowerCase();
                      return name.contains(_productSearchQuery) || sub.contains(_productSearchQuery);
                    }).toList();

              if (docs.isEmpty) {
                return Center(
                  child: Text('No products found.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                );
              }

              return _buildProductsGridList(docs);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsGridList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 1200 ? 3 : (width > 700 ? 2 : 1);
        final childAspectRatio = width > 700 ? 1.5 : 2.0;

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data();
            final name = data['name'] as String? ?? '';
            final subCategory = data['subCategory'] as String? ?? '';
            final price = data['price'] as String? ?? '';
            final stockQty = (data['stockQuantity'] as num?)?.toInt() ?? -1;
            final inStock = data['inStock'] as bool? ?? true;

            Widget stockBadge;
            if (!inStock || stockQty == 0) {
              stockBadge = _buildStockBadge('Out of Stock', Colors.red.shade50, Colors.red.shade800);
            } else if (stockQty > 0 && stockQty <= 5) {
              stockBadge = _buildStockBadge('Low Stock: $stockQty left', Colors.orange.shade50, Colors.orange.shade900);
            } else if (stockQty > 5) {
              stockBadge = _buildStockBadge('In Stock: $stockQty', Colors.green.shade50, Colors.green.shade800);
            } else {
              stockBadge = const SizedBox.shrink();
            }

            final isInstallationNeeded = data['isInstallationNeeded'] as bool? ?? false;
            final isInstallationFree = data['isInstallationFree'] as bool? ?? true;
            final installationFee = (data['installationFee'] ?? '').toString();

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (!inStock || stockQty == 0) ? Colors.red.shade200 : (stockQty > 0 && stockQty <= 5) ? Colors.orange.shade200 : const Color(0xFFEAEAEA),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (data['imageUrl'] != null || data['image'] != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  (data['imageUrl'] ?? data['image']).toString(),
                                  width: 44,
                                  height: 44,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 24, color: Colors.grey),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 14),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      stockBadge,
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: const Color(0xFFBFDBFE), width: 0.5),
                                    ),
                                    child: Text(
                                      subCategory.isNotEmpty ? subCategory : 'General Appliance',
                                      style: const TextStyle(
                                        color: Color(0xFF1E40AF),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
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
                        const SizedBox(height: 6),
                        _buildInstallationBadge(isNeeded: isInstallationNeeded, isFree: isInstallationFree, fee: installationFee),
                        const SizedBox(height: 8),
                        Text(price, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontWeight: FontWeight.bold, fontSize: 16)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                        onPressed: () => _showProductFormDialog(doc, preselectedCategory: subCategory),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () async {
                          final confirmed = await _showDeleteConfirmationDialog(
                            title: 'Delete Product',
                            itemLabel: name.isNotEmpty ? name : 'this product',
                          );
                          if (confirmed) {
                            try {
                              await _service.deleteProduct(doc.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Product deleted successfully'), backgroundColor: Color(0xFF00C853)),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to delete product: $e'), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStockBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showProductFormDialog(dynamic doc, {String? preselectedCategory}) {
    final formKey = GlobalKey<FormState>();
    Map<String, dynamic> data = {};
    String docId = '';
    if (doc is DocumentSnapshot) {
      docId = doc.id;
      data = (doc.data() as Map<String, dynamic>?) ?? {};
    } else if (doc is Map) {
      docId = doc['id']?.toString() ?? '';
      data = Map<String, dynamic>.from(doc);
    }

    final nameController = TextEditingController(text: data['name']?.toString() ?? '');
    String? selectedCategory = data['subCategory']?.toString() ?? preselectedCategory;
    bool isCustomCategory = false;
    final customCatController = TextEditingController();

    final priceController = TextEditingController(text: data['price']?.toString() ?? '');
    final originalPriceController = TextEditingController(text: data['originalPrice']?.toString() ?? '');
    final imageController = TextEditingController(text: data['image']?.toString() ?? '');
    final descriptionController = TextEditingController(text: data['description']?.toString() ?? '');
    final warrantyController = TextEditingController(text: data['warrantyPeriod']?.toString() ?? '1 Year Comprehensive Warranty');
    final deliveryDaysController = TextEditingController(text: (data['deliveryDays'] ?? 2).toString());
    final stockQtyController = TextEditingController(text: data['stockQuantity']?.toString() ?? '10');
    final installationFeeController = TextEditingController(text: data['installationFee']?.toString() ?? '₹299');

    // Parse specifications map to multi-line string "Key: Value"
    String initialSpecsStr = '';
    if (data['specifications'] is Map) {
      final specEntries = (data['specifications'] as Map).entries.map((e) => '${e.key}: ${e.value}').toList();
      initialSpecsStr = specEntries.join('\n');
    }
    final specsController = TextEditingController(text: initialSpecsStr);

    bool isInStock = data.containsKey('inStock') ? (data['inStock'] == true) : true;
    bool isInstallationNeeded = data.containsKey('isInstallationNeeded')
        ? (data['isInstallationNeeded'] == true)
        : false;

    bool isInstallationFree = data.containsKey('isInstallationFree')
        ? (data['isInstallationFree'] == true)
        : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return StreamBuilder<QuerySnapshot>(
              stream: _service.getMarketCategoriesStream(),
              builder: (context, snapshot) {
                // Gather categories
                final List<String> catList = [
                  'Water Purifier',
                  'CCTV Security Cameras',
                  'Chimney',
                  'Voltage Stabilizers',
                  'Water Purifier Spare Parts',
                  'Geysers (Gas & Electric)',
                  'Solar Solutions',
                ];
                if (snapshot.hasData && snapshot.data != null) {
                  for (var cDoc in snapshot.data!.docs) {
                    final cData = cDoc.data() as Map<String, dynamic>? ?? {};
                    final name = (cData['name'] ?? cDoc.id).toString().trim();
                    if (name.isNotEmpty && !catList.contains(name)) {
                      catList.add(name);
                    }
                  }
                }
                if (selectedCategory != null &&
                    selectedCategory!.isNotEmpty &&
                    !catList.contains(selectedCategory) &&
                    !isCustomCategory) {
                  catList.add(selectedCategory!);
                }

                if ((selectedCategory == null || selectedCategory!.isEmpty) && !isCustomCategory) {
                  selectedCategory = preselectedCategory ?? (catList.isNotEmpty ? catList.first : null);
                }

                final effectiveCategory = isCustomCategory
                    ? customCatController.text.trim()
                    : (selectedCategory ?? '');

                return AlertDialog(
                  backgroundColor: const Color(0xFF161230),
                  title: Text(
                    doc == null ? 'Create Retail Appliance / Product' : 'Edit Retail Appliance / Product',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  content: Form(
                    key: formKey,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextFormField(
                              controller: nameController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Product / Appliance Name',
                                labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                hintText: 'e.g. AquaPure 9-Stage RO / 4CH HD CCTV Kit / 1.5 Ton Split AC',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: isCustomCategory
                                        ? '__custom__'
                                        : (catList.contains(selectedCategory) ? selectedCategory : null),
                                    dropdownColor: const Color(0xFF161230),
                                    style: const TextStyle(color: Colors.white, fontSize: 13),
                                    decoration: const InputDecoration(
                                      labelText: 'Product Category',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                    ),
                                    items: [
                                      ...catList.map((c) => DropdownMenuItem(
                                            value: c,
                                            child: Text(c, overflow: TextOverflow.ellipsis),
                                          )),
                                      const DropdownMenuItem(
                                        value: '__custom__',
                                        child: Text(
                                          '➕ Add Custom Category...',
                                          style: TextStyle(
                                            color: Color(0xFFE5A65E),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setDialogState(() {
                                        if (val == '__custom__') {
                                          isCustomCategory = true;
                                        } else {
                                          isCustomCategory = false;
                                          selectedCategory = val;
                                        }
                                      });
                                    },
                                    validator: (v) {
                                      if (!isCustomCategory && (v == null || v.isEmpty)) {
                                        return 'Please select a category';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: stockQtyController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Stock Units',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                      hintText: '10',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isCustomCategory) ...[
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: customCatController,
                                style: const TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText: 'New Category Name',
                                  labelStyle: const TextStyle(color: Color(0xFFE5A65E)),
                                  hintText: 'e.g. Microwave Ovens / Air Conditioners',
                                  hintStyle: const TextStyle(color: Colors.grey, fontSize: 12),
                                  prefixIcon: const Icon(Icons.add_box_rounded, color: Color(0xFFE5A65E), size: 18),
                                  suffixIcon: IconButton(
                                    icon: const Icon(Icons.close, color: Colors.white60, size: 18),
                                    onPressed: () => setDialogState(() => isCustomCategory = false),
                                  ),
                                ),
                                validator: (v) {
                                  if (isCustomCategory && (v == null || v.trim().isEmpty)) {
                                    return 'Please enter category name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: priceController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Selling Price (e.g. ₹8,499)',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                    ),
                                    validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: originalPriceController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'MRP / Original Price (e.g. ₹12,999)',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            _buildImageUploadField(
                              context: context,
                              controller: imageController,
                              setDialogState: setDialogState,
                              subFolder: 'products',
                              categoryName: effectiveCategory.isNotEmpty ? effectiveCategory : 'products',
                              getItemName: () => nameController.text.trim(),
                              label: 'Product Image',
                              isRequired: true,
                              isDark: true,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: descriptionController,
                              maxLines: 2,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Product Description',
                                labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                hintText: 'Key highlights, capacity, build quality, included accessories...',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: warrantyController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Warranty Period',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                      hintText: '1 Year Comprehensive Warranty',
                                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: deliveryDaysController,
                                    keyboardType: TextInputType.number,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      labelText: 'Estimated Delivery Days',
                                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                      hintText: '2',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: specsController,
                              maxLines: 3,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                labelText: 'Technical Specifications (Key: Value per line)',
                                labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                hintText: 'Capacity: 10 Litres RO+UV\nFilter Stages: 9 Stage Filtration\nPower: 60 Watts',
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('In Stock & Ready for Dispatch', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 14)),
                                Switch(
                                  value: isInStock,
                                  activeColor: const Color(0xFF34A853),
                                  onChanged: (v) => setDialogState(() => isInStock = v),
                                ),
                              ],
                            ),
                            const Divider(color: Colors.white24, height: 24),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Delivery & Installation Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Is Installation Needed?', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 13)),
                                Switch(
                                  value: isInstallationNeeded,
                                  activeColor: const Color(0xFF000062),
                                  onChanged: (v) => setDialogState(() => isInstallationNeeded = v),
                                ),
                              ],
                            ),
                            if (isInstallationNeeded) ...[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Is Installation FREE?', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 13)),
                                  Switch(
                                    value: isInstallationFree,
                                    activeColor: const Color(0xFF34A853),
                                    onChanged: (v) => setDialogState(() => isInstallationFree = v),
                                  ),
                                ],
                              ),
                              if (!isInstallationFree) ...[
                                TextFormField(
                                  controller: installationFeeController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    labelText: 'Installation Fee (e.g. ₹299 / ₹499)',
                                    labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                    ElevatedButton(
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;
                        final finalCategory = isCustomCategory
                            ? customCatController.text.trim()
                            : (selectedCategory ?? '').trim();
                        if (finalCategory.isEmpty) return;

                        Navigator.pop(context);

                        // If user entered a new custom category, also create category document in market_categories
                        if (isCustomCategory) {
                          final newCatId = finalCategory
                              .toLowerCase()
                              .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
                              .replaceAll(RegExp(r'^_+|_+$'), '');
                          await _service.saveMarketCategory(newCatId, {
                            'name': finalCategory,
                            'icon': 'widgets_rounded',
                            'description': '$finalCategory appliances and accessories',
                            'order': 99,
                            'isActive': true,
                          });
                        }

                        final id = docId.isNotEmpty ? docId : 'prod_${DateTime.now().millisecondsSinceEpoch}';
                        final stockQtyVal = int.tryParse(stockQtyController.text.trim()) ?? 10;
                        final deliveryDaysVal = int.tryParse(deliveryDaysController.text.trim()) ?? 2;

                        // Parse specs string into Map
                        final Map<String, String> specsMap = {};
                        final specLines = specsController.text.split('\n');
                        for (var line in specLines) {
                          final parts = line.split(':');
                          if (parts.length >= 2) {
                            final key = parts[0].trim();
                            final val = parts.sublist(1).join(':').trim();
                            if (key.isNotEmpty && val.isNotEmpty) {
                              specsMap[key] = val;
                            }
                          }
                        }

                        final data = {
                          'id': id,
                          'name': nameController.text.trim(),
                          'subCategory': finalCategory,
                          'price': priceController.text.trim(),
                          'originalPrice': originalPriceController.text.trim(),
                          'image': imageController.text.trim(),
                          'description': descriptionController.text.trim(),
                          'warrantyPeriod': warrantyController.text.trim().isNotEmpty
                              ? warrantyController.text.trim()
                              : '1 Year Comprehensive Warranty',
                          'deliveryDays': deliveryDaysVal,
                          'specifications': specsMap,
                          'inStock': isInStock,
                          'stockQuantity': stockQtyVal,
                          'isInstallationNeeded': isInstallationNeeded,
                          'isInstallationFree': isInstallationFree,
                          'installationFee': installationFeeController.text.trim(),
                          'updatedAt': FieldValue.serverTimestamp(),
                        };
                        await _service.saveProduct(id, data);
                      },
                      child: const Text('Save Product'),
                    )
                  ],
                );
              },
            );
          },
        );
      },
    );
  }


  // ==================== SPARE PARTS & RATE CARDS PANEL ====================

  String _selectedCategoryFilter = 'All';

  Widget _buildRateCardsPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 700;
          final headerText = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spare Parts & Rate Cards Catalog',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF111111),
                  fontSize: isMobile ? 16 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage standard spare part prices, warranties, and rate cards grouped by appliance category.',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
              ),
            ],
          );

          final addBtn = ElevatedButton.icon(
            onPressed: () => _showSparePartFormDialog(null),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Spare Part Rate'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF000062),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );

          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                headerText,
                const SizedBox(height: 12),
                SizedBox(width: double.infinity, child: addBtn),
              ],
            );
          }

          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: headerText),
              const SizedBox(width: 16),
              addBtn,
            ],
          );
        }),
        const SizedBox(height: 16),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _service.getSparePartsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text(
                    'No standard spare parts configured. Tap "Add Spare Part Rate" to create your first rate card entry.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
                  ),
                );
              }

              // Group docs by Category
              final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>> grouped = {};
              for (var doc in docs) {
                final cat = (doc.data()['category'] ?? 'General').toString();
                grouped.putIfAbsent(cat, () => []).add(doc);
              }

              final categories = ['All', ...grouped.keys.toList()..sort()];

              // Filtered list
              final displayCategories = _selectedCategoryFilter == 'All'
                  ? grouped.keys.toList()
                  : grouped.keys.where((c) => c.toLowerCase() == _selectedCategoryFilter.toLowerCase()).toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Horizontal Category Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: categories.map((cat) {
                        final count = cat == 'All'
                            ? docs.length
                            : (grouped[cat]?.length ?? 0);
                        final isSelected = _selectedCategoryFilter == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            selected: isSelected,
                            showCheckmark: false,
                            avatar: CircleAvatar(
                              radius: 10,
                              backgroundColor: isSelected ? Colors.white : const Color(0xFF000062).withValues(alpha: 0.1),
                              child: Text(
                                '$count',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? const Color(0xFF000062) : const Color(0xFF000062),
                                ),
                              ),
                            ),
                            label: Text(
                              cat,
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : const Color(0xFF111111),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                            selectedColor: const Color(0xFF000062),
                            backgroundColor: Colors.white,
                            side: BorderSide(
                              color: isSelected ? const Color(0xFF000062) : const Color(0xFFE0E0E0),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter = cat;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Grouped Category Cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: displayCategories.length,
                      itemBuilder: (context, catIndex) {
                        final catName = displayCategories[catIndex];
                        final categoryDocs = grouped[catName] ?? [];

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: const Color(0xFFEAEAEA)),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Header Bar
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF000062).withValues(alpha: 0.04),
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  border: const Border(bottom: BorderSide(color: Color(0xFFEAEAEA))),
                                ),
                                child: Wrap(
                                  alignment: WrapAlignment.spaceBetween,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.category_rounded, color: Color(0xFF000062), size: 18),
                                        const SizedBox(width: 8),
                                        Text(
                                          catName,
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF111111),
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF000062).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Text(
                                            '${categoryDocs.length} Parts',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: const Color(0xFF000062),
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    TextButton.icon(
                                      onPressed: () => _showSparePartFormDialogWithCategory(catName),
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 16, color: Color(0xFF000062)),
                                      label: Text(
                                        'Add $catName Part',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: const Color(0xFF000062),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Spare Parts List / Table
                              LayoutBuilder(
                                builder: (context, cardConstraints) {
                                  final isMobile = cardConstraints.maxWidth < 750;

                                  if (isMobile) {
                                    return ListView.separated(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.all(12),
                                      itemCount: categoryDocs.length,
                                      separatorBuilder: (_, __) => const Divider(height: 16),
                                      itemBuilder: (context, docIndex) {
                                        final doc = categoryDocs[docIndex];
                                        final data = doc.data();
                                        final name = data['partName'] ?? data['title'] ?? 'Spare Part';
                                        final price = (data['price'] as num? ?? data['standardPrice'] as num? ?? 0.0).toDouble();
                                        final warrantyDays = data['warrantyDays'] ?? 90;
                                        final description = data['description'] ?? 'Standard component replacement';

                                        return Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF9FAFC),
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: const Color(0xFFEAEAEA)),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF000062)),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      name,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: const Color(0xFF111111),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    '₹${price.toStringAsFixed(0)}',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: const Color(0xFF34A853),
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                description,
                                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue.withValues(alpha: 0.08),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      '🛡️ $warrantyDays Days',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: Colors.blue.shade800,
                                                        fontSize: 11,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        tooltip: 'Edit Spare Part',
                                                        icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                                                        onPressed: () => _showSparePartFormDialog(doc),
                                                        visualDensity: VisualDensity.compact,
                                                      ),
                                                      IconButton(
                                                        tooltip: 'Delete Spare Part',
                                                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                        onPressed: () => _service.deleteSparePart(doc.id),
                                                        visualDensity: VisualDensity.compact,
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  return SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(minWidth: cardConstraints.maxWidth),
                                      child: DataTable(
                                        columnSpacing: 28,
                                        horizontalMargin: 16,
                                        headingRowHeight: 40,
                                        dataRowMinHeight: 48,
                                        dataRowMaxHeight: 56,
                                        headingRowColor: WidgetStateProperty.all(Colors.transparent),
                                        columns: [
                                          DataColumn(label: Text('Part Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('Standard Rate', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('Warranty', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('Description', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontWeight: FontWeight.bold, fontSize: 12))),
                                          DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF555555), fontWeight: FontWeight.bold, fontSize: 12))),
                                        ],
                                        rows: categoryDocs.map((doc) {
                                          final data = doc.data();
                                          final name = data['partName'] ?? data['title'] ?? 'Spare Part';
                                          final price = (data['price'] as num? ?? data['standardPrice'] as num? ?? 0.0).toDouble();
                                          final warrantyDays = data['warrantyDays'] ?? 90;
                                          final description = data['description'] ?? 'Standard component replacement';

                                          return DataRow(
                                            cells: [
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.build_circle_outlined, size: 16, color: Color(0xFF000062)),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      name,
                                                      style: GoogleFonts.plusJakartaSans(
                                                        color: const Color(0xFF111111),
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  '₹${price.toStringAsFixed(0)}',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    color: const Color(0xFF34A853),
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                  decoration: BoxDecoration(
                                                    color: Colors.blue.withValues(alpha: 0.08),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    '🛡️ $warrantyDays Days',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      color: Colors.blue.shade800,
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              DataCell(
                                                Text(
                                                  description,
                                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              DataCell(
                                                Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    IconButton(
                                                      tooltip: 'Edit Spare Part',
                                                      icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                                                      onPressed: () => _showSparePartFormDialog(doc),
                                                    ),
                                                    IconButton(
                                                      tooltip: 'Delete Spare Part',
                                                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                                      onPressed: () async {
                                                        final confirmed = await _showDeleteConfirmationDialog(
                                                          title: 'Delete Spare Part',
                                                          itemLabel: name.toString().isNotEmpty ? name.toString() : 'this item',
                                                        );
                                                        if (confirmed) {
                                                          await _service.deleteSparePart(doc.id);
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSparePartFormDialogWithCategory(String defaultCat) {
    _showSparePartFormDialog(null, initialCategory: defaultCat);
  }

  void _showSparePartFormDialog(dynamic doc, {String? initialCategory}) {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic>? data = doc != null
        ? (doc.data() is Map ? Map<String, dynamic>.from(doc.data() as Map) : null)
        : null;

    final partNameController = TextEditingController(text: data != null ? (data['partName'] ?? data['title'] ?? '') : '');
    final priceController = TextEditingController(text: data != null ? (data['price'] ?? data['standardPrice'] ?? '').toString() : '');
    final warrantyController = TextEditingController(text: data != null ? (data['warrantyDays'] ?? 90).toString() : '90');
    final descriptionController = TextEditingController(text: data != null ? (data['description'] ?? '') : '');
    final imageController = TextEditingController(text: data != null ? (data['image'] ?? data['bannerImage'] ?? '') : '');
    final installationFeeController = TextEditingController(text: data != null ? (data['installationFee']?.toString() ?? '₹299') : '₹299');
    
    String selectedCategory = data != null ? (data['category'] ?? 'Washing Machine') : (initialCategory ?? 'Washing Machine');
    bool isInstallationNeeded = data != null && data.containsKey('isInstallationNeeded')
        ? (data['isInstallationNeeded'] == true)
        : false;

    bool isInstallationFree = data != null && data.containsKey('isInstallationFree')
        ? (data['isInstallationFree'] == true)
        : true;

    final categories = [
      'Washing Machine',
      'Refrigerator',
      'Water Purifier',
      'AC Repair',
      'Kitchen Chimney',
      'Air Cooler',
      'Geyser',
      'Microwave Oven',
      'Electrician',
      'Plumbing',
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text(doc == null ? 'Add Standard Spare Part Rate' : 'Edit Spare Part Rate', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Appliance Category', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        value: categories.contains(selectedCategory) ? selectedCategory : categories.first,
                        decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: categories.map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => selectedCategory = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Text('Spare Part / Service Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: partNameController,
                        decoration: const InputDecoration(hintText: 'e.g. Drain Pump Motor / Capacitor 36uF', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        validator: (v) => v == null || v.isEmpty ? 'Part name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Standard Rate (₹)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'e.g. 650', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Warranty (Days)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: warrantyController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(hintText: 'e.g. 90', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      _buildImageUploadField(
                        context: context,
                        controller: imageController,
                        setDialogState: setDialogState,
                        subFolder: 'spare_parts',
                        getItemName: () => '$selectedCategory ${partNameController.text.trim()}'.trim(),
                        label: 'Part Image',
                        isRequired: false,
                        isDark: false,
                      ),
                      const SizedBox(height: 12),
                      Text('Part Description / Notes', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 2,
                        decoration: const InputDecoration(hintText: 'e.g. Original copper winding with 90-day warranty card', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                      const SizedBox(height: 12),
                      const Text('Installation Options', style: TextStyle(color: Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Is Installation Needed?', style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                          Switch(
                            value: isInstallationNeeded,
                            activeColor: const Color(0xFF000062),
                            onChanged: (v) => setDialogState(() => isInstallationNeeded = v),
                          ),
                        ],
                      ),
                      if (isInstallationNeeded) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Is Installation FREE?', style: TextStyle(color: Color(0xFF555555), fontSize: 12)),
                            Switch(
                              value: isInstallationFree,
                              activeColor: const Color(0xFF34A853),
                              onChanged: (v) => setDialogState(() => isInstallationFree = v),
                            ),
                          ],
                        ),
                        if (!isInstallationFree) ...[
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: installationFeeController,
                            decoration: const InputDecoration(labelText: 'Installation Fee (e.g. ₹299)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    final data = {
                      'partName': partNameController.text.trim(),
                      'title': partNameController.text.trim(),
                      'category': selectedCategory,
                      'price': double.tryParse(priceController.text.trim()) ?? 0.0,
                      'standardPrice': double.tryParse(priceController.text.trim()) ?? 0.0,
                      'warrantyDays': int.tryParse(warrantyController.text.trim()) ?? 90,
                      'description': descriptionController.text.trim(),
                      'image': imageController.text.trim(),
                      'bannerImage': imageController.text.trim(),
                      'isInstallationNeeded': isInstallationNeeded,
                      'isInstallationFree': isInstallationFree,
                      'installationFee': installationFeeController.text.trim(),
                      'isVerified': true,
                    };
                    if (doc == null) {
                      await _service.addSparePart(data);
                    } else {
                      await _service.updateSparePart(doc.id, data);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062), foregroundColor: Colors.white),
                  child: const Text('Save Rate Card Item'),
                ),
              ],
            );
          },
        );
      },
    );
  }

}
