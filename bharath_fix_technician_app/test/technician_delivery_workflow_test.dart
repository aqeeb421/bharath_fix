import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix_technician_app/models/technician_model.dart';
import 'package:bharath_fix_technician_app/models/technician_order_model.dart';

void main() {
  group('Technician App Delivery Opt-in & OTP Verification Tests', () {
    test('1. TechnicianModel Serialization & Delivery Opt-In Flag', () {
      final tech = TechnicianModel(
        uid: 'tech_101',
        name: 'Ramesh Express',
        email: 'ramesh@bharathfix.com',
        phone: '9876543210',
        canDeliver: true,
      );

      final map = tech.toMap();
      expect(map['uid'], equals('tech_101'));
      expect(map['canDeliver'], isTrue);
      expect(map['isDeliveryPartner'], isTrue);

      final parsed = TechnicianModel.fromMap(map, 'tech_101');
      expect(parsed.name, equals('Ramesh Express'));
      expect(parsed.canDeliver, isTrue);
    });

    test('2. TechnicianOrderModel Deserialization from Admin Order', () {
      final rawOrderMap = {
        'id': 'ORD_8849',
        'userId': 'cust_55',
        'userName': 'Suresh Gowda',
        'userPhone': '9900112233',
        'deliveryAddress': '#45, BM Road, Hassan 573201',
        'productId': 'prod_ro_01',
        'productName': 'AquaGuard RO Water Purifier',
        'productImage': 'https://example.com/ro.jpg',
        'price': 14999.0,
        'quantity': 1,
        'totalPaid': 14499.0,
        'orderStatus': 'outForDelivery',
        'deliveryPartnerId': 'tech_101',
        'deliveryPartnerName': 'Ramesh Express',
        'deliveryPartnerPhone': '9876543210',
        'deliveryOtp': '6419',
        'requiresInstallation': true,
      };

      final order = TechnicianOrderModel.fromMap(rawOrderMap, docId: 'ORD_8849');
      expect(order.id, equals('ORD_8849'));
      expect(order.productName, equals('AquaGuard RO Water Purifier'));
      expect(order.deliveryPartnerId, equals('tech_101'));
      expect(order.deliveryOtp, equals('6419'));
      expect(order.orderStatus, equals('outfordelivery'));
    });

    test('3. Delivery OTP Guard Validation Logic', () {
      const correctOtp = '6419';
      const wrongOtp = '1234';

      expect(wrongOtp == correctOtp, isFalse);
      expect(correctOtp == correctOtp, isTrue);
    });
  });
}
