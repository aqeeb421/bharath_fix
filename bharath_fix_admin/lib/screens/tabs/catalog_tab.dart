// lib/screens/tabs/catalog_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _service = FirebaseService();
  String _productSearchQuery = '';

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
          Text(
            'App Catalog & Rate Cards Control',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure banners, service categories, spare part rate cards, and retail products dynamically.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),
          
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
              Tab(text: 'Promo Banners'),
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
                _buildBannersPanel(),
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
    return Container(
      margin: const EdgeInsets.only(top: 10),
      height: 80,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        url.trim(),
        fit: BoxFit.cover,
        width: double.infinity,
        height: 80,
        errorBuilder: (_, __, ___) => const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_rounded, color: Colors.orangeAccent, size: 24),
            SizedBox(height: 4),
            Text('Invalid or unreachable Image URL', style: TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
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

  // ==================== BANNERS SUB-PANEL ====================

  Widget _buildBannersPanel() {

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showBannerFormDialog(null),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: const Text('Add Banner', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: _service.getBannersStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data = doc.data();
                  final title = data['title'] as String? ?? '';
                  final subtitle = data['subtitle'] as String? ?? '';
                  final image = data['image'] as String? ?? '';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      leading: image.isNotEmpty
                          ? Image.network(
                              image,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                            )
                          : const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                      title: Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                      subtitle: Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062)),
                            onPressed: () => _showBannerFormDialog(doc),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                            onPressed: () async {
                              final confirmed = await _showDeleteConfirmationDialog(
                                title: 'Delete Banner',
                                itemLabel: title.isNotEmpty ? title : 'this banner',
                              );
                              if (confirmed) {
                                await _service.deleteBanner(doc.id);
                              }
                            },
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

  void _showBannerFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: doc != null ? doc['title'] : '');
    final subtitleController = TextEditingController(text: doc != null ? doc['subtitle'] : '');
    final imageController = TextEditingController(text: doc != null ? doc['image'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161230),
              title: Text(doc == null ? 'Create Banner' : 'Edit Banner', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: subtitleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Subtitle', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                      ),
                      TextFormField(
                        controller: imageController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(labelText: 'Banner Image Web URL', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      _buildImageUrlPreview(imageController.text),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    final data = {
                      'title': titleController.text.trim(),
                      'subtitle': subtitleController.text.trim(),
                      'image': imageController.text.trim(),
                    };
                    final id = doc != null ? doc.id : 'banner_${DateTime.now().millisecondsSinceEpoch}';
                    await _service.saveBanner(id, data);
                  },
                  child: const Text('Save'),
                )
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

                                        return Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                                    width: 32,
                                                    height: 32,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                              ] else ...[
                                                const Icon(Icons.image_outlined, size: 20, color: Colors.grey),
                                                const SizedBox(width: 8),
                                              ],
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      subName,
                                                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF222222), fontSize: 13, fontWeight: FontWeight.w600),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    const SizedBox(height: 2),
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
                subIndex == null ? 'Add Subcategory' : 'Edit Subcategory',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Subcategory Name',
                          labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                          hintText: 'e.g. Front Load / Split AC',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Subcategory name is required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Image Web URL',
                          labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                          hintText: 'https://images.unsplash.com/...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Image URL is required' : null,
                      ),
                      _buildImageUrlPreview(imageController.text),
                      const Divider(color: Colors.white24, height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Default Installation Settings for Subcategory',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Is Installation Needed Toggle
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
                              labelText: 'Default Installation Fee (e.g. ₹299)',
                              labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);

                    final currentSubCats = List<dynamic>.from(catDoc['subCategories'] as List<dynamic>? ?? []);
                    final newSubMap = {
                      'id': initialSub != null ? (initialSub['id'] as String? ?? 'sub_${DateTime.now().millisecondsSinceEpoch}') : 'sub_${DateTime.now().millisecondsSinceEpoch}',
                      'name': nameController.text.trim(),
                      'image': imageController.text.trim(),
                      'placeholderImage': imageController.text.trim(),
                      'isInstallationNeeded': isInstallationNeeded,
                      'isInstallationFree': isInstallationFree,
                      'installationFee': installationFeeController.text.trim(),
                    };

                    if (subIndex == null) {
                      currentSubCats.add(newSubMap);
                    } else {
                      currentSubCats[subIndex] = newSubMap;
                    }

                    await _service.updateCategorySubcategories(catDoc.id, currentSubCats);
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
    final nameController = TextEditingController(text: doc != null ? doc['name'] : '');
    final iconController = TextEditingController(text: doc != null ? doc['iconName'] : 'kitchen_rounded');
    final imageController = TextEditingController(text: doc != null ? (doc['image'] ?? '') : '');

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
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Category Name', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: iconController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Material Icon Name', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: imageController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Main Category Image Web URL (Optional)',
                          labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                          hintText: 'https://images.unsplash.com/...',
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                      _buildImageUrlPreview(imageController.text),
                    ],
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

                    final data = {
                      'name': name,
                      'iconName': icon,
                      'image': image,
                    };
                    
                    final id = doc != null ? doc.id : 'cat_${DateTime.now().millisecondsSinceEpoch}';
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

  // ==================== PRODUCTS SUB-PANEL ====================

  Widget _buildProductsPanel() {
    return Column(
      children: [
        // Header: Search + Add Button
        LayoutBuilder(builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final searchField = TextField(
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
            onChanged: (v) => setState(() => _productSearchQuery = v.toLowerCase().trim()),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575), size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEAEAEA))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF000062))),
            ),
          );
          final addBtn = ElevatedButton.icon(
            onPressed: () => _showProductFormDialog(null),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          );
          if (isMobile) {
            return Column(
              children: [
                searchField,
                const SizedBox(height: 10),
                SizedBox(width: double.infinity, child: addBtn),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: searchField),
              const SizedBox(width: 12),
              addBtn,
            ],
          );
        }),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: _service.getProductsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
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

                      // Stock badge
                      Widget stockBadge;
                      if (!inStock || stockQty == 0) {
                        stockBadge = _buildStockBadge('Out of Stock', Colors.red.shade50, Colors.red.shade800);
                      } else if (stockQty > 0 && stockQty <= 5) {
                        stockBadge = _buildStockBadge('Low Stock: $stockQty left', Colors.orange.shade50, Colors.orange.shade900);
                      } else if (stockQty > 5) {
                        stockBadge = _buildStockBadge('In Stock: $stockQty', Colors.green.shade50, Colors.green.shade800);
                      } else {
                        stockBadge = const SizedBox.shrink(); // no badge if field not set
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
                                    children: [
                                      Expanded(child: Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                      stockBadge,
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text('Cat: $subCategory', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12)),
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
                                  onPressed: () => _showProductFormDialog(doc),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                  onPressed: () async {
                                    final confirmed = await _showDeleteConfirmationDialog(
                                      title: 'Delete Product',
                                      itemLabel: name.isNotEmpty ? name : 'this product',
                                    );
                                    if (confirmed) {
                                      await _service.deleteProduct(doc.id);
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
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStockBadge(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  void _showProductFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final Map<String, dynamic>? data = doc != null
        ? (doc.data() is Map ? Map<String, dynamic>.from(doc.data() as Map) : null)
        : null;

    final nameController = TextEditingController(text: data != null ? (data['name'] ?? '') : '');
    final subCatController = TextEditingController(text: data != null ? (data['subCategory'] ?? '') : '');
    final priceController = TextEditingController(text: data != null ? (data['price'] ?? '') : '');
    final imageController = TextEditingController(text: data != null ? (data['image'] ?? '') : '');
    final stockQtyController = TextEditingController(text: data != null ? (data['stockQuantity']?.toString() ?? '') : '');
    final installationFeeController = TextEditingController(text: data != null ? (data['installationFee']?.toString() ?? '₹299') : '₹299');
    
    bool isInStock = data != null ? (data['inStock'] as bool? ?? true) : true;
    bool isInstallationNeeded = data != null && data.containsKey('isInstallationNeeded')
        ? (data['isInstallationNeeded'] == true)
        : false;

    bool isInstallationFree = data != null && data.containsKey('isInstallationFree')
        ? (data['isInstallationFree'] == true)
        : true;


    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161230),
              title: Text(doc == null ? 'Create Product' : 'Edit Product', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Product Name', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: subCatController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Sub Category Label', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: priceController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Price (e.g. ₹12,999)', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      TextFormField(
                        controller: imageController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(labelText: 'Product Image Web URL', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      _buildImageUrlPreview(imageController.text),
                      const SizedBox(height: 12),
                      // Stock Quantity
                      TextFormField(
                        controller: stockQtyController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Stock Quantity (units)',
                          labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                          hintText: 'Leave blank if unlimited',
                          hintStyle: TextStyle(color: Color(0xFF757575), fontSize: 12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // In Stock Toggle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('In Stock', style: TextStyle(color: Color(0xFFA29EB6), fontSize: 14)),
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
                        child: Text('Installation Options', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                      const SizedBox(height: 6),
                      // Installation Needed Toggle
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
                              labelText: 'Installation Fee (e.g. ₹299)',
                              labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white60))),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    final id = doc != null ? doc['id'] : 'prod_${DateTime.now().millisecondsSinceEpoch}';
                    final stockQtyVal = int.tryParse(stockQtyController.text.trim());
                    final data = {
                      'id': id,
                      'name': nameController.text.trim(),
                      'subCategory': subCatController.text.trim(),
                      'price': priceController.text.trim(),
                      'image': imageController.text.trim(),
                      'inStock': isInStock,
                      'isInstallationNeeded': isInstallationNeeded,
                      'isInstallationFree': isInstallationFree,
                      'installationFee': installationFeeController.text.trim(),
                      if (stockQtyVal != null) 'stockQuantity': stockQtyVal,
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
    final installationFeeController = TextEditingController(text: data != null ? (data['installationFee']?.toString() ?? '₹199') : '₹199');
    
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
                      const SizedBox(height: 12),
                      Text('Image Web URL', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: imageController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(hintText: 'https://images.unsplash.com/...', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                      ),
                      _buildImageUrlPreview(imageController.text),
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
                            decoration: const InputDecoration(labelText: 'Installation Fee (e.g. ₹199)', border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
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
