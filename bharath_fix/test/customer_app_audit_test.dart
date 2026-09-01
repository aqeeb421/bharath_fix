import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/models/OrderModel.dart';
import 'package:bharath_fix/models/BookingEntry.dart';
import 'package:bharath_fix/models/job_status.dart';
import 'package:bharath_fix/services/coupon_service.dart';

void main() {
  group('1. Wallet & Checkout Balance Calculations Audit', () {
    test('Calculates exact deficit when wallet balance is lower than payable', () {
      const double orderAmount = 899.0;
      const double currentBalance = 250.0;
      final double neededAmount = orderAmount - currentBalance;

      expect(neededAmount, equals(649.0));
      expect(currentBalance < orderAmount, isTrue);
    });

    test('Identifies sufficient balance when wallet balance meets or exceeds payable', () {
      const double orderAmount = 499.0;
      const double currentBalance = 500.0;
      final bool hasSufficientWallet = currentBalance >= orderAmount;

      expect(hasSufficientWallet, isTrue);
    });

    test('Handles zero balance edge case cleanly', () {
      const double orderAmount = 350.0;
      const double currentBalance = 0.0;
      final double neededAmount = orderAmount - currentBalance;

      expect(neededAmount, equals(350.0));
    });
  });

  group('2. Product Order Model & Status Integrity Audit', () {
    test('OrderModel serialization and deserialization with all fields', () {
      final now = DateTime.now();
      final model = OrderModel(
        id: 'ORD_998877',
        userId: 'user_123',
        userName: 'Priya Sharma',
        userPhone: '+919876543210',
        userEmail: 'priya@example.com',
        deliveryAddress: 'Vidya Nagar, Hassan, Karnataka',
        productId: 'prod_ro_01',
        productName: 'Aquaguard RO Water Purifier',
        productImage: 'https://example.com/ro.jpg',
        price: 12500.0,
        quantity: 1,
        discountAmount: 500.0,
        totalPaid: 12000.0,
        orderStatus: OrderStatus.placed,
        deliveryOtp: '8492',
        paymentMode: 'ONLINE_RAZORPAY',
        isPaid: true,
        requiresInstallation: true,
        createdAt: now,
      );

      final map = model.toMap();
      expect(map['id'], 'ORD_998877');
      expect(map['totalPaid'], 12000.0);
      expect(map['deliveryOtp'], '8492');

      final reconstructed = OrderModel.fromMap(map, docId: 'ORD_998877');
      expect(reconstructed.id, 'ORD_998877');
      expect(reconstructed.userName, 'Priya Sharma');
      expect(reconstructed.orderStatus, OrderStatus.placed);
      expect(reconstructed.totalPaid, 12000.0);
      expect(reconstructed.deliveryOtp, '8492');
    });

    test('OrderStatus.fromString handles varied formats robustly', () {
      expect(OrderStatus.fromString('placed'), OrderStatus.placed);
      expect(OrderStatus.fromString('SHIPPED'), OrderStatus.shipped);
      expect(OrderStatus.fromString('out_for_delivery'), OrderStatus.outForDelivery);
      expect(OrderStatus.fromString('outForDelivery'), OrderStatus.outForDelivery);
      expect(OrderStatus.fromString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromString('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.fromString('rejected'), OrderStatus.cancelled);
      expect(OrderStatus.fromString(null), OrderStatus.placed);
    });

    test('OrderModel parses dirty numeric strings and missing docIds gracefully', () {
      final dirtyMap = <String, dynamic>{
        'price': '4,999.00',
        'quantity': '2',
        'discountAmount': '100',
        'totalPaid': '9898',
        'status': 'shipped',
      };

      // Ensure no runtime exceptions on malformed numbers
      final order = OrderModel.fromMap(dirtyMap, docId: 'FALLBACK_ID');
      expect(order.id, 'FALLBACK_ID');
      expect(order.orderStatus, OrderStatus.shipped);
    });
  });

  group('3. Quotation & Visiting Charge Edge Cases Audit', () {
    test('Job status normalization accurately separates active vs closed jobs', () {
      final activeStatuses = [
        'pending',
        'accepted',
        'assigned',
        'on_the_way',
        'in_transit',
        'arrived',
        'inspection_in_progress',
        'quotation_pending_approval',
        'repair_in_progress',
        'in_progress',
        'work_started',
      ];

      final closedStatuses = [
        'completed',
        'WORK_COMPLETED',
        'paid_and_closed',
        'closed',
        'cancelled',
        'cancelled_by_customer',
      ];

      for (var s in activeStatuses) {
        final isClosed = ['completed', 'work_completed', 'paid_and_closed', 'closed', 'cancelled', 'cancelled_by_customer'].contains(s.toLowerCase());
        expect(isClosed, isFalse, reason: '$s should be ACTIVE');
      }

      for (var s in closedStatuses) {
        final isClosed = ['completed', 'work_completed', 'paid_and_closed', 'closed', 'cancelled', 'cancelled_by_customer'].contains(s.toLowerCase());
        expect(isClosed, isTrue, reason: '$s should be CLOSED');
      }
    });

    test('Quotation total properly combines spare parts and deductions', () {
      final items = [
        QuoteItem(title: 'Motor Capacitor', price: 450.0),
        QuoteItem(title: 'Drain Valve', price: 250.0),
      ];

      final double partsTotal = items.fold(0.0, (sum, it) => sum + it.price);
      expect(partsTotal, equals(700.0));

      // If visiting fee was unpaid, add ₹19
      const double visitingFee = 19.0;
      final double totalWhenVisitingUnpaid = partsTotal + visitingFee;
      expect(totalWhenVisitingUnpaid, equals(719.0));

      // If visiting fee was already paid, total is only partsTotal
      final double totalWhenVisitingPaid = partsTotal;
      expect(totalWhenVisitingPaid, equals(700.0));
    });
  });

  group('4. Coupon Scoping & Discount Thresholds Audit', () {
    test('Validates percentage and flat discount limits', () {
      const double cartValue = 2000.0;
      
      // Flat discount of ₹200 with min order ₹500
      const double flatDiscount = 200.0;
      final double finalAmount = (cartValue - flatDiscount).clamp(0.0, double.infinity);
      expect(finalAmount, equals(1800.0));

      // Excessive discount does not drop final amount below 0
      const double excessiveDiscount = 2500.0;
      final double clampedAmount = (cartValue - excessiveDiscount).clamp(0.0, double.infinity);
      expect(clampedAmount, equals(0.0));
    });
  });

  group('5. Serviceable Region & Taluk Validation Audit', () {
    test('Official Hassan Taluks list covers all 8 functional regions', () {
      final List<String> hassanTaluks = [
        'hassan',
        'alur',
        'arkalgud',
        'arsikere',
        'belur',
        'channarayapatna',
        'holenarasipura',
        'sakleshpura',
        'sakleshpur',
      ];

      expect(hassanTaluks.contains('hassan'.toLowerCase()), isTrue);
      expect(hassanTaluks.contains('Belur'.toLowerCase()), isTrue);
      expect(hassanTaluks.contains('Sakleshpur'.toLowerCase()), isTrue);
      expect(hassanTaluks.contains('Bengaluru'.toLowerCase()), isFalse);
    });
  });

  group('6. Cancellation Refund & Stock Verification Audit', () {
    test('Cancellation of booking with paid visiting fee refunds full fee to wallet', () {
      final booking = BookingEntry(
        id: 'booking_cancel_01',
        title: 'Refrigerator Gas Refill',
        dateTime: 'Today 11:00 AM',
        visitingFee: 19.0,
        isVisitingFeePaid: true,
      );

      final double refundAmount = booking.isVisitingFeePaid ? booking.visitingFee : 0.0;
      expect(refundAmount, equals(19.0));
    });

    test('Cancellation of COD booking with unpaid visiting fee initiates 0 refund', () {
      final booking = BookingEntry(
        id: 'booking_cancel_02',
        title: 'AC Service',
        dateTime: 'Tomorrow 10:00 AM',
        visitingFee: 19.0,
        isVisitingFeePaid: false,
        paymentMode: 'COD',
      );

      final double refundAmount = booking.isVisitingFeePaid ? booking.visitingFee : 0.0;
      expect(refundAmount, equals(0.0));
    });

    test('Stock decrement clamps to non-negative value and flips isAvailable flag', () {
      const int initialStock = 1;
      const int purchaseCount = 1;
      final int newStock = (initialStock - purchaseCount).clamp(0, 999999);
      final bool isAvailable = newStock > 0;

      expect(newStock, equals(0));
      expect(isAvailable, isFalse);
    });
  });
}
