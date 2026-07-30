import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class CouponService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static const Map<String, Map<String, dynamic>> _staticCoupons = {
    'FIRST50': {
      'isActive': true,
      'minOrderValue': 149.0,
      'discountType': 'percentage',
      'discountValue': 50.0,
      'maxDiscount': 150.0,
    },
    'BF20': {
      'isActive': true,
      'minOrderValue': 199.0,
      'discountType': 'percentage',
      'discountValue': 20.0,
      'maxDiscount': 100.0,
    },
    'BHARATH20': {
      'isActive': true,
      'minOrderValue': 149.0,
      'discountType': 'percentage',
      'discountValue': 20.0,
      'maxDiscount': 100.0,
    },
    'FIXFIRST': {
      'isActive': true,
      'minOrderValue': 299.0,
      'discountType': 'fixed',
      'discountValue': 150.0,
      'maxDiscount': 150.0,
    },
    'WELCOME50': {
      'isActive': true,
      'minOrderValue': 199.0,
      'discountType': 'percentage',
      'discountValue': 50.0,
      'maxDiscount': 200.0,
    },
  };

  Future<Map<String, dynamic>> validateAndApplyCoupon(String rawCode, double cartTotalAmount) async {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) {
      return {'success': false, 'message': 'Please enter a coupon code.'};
    }

    try {
      Map<String, dynamic>? data;

      // 1. Try Firestore first
      try {
        final doc = await _db.collection('coupons').doc(code).get();
        if (doc.exists && doc.data() != null) {
          data = doc.data()!;
        }
      } catch (e) {
        debugPrint('Firestore coupon lookup offline: $e');
      }

      // 2. Fallback to predefined local static coupons
      if (data == null && _staticCoupons.containsKey(code)) {
        data = _staticCoupons[code];
      }

      if (data == null) {
        // Generic custom code fallback (₹40 discount)
        data = {
          'isActive': true,
          'minOrderValue': 0.0,
          'discountType': 'fixed',
          'discountValue': 40.0,
          'maxDiscount': 40.0,
        };
      }

      final bool isActive = data['isActive'] ?? true;
      final double minOrderValue = (data['minOrderValue'] as num?)?.toDouble() ?? 0.0;
      final String discountType = data['discountType'] ?? 'percentage';
      final double discountVal = (data['discountValue'] as num?)?.toDouble() ?? 0.0;
      final double maxDiscount = (data['maxDiscount'] as num?)?.toDouble() ?? discountVal;

      if (!isActive) {
        return {'success': false, 'message': 'This coupon code has expired.'};
      }

      if (cartTotalAmount < minOrderValue) {
        return {
          'success': false,
          'message': 'Minimum order amount for $code is ₹${minOrderValue.toInt()}.'
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
