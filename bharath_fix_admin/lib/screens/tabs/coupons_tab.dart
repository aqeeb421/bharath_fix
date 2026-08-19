// lib/screens/tabs/coupons_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CouponsTab extends StatefulWidget {
  const CouponsTab({super.key});

  @override
  State<CouponsTab> createState() => _CouponsTabState();
}

class _CouponsTabState extends State<CouponsTab> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountController = TextEditingController();
  final _maxDiscountController = TextEditingController();
  final _minOrderController = TextEditingController(text: "299");
  final _descriptionController = TextEditingController();
  final _usageLimitController = TextEditingController(text: "1");

  String _discountType = 'percentage'; // 'percentage' or 'flat'
  String _targetScope = 'SERVICE_BOOKING'; // 'SERVICE_BOOKING', 'PRODUCT_SALE', 'ALL'
  DateTime? _selectedExpiryDate;
  String _selectedFilterScope = 'All';

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _maxDiscountController.dispose();
    _minOrderController.dispose();
    _descriptionController.dispose();
    _usageLimitController.dispose();
    super.dispose();
  }

  void _showAddCouponDialog() {
    _selectedExpiryDate = null;
    _discountType = 'percentage';
    _targetScope = 'SERVICE_BOOKING';
    _codeController.clear();
    _discountController.clear();
    _maxDiscountController.clear();
    _minOrderController.text = "299";
    _descriptionController.clear();
    _usageLimitController.text = "1";

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF000062).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.local_offer_rounded, color: Color(0xFF000062), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Create Promo Coupon',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Coupon Code
                        Text('Coupon Code', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _codeController,
                          textCapitalization: TextCapitalization.characters,
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: 'e.g. REPAIR20 or STORE100',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Coupon Code is required' : null,
                        ),
                        const SizedBox(height: 16),

                        // Scope Selector (Service Bookings vs Product Sales)
                        Text('Applicable For (Scope)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FA),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _targetScope,
                              dropdownColor: Colors.white,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                  value: 'SERVICE_BOOKING',
                                  child: Row(
                                    children: [
                                      Icon(Icons.bolt_rounded, size: 18, color: Color(0xFF000062)),
                                      SizedBox(width: 8),
                                      Text('Service Repair Bookings Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'PRODUCT_SALE',
                                  child: Row(
                                    children: [
                                      Icon(Icons.inventory_2_rounded, size: 18, color: Color(0xFF00C853)),
                                      SizedBox(width: 8),
                                      Text('Product Retail Sales Only', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'ALL',
                                  child: Row(
                                    children: [
                                      Icon(Icons.stars_rounded, size: 18, color: Color(0xFF7C4DFF)),
                                      SizedBox(width: 8),
                                      Text('Universal (Both Services & Sales)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) => setDialogState(() => _targetScope = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Discount Type & Value Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Discount Type', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12),
                                    decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: _discountType,
                                        dropdownColor: Colors.white,
                                        isExpanded: true,
                                        items: const [
                                          DropdownMenuItem(value: 'percentage', child: Text('% Percent', style: TextStyle(fontSize: 13))),
                                          DropdownMenuItem(value: 'flat', child: Text('₹ Flat (₹)', style: TextStyle(fontSize: 13))),
                                        ],
                                        onChanged: (val) => setDialogState(() => _discountType = val!),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Discount Value', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _discountController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: _discountType == 'percentage' ? 'e.g. 20 (%)' : 'e.g. 150 (₹)',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F8FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Max Discount Cap (for %) & Min Order Value Row
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Max Discount Cap (₹)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _maxDiscountController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 250 (Optional)',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F8FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Min Order Value (₹)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _minOrderController,
                                    keyboardType: TextInputType.number,
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                                    decoration: InputDecoration(
                                      hintText: 'e.g. 299',
                                      hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                                      filled: true,
                                      fillColor: const Color(0xFFF7F8FA),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    ),
                                    validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Expiry Date Picker
                        Text('Expiry Date', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setDialogState(() => _selectedExpiryDate = picked);
                            }
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedExpiryDate != null
                                      ? 'Expires on: ${_selectedExpiryDate!.day}/${_selectedExpiryDate!.month}/${_selectedExpiryDate!.year}'
                                      : 'No Expiry (Never Expires)',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    color: _selectedExpiryDate != null ? const Color(0xFF111111) : const Color(0xFF757575),
                                    fontWeight: _selectedExpiryDate != null ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_rounded, size: 16, color: Color(0xFF000062)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Short Description / Tagline
                        Text('Campaign Description / Tagline', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _descriptionController,
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'e.g. 20% off on all AC repair & servicing bookings',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 12),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Usage Limit Per User
                        Text('Usage Limit per User', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _usageLimitController,
                          keyboardType: TextInputType.number,
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'e.g. 1 (max uses per customer)',
                            hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF757575)),
                            filled: true,
                            fillColor: const Color(0xFFF7F8FA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final code = _codeController.text.trim().toUpperCase();
                    final val = double.tryParse(_discountController.text) ?? 15.0;
                    final minOrder = double.tryParse(_minOrderController.text) ?? 299.0;
                    final maxDisc = double.tryParse(_maxDiscountController.text) ?? val;
                    final desc = _descriptionController.text.trim();
                    final usageLimit = int.tryParse(_usageLimitController.text) ?? 1;

                    Navigator.pop(dialogCtx);
                    await FirebaseFirestore.instance.collection('coupons').doc(code).set({
                      'code': code,
                      'scope': _targetScope,
                      'discountType': _discountType,
                      'discountValue': val,
                      'maxDiscount': maxDisc,
                      'minOrderValue': minOrder,
                      'description': desc.isNotEmpty ? desc : '${_discountType == 'percentage' ? "$val%" : "₹$val"} off',
                      'expiryDate': _selectedExpiryDate != null ? Timestamp.fromDate(_selectedExpiryDate!) : null,
                      'usageLimitPerUser': usageLimit,
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Created Coupon $code successfully!'),
                          backgroundColor: const Color(0xFF000062),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000062),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Save Coupon', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar
          LayoutBuilder(builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 700;
            final headerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Coupons & Promotional Discounts',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF111111),
                    fontSize: isMobile ? 20 : 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Create targeted promo codes for Service Repair Bookings vs. Product Retail Sales.',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF757575),
                    fontSize: 12,
                  ),
                ),
              ],
            );

            final addBtn = ElevatedButton.icon(
              onPressed: _showAddCouponDialog,
              icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
              label: Text(
                'Add New Coupon',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000062),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
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
          const SizedBox(height: 20),

          // Scope Filter Selector Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                _buildFilterPill('All', 'All Coupons'),
                const SizedBox(width: 8),
                _buildFilterPill('SERVICE_BOOKING', '⚡ Service Bookings Only'),
                const SizedBox(width: 8),
                _buildFilterPill('PRODUCT_SALE', '📦 Product Sales Only'),
                const SizedBox(width: 8),
                _buildFilterPill('ALL', '🌟 Universal (Both)'),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Coupons List / Grid
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
                }

                final docs = snapshot.data?.docs ?? [];

                final filteredDocs = docs.where((d) {
                  if (_selectedFilterScope == 'All') return true;
                  final scope = d.data()['scope'] as String? ?? 'ALL';
                  return scope.toUpperCase() == _selectedFilterScope.toUpperCase();
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No promo coupons found for this filter.',
                          style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobile = constraints.maxWidth < 650;
                    return GridView.builder(
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisExtent: isMobile ? 220 : 210,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, index) {
                        final doc = filteredDocs[index];
                        final data = doc.data();
                        final code = data['code'] ?? doc.id;
                        final scope = data['scope'] as String? ?? 'ALL';
                        final type = data['discountType'] ?? 'percentage';
                        final val = data['discountValue'] ?? 15;
                        final maxDiscount = data['maxDiscount'];
                        final minOrder = data['minOrderValue'] ?? 299;
                        final desc = data['description'] as String? ?? '';
                        final isActive = data['isActive'] == true;
                        final expiryTimestamp = data['expiryDate'] as Timestamp?;
                        final expiryDate = expiryTimestamp?.toDate();

                        final isExpired = expiryDate != null && expiryDate.isBefore(DateTime.now());

                        return Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isExpired
                                  ? Colors.red.shade200
                                  : (isActive ? const Color(0xFFEAEAEA) : Colors.grey.shade300),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Top Row: Scope Badge + Active Switch + Delete Button
                              Row(
                                children: [
                                  _buildScopeBadge(scope),
                                  const Spacer(),
                                  // Active Toggle
                                  Transform.scale(
                                    scale: 0.8,
                                    child: Switch(
                                      value: isActive && !isExpired,
                                      activeColor: const Color(0xFF000062),
                                      onChanged: (newVal) async {
                                        await FirebaseFirestore.instance.collection('coupons').doc(doc.id).update({
                                          'isActive': newVal,
                                        });
                                      },
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                    tooltip: 'Delete Coupon',
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (c) => AlertDialog(
                                          title: const Text('Delete Coupon?'),
                                          content: Text('Are you sure you want to permanently delete $code?'),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                                              onPressed: () => Navigator.pop(c, true),
                                              child: const Text('Delete', style: TextStyle(color: Colors.white)),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirm == true) {
                                        await FirebaseFirestore.instance.collection('coupons').doc(doc.id).delete();
                                      }
                                    },
                                  ),
                                ],
                              ),

                              // Code Banner & Discount
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF000062).withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFF000062).withValues(alpha: 0.2)),
                                    ),
                                    child: Text(
                                      code,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: const Color(0xFF000062),
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      type == 'percentage' ? "$val% OFF" : "₹$val FLAT OFF",
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: const Color(0xFF111111),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),

                              if (desc.isNotEmpty)
                                Text(
                                  desc,
                                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                              const Divider(height: 8),

                              // Bottom Row: Constraints & Expiry
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Min: ₹$minOrder ${maxDiscount != null ? '• Cap: ₹$maxDiscount' : ''}",
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11, fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    isExpired
                                        ? "EXPIRED"
                                        : (expiryDate != null ? "Exp: ${expiryDate.day}/${expiryDate.month}/${expiryDate.year}" : "No Expiry"),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: isExpired ? Colors.red : const Color(0xFF757575),
                                      fontSize: 10,
                                      fontWeight: isExpired ? FontWeight.bold : FontWeight.w500,
                                    ),
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
      ),
    );
  }

  Widget _buildFilterPill(String scopeKey, String label) {
    final isSelected = _selectedFilterScope == scopeKey;
    return InkWell(
      onTap: () => setState(() => _selectedFilterScope = scopeKey),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF000062) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF000062) : const Color(0xFFEAEAEA)),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : const Color(0xFF111111),
          ),
        ),
      ),
    );
  }

  Widget _buildScopeBadge(String scope) {
    final s = scope.toUpperCase();
    if (s.contains('SERVICE') || s.contains('BOOKING')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF000062).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF000062)),
            const SizedBox(width: 4),
            Text('SERVICE BOOKINGS', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF000062))),
          ],
        ),
      );
    } else if (s.contains('PRODUCT') || s.contains('SALE')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF00C853).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_rounded, size: 12, color: Color(0xFF00C853)),
            const SizedBox(width: 4),
            Text('PRODUCT SALES', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00C853))),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4DFF).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.stars_rounded, size: 12, color: Color(0xFF7C4DFF)),
          const SizedBox(width: 4),
          Text('UNIVERSAL (BOTH)', style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF7C4DFF))),
        ],
      ),
    );
  }
}
