import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/services/coupon_service.dart';

void main() {
  group('Scoped Coupon Code Validation Tests (Sales vs Service Bookings)', () {
    final couponService = CouponService();

    test('1. Product Sales Coupon (STORE100) passes for productSale scope and fails for serviceBooking scope', () async {
      // Test productSale scope -> Should succeed
      final resSales = await couponService.validateAndApplyCoupon(
        'STORE100',
        999.0,
        targetScope: CouponScope.productSale,
      );
      expect(resSales['success'], isTrue);
      expect(resSales['discountAmount'], equals(100.0));

      // Test serviceBooking scope -> Should fail with scope mismatch error
      final resBooking = await couponService.validateAndApplyCoupon(
        'STORE100',
        999.0,
        targetScope: CouponScope.serviceBooking,
      );
      expect(resBooking['success'], isFalse);
      expect(resBooking['message'], contains('valid only for Product Purchases'));
    });

    test('2. Service Booking Coupon (FIXFIRST) passes for serviceBooking scope and fails for productSale scope', () async {
      // Test serviceBooking scope -> Should succeed
      final resBooking = await couponService.validateAndApplyCoupon(
        'FIXFIRST',
        499.0,
        targetScope: CouponScope.serviceBooking,
      );
      expect(resBooking['success'], isTrue);
      expect(resBooking['discountAmount'], equals(150.0));

      // Test productSale scope -> Should fail with scope mismatch error
      final resSales = await couponService.validateAndApplyCoupon(
        'FIXFIRST',
        499.0,
        targetScope: CouponScope.productSale,
      );
      expect(resSales['success'], isFalse);
      expect(resSales['message'], contains('valid only for Service Repair Bookings'));
    });

    test('3. High Value Product Sales Coupon (ROOFFER500)', () async {
      final res = await couponService.validateAndApplyCoupon(
        'ROOFFER500',
        6999.0,
        targetScope: CouponScope.productSale,
      );
      expect(res['success'], isTrue);
      expect(res['discountAmount'], equals(500.0));
      expect(res['finalTotal'], equals(6499.0));
    });
  });
}
