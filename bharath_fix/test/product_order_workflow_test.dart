import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/models/OrderModel.dart';

void main() {
  group('Product Orders Architecture & Delivery Partner Workflow Tests', () {
    test('1. OrderModel Serialization & Deserialization', () {
      final mapData = {
        'id': 'ORD_2026_9999',
        'userId': 'user_customer_101',
        'userName': 'Bharath Customer',
        'userPhone': '+919876543210',
        'userEmail': 'customer@bharathfix.com',
        'deliveryAddress': 'Flat 302, MG Road, Hassan 573201',
        'productId': 'prod_ro_101',
        'productName': 'Smart Copper RO Water Purifier',
        'productImage': 'https://example.com/ro.jpg',
        'price': 6999.0,
        'quantity': 1,
        'discountAmount': 150.0,
        'totalPaid': 6849.0,
        'orderStatus': 'placed',
        'deliveryOtp': '5829',
        'paymentMode': 'ONLINE_RAZORPAY',
        'isPaid': true,
        'expectedDeliveryDate': 'Delivery by Thursday, Aug 20',
      };

      final order = OrderModel.fromMap(mapData);

      expect(order.id, equals('ORD_2026_9999'));
      expect(order.userId, equals('user_customer_101'));
      expect(order.productName, contains('Smart Copper RO'));
      expect(order.totalPaid, equals(6849.0));
      expect(order.orderStatus, equals(OrderStatus.placed));
      expect(order.deliveryOtp, equals('5829'));

      final serialized = order.toMap();
      expect(serialized['id'], equals('ORD_2026_9999'));
      expect(serialized['orderStatus'], equals('placed'));
      expect(serialized['orderType'], equals('PRODUCT_SALE'));
    });

    test('2. OrderStatus Enum Parsing & Display Strings', () {
      expect(OrderStatus.fromString('placed'), equals(OrderStatus.placed));
      expect(OrderStatus.fromString('shipped'), equals(OrderStatus.shipped));
      expect(OrderStatus.fromString('out_for_delivery'), equals(OrderStatus.outForDelivery));
      expect(OrderStatus.fromString('delivered'), equals(OrderStatus.delivered));
      expect(OrderStatus.fromString('cancelled'), equals(OrderStatus.cancelled));

      expect(OrderStatus.placed.toDisplayString(), equals('ORDER PLACED'));
      expect(OrderStatus.outForDelivery.toDisplayString(), equals('OUT FOR DELIVERY'));
    });

    test('3. Delivery Partner Assignment & Delivery OTP Guard', () {
      final unassignedOrder = const OrderModel(
        id: 'ORD_101',
        userId: 'u1',
        userName: 'Customer A',
        userPhone: '9876543210',
        userEmail: 'c@a.com',
        deliveryAddress: 'Hassan',
        productId: 'p1',
        productName: 'Purifier',
        productImage: '',
        price: 5000,
        totalPaid: 5000,
        deliveryOtp: '8910',
      );

      expect(unassignedOrder.deliveryPartnerId, isNull);

      final assignedOrder = unassignedOrder.copyWith(
        orderStatus: OrderStatus.shipped,
        deliveryPartnerId: 'partner_delivery_9',
        deliveryPartnerName: 'Ramesh Express Delivery',
        deliveryPartnerPhone: '+919988776655',
      );

      expect(assignedOrder.deliveryPartnerId, equals('partner_delivery_9'));
      expect(assignedOrder.deliveryPartnerName, contains('Ramesh Express'));
      expect(assignedOrder.orderStatus, equals(OrderStatus.shipped));
    });

    test('4. Admin Assignment & Installation Opt-in Flags', () {
      final order = const OrderModel(
        id: 'ORD_202',
        userId: 'u2',
        userName: 'Customer B',
        userPhone: '9876543210',
        userEmail: 'cb@a.com',
        deliveryAddress: 'Hassan 573201',
        productId: 'prod_ac_101',
        productName: 'Smart Inverter AC 1.5 Ton',
        productImage: '',
        price: 32000,
        totalPaid: 32000,
        deliveryOtp: '1234',
        requiresInstallation: true,
        assignedByAdmin: true,
      );

      expect(order.requiresInstallation, isTrue);
      expect(order.assignedByAdmin, isTrue);

      final map = order.toMap();
      expect(map['requiresInstallation'], equals(1));
      expect(map['assignedByAdmin'], equals(1));

      final restored = OrderModel.fromMap(map);
      expect(restored.requiresInstallation, isTrue);
      expect(restored.assignedByAdmin, isTrue);
    });
  });
}
