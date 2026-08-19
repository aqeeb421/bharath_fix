import 'package:cloud_firestore/cloud_firestore.dart';
import 'AddressModel.dart';

class UserModel {
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String? photoUrl;
  final String? defaultAddress;
  final List<AddressModel> addresses;
  final double walletBalance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.name,
    required this.phone,
    required this.email,
    this.photoUrl,
    this.defaultAddress,
    this.addresses = const [],
    this.walletBalance = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime? parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    double parseWallet(dynamic val) {
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? 0.0;
      return 0.0;
    }

    List<AddressModel> parsedAddresses = [];

    final rawAddresses = map['addresses'];
    if (rawAddresses is List) {
      for (int i = 0; i < rawAddresses.length; i++) {
        final item = rawAddresses[i];
        if (item is Map<String, dynamic>) {
          parsedAddresses.add(AddressModel.fromMap(item));
        } else if (item is Map) {
          parsedAddresses.add(AddressModel.fromMap(Map<String, dynamic>.from(item)));
        } else if (item is String && item.trim().isNotEmpty) {
          parsedAddresses.add(AddressModel(
            id: 'user_addr_${i + 1}',
            details: item.trim(),
            tag: i == 0 ? 'Home' : 'Address ${i + 1}',
          ));
        }
      }
    } else if (rawAddresses is Map) {
      rawAddresses.forEach((key, val) {
        if (val is Map<String, dynamic>) {
          parsedAddresses.add(AddressModel.fromMap(val, docId: key.toString()));
        } else if (val is Map) {
          parsedAddresses.add(AddressModel.fromMap(Map<String, dynamic>.from(val), docId: key.toString()));
        } else if (val is String && val.trim().isNotEmpty) {
          parsedAddresses.add(AddressModel(
            id: key.toString(),
            details: val.trim(),
            tag: 'Home',
          ));
        }
      });
    }

    String? resolvedDefaultAddress;
    final explicitDefault = parsedAddresses.where((a) => a.isDefault).firstOrNull;
    if (explicitDefault != null) {
      resolvedDefaultAddress = explicitDefault.details;
    } else {
      final defaultAddrVal = map['defaultAddress'] ?? map['address'];

      if (defaultAddrVal is String && defaultAddrVal.trim().isNotEmpty) {
        resolvedDefaultAddress = defaultAddrVal.trim();
        final existsInList = parsedAddresses.any((a) => a.details.trim() == resolvedDefaultAddress);
        if (!existsInList) {
          parsedAddresses.add(AddressModel(
            id: 'user_default_address',
            details: resolvedDefaultAddress,
            tag: 'Home',
            isDefault: true,
          ));
        }
      } else if (defaultAddrVal is Map) {
        final addrFromMap = AddressModel.fromMap(Map<String, dynamic>.from(defaultAddrVal));
        resolvedDefaultAddress = addrFromMap.details;
        final existsInList = parsedAddresses.any((a) => a.id == addrFromMap.id || a.details.trim() == addrFromMap.details.trim());
        if (!existsInList) {
          parsedAddresses.add(addrFromMap.copyWith(isDefault: true));
        }
      }
    }

    if (resolvedDefaultAddress == null && parsedAddresses.isNotEmpty) {
      final defaultItem = parsedAddresses.firstWhere(
        (a) => a.isDefault,
        orElse: () => parsedAddresses.first,
      );
      resolvedDefaultAddress = defaultItem.details;
    }

    return UserModel(
      uid: map['uid'] as String? ?? docId ?? '',
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      defaultAddress: resolvedDefaultAddress,
      addresses: parsedAddresses,
      walletBalance: parseWallet(map['walletBalance']),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt'] ?? map['lastUpdated']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'photoUrl': photoUrl,
      'defaultAddress': defaultAddress,
      'addresses': addresses.map((a) => a.toMap()).toList(),
      'walletBalance': walletBalance,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? uid,
    String? name,
    String? phone,
    String? email,
    String? photoUrl,
    String? defaultAddress,
    List<AddressModel>? addresses,
    double? walletBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      addresses: addresses ?? this.addresses,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
