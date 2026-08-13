import 'dart:convert';
import 'job_status.dart';

class QuoteItem {
  final String title;
  final double price;
  final bool isSparePart;

  const QuoteItem({
    required this.title,
    required this.price,
    this.isSparePart = true,
  });

  Map<String, dynamic> toMap() {
    return {'title': title, 'price': price, 'isSparePart': isSparePart};
  }

  factory QuoteItem.fromMap(Map<String, dynamic> map) {
    return QuoteItem(
      title: map['title'] ?? map['name'] ?? map['item'] ?? '',
      price: (map['price'] ?? map['amount'] ?? 0).toDouble(),
      isSparePart: map['isSparePart'] ?? true,
    );
  }
}

class BookingEntry {
  final String id;
  final String title;
  final String dateTime;
  final double visitingFee;
  final double quoteTotal;
  final double finalAmountPaid;
  final JobStatus status;
  final String address;
  final double? latitude;
  final double? longitude;
  final int isSynced;
  final String startOtp;
  final String completionOtp;
  final String providerId;
  final String providerName;
  final String providerPhone;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final List<QuoteItem> quoteItems;
  final List<String> beforePhotos;
  final List<String> afterPhotos;
  final String paymentMode; // 'ONLINE', 'COD'
  final bool isVisitingFeePaid;
  final bool isFinalBillPaid;

  const BookingEntry({
    required this.id,
    required this.title,
    required this.dateTime,
    this.visitingFee = 199.0,
    this.quoteTotal = 0.0,
    this.finalAmountPaid = 0.0,
    this.status = JobStatus.draft,
    this.address = '',
    this.latitude,
    this.longitude,
    this.isSynced = 0,
    this.startOtp = '',
    this.completionOtp = '',
    this.providerId = '',
    this.providerName = '',
    this.providerPhone = '',
    this.customerId = '',
    this.customerName = '',
    this.customerPhone = '',
    this.quoteItems = const [],
    this.beforePhotos = const [],
    this.afterPhotos = const [],
    this.paymentMode = 'ONLINE',
    this.isVisitingFeePaid = false,
    this.isFinalBillPaid = false,
  });

  String get cost =>
      '₹${(isVisitingFeePaid ? (quoteTotal > 0 ? quoteTotal : visitingFee) : visitingFee).toStringAsFixed(0)}';

  /// Total payable amount for quotation approval: quotation total + visiting fee if not paid while booking
  double get totalPayableAmount =>
      quoteTotal + (isVisitingFeePaid ? 0.0 : visitingFee);

  /// Unpaid visiting fee component (returns 0.0 if already paid during booking)
  double get unpaidVisitingFee => isVisitingFeePaid ? 0.0 : visitingFee;

  BookingEntry copyWith({
    String? id,
    String? title,
    String? dateTime,
    double? visitingFee,
    double? quoteTotal,
    double? finalAmountPaid,
    JobStatus? status,
    String? address,
    double? latitude,
    double? longitude,
    int? isSynced,
    String? startOtp,
    String? completionOtp,
    String? providerId,
    String? providerName,
    String? providerPhone,
    String? customerId,
    String? customerName,
    String? customerPhone,
    List<QuoteItem>? quoteItems,
    List<String>? beforePhotos,
    List<String>? afterPhotos,
    String? paymentMode,
    bool? isVisitingFeePaid,
    bool? isFinalBillPaid,
  }) {
    return BookingEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      dateTime: dateTime ?? this.dateTime,
      visitingFee: visitingFee ?? this.visitingFee,
      quoteTotal: quoteTotal ?? this.quoteTotal,
      finalAmountPaid: finalAmountPaid ?? this.finalAmountPaid,
      status: status ?? this.status,
      address: address ?? this.address,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isSynced: isSynced ?? this.isSynced,
      startOtp: startOtp ?? this.startOtp,
      completionOtp: completionOtp ?? this.completionOtp,
      providerId: providerId ?? this.providerId,
      providerName: providerName ?? this.providerName,
      providerPhone: providerPhone ?? this.providerPhone,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      quoteItems: quoteItems ?? this.quoteItems,
      beforePhotos: beforePhotos ?? this.beforePhotos,
      afterPhotos: afterPhotos ?? this.afterPhotos,
      paymentMode: paymentMode ?? this.paymentMode,
      isVisitingFeePaid: isVisitingFeePaid ?? this.isVisitingFeePaid,
      isFinalBillPaid: isFinalBillPaid ?? this.isFinalBillPaid,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime,
      'cost': cost,
      'visitingFee': visitingFee,
      'quoteTotal': quoteTotal,
      'finalAmountPaid': finalAmountPaid,
      'status': status.code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isSynced': isSynced,
      'startOtp': startOtp,
      'completionOtp': completionOtp,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'quoteItems': quoteItems.map((e) => e.toMap()).toList(),
      'beforePhotos': beforePhotos,
      'afterPhotos': afterPhotos,
      'paymentMode': paymentMode,
      'isVisitingFeePaid': isVisitingFeePaid,
      'isFinalBillPaid': isFinalBillPaid,
    };
  }

  Map<String, dynamic> toSQLiteMap() {
    return {
      'id': id,
      'title': title,
      'dateTime': dateTime,
      'cost': cost,
      'visitingFee': visitingFee,
      'quoteTotal': quoteTotal,
      'finalAmountPaid': finalAmountPaid,
      'status': status.code,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'isSynced': isSynced,
      'startOtp': startOtp,
      'completionOtp': completionOtp,
      'providerId': providerId,
      'providerName': providerName,
      'providerPhone': providerPhone,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'quoteItems': jsonEncode(quoteItems.map((e) => e.toMap()).toList()),
      'beforePhotos': jsonEncode(beforePhotos),
      'afterPhotos': jsonEncode(afterPhotos),
      'paymentMode': paymentMode,
      'isVisitingFeePaid': isVisitingFeePaid ? 1 : 0,
      'isFinalBillPaid': isFinalBillPaid ? 1 : 0,
    };
  }

  factory BookingEntry.fromMap(Map<String, dynamic> map) {
    List<QuoteItem> decodedQuoteItems = [];
    dynamic rawItems = map['quoteItems'];
    if (rawItems == null && map['quotation'] is Map) {
      rawItems = map['quotation']['items'];
    }

    if (rawItems is String && rawItems.isNotEmpty) {
      try {
        final List parsed = jsonDecode(rawItems);
        decodedQuoteItems = parsed
            .map((e) => QuoteItem.fromMap(Map<String, dynamic>.from(e)))
            .toList();
      } catch (_) {}
    } else if (rawItems is List) {
      decodedQuoteItems = rawItems
          .map((e) => QuoteItem.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    }

    double parsedQuoteTotal = (map['quoteTotal'] as num?)?.toDouble() ?? 0.0;
    if (parsedQuoteTotal == 0.0 && map['quotation'] is Map) {
      parsedQuoteTotal =
          (map['quotation']['totalAmount'] as num?)?.toDouble() ?? 0.0;
    }
    if (parsedQuoteTotal == 0.0 && decodedQuoteItems.isNotEmpty) {
      parsedQuoteTotal = decodedQuoteItems.fold(
        0.0,
        (sum, item) => sum + item.price,
      );
    }

    List<String> decodedBefore = [];
    if (map['beforePhotos'] is String &&
        (map['beforePhotos'] as String).isNotEmpty) {
      try {
        final List parsed = jsonDecode(map['beforePhotos'] as String);
        decodedBefore = parsed.cast<String>();
      } catch (_) {}
    } else if (map['beforePhotos'] is List) {
      decodedBefore = (map['beforePhotos'] as List).cast<String>();
    }

    List<String> decodedAfter = [];
    if (map['afterPhotos'] is String &&
        (map['afterPhotos'] as String).isNotEmpty) {
      try {
        final List parsed = jsonDecode(map['afterPhotos'] as String);
        decodedAfter = parsed.cast<String>();
      } catch (_) {}
    } else if (map['afterPhotos'] is List) {
      decodedAfter = (map['afterPhotos'] as List).cast<String>();
    }

    bool parseBool(dynamic val) {
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) return val == '1' || val.toLowerCase() == 'true';
      return false;
    }

    return BookingEntry(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      dateTime: map['dateTime'] ?? '',
      visitingFee: (map['visitingFee'] ?? 199.0).toDouble(),
      quoteTotal: parsedQuoteTotal,
      finalAmountPaid: (map['finalAmountPaid'] ?? 0.0).toDouble(),
      status: JobStatus.fromCode(map['status'] ?? 'DRAFT'),
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      isSynced: map['isSynced'] ?? 0,
      startOtp: map['startOtp'] ?? '',
      completionOtp: map['completionOtp'] ?? '',
      providerId: map['providerId'] ?? '',
      providerName: map['providerName'] ?? '',
      providerPhone: map['providerPhone'] ?? '',
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      quoteItems: decodedQuoteItems,
      beforePhotos: decodedBefore,
      afterPhotos: decodedAfter,
      paymentMode: map['paymentMode'] ?? 'ONLINE',
      isVisitingFeePaid: parseBool(map['isVisitingFeePaid']),
      isFinalBillPaid: parseBool(map['isFinalBillPaid']),
    );
  }
}
