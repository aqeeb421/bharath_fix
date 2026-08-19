import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminOrderStatus {
  placed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled;

  String toDisplayString() {
    switch (this) {
      case AdminOrderStatus.placed:
        return 'ORDER PLACED';
      case AdminOrderStatus.processing:
        return 'PROCESSING';
      case AdminOrderStatus.shipped:
        return 'SHIPPED';
      case AdminOrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case AdminOrderStatus.delivered:
        return 'DELIVERED';
      case AdminOrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static AdminOrderStatus fromString(String? val) {
    if (val == null) return AdminOrderStatus.placed;
    final clean = val.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (clean.contains('shipped') || clean.contains('dispatched')) {
      return AdminOrderStatus.shipped;
    }
    if (clean.contains('outfordelivery') || clean.contains('ontheway')) {
      return AdminOrderStatus.outForDelivery;
    }
    if (clean.contains('delivered') || clean.contains('completed')) {
      return AdminOrderStatus.delivered;
    }
    if (clean.contains('cancelled') || clean.contains('rejected')) {
      return AdminOrderStatus.cancelled;
    }
    if (clean.contains('processing') || clean.contains('accepted')) {
      return AdminOrderStatus.processing;
    }
    return AdminOrderStatus.placed;
  }
}

class AdminOrderModel {
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
  final double discountAmount;
  final double totalPaid;

  final AdminOrderStatus orderStatus;
  final String? deliveryPartnerId;
  final String? deliveryPartnerName;
  final String? deliveryPartnerPhone;
  final String deliveryOtp;

  final String paymentMode;
  final bool isPaid;
  final bool requiresInstallation;
  final bool assignedByAdmin;
  final DateTime? assignedAt;
  final DateTime? createdAt;
  final String? expectedDeliveryDate;

  const AdminOrderModel({
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
    this.discountAmount = 0.0,
    required this.totalPaid,
    this.orderStatus = AdminOrderStatus.placed,
    this.deliveryPartnerId,
    this.deliveryPartnerName,
    this.deliveryPartnerPhone,
    required this.deliveryOtp,
    this.paymentMode = 'ONLINE_RAZORPAY',
    this.isPaid = true,
    this.requiresInstallation = true,
    this.assignedByAdmin = true,
    this.assignedAt,
    this.createdAt,
    this.expectedDeliveryDate,
  });

  factory AdminOrderModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>? ?? {};
    return AdminOrderModel.fromMap(map, docId: doc.id);
  }

  factory AdminOrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
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

    int parseInt(dynamic val) {
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? 1;
      return 1;
    }

    return AdminOrderModel(
      id: map['id'] as String? ?? docId ?? 'ORD_UNKNOWN',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? map['clientName'] as String? ?? 'Customer',
      userPhone: map['userPhone'] as String? ?? map['clientPhone'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? map['clientEmail'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? map['address'] as String? ?? 'Address not specified',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? map['title'] as String? ?? 'Product Order',
      productImage: map['productImage'] as String? ?? map['image'] as String? ?? '',
      price: parseDouble(map['price'] ?? map['itemPrice']),
      quantity: parseInt(map['quantity']),
      discountAmount: parseDouble(map['discountAmount']),
      totalPaid: parseDouble(map['totalPaid'] ?? map['visitingFee'] ?? map['finalAmountPaid']),
      orderStatus: AdminOrderStatus.fromString(map['orderStatus'] as String? ?? map['status'] as String?),
      deliveryPartnerId: map['deliveryPartnerId'] as String?,
      deliveryPartnerName: map['deliveryPartnerName'] as String?,
      deliveryPartnerPhone: map['deliveryPartnerPhone'] as String?,
      deliveryOtp: map['deliveryOtp'] as String? ?? map['startOtp'] as String? ?? '5829',
      paymentMode: map['paymentMode'] as String? ?? 'ONLINE_RAZORPAY',
      isPaid: map['isPaid'] == true || map['isPaid'] == 1,
      requiresInstallation: map['requiresInstallation'] != false && map['requiresInstallation'] != 0,
      assignedByAdmin: map['assignedByAdmin'] != false && map['assignedByAdmin'] != 0,
      assignedAt: parseDate(map['assignedAt']),
      createdAt: parseDate(map['createdAt']),
      expectedDeliveryDate: map['expectedDeliveryDate'] as String? ?? map['dateTime'] as String?,
    );
  }
}
