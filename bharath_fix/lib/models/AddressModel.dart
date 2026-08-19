import 'package:cloud_firestore/cloud_firestore.dart';

class AddressModel {
  final String id;
  final String tag; // 'Home', 'Office', 'Other'
  final String details;
  final String? house;
  final String? street;
  final String? landmark;
  final String? pincode;
  final bool isDefault;
  final DateTime? createdAt;

  AddressModel({
    required this.id,
    required this.details,
    this.tag = 'Home',
    this.house,
    this.street,
    this.landmark,
    this.pincode,
    this.isDefault = false,
    this.createdAt,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    String detailsStr = map['details'] as String? ??
        map['address'] as String? ??
        map['defaultAddress'] as String? ??
        map['fullAddress'] as String? ??
        '';

    if (detailsStr.isEmpty) {
      final h = map['house'] ?? map['houseNo'] ?? map['flat'] ?? '';
      final s = map['street'] ?? map['area'] ?? '';
      final l = map['landmark'] ?? '';
      final p = map['pincode'] ?? map['zip'] ?? '';

      final parts = [h, s, l, p]
          .where((e) => e.toString().trim().isNotEmpty)
          .toList();
      detailsStr = parts.join(', ');
    }

    return AddressModel(
      id: map['id'] as String? ??
          docId ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      details: detailsStr.isNotEmpty ? detailsStr : 'Saved Address',
      tag: map['tag'] as String? ?? map['type'] as String? ?? 'Home',
      house: map['house'] as String? ?? map['houseNo'] as String?,
      street: map['street'] as String? ?? map['area'] as String?,
      landmark: map['landmark'] as String?,
      pincode: map['pincode'] as String? ?? map['zip'] as String?,
      isDefault: map['isDefault'] == true || map['isDefault'] == 1,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'details': details,
      'tag': tag,
      'house': house,
      'street': street,
      'landmark': landmark,
      'pincode': pincode,
      'isDefault': isDefault ? 1 : 0,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  AddressModel copyWith({
    String? id,
    String? tag,
    String? details,
    String? house,
    String? street,
    String? landmark,
    String? pincode,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return AddressModel(
      id: id ?? this.id,
      tag: tag ?? this.tag,
      details: details ?? this.details,
      house: house ?? this.house,
      street: street ?? this.street,
      landmark: landmark ?? this.landmark,
      pincode: pincode ?? this.pincode,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
