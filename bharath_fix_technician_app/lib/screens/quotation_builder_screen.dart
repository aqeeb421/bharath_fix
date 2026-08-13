import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';

class QuoteItemDraft {
  String title;
  double price;
  bool isSparePart;
  bool isVerified;
  int warrantyDays;

  QuoteItemDraft({
    required this.title,
    required this.price,
    this.isSparePart = true,
    this.isVerified = true,
    this.warrantyDays = 90,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'price': price,
      'isSparePart': isSparePart,
      'isVerified': isVerified,
      'warrantyDays': warrantyDays,
    };
  }
}

class QuotationBuilderScreen extends StatefulWidget {
  final String jobId;
  final String categoryName;
  final List<dynamic>? initialItems;
  final Function(List<QuoteItemDraft>) onSubmitQuote;

  const QuotationBuilderScreen({
    Key? key,
    required this.jobId,
    this.categoryName = 'Washing Machine',
    this.initialItems,
    required this.onSubmitQuote,
  }) : super(key: key);

  @override
  State<QuotationBuilderScreen> createState() => _QuotationBuilderScreenState();
}

class _QuotationBuilderScreenState extends State<QuotationBuilderScreen> {
  final List<QuoteItemDraft> _items = [];

  final TextEditingController _customTitleController = TextEditingController();
  final TextEditingController _customPriceController = TextEditingController();
  final TextEditingController _catalogSearchController =
      TextEditingController();
  String _catalogSearchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialItems != null && widget.initialItems!.isNotEmpty) {
      for (var item in widget.initialItems!) {
        if (item is Map) {
          final title = (item['title'] ?? item['name'] ?? 'Item').toString();
          final price = (item['price'] as num? ?? 0.0).toDouble();
          final isSparePart = item['isSparePart'] == true ||
              item['isSparePart'] == 1 ||
              item['isSparePart'] == null;
          final isVerified = item['isVerified'] == true ||
              item['isVerified'] == 1 ||
              item['isVerified'] == null;
          final warrantyDays = (item['warrantyDays'] as num? ?? 90).toInt();

          if (title.isNotEmpty) {
            _items.add(
              QuoteItemDraft(
                title: title,
                price: price,
                isSparePart: isSparePart,
                isVerified: isVerified,
                warrantyDays: warrantyDays,
              ),
            );
          }
        }
      }
    }
  }

  double get _totalAmount => _items.fold(0, (sum, item) => sum + item.price);

  void _addStandardPart(Map<String, dynamic> partData) {
    final title = (partData['partName'] ?? partData['title'] ?? 'Spare Part')
        .toString();
    final price =
        (partData['price'] as num? ?? partData['standardPrice'] as num? ?? 0.0)
            .toDouble();
    final warrantyDays = (partData['warrantyDays'] as num? ?? 90).toInt();

    // Prevent duplicate additions
    if (_items.any((item) => item.title.toLowerCase() == title.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$title is already added to quotation."),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _items.add(
        QuoteItemDraft(
          title: title,
          price: price,
          isSparePart: true,
          isVerified: true,
          warrantyDays: warrantyDays,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Added $title (₹${price.toStringAsFixed(0)}) to quote."),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _removeItemByTitle(String title) {
    setState(() {
      _items.removeWhere((i) => i.title.toLowerCase() == title.toLowerCase());
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Removed $title from quote."),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _addCustomItem() {
    final title = _customTitleController.text.trim();
    final price = double.tryParse(_customPriceController.text.trim()) ?? 0;

    if (title.isNotEmpty && price > 0) {
      setState(() {
        _items.add(
          QuoteItemDraft(
            title: title,
            price: price,
            isSparePart: true,
            isVerified: false,
            warrantyDays: 30,
          ),
        );
        _customTitleController.clear();
        _customPriceController.clear();
      });
    }
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
  }

  String _normalizeCategory(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.contains('wash') ||
        lower.contains('front load') ||
        lower.contains('top load') ||
        lower.contains('laundry') ||
        lower.contains('spin') ||
        lower.contains('pulsator') ||
        lower.contains('drum')) {
      return 'washing machine';
    }
    if (lower.contains('refri') ||
        lower.contains('fridge') ||
        lower.contains('freezer') ||
        lower.contains('single door') ||
        lower.contains('double door')) {
      return 'refrigerator';
    }
    if (lower.contains('ac') ||
        lower.contains('air condition') ||
        lower.contains('split') ||
        lower.contains('window')) {
      return 'ac repair';
    }
    if (lower.contains('water') ||
        lower.contains('ro') ||
        lower.contains('purifier') ||
        lower.contains('uv') ||
        lower.contains('filter')) {
      return 'water purifier';
    }
    if (lower.contains('chimney') ||
        lower.contains('exhaust') ||
        lower.contains('baffle')) {
      return 'kitchen chimney';
    }
    if (lower.contains('micro') ||
        lower.contains('oven') ||
        lower.contains('magnetron')) {
      return 'microwave oven';
    }
    if (lower.contains('geyser') ||
        lower.contains('heater') ||
        lower.contains('boiler')) {
      return 'geyser';
    }
    if (lower.contains('cooler')) {
      return 'air cooler';
    }
    if (lower.contains('electr') ||
        lower.contains('switch') ||
        lower.contains('mcb') ||
        lower.contains('fan')) {
      return 'electrician';
    }
    if (lower.contains('plumb') ||
        lower.contains('tap') ||
        lower.contains('valve') ||
        lower.contains('pipe') ||
        lower.contains('sink')) {
      return 'plumbing';
    }
    return lower;
  }

  bool _isCategoryMatch(String catalogCat, String jobCat) {
    final normCatalog = _normalizeCategory(catalogCat);
    final normJob = _normalizeCategory(jobCat);

    if (normCatalog == normJob) return true;
    if (catalogCat.toLowerCase().contains(jobCat.toLowerCase()) ||
        jobCat.toLowerCase().contains(catalogCat.toLowerCase()))
      return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          "Create Quotation - ${widget.categoryName}",
          style: AppTextStyle.sectionHeader.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category Header Tag
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified_user_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Official Rate Card Catalog",
                                style: AppTextStyle.cardTitle.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                              Text(
                                "Select verified parts for ${widget.categoryName}. Standard prices & 90-day warranty included.",
                                style: AppTextStyle.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Added Quotation Items Summary Card (Displayed PROMINENTLY AT TOP)
                  Container(
                    decoration: BoxDecoration(
                      color: _items.isNotEmpty
                          ? Colors.green.withValues(alpha: 0.05)
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(
                        color: _items.isNotEmpty
                            ? Colors.green.shade300
                            : AppColors.border,
                        width: _items.isNotEmpty ? 1.5 : 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.shopping_cart_checkout_rounded,
                                  color: AppColors.primary,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Added Quotation Items (${_items.length})",
                                  maxLines: 2,
                                  style: AppTextStyle.sectionHeader.copyWith(
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            if (_items.isNotEmpty)
                              Text(
                                "Subtotal: ₹${_totalAmount.toStringAsFixed(0)}",
                                style: AppTextStyle.cardTitle.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_items.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              "No items added yet. Select spare parts from the rate card below or add custom items.",
                              style: AppTextStyle.subtitle.copyWith(
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              color: AppColors.border,
                            ),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      item.isSparePart
                                          ? Icons.extension_rounded
                                          : Icons.build_circle_rounded,
                                      color: item.isSparePart
                                          ? AppColors.primary
                                          : AppColors.warning,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.title,
                                            style: AppTextStyle.cardTitle
                                                .copyWith(fontSize: 13),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            item.isVerified
                                                ? "🛡️ Verified • ${item.warrantyDays}d Warranty"
                                                : "Custom Item • Service Guarantee",
                                            style: AppTextStyle.subtitle
                                                .copyWith(
                                                  fontSize: 10,
                                                  color: Colors.green.shade700,
                                                ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "₹${item.price.toStringAsFixed(0)}",
                                      style: AppTextStyle.cardTitle.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: const EdgeInsets.all(4),
                                      icon: const Icon(
                                        Icons.remove_circle_outline_rounded,
                                        color: AppColors.error,
                                        size: 20,
                                      ),
                                      onPressed: () => _removeItem(index),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Catalog Header & Search Field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Standard Rate Card Parts",
                        style: AppTextStyle.sectionHeader,
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          widget.categoryName,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Search Bar Input
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      controller: _catalogSearchController,
                      onChanged: (val) => setState(
                        () => _catalogSearchQuery = val.trim().toLowerCase(),
                      ),
                      decoration: InputDecoration(
                        hintText:
                            "Search spare parts or category (e.g. Pump, Motor, AC)...",
                        hintStyle: AppTextStyle.subtitle.copyWith(fontSize: 12),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        suffixIcon: _catalogSearchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _catalogSearchController.clear();
                                  setState(() => _catalogSearchQuery = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance
                        .collection('spare_parts_catalog')
                        .snapshots(),
                    builder: (context, snapshot) {
                      List<Map<String, dynamic>> partsList = [];

                      if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                        final docs = snapshot.data!.docs;

                        // Strict category match by default
                        var filtered = docs.where((doc) {
                          final cat = (doc.data()['category'] ?? '').toString();
                          return _isCategoryMatch(cat, widget.categoryName);
                        }).toList();

                        // Safety fallback: if no items matched exact subcategory, fallback to all catalog docs
                        if (filtered.isEmpty && _catalogSearchQuery.isEmpty) {
                          filtered = docs.toList();
                        }

                        // If user types in search bar, search across all catalog docs
                        if (_catalogSearchQuery.isNotEmpty) {
                          filtered = docs.where((doc) {
                            final data = doc.data();
                            final name =
                                (data['partName'] ?? data['title'] ?? '')
                                    .toString()
                                    .toLowerCase();
                            final cat = (data['category'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(_catalogSearchQuery) ||
                                cat.contains(_catalogSearchQuery);
                          }).toList();
                        }

                        for (var doc in filtered) {
                          partsList.add(doc.data());
                        }
                      }

                      if (partsList.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(
                              AppRadius.medium,
                            ),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            _catalogSearchQuery.isNotEmpty
                                ? "No spare parts found matching '$_catalogSearchQuery'."
                                : "No rate card spare parts listed for ${widget.categoryName} in Admin catalog.",
                            style: AppTextStyle.subtitle,
                            textAlign: TextAlign.center,
                          ),
                        );
                      }

                      return Container(
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: partsList.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: AppColors.border),
                          itemBuilder: (context, index) {
                            final part = partsList[index];
                            final name =
                                (part['partName'] ??
                                         part['title'] ??
                                         'Spare Part')
                                     .toString();
                            final category =
                                (part['category'] ?? widget.categoryName)
                                    .toString();
                            final price =
                                (part['price'] as num? ??
                                        part['standardPrice'] as num? ??
                                        0.0)
                                    .toDouble();
                            final warrantyDays = part['warrantyDays'] ?? 90;
                            final isAdded = _items.any(
                              (i) =>
                                  i.title.toLowerCase() == name.toLowerCase(),
                            );

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.extension_rounded,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: AppTextStyle.cardTitle
                                              .copyWith(fontSize: 13),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 6,
                                                    vertical: 2,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.08),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                category,
                                                style: const TextStyle(
                                                  color: AppColors.primary,
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                "🛡️ Verified • ${warrantyDays}d Warranty",
                                                style: AppTextStyle.subtitle
                                                    .copyWith(
                                                      color: AppColors.success,
                                                      fontSize: 11,
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
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${price.toStringAsFixed(0)}",
                                    style: AppTextStyle.cardTitle.copyWith(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      if (isAdded) {
                                        _removeItemByTitle(name);
                                      } else {
                                        _addStandardPart(part);
                                      }
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isAdded
                                          ? Colors.green.shade100
                                          : AppColors.primary,
                                      side: isAdded
                                          ? BorderSide(
                                              color: Colors.green.shade600,
                                            )
                                          : null,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      minimumSize: const Size(70, 32),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isAdded) ...[
                                          Icon(
                                            Icons.check_circle_rounded,
                                            size: 13,
                                            color: Colors.green.shade800,
                                          ),
                                          const SizedBox(width: 4),
                                        ],
                                        Text(
                                          isAdded ? "Selected" : "+ Add",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isAdded
                                                ? Colors.green.shade800
                                                : Colors.white,
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
                    },
                  ),

                  const SizedBox(height: 20),

                  // Optional Custom Item Input (Safely wrapped)
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      "+ Add Unlisted Custom Item (If Needed)",
                      style: AppTextStyle.subtitle.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          children: [
                            TextField(
                              controller: _customTitleController,
                              style: AppTextStyle.cardTitle.copyWith(
                                fontWeight: FontWeight.normal,
                              ),
                              decoration: InputDecoration(
                                hintText: "Custom Part / Special Charge Name",
                                hintStyle: AppTextStyle.subtitle,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.medium,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _customPriceController,
                                    keyboardType: TextInputType.number,
                                    style: AppTextStyle.cardTitle.copyWith(
                                      fontWeight: FontWeight.normal,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: "Cost (₹)",
                                      hintStyle: AppTextStyle.subtitle,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.medium,
                                        ),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _addCustomItem,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.medium,
                                      ),
                                    ),
                                  ),
                                  child: const Text(
                                    "Add Custom",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
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

          // Fixed Bottom Bar with Theme Colors & No Overflows
          Container(
            padding: const EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.background,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total Quote Amount:", style: AppTextStyle.cardTitle),
                    Text(
                      "₹${_totalAmount.toStringAsFixed(0)}",
                      style: AppTextStyle.mainTitle.copyWith(
                        color: AppColors.primary,
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_items.isNotEmpty) {
                        widget.onSubmitQuote(_items);
                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                    child: const Text(
                      "Send Quotation to Customer",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
