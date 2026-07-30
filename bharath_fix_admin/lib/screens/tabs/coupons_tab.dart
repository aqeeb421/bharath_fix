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
  final _minOrderController = TextEditingController(text: "299");
  String _discountType = 'percentage'; // 'percentage' or 'flat'

  @override
  void dispose() {
    _codeController.dispose();
    _discountController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  void _showAddCouponDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Text('Create Promo Coupon Code', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Coupon Code', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _codeController,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. CLEAN15',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Coupon Code is required' : null,
                    ),
                    const SizedBox(height: 16),

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
                                decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(8)),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _discountType,
                                    dropdownColor: Colors.white,
                                    isExpanded: true,
                                    items: const [
                                      DropdownMenuItem(value: 'percentage', child: Text('% Percent')),
                                      DropdownMenuItem(value: 'flat', child: Text('₹ Flat Amount')),
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
                              Text('Value', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _discountController,
                                keyboardType: TextInputType.number,
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: _discountType == 'percentage' ? '15 (%)' : '150 (₹)',
                                  filled: true,
                                  fillColor: const Color(0xFFF7F8FA),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                                ),
                                validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Min Order Value (₹)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _minOrderController,
                      keyboardType: TextInputType.number,
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. 299',
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final code = _codeController.text.trim().toUpperCase();
                    final val = double.tryParse(_discountController.text) ?? 15.0;
                    final minOrder = double.tryParse(_minOrderController.text) ?? 299.0;

                    Navigator.pop(context);
                    await FirebaseFirestore.instance.collection('coupons').doc(code).set({
                      'code': code,
                      'discountType': _discountType,
                      'discountValue': val,
                      'minOrderValue': minOrder,
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    _codeController.clear();
                    _discountController.clear();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Created Coupon $code successfully!')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF000062)),
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
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Coupons & Promotional Discounts',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create promo codes for customer discounts on service bookings.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _showAddCouponDialog,
                icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Add New Coupon',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000062),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Text('No promo coupons created yet.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    mainAxisExtent: 140,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data();
                    final code = data['code'] ?? docs[index].id;
                    final type = data['discountType'] ?? 'percentage';
                    final val = data['discountValue'] ?? 15;
                    final minOrder = data['minOrderValue'] ?? 299;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF7F8FA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEAEAEA)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: const Color(0xFF000062).withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                child: Text(code, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontWeight: FontWeight.bold, fontSize: 14)),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                                onPressed: () async {
                                  await FirebaseFirestore.instance.collection('coupons').doc(docs[index].id).delete();
                                },
                              ),
                            ],
                          ),
                          Text(
                            type == 'percentage' ? "$val% OFF Discount" : "₹$val OFF Flat Discount",
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF111111)),
                          ),
                          Text(
                            "Min Order Value: ₹$minOrder",
                            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                          ),
                        ],
                      ),
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
}
