import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix_admin/widgets/admin_state_widgets.dart';
import 'package:bharath_fix_admin/models/admin_order_model.dart';

void main() {
  testWidgets('AdminEmptyStateWidget renders title and message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminEmptyStateWidget(
            title: 'No Orders Found',
            message: 'There are currently no customer product orders.',
            icon: Icons.inventory_2_outlined,
          ),
        ),
      ),
    );

    expect(find.text('No Orders Found'), findsOneWidget);
    expect(find.text('There are currently no customer product orders.'), findsOneWidget);
    expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
  });

  testWidgets('AdminLoadingStateWidget renders loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminLoadingStateWidget(message: 'Loading orders...'),
        ),
      ),
    );

    expect(find.text('Loading orders...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  test('AdminOrderModel serializes delivery partner assignment fields', () {
    final order = AdminOrderModel.fromMap({
      'id': 'ORD_ASSIGN_99',
      'userId': 'user_cust_01',
      'userName': 'Ravi Kumar',
      'userPhone': '+919988776655',
      'deliveryAddress': 'Hassan Main Road',
      'productId': 'prod_wm_01',
      'productName': 'Semi Automatic Washing Machine',
      'price': 15999.0,
      'quantity': 1,
      'totalPaid': 15999.0,
      'orderStatus': 'shipped',
      'deliveryPartnerId': 'tech_suresh_01',
      'deliveryPartnerName': 'Suresh Kumar',
      'deliveryPartnerPhone': '+919876543210',
      'deliveryOtp': '4589',
      'paymentMode': 'ONLINE_RAZORPAY',
      'assignedByAdmin': true,
    }, docId: 'ORD_ASSIGN_99');

    expect(order.id, equals('ORD_ASSIGN_99'));
    expect(order.deliveryPartnerId, equals('tech_suresh_01'));
    expect(order.deliveryPartnerName, equals('Suresh Kumar'));
    expect(order.assignedByAdmin, isTrue);
    expect(order.orderStatus, equals(AdminOrderStatus.shipped));
  });
}
