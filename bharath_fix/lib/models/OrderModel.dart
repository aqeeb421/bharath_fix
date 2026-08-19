import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  placed,
  processing,
  shipped,
  outForDelivery,
  delivered,
  cancelled;

  String toDisplayString() {
    switch (this) {
      case OrderStatus.placed:
        return 'ORDER PLACED';
      case OrderStatus.processing:
        return 'PROCESSING';
      case OrderStatus.shipped:
        return 'SHIPPED';
      case OrderStatus.outForDelivery:
        return 'OUT FOR DELIVERY';
      case OrderStatus.delivered:
        return 'DELIVERED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  static OrderStatus fromString(String? val) {
    if (val == null) return OrderStatus.placed;
    final clean = val.toLowerCase().replaceAll('_', '').replaceAll(' ', '');
    if (clean.contains('shipped') || clean.contains('dispatched')) {
      return OrderStatus.shipped;
    }
    if (clean.contains('outfordelivery') || clean.contains('ontheway')) {
      return OrderStatus.outForDelivery;
    }
    if (clean.contains('delivered') || clean.contains('completed')) {
      return OrderStatus.delivered;
    }
    if (clean.contains('cancelled') || clean.contains('rejected')) {
      return OrderStatus.cancelled;
    }
    if (clean.contains('processing') || clean.contains('accepted')) {
      return OrderStatus.processing;
    }
    return OrderStatus.placed;
  }
}

class OrderModel {
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

  final OrderStatus orderStatus;
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
  final DateTime? deliveredAt;

  const OrderModel({
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
    this.orderStatus = OrderStatus.placed,
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
    this.deliveredAt,
  });

  factory OrderModel.fromMap(Map<String, dynamic> map, {String? docId}) {
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

    return OrderModel(
      id: map['id'] as String? ?? docId ?? 'ORD_${DateTime.now().millisecondsSinceEpoch}',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? '',
      userPhone: map['userPhone'] as String? ?? '',
      userEmail: map['userEmail'] as String? ?? '',
      deliveryAddress: map['deliveryAddress'] as String? ?? map['address'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? map['title'] as String? ?? 'Product Item',
      productImage: map['productImage'] as String? ?? map['image'] as String? ?? '',
      price: parseDouble(map['price'] ?? map['itemPrice']),
      quantity: parseInt(map['quantity']),
      discountAmount: parseDouble(map['discountAmount']),
      totalPaid: parseDouble(map['totalPaid'] ?? map['visitingFee'] ?? map['finalAmountPaid']),
      orderStatus: OrderStatus.fromString(map['orderStatus'] as String? ?? map['status'] as String?),
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
      deliveredAt: parseDate(map['deliveredAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userPhone': userPhone,
      'userEmail': userEmail,
      'deliveryAddress': deliveryAddress,
      'productId': productId,
      'productName': productName,
      'productImage': productImage,
      'price': price,
      'quantity': quantity,
      'discountAmount': discountAmount,
      'totalPaid': totalPaid,
      'orderStatus': orderStatus.name,
      'deliveryPartnerId': deliveryPartnerId,
      'deliveryPartnerName': deliveryPartnerName,
      'deliveryPartnerPhone': deliveryPartnerPhone,
      'deliveryOtp': deliveryOtp,
      'paymentMode': paymentMode,
      'isPaid': isPaid ? 1 : 0,
      'requiresInstallation': requiresInstallation ? 1 : 0,
      'assignedByAdmin': assignedByAdmin ? 1 : 0,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'expectedDeliveryDate': expectedDeliveryDate,
      'deliveredAt': deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'orderType': 'PRODUCT_SALE',
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userPhone,
    String? userEmail,
    String? deliveryAddress,
    String? productId,
    String? productName,
    String? productImage,
    double? price,
    int? quantity,
    double? discountAmount,
    double? totalPaid,
    OrderStatus? orderStatus,
    String? deliveryPartnerId,
    String? deliveryPartnerName,
    String? deliveryPartnerPhone,
    String? deliveryOtp,
    String? paymentMode,
    bool? isPaid,
    bool? requiresInstallation,
    bool? assignedByAdmin,
    DateTime? assignedAt,
    DateTime? createdAt,
    String? expectedDeliveryDate,
    DateTime? deliveredAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      userEmail: userEmail ?? this.userEmail,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      discountAmount: discountAmount ?? this.discountAmount,
      totalPaid: totalPaid ?? this.totalPaid,
      orderStatus: orderStatus ?? this.orderStatus,
      deliveryPartnerId: deliveryPartnerId ?? this.deliveryPartnerId,
      deliveryPartnerName: deliveryPartnerName ?? this.deliveryPartnerName,
      deliveryPartnerPhone: deliveryPartnerPhone ?? this.deliveryPartnerPhone,
      deliveryOtp: deliveryOtp ?? this.deliveryOtp,
      paymentMode: paymentMode ?? this.paymentMode,
      isPaid: isPaid ?? this.isPaid,
      requiresInstallation: requiresInstallation ?? this.requiresInstallation,
      assignedByAdmin: assignedByAdmin ?? this.assignedByAdmin,
      assignedAt: assignedAt ?? this.assignedAt,
      createdAt: createdAt ?? this.createdAt,
      expectedDeliveryDate: expectedDeliveryDate ?? this.expectedDeliveryDate,
      deliveredAt: deliveredAt ?? this.deliveredAt,
    );
  }
}
