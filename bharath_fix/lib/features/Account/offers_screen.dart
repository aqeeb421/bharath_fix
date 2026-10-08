import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class CouponModel {
  final String code;
  final String title;
  final String description;
  final String discountTag;
  final String expiryDate;
  final double minOrderValue;
  final double maxDiscount;
  final bool isPercentage;
  final double discountValue;

  const CouponModel({
    required this.code,
    required this.title,
    required this.description,
    required this.discountTag,
    required this.expiryDate,
    required this.minOrderValue,
    required this.maxDiscount,
    required this.isPercentage,
    required this.discountValue,
  });

  factory CouponModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final code = (data['code'] ?? doc.id).toString();
    final discountType = (data['discountType'] ?? data['type'] ?? 'percentage').toString();
    final isPercentage = discountType == 'percentage' || data['isPercentage'] == true;
    final discountVal = (data['discountValue'] as num? ?? data['value'] as num? ?? 0.0).toDouble();
    final minOrder = (data['minOrderValue'] as num? ?? 0.0).toDouble();
    final maxDisc = (data['maxDiscount'] as num? ?? discountVal).toDouble();
    final desc = (data['description'] ?? 'Special discount coupon').toString();

    String formattedExpiry = 'Limited Period';
    if (data['expiryDate'] is Timestamp) {
      final date = (data['expiryDate'] as Timestamp).toDate();
      formattedExpiry = 'Valid till ${date.day}/${date.month}/${date.year}';
    } else if (data['expiryDate'] is String && data['expiryDate'].toString().isNotEmpty) {
      formattedExpiry = data['expiryDate'].toString();
    }

    final tag = isPercentage ? '${discountVal.toInt()}% OFF' : 'FLAT ₹${discountVal.toInt()} OFF';

    return CouponModel(
      code: code,
      title: data['title']?.toString() ?? '$tag on BharathFix Services',
      description: desc,
      discountTag: tag,
      expiryDate: formattedExpiry,
      minOrderValue: minOrder,
      maxDiscount: maxDisc,
      isPercentage: isPercentage,
      discountValue: discountVal,
    );
  }
}

class OffersScreen extends StatefulWidget {
  final bool isSelectionMode;

  const OffersScreen({
    super.key,
    this.isSelectionMode = false,
  });

  static const List<CouponModel> availableCoupons = [
    CouponModel(
      code: 'BHARATH20',
      title: 'Get 20% OFF on all Home Services',
      description: 'Use code BHARATH20 and get 20% instant discount up to ₹100 on AC, Electrical & Plumbing services.',
      discountTag: '20% OFF',
      expiryDate: 'Valid till 31 Aug 2026',
      minOrderValue: 149.0,
      maxDiscount: 100.0,
      isPercentage: true,
      discountValue: 20.0,
    ),
    CouponModel(
      code: 'FIXFIRST',
      title: 'Flat ₹150 OFF on Your First Booking',
      description: 'Special welcome offer for new BharathFix customers on any service booking above ₹299.',
      discountTag: 'FLAT ₹150 OFF',
      expiryDate: 'Valid for First Booking',
      minOrderValue: 299.0,
      maxDiscount: 150.0,
      isPercentage: false,
      discountValue: 150.0,
    ),
    CouponModel(
      code: 'WELCOME50',
      title: '50% OFF Super Savings Offer',
      description: 'Get massive 50% discount up to ₹200 on all home appliance repairs & inspection visits.',
      discountTag: '50% OFF',
      expiryDate: 'Limited Time Offer',
      minOrderValue: 199.0,
      maxDiscount: 200.0,
      isPercentage: true,
      discountValue: 50.0,
    ),
    CouponModel(
      code: 'FESTIVE25',
      title: 'Festive Season Special 25% OFF',
      description: 'Celebrate with clean homes! Get 25% discount up to ₹120 on house cleaning & painting.',
      discountTag: '25% OFF',
      expiryDate: 'Valid till 15 Aug 2026',
      minOrderValue: 399.0,
      maxDiscount: 120.0,
      isPercentage: true,
      discountValue: 25.0,
    ),
  ];

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
  }

  final TextEditingController _codeController = TextEditingController();

  void _applyCoupon(CouponModel coupon) {
    Clipboard.setData(ClipboardData(text: coupon.code));

    if (widget.isSelectionMode) {
      Navigator.pop(context, coupon.code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Coupon code "${coupon.code}" copied to clipboard!',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleCustomApply() async {
    final text = _codeController.text.trim().toUpperCase();
    if (text.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance.collection('coupons').doc(text).get();
      if (doc.exists && doc.data() != null) {
        final coupon = CouponModel.fromFirestore(doc);
        _applyCoupon(coupon);
        return;
      }
    } catch (_) {}

    final matched = OffersScreen.availableCoupons.firstWhere(
      (c) => c.code == text,
      orElse: () => CouponModel(
        code: text,
        title: 'Special Promo Code',
        description: 'Custom promo discount',
        discountTag: 'SPECIAL',
        expiryDate: 'Valid',
        minOrderValue: 0,
        maxDiscount: 50,
        isPercentage: false,
        discountValue: 50,
      ),
    );

    _applyCoupon(matched);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Offers & Coupons', style: AppTextStyle.sectionHeader),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Search / Promo Input Box
            Container(
              padding: EdgeInsets.all(AppSpacing.small),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: AppColors.title),
                      decoration: InputDecoration(
                        hintText: 'ENTER PROMO CODE',
                        hintStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.subtitle, fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _handleCustomApply,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: AppSpacing.large),

            Text('Best Offers For You', style: AppTextStyle.sectionHeader),
            SizedBox(height: AppSpacing.small),
            Text(
              'Apply promo codes at checkout to get instant discounts on service fees.',
              style: AppTextStyle.subtitle.copyWith(fontSize: 12),
            ),
            SizedBox(height: AppSpacing.medium),

            // 2. Real-Time Coupon Cards List from Firestore
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('coupons').snapshots(),
              builder: (context, snapshot) {
                List<CouponModel> coupons = [];
                if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                  final activeDocs = snapshot.data!.docs.where((doc) {
                    final data = doc.data();
                    return data['isActive'] == null || data['isActive'] == true;
                  }).toList();

                  coupons = activeDocs.map((doc) => CouponModel.fromFirestore(doc)).toList();
                }

                if (coupons.isEmpty) {
                  coupons = OffersScreen.availableCoupons;
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: coupons.length,
                  itemBuilder: (context, index) {
                    final coupon = coupons[index];
                    return _buildCouponCard(coupon);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponCard(CouponModel coupon) {
    return Container(
      margin: EdgeInsets.only(bottom: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Top Header Banner
          Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
            decoration: BoxDecoration(
              color: Color(0xFF000062),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppRadius.large),
                topRight: Radius.circular(AppRadius.large),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_offer_rounded, color: Color(0xFFFFD700), size: 16),
                    SizedBox(width: 6),
                    Text(
                      coupon.discountTag,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Color(0xFFFFD700),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Text(
                  coupon.expiryDate,
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),

          // Main Card Content
          Padding(
            padding: EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            coupon.title,
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: AppColors.title,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            coupon.description,
                            style: AppTextStyle.subtitle.copyWith(fontSize: 12, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppSpacing.medium),
                Divider(color: AppColors.border, height: 1),
                SizedBox(height: AppSpacing.medium),

                // Dashed Code Pill & Action Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF8),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary, width: 1),
                      ),
                      child: Text(
                        coupon.code,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => _applyCoupon(coupon),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary, width: 1.5),
                        ),
                        child: Text(
                          widget.isSelectionMode ? 'APPLY CODE' : 'COPY CODE',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
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
    );
  }
}
