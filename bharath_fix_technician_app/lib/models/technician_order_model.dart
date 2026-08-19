import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianOrderModel {
  final String id;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  final String deliveryAddress;

  final String productId;
  final String productName;
  final String productImage;
  final double price;
  final int quantity;
  final double totalPaid;

  final String orderStatus;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String deliveryOtp;

  final String paymentMode;
  final bool isPaid;
  final bool requiresInstallation;
  final DateTime? createdAt;

  const TechnicianOrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.deliveryAddress,
    required this.productId,
    required this.productName,
    required this.productImage,
    required this.price,
    this.quantity = 1,
    required this.totalPaid,
    required this.orderStatus,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    required this.deliveryOtp,
    this.paymentMode = 'ONLINE_RAZORPAY',
    this.isPaid = true,
    this.requiresInstallation = true,
    this.createdAt,
  });

  factory TechnicianOrderModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return TechnicianOrderModel.fromMap(map, docId: doc.id);
  }

  factory TechnicianOrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    double parseDouble(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    return TechnicianOrderModel(
      id: map['id'] as String? ?? docId ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? map['clientName'] as String? ?? 'Customer',
      userPhone: map['userPhone'] as String? ?? map['clientPhone'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? map['clientEmail'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? map['address'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? map['title'] as String? ?? 'Appliance Item',
      productImage: map['productImage'] as String? ?? map['image'] as String? ?? '',
      price: parseDouble(map['price'] ?? map['itemPrice']),
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      totalPaid: parseDouble(map['totalPaid'] ?? map['finalAmountPaid']),
      orderStatus: (map['orderStatus'] as String? ?? map['status'] as String? ?? 'placed').toLowerCase(),
      deliveryPartnerId: map['deliveryPartnerId'] as String?,
      deliveryPartnerName: map['deliveryPartnerName'] as String?,
      deliveryPartnerPhone: map['deliveryPartnerPhone'] as String?,
      deliveryOtp: map['deliveryOtp'] as String? ?? map['startOtp'] as String? ?? '5829',
      paymentMode: map['paymentMode'] as String? ?? 'ONLINE_RAZORPAY',
      isPaid: map['isPaid'] == true || map['isPaid'] == 1,
      requiresInstallation: map['requiresInstallation'] != false,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
