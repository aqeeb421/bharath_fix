import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String category;
  final String status;
  final bool isOnline;
  final double earnings;
  final int completedJobs;
  final double rating;
  final String? photoUrl;
  final String? experience;
  final String? address;
  final DateTime? createdAt;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.category = 'All Appliances Specialist',
    this.status = 'active',
    this.isOnline = true,
    this.earnings = 0.0,
    this.completedJobs = 0,
    this.rating = 5.0,
    this.photoUrl,
    this.experience,
    this.address,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': uid,
      'uid': uid,
      'name': name,
      'email': email,
      'phone': phone,
      'category': category,
      'status': status,
      'isOnline': isOnline,
      'earnings': earnings,
      'completedJobs': completedJobs,
      'rating': rating,
      'photoUrl': photoUrl ?? '',
      'experience': experience ?? '',
      'address': address ?? '',
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory TechnicianModel.fromMap(Map<String, dynamic> map, String docId) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TechnicianModel(
      uid: map['uid'] as String? ?? map['id'] as String? ?? docId,
      name: map['name'] as String? ?? 'Technician',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      category: map['category'] as String? ?? 'All Appliances Specialist',
      status: map['status'] as String? ?? 'active',
      isOnline: map['isOnline'] as bool? ?? true,
      earnings: (map['earnings'] as num? ?? 0.0).toDouble(),
      completedJobs: (map['completedJobs'] as num? ?? 0).toInt(),
      rating: (map['rating'] as num? ?? 5.0).toDouble(),
      photoUrl: map['photoUrl'] as String?,
      experience: map['experience'] as String?,
      address: map['address'] as String?,
      createdAt: parseDate(map['createdAt']),
    );
  }
}
