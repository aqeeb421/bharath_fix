import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fcm_direct_service.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Authentication Getters
  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Admin login credentials check simulation/auth
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Streams all bookings uniquely from both root collections and subcollections
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getBookingsCombinedStream() {
    final controller = StreamController<List<QueryDocumentSnapshot<Map<String, dynamic>>>>();
    
    List<QueryDocumentSnapshot<Map<String, dynamic>>> groupDocs = [];
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rootDocs = [];

    void emit() {
      final List<QueryDocumentSnapshot<Map<String, dynamic>>> combined = [];
      final Set<String> ids = {};

      for (var doc in groupDocs) {
        if (ids.add(doc.id)) combined.add(doc);
      }
      for (var doc in rootDocs) {
        if (ids.add(doc.id)) combined.add(doc);
      }
      if (!controller.isClosed) {
        controller.add(combined);
      }
    }

    final sub1 = _db.collectionGroup('bookings').snapshots().listen((snap) {
      groupDocs = snap.docs;
      emit();
    }, onError: (e) {
      // Fail silently if collectionGroup requires setup indexes
      print('Group query check: $e');
    });

    final sub2 = _db.collection('bookings').snapshots().listen((snap) {
      rootDocs = snap.docs;
      emit();
    }, onError: (e) {
      print('Root query error: $e');
    });

    controller.onCancel = () {
      sub1.cancel();
      sub2.cancel();
      controller.close();
    };

    return controller.stream;
  }

  // Updates booking status directly in its exact Firestore path and syncs counterpart document
  Future<void> updateBookingStatus(String path, String newStatus) async {
    final batch = _db.batch();
    final docRef = _db.doc(path);
    batch.update(docRef, {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});

    final docSnap = await docRef.get();
    if (docSnap.exists) {
      final docId = docSnap.id;
      final userId = docSnap.data()?['userId']?.toString() ?? docSnap.data()?['customerId']?.toString();
      final providerId = docSnap.data()?['providerId']?.toString();

      if (path.startsWith('users/')) {
        final rootRef = _db.collection('bookings').doc(docId);
        batch.set(rootRef, {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      } else if (userId != null && userId.isNotEmpty) {
        final userSubRef = _db.collection('users').doc(userId).collection('bookings').doc(docId);
        batch.set(userSubRef, {'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      }

      // Direct FCM Push to Customer
      if (userId != null && userId.isNotEmpty) {
        try {
          final userDoc = await _db.collection('users').doc(userId).get();
          final fcmToken = userDoc.data()?['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await FcmDirectService.sendPushNotification(
              targetToken: fcmToken,
              title: 'Status Updated: $newStatus',
              body: 'Your service request status is now $newStatus.',
              data: {'jobId': docId, 'status': newStatus, 'type': 'JOB_STATUS_UPDATE'},
            );
          }
        } catch (e) {
          print('Admin FCM push error: $e');
        }
      }

      // Direct FCM Push to Provider
      if (providerId != null && providerId.isNotEmpty) {
        try {
          final providerDoc = await _db.collection('providers').doc(providerId).get();
          final fcmToken = providerDoc.data()?['fcmToken'] as String?;
          if (fcmToken != null && fcmToken.isNotEmpty) {
            await FcmDirectService.sendPushNotification(
              targetToken: fcmToken,
              title: 'Job Update: $newStatus',
              body: 'Assigned job #$docId status updated to $newStatus.',
              data: {'jobId': docId, 'status': newStatus, 'type': 'JOB_STATUS_UPDATE'},
            );
          }
        } catch (e) {
          print('Admin FCM push to tech error: $e');
        }
      }
    }

    await batch.commit();
  }


  // ==================== USERS COLLECTION ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getUsersStream() {
    return _db.collection('users').snapshots();
  }

  Future<void> deleteUser(String uid) async {
    await _db.collection('users').doc(uid).delete();
  }

  // ==================== PROVIDERS COLLECTION ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getProvidersStream() {
    return _db.collection('providers').snapshots();
  }

  Future<void> addProvider({
    required String name,
    required String phone,
    required String category,
    required String status,
  }) async {
    final docRef = _db.collection('providers').doc();
    await docRef.set({
      'id': docRef.id,
      'name': name,
      'phone': phone,
      'category': category,
      'status': status,
      'rating': '5.0',
      'completedJobs': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateProviderStatus(String id, String newStatus) async {
    final normStatus = newStatus.trim().toLowerCase();
    final isActivating = normStatus == 'active' || normStatus == 'approved' || normStatus == 'verified';
    await _db.collection('providers').doc(id).set({
      'status': normStatus,
      'isOnline': isActivating,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (isActivating) {
      try {
        final notifId = 'notif_t_${DateTime.now().millisecondsSinceEpoch}';
        await _db.collection('providers').doc(id).collection('notifications').doc(notifId).set({
          'id': notifId,
          'techId': id,
          'title': 'Account Activated! 🎉',
          'body': 'Your KYC has been approved by Admin. Toggle ONLINE to start receiving jobs.',
          'data': {'type': 'ACCOUNT_ACTIVATED'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}
    }
  }

  Future<void> deleteProvider(String id) async {
    await _db.collection('providers').doc(id).delete();
  }

  // ==================== CATALOG MANAGEMENT ====================

  // 1. Categories
  Stream<QuerySnapshot<Map<String, dynamic>>> getCategoriesStream() {
    return _db.collection('categories').snapshots();
  }

  Future<void> saveCategory(String docId, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(docId).set(data);
  }

  Future<void> deleteCategory(String docId) async {
    await _db.collection('categories').doc(docId).delete();
  }

  // 2. Banners
  Stream<QuerySnapshot<Map<String, dynamic>>> getBannersStream() {
    return _db.collection('banners').snapshots();
  }

  Future<void> saveBanner(String docId, Map<String, dynamic> data) async {
    await _db.collection('banners').doc(docId).set(data);
  }

  Future<void> deleteBanner(String docId) async {
    await _db.collection('banners').doc(docId).delete();
  }

  // 3. Products
  Stream<QuerySnapshot<Map<String, dynamic>>> getProductsStream() {
    return _db.collection('products').snapshots();
  }

  Future<void> saveProduct(String docId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(docId).set(data);
  }

  Future<void> deleteProduct(String docId) async {
    await _db.collection('products').doc(docId).delete();
  }

  Future<void> reseedData() async {
    final String hostOrigin = Uri.base.origin;

    final defaultCategories = [
      {
        'id': 'm1',
        'name': 'Refrigerator',
        'iconName': 'kitchen_rounded',
        'subCategories': [
          {'id': 's1_1', 'name': 'Single Door', 'image': '$hostOrigin/app_images/s1_1.png'},
          {'id': 's1_2', 'name': 'Double Door', 'image': '$hostOrigin/app_images/s1_2.png'},
          {'id': 's1_3', 'name': 'Bottom Freezer', 'image': '$hostOrigin/app_images/s1_3.png'},
          {'id': 's1_4', 'name': 'Triple Door', 'image': '$hostOrigin/app_images/s1_4.png'},
          {'id': 's1_5', 'name': 'Deep Freezer', 'image': '$hostOrigin/app_images/s1_5.png'},
        ]
      },
      {
        'id': 'm2',
        'name': 'Washing Machine',
        'iconName': 'local_laundry_service_rounded',
        'subCategories': [
          {'id': 's2_1', 'name': 'Top Load', 'image': '$hostOrigin/app_images/s2_1.png'},
          {'id': 's2_2', 'name': 'Front Load', 'image': '$hostOrigin/app_images/s2_2.png'},
          {'id': 's2_3', 'name': 'Semi-Automatic', 'image': '$hostOrigin/app_images/s2_3.png'},
          {'id': 's2_4', 'name': 'Fully Automatic', 'image': '$hostOrigin/app_images/s2_4.png'},
        ]
      },
      {
        'id': 'm3',
        'name': 'Water Purifier',
        'iconName': 'water_drop_rounded',
        'subCategories': [
          {'id': 's3_1', 'name': 'Hot and Cool RO', 'image': '$hostOrigin/app_images/s3_1.png'},
          {'id': 's3_2', 'name': 'UV RO Purifier', 'image': '$hostOrigin/app_images/s3_2.png'},
          {'id': 's3_3', 'name': 'Commercial Plant', 'image': '$hostOrigin/app_images/s3_3.png'},
        ]
      },
      {
        'id': 'm4',
        'name': 'AC Repair',
        'iconName': 'ac_unit_rounded',
        'subCategories': [
          {'id': 's4_1', 'name': 'Split AC', 'image': '$hostOrigin/app_images/s4_1.png'},
          {'id': 's4_2', 'name': 'Ductable AC', 'image': '$hostOrigin/app_images/s4_2.png'},
        ]
      },
      {
        'id': 'm5',
        'name': 'Kitchen Chimney',
        'iconName': 'blender_rounded',
        'subCategories': [
          {'id': 's5_1', 'name': 'Analog Control', 'image': '$hostOrigin/app_images/s5_1.png'},
          {'id': 's5_2', 'name': 'Digital Touch', 'image': '$hostOrigin/app_images/s5_2.png'},
        ]
      },
      {
        'id': 'm6',
        'name': 'Air Cooler',
        'iconName': 'wind_power_rounded',
        'subCategories': [
          {'id': 's6_1', 'name': 'Desert Cooler', 'image': '$hostOrigin/app_images/s6_1.png'},
          {'id': 's6_2', 'name': 'Personal Tower Cooler', 'image': '$hostOrigin/app_images/s6_2.png'},
        ]
      },
      {
        'id': 'm7',
        'name': 'Geyser',
        'iconName': 'hot_tub_rounded',
        'subCategories': [
          {'id': 's7_1', 'name': 'Instant Geyser', 'image': '$hostOrigin/app_images/s7_1.png'},
          {'id': 's7_2', 'name': 'Storage Tank Geyser', 'image': '$hostOrigin/app_images/s7_2.png'},
        ]
      },
      {
        'id': 'm8',
        'name': 'Microwave Oven',
        'iconName': 'microwave_rounded',
        'subCategories': [
          {'id': 's8_1', 'name': 'Convection Oven', 'image': '$hostOrigin/app_images/s8_1.png'},
          {'id': 's8_2', 'name': 'Solo / Grill Microwave', 'image': '$hostOrigin/app_images/s8_2.png'},
        ]
      }
    ];

    for (var cat in defaultCategories) {
      final id = cat['id'] as String;
      await _db.collection('categories').doc(id).set({
        'name': cat['name'],
        'iconName': cat['iconName'],
        'subCategories': cat['subCategories'],
      });
    }

    final defaultBanners = [
      {
        'title': '20% OFF on Chimney Cleaning',
        'subtitle': 'Use code CLEAN15 • Sparkling homes await',
        'image': '$hostOrigin/app_images/s5_2.png'
      },
      {
        'title': 'Washing Machine Service Special',
        'subtitle': 'Flat ₹150 OFF on Front Load servicing',
        'image': '$hostOrigin/app_images/s2_2.png'
      },
      {
        'title': 'RO Water Purifier Servicing',
        'subtitle': 'Free TDS Check with filter replacement',
        'image': '$hostOrigin/app_images/s3_2.png'
      }
    ];

    for (var i = 0; i < defaultBanners.length; i++) {
      await _db.collection('banners').doc('banner_$i').set(defaultBanners[i]);
    }

    final defaultProducts = [
      {
        'id': 'p1',
        'name': 'AquaPure Economic RO',
        'subCategory': 'Standard RO',
        'price': '₹6,999',
        'image': '$hostOrigin/app_images/s3_1.png'
      },
      {
        'id': 'p2',
        'name': 'LivPure UV Compact',
        'subCategory': 'UV Purifier',
        'price': '₹8,499',
        'image': '$hostOrigin/app_images/s3_2.png'
      },
      {
        'id': 'p3',
        'name': 'AquaShield Copper RO',
        'subCategory': 'Standard RO',
        'price': '₹12,999',
        'image': '$hostOrigin/app_images/s3_3.png'
      },
      {
        'id': 'p4',
        'name': 'HydroAlkaline Premium',
        'subCategory': 'Alkaline Special',
        'price': '₹16,500',
        'image': '$hostOrigin/app_images/s8_1.png'
      },
      {
        'id': 'p5',
        'name': 'Kent Maxima Pro RO+UV',
        'subCategory': 'UV Purifier',
        'price': '₹19,999',
        'image': '$hostOrigin/app_images/s1_3.png'
      },
      {
        'id': 'p6',
        'name': 'AquaGrand Luxury Custom',
        'subCategory': 'Alkaline Special',
        'price': '₹29,999',
        'image': '$hostOrigin/app_images/s5_1.png'
      }
    ];

    for (var prod in defaultProducts) {
      final id = prod['id'] as String;
      await _db.collection('products').doc(id).set(prod);
    }
  }

  // ==================== ADMIN NOTIFICATIONS ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getAdminNotificationsStream() {
    return _db
        .collection('admin_notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ==================== SPARE PARTS & RATE CARDS ====================

  Stream<QuerySnapshot<Map<String, dynamic>>> getSparePartsStream() {
    return _db.collection('spare_parts_catalog').snapshots();
  }

  Future<void> addSparePart(Map<String, dynamic> data) async {
    await _db.collection('spare_parts_catalog').add({
      ...data,
      'isVerified': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateSparePart(String docId, Map<String, dynamic> data) async {
    await _db.collection('spare_parts_catalog').doc(docId).set({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> deleteSparePart(String docId) async {
    await _db.collection('spare_parts_catalog').doc(docId).delete();
  }
}

