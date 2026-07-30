// lib/screens/tabs/catalog_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class CatalogTab extends StatefulWidget {
  const CatalogTab({super.key});

  @override
  State<CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<CatalogTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _service = FirebaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'App Catalog Control',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Configure banners, service categories, and retail products dynamically.',
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
              ],
            ),
          ),
        ],
      ),
    );
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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1200 ? 3 : (width > 700 ? 2 : 1);
                  final childAspectRatio = width > 700 ? 1.8 : 2.5;

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
                  final title = data['title'] as String? ?? '';
                  final subtitle = data['subtitle'] as String? ?? '';
                  final image = data['image'] as String? ?? '';

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                          child: Row(
                            children: [
                              if (image.isNotEmpty) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    image,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20),
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(title, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(subtitle, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                              onPressed: () => _showBannerFormDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              onPressed: () async => await _service.deleteBanner(doc.id),
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

  void _showBannerFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: doc != null ? doc['title'] : '');
    final subtitleController = TextEditingController(text: doc != null ? doc['subtitle'] : '');
    final imageController = TextEditingController(text: doc != null ? doc['image'] : '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161230),
          title: Text(doc == null ? 'Create Banner' : 'Edit Banner', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
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
                  decoration: const InputDecoration(labelText: 'Image URL', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                  validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
  }

  // ==================== CATEGORIES SUB-PANEL ====================

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

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 700 ? 2 : 1;
                  final childAspectRatio = width > 700 ? 1.8 : 1.5;

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
                  final iconName = data['iconName'] as String? ?? '';
                  final subCats = data['subCategories'] as List<dynamic>? ?? [];

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                            Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('Icon: $iconName', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: subCats.map((sub) {
                              final sMap = sub as Map<dynamic, dynamic>;
                              return Text(
                                '- ${sMap['name'] ?? ''}',
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, color: Color(0xFF000062), size: 18),
                              onPressed: () => _showCategoryFormDialog(doc),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                              onPressed: () async => await _service.deleteCategory(doc.id),
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

  void _showCategoryFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: doc != null ? doc['name'] : '');
    final iconController = TextEditingController(text: doc != null ? doc['iconName'] : 'kitchen_rounded');
    final subCatsController = TextEditingController();

    if (doc != null) {
      final List<dynamic> subs = doc['subCategories'] as List<dynamic>? ?? [];
      final names = subs.map((s) => s['name'] as String? ?? '').join(', ');
      subCatsController.text = names;
    }

    showDialog(
      context: context,
      builder: (context) {
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
                    controller: subCatsController,
                    maxLines: 3,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Subcategories (Comma separated)',
                      labelStyle: TextStyle(color: Color(0xFFA29EB6)),
                      hintText: 'e.g. Single Door, Double Door, Deep Freezer',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
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

                final String name = nameController.text.trim();
                final String icon = iconController.text.trim();
                final String subsRaw = subCatsController.text.trim();

                // Parsing subcategories
                final subNamesList = subsRaw.isNotEmpty ? subsRaw.split(',').map((s) => s.trim()).toList() : [];
                final List<Map<String, String>> subCategories = [];
                for (var i = 0; i < subNamesList.length; i++) {
                  subCategories.add({
                    'id': 'sub_${i}_${DateTime.now().millisecondsSinceEpoch}',
                    'name': subNamesList[i],
                    'image': 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400',
                  });
                }

                final data = {
                  'name': name,
                  'iconName': icon,
                  'subCategories': subCategories,
                };
                
                final id = doc != null ? doc.id : 'cat_${DateTime.now().millisecondsSinceEpoch}';
                await _service.saveCategory(id, data);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }

  // ==================== PRODUCTS SUB-PANEL ====================

  Widget _buildProductsPanel() {
    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () => _showProductFormDialog(null),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 16),
            label: const Text('Add Product', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder(
            stream: _service.getProductsStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final docs = snapshot.data!.docs;

              return LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final crossAxisCount = width > 1200 ? 3 : (width > 700 ? 2 : 1);
                  final childAspectRatio = width > 700 ? 1.6 : 2.0;

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

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFEAEAEA)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
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
                              Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('Cat: $subCategory', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12)),
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
                              onPressed: () async => await _service.deleteProduct(doc.id),
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

  void _showProductFormDialog(dynamic doc) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: doc != null ? doc['name'] : '');
    final subCatController = TextEditingController(text: doc != null ? doc['subCategory'] : '');
    final priceController = TextEditingController(text: doc != null ? doc['price'] : '');
    final imageController = TextEditingController(text: doc != null ? doc['image'] : '');

    showDialog(
      context: context,
      builder: (context) {
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
                    decoration: const InputDecoration(labelText: 'Product Image URL', labelStyle: TextStyle(color: Color(0xFFA29EB6))),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
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
                final id = doc != null ? doc['id'] : 'prod_${DateTime.now().millisecondsSinceEpoch}';
                final data = {
                  'id': id,
                  'name': nameController.text.trim(),
                  'subCategory': subCatController.text.trim(),
                  'price': priceController.text.trim(),
                  'image': imageController.text.trim(),
                };
                await _service.saveProduct(id, data);
              },
              child: const Text('Save'),
            )
          ],
        );
      },
    );
  }
}
