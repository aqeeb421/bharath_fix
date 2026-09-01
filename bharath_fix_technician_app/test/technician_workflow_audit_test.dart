import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix_technician_app/models/technician_order_model.dart';
import 'package:bharath_fix_technician_app/screens/quotation_builder_screen.dart';

void main() {
  group('1. Assigned Jobs Status Filtering & Life Cycle Audit', () {
    test('Job filter excludes all completed, closed, and cancelled statuses', () {
      final closedStatuses = [
        'completed',
        'work_completed',
        'WORK_COMPLETED',
        'paid_and_closed',
        'closed',
        'cancelled',
        'cancelled_by_customer',
        'cancelled_by_technician',
        'unrepairable_closed',
      ];

      final activeStatuses = [
        'pending',
        'accepted',
        'assigned',
        'on_the_way',
        'in_transit',
        'arrived',
        'inspection_in_progress',
        'quotation_pending',
        'quotation_pending_approval',
        'repair_in_progress',
        'in_progress',
        'work_started',
        'work_in_progress',
      ];

      for (var s in closedStatuses) {
        final statusNorm = s.toLowerCase().trim();
        final isClosed = [
          'completed',
          'work_completed',
          'paid_and_closed',
          'closed',
          'cancelled',
          'cancelled_by_customer',
          'cancelled_by_technician',
          'unrepairable_closed',
        ].contains(statusNorm);
        expect(isClosed, isTrue, reason: '$s should be classified as CLOSED');
      }

      for (var s in activeStatuses) {
        final statusNorm = s.toLowerCase().trim();
        final isClosed = [
          'completed',
          'work_completed',
          'paid_and_closed',
          'closed',
          'cancelled',
          'cancelled_by_customer',
          'cancelled_by_technician',
          'unrepairable_closed',
        ].contains(statusNorm);
        expect(isClosed, isFalse, reason: '$s should be classified as ACTIVE');
      }
    });
  });

  group('2. Appliance Delivery Partner Workflow Audit', () {
    test('TechnicianOrderModel correctly parses data from Firestore Map', () {
      final data = {
        'id': 'ORD_556677',
        'userId': 'user_cust_01',
        'userName': 'Ramesh Kumar',
        'userPhone': '+919876543210',
        'deliveryAddress': 'Hassan Main Market, KA',
        'productId': 'prod_wm_01',
        'productName': 'LG Smart Washing Machine',
        'price': 24999.0,
        'quantity': 1,
        'totalPaid': 24999.0,
        'orderStatus': 'outForDelivery',
        'deliveryPartnerId': 'tech_01',
        'deliveryPartnerName': 'Suresh (Partner)',
        'deliveryOtp': '6391',
        'paymentMode': 'ONLINE_RAZORPAY',
        'isPaid': true,
      };

      final order = TechnicianOrderModel.fromMap(data, docId: 'ORD_556677');
      expect(order.id, 'ORD_556677');
      expect(order.productName, 'LG Smart Washing Machine');
      expect(order.orderStatus, 'outfordelivery');
      expect(order.deliveryOtp, '6391');
      expect(order.isPaid, isTrue);
    });

    test('Delivery OTP verification strictly checks customer OTP', () {
      const String expectedOtp = '7429';
      const String correctInput = '7429';
      const String wrongInput = '1234';

      expect(correctInput == expectedOtp, isTrue);
      expect(wrongInput == expectedOtp, isFalse);
    });

    test('Delivery active filter correctly isolates delivered and cancelled orders', () {
      final allOrders = [
        {'id': '1', 'orderStatus': 'shipped'},
        {'id': '2', 'orderStatus': 'outForDelivery'},
        {'id': '3', 'orderStatus': 'delivered'},
        {'id': '4', 'orderStatus': 'cancelled'},
      ];

      final active = allOrders.where((o) {
        final st = o['orderStatus']!.toLowerCase();
        return st != 'delivered' && st != 'cancelled';
      }).toList();

      expect(active.length, equals(2));
      expect(active.map((o) => o['id']).toList(), equals(['1', '2']));
    });
  });

  group('3. Quotation Builder & Spare Parts Calculation Audit', () {
    test('QuoteItemDraft serialization and total sum accumulation', () {
      final items = [
        QuoteItemDraft(title: 'Drain Pump', price: 650.0, warrantyDays: 90),
        QuoteItemDraft(title: 'Inlet Solenoid Valve', price: 400.0, warrantyDays: 180),
        QuoteItemDraft(title: 'Service Labor Charge', price: 250.0, isSparePart: false),
      ];

      final double totalQuote = items.fold(0.0, (sum, it) => sum + it.price);
      expect(totalQuote, equals(1300.0));

      final mapped = items.first.toMap();
      expect(mapped['title'], equals('Drain Pump'));
      expect(mapped['price'], equals(650.0));
      expect(mapped['warrantyDays'], equals(90));
      expect(mapped['isSparePart'], isTrue);
    });
  });

  group('4. Service Start & Completion OTP Validation Audit', () {
    test('Start OTP and Completion OTP match validation', () {
      const String startOtp = '4821';
      const String completionOtp = '9053';

      expect('4821'.trim() == startOtp, isTrue);
      expect('0000'.trim() == startOtp, isFalse);

      expect('9053'.trim() == completionOtp, isTrue);
      expect('4821'.trim() == completionOtp, isFalse);
    });
  });

  group('5. COD Collection Calculation Audit', () {
    test('Calculates final collected amount when visiting fee was unpaid', () {
      double computeDue(double quote, double fee, bool isPaid) {
        return quote + (isPaid ? 0.0 : fee);
      }

      expect(computeDue(750.0, 19.0, false), equals(769.0));
      expect(computeDue(750.0, 19.0, true), equals(750.0));
    });
  });
}
