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
  final String experience;
  final String address;
  final double operatingRadiusKm;
  final List<String> skills;
  final Map<String, dynamic> bankDetails;
  final Map<String, dynamic> kyc;
  final DateTime? createdAt;

  TechnicianModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    this.category = 'Appliance Specialist',
    this.status = 'active',
    this.isOnline = true,
    this.earnings = 0.0,
    this.completedJobs = 0,
    this.rating = 5.0,
    this.photoUrl,
    this.experience = '3',
    this.address = '',
    this.operatingRadiusKm = 15.0,
    this.skills = const [],
    this.bankDetails = const {},
    this.kyc = const {},
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
      // Uniform experience keys
      'experience': experience,
      'experienceYears': int.tryParse(experience) ?? 3,
      // Uniform address keys
      'address': address,
      'city': address,
      'operatingRadiusKm': operatingRadiusKm,
      'skills': skills,
      'bankDetails': bankDetails,
      'kyc': kyc,
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

    final rawExp = map['experience'] ?? map['experienceYears'];
    final rawAddr = map['address'] ?? map['city'];
    final skillsRaw = map['skills'] as List<dynamic>? ?? [];

    return TechnicianModel(
      uid: map['uid'] as String? ?? map['id'] as String? ?? docId,
      name: map['name'] as String? ?? 'Technician',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      category: map['category'] as String? ?? 'Appliance Specialist',
      status: map['status'] as String? ?? 'active',
      isOnline: map['isOnline'] as bool? ?? true,
      earnings: (map['earnings'] as num? ?? 0.0).toDouble(),
      completedJobs: (map['completedJobs'] as num? ?? 0).toInt(),
      rating: (map['rating'] as num? ?? 5.0).toDouble(),
      photoUrl: map['photoUrl'] as String?,
      experience: rawExp != null ? rawExp.toString() : '3',
      address: rawAddr != null ? rawAddr.toString() : '',
      operatingRadiusKm: (map['operatingRadiusKm'] as num? ?? 15.0).toDouble(),
      skills: skillsRaw.map((e) => e.toString()).toList(),
      bankDetails: (map['bankDetails'] as Map<String, dynamic>?) ?? {},
      kyc: (map['kyc'] as Map<String, dynamic>?) ?? {},
      createdAt: parseDate(map['createdAt']),
    );
  }
}
