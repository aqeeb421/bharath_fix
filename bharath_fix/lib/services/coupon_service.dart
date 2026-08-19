import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum CouponScope {
  serviceBooking,
  productSale,
  all;

  String toScopeString() {
    switch (this) {
      case CouponScope.serviceBooking:
        return 'SERVICE_BOOKING';
      case CouponScope.productSale:
        return 'PRODUCT_SALE';
      case CouponScope.all:
        return 'ALL';
    }
  }

  static CouponScope fromString(String? val) {
    if (val == null) return CouponScope.all;
    final clean = val.toUpperCase().trim();
    if (clean.contains('PRODUCT') || clean.contains('SALE') || clean.contains('STORE')) {
      return CouponScope.productSale;
    }
    if (clean.contains('SERVICE') || clean.contains('BOOKING') || clean.contains('REPAIR')) {
      return CouponScope.serviceBooking;
    }
    return CouponScope.all;
  }
}

class CouponService {
  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static const Map<String, Map<String, dynamic>> _staticCoupons = {
    // Service Repair Bookings Coupons
    'FIRST50': {
      'isActive': true,
      'minOrderValue': 149.0,
      'discountType': 'percentage',
      'discountValue': 50.0,
      'maxDiscount': 150.0,
      'scope': 'SERVICE_BOOKING',
    },
    'BF20': {
      'isActive': true,
      'minOrderValue': 199.0,
      'discountType': 'percentage',
      'discountValue': 20.0,
      'maxDiscount': 100.0,
      'scope': 'SERVICE_BOOKING',
    },
    'BHARATH20': {
      'isActive': true,
      'minOrderValue': 149.0,
      'discountType': 'percentage',
      'discountValue': 20.0,
      'maxDiscount': 100.0,
      'scope': 'SERVICE_BOOKING',
    },
    'FIXFIRST': {
      'isActive': true,
      'minOrderValue': 299.0,
      'discountType': 'fixed',
      'discountValue': 150.0,
      'maxDiscount': 150.0,
      'scope': 'SERVICE_BOOKING',
    },
    'WELCOME50': {
      'isActive': true,
      'minOrderValue': 199.0,
      'discountType': 'percentage',
      'discountValue': 50.0,
      'maxDiscount': 200.0,
      'scope': 'SERVICE_BOOKING',
    },

    // Product Sales / Store Purchase Coupons
    'STORE100': {
      'isActive': true,
      'minOrderValue': 499.0,
      'discountType': 'fixed',
      'discountValue': 100.0,
      'maxDiscount': 100.0,
      'scope': 'PRODUCT_SALE',
    },
    'ROOFFER500': {
      'isActive': true,
      'minOrderValue': 2999.0,
      'discountType': 'fixed',
      'discountValue': 500.0,
      'maxDiscount': 500.0,
      'scope': 'PRODUCT_SALE',
    },
    'APPLIANCE10': {
      'isActive': true,
      'minOrderValue': 999.0,
      'discountType': 'percentage',
      'discountValue': 10.0,
      'maxDiscount': 1000.0,
      'scope': 'PRODUCT_SALE',
    },
  };

  Future<Map<String, dynamic>> validateAndApplyCoupon(
    String rawCode,
    double cartTotalAmount, {
    CouponScope targetScope = CouponScope.serviceBooking,
  }) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return {'success': false, 'message': 'Please enter a coupon code.'};
    }

    try {
      Map<String, dynamic>? data;

      // 1. Try Firestore first
      try {
        if (_db != null) {
          final doc = await _db!.collection('coupons').doc(code).get();
          if (doc.exists && doc.data() != null) {
            data = doc.data()!;
          }
        }
      } catch (e) {
        debugPrint('Firestore coupon lookup offline: $e');
      }

      // 2. Fallback to predefined local static coupons
      if (data == null && _staticCoupons.containsKey(code)) {
        data = _staticCoupons[code];
      }

      if (data == null) {
        return {'success': false, 'message': 'Invalid coupon code.'};
      }

      final bool isActive = data['isActive'] ?? true;
      final double minOrderValue = (data['minOrderValue'] as num?)?.toDouble() ?? 0.0;
      final String discountType = data['discountType'] ?? 'percentage';
      final double discountVal = (data['discountValue'] as num?)?.toDouble() ?? 0.0;
      final double maxDiscount = (data['maxDiscount'] as num?)?.toDouble() ?? discountVal;
      final CouponScope couponScope = CouponScope.fromString(data['scope'] as String?);

      if (!isActive) {
        return {'success': false, 'message': 'This coupon code has expired.'};
      }

      // Verify scope constraint
      if (targetScope != CouponScope.all && couponScope != CouponScope.all) {
        if (targetScope == CouponScope.productSale && couponScope == CouponScope.serviceBooking) {
          return {
            'success': false,
            'message': 'Coupon $code is valid only for Service Repair Bookings, not Product Purchases.',
          };
        }
        if (targetScope == CouponScope.serviceBooking && couponScope == CouponScope.productSale) {
          return {
            'success': false,
            'message': 'Coupon $code is valid only for Product Purchases, not Service Repair Bookings.',
          };
        }
      }

      if (cartTotalAmount < minOrderValue) {
        return {
          'success': false,
          'message': 'Minimum order amount for $code is ₹${minOrderValue.toInt()}.',
        };
      }

      double discountAmount = 0.0;
      if (discountType == 'percentage') {
        discountAmount = (cartTotalAmount * discountVal) / 100.0;
        if (discountAmount > maxDiscount) discountAmount = maxDiscount;
      } else {
        discountAmount = discountVal;
      }

      if (discountAmount > cartTotalAmount) {
        discountAmount = cartTotalAmount;
      }

      final finalTotal = cartTotalAmount - discountAmount;

      return {
        'success': true,
        'code': code,
        'discountAmount': discountAmount,
        'finalTotal': finalTotal < 0 ? 0.0 : finalTotal,
        'message': 'Coupon $code applied! You saved ₹${discountAmount.toStringAsFixed(0)}.',
      };
    } catch (e) {
      debugPrint("Error validating coupon code: $e");
      return {'success': false, 'message': 'Failed to validate coupon code.'};
    }
  }
}
