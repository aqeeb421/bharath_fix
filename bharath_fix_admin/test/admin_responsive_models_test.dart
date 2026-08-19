import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix_admin/models/admin_order_model.dart';

void main() {
  group('Admin App Responsive Models & Status Tests', () {
    test('1. AdminOrderStatus Enum Display Strings', () {
      expect(AdminOrderStatus.placed.toDisplayString(), 'ORDER PLACED');
      expect(AdminOrderStatus.shipped.toDisplayString(), 'SHIPPED');
      expect(AdminOrderStatus.outForDelivery.toDisplayString(), 'OUT FOR DELIVERY');
      expect(AdminOrderStatus.delivered.toDisplayString(), 'DELIVERED');
      expect(AdminOrderStatus.cancelled.toDisplayString(), 'CANCELLED');
    });

    test('2. AdminOrderModel Map Deserialization', () {
      final map = {
        'userName': 'Jane Doe',
        'userPhone': '9876543210',
        'productName': 'Water Purifier 15L',
        'productImage': 'https://example.com/item.png',
        'price': 4999.0,
        'quantity': 1,
        'discountAmount': 500.0,
        'totalPaid': 4499.0,
        'deliveryAddress': '123 MG Road, Bangalore',
        'paymentMode': 'ONLINE_RAZORPAY',
        'orderStatus': 'shipped',
        'deliveryOtp': '4321',
        'deliveryPartnerId': 'agent_99',
        'deliveryPartnerName': 'Ramesh Kumar',
      };

      final model = AdminOrderModel.fromMap(map, docId: 'ord_101');
      expect(model.id, 'ord_101');
      expect(model.userName, 'Jane Doe');
      expect(model.productName, 'Water Purifier 15L');
      expect(model.totalPaid, 4499.0);
      expect(model.orderStatus, AdminOrderStatus.shipped);
      expect(model.deliveryOtp, '4321');
      expect(model.deliveryPartnerName, 'Ramesh Kumar');
    });
  });
}
