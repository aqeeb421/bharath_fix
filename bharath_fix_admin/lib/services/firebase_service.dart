import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

  // Streams all bookings directly from the bookings collection
  Stream<List<QueryDocumentSnapshot<Map<String, dynamic>>>> getBookingsCombinedStream() {
    return _db.collection('bookings').snapshots().map((snap) => snap.docs);
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

      // Direct FCM Push logic removed - now handled centrally by Node.js fcm_engine.js
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

  Future<void> _bumpCatalogVersion() async {
    try {
      await _db.collection('app_config').doc('catalog_metadata').set({
        'version': FieldValue.increment(1),
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error bumping catalog version: $e');
    }
  }

  Future<void> saveCategory(String docId, Map<String, dynamic> data) async {
    await _db.collection('categories').doc(docId).set(data, SetOptions(merge: true));
    await _bumpCatalogVersion();
  }

  Future<void> updateCategorySubcategories(String docId, List<dynamic> subCategories) async {
    await _db.collection('categories').doc(docId).update({
      'subCategories': subCategories,
    });
    await _bumpCatalogVersion();
  }

  Future<void> deleteCategory(String docId) async {
    await _db.collection('categories').doc(docId).delete();
    await _bumpCatalogVersion();
  }

  // 2. Banners
  Stream<QuerySnapshot<Map<String, dynamic>>> getBannersStream() {
    return _db.collection('banners').snapshots();
  }

  Future<void> saveBanner(String docId, Map<String, dynamic> data) async {
    await _db.collection('banners').doc(docId).set(data);
    await _bumpCatalogVersion();
  }

  Future<void> deleteBanner(String docId) async {
    await _db.collection('banners').doc(docId).delete();
    await _bumpCatalogVersion();
  }

  // 2b. Special Marketing Offers & Deals
  Stream<QuerySnapshot<Map<String, dynamic>>> getOffersStream() {
    return _db.collection('offers').snapshots();
  }

  Future<void> saveOffer(String docId, Map<String, dynamic> data) async {
    await _db.collection('offers').doc(docId).set(data, SetOptions(merge: true));
    await _bumpCatalogVersion();
  }

  Future<void> deleteOffer(String docId) async {
    await _db.collection('offers').doc(docId).delete();
    await _bumpCatalogVersion();
  }

  // 3. Products
  Stream<QuerySnapshot<Map<String, dynamic>>> getProductsStream() {
    return _db.collection('products').snapshots();
  }

  Future<void> saveProduct(String docId, Map<String, dynamic> data) async {
    await _db.collection('products').doc(docId).set(data);
    await _bumpCatalogVersion();
  }

  Future<void> deleteProduct(String docId) async {
    await _db.collection('products').doc(docId).delete();
    await _bumpCatalogVersion();
  }

  // 4. Product Orders & Retail Sales
  Stream<QuerySnapshot<Map<String, dynamic>>> getOrdersStream() {
    return _db.collection('orders').orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> reseedData() async {
    const String storageBase = 'https://firebasestorage.googleapis.com/v0/b/bharathfix-735c5.firebasestorage.app/o/app_images%2F';

    final defaultCategories = [
      {
        'id': 'm1',
        'name': 'Refrigerator',
        'iconName': 'kitchen_rounded',
        'subCategories': [
          {'id': 's1_1', 'name': 'Single Door', 'image': '${storageBase}categories%2Frefrigerator%2Fsingle_door.png?alt=media'},
          {'id': 's1_2', 'name': 'Double Door', 'image': '${storageBase}categories%2Frefrigerator%2Fdouble_door.png?alt=media'},
          {'id': 's1_3', 'name': 'Bottom Freezer', 'image': '${storageBase}categories%2Frefrigerator%2Fbottom_freezer.png?alt=media'},
          {'id': 's1_4', 'name': 'Triple Door', 'image': '${storageBase}categories%2Frefrigerator%2Ftriple_door.png?alt=media'},
          {'id': 's1_5', 'name': 'Deep Freezer', 'image': '${storageBase}categories%2Frefrigerator%2Fdeep_freezer.png?alt=media'},
        ]
      },
      {
        'id': 'm2',
        'name': 'Washing Machine',
        'iconName': 'local_laundry_service_rounded',
        'subCategories': [
          {'id': 's2_1', 'name': 'Top Load', 'image': '${storageBase}categories%2Fwashing_machine%2Ftop_load.png?alt=media'},
          {'id': 's2_2', 'name': 'Front Load', 'image': '${storageBase}categories%2Fwashing_machine%2Ffront_load.png?alt=media'},
          {'id': 's2_3', 'name': 'Semi-Automatic', 'image': '${storageBase}categories%2Fwashing_machine%2Fsemi_automatic.png?alt=media'},
          {'id': 's2_4', 'name': 'Fully Automatic', 'image': '${storageBase}categories%2Fwashing_machine%2Ffully_automatic.png?alt=media'},
        ]
      },
      {
        'id': 'm3',
        'name': 'Water Purifier',
        'iconName': 'water_drop_rounded',
        'subCategories': [
          {'id': 's3_1', 'name': 'Hot and Cool RO', 'image': '${storageBase}categories%2Fwater_purifier%2Fhot_cool_ro.png?alt=media'},
          {'id': 's3_2', 'name': 'UV RO Purifier', 'image': '${storageBase}categories%2Fwater_purifier%2Fuv_ro_purifier.png?alt=media'},
          {'id': 's3_3', 'name': 'Commercial Plant', 'image': '${storageBase}categories%2Fwater_purifier%2Fcommercial_plant.png?alt=media'},
        ]
      },
      {
        'id': 'm4',
        'name': 'AC Repair',
        'iconName': 'ac_unit_rounded',
        'subCategories': [
          {'id': 's4_1', 'name': 'Split AC', 'image': '${storageBase}categories%2Fac_repair%2Fsplit_ac.png?alt=media'},
          {'id': 's4_2', 'name': 'Ductable AC', 'image': '${storageBase}categories%2Fac_repair%2Fductable_ac.png?alt=media'},
        ]
      },
      {
        'id': 'm5',
        'name': 'Kitchen Chimney',
        'iconName': 'blender_rounded',
        'subCategories': [
          {'id': 's5_1', 'name': 'Analog Control', 'image': '${storageBase}categories%2Fkitchen_chimney%2Fanalog_control.png?alt=media'},
          {'id': 's5_2', 'name': 'Digital Touch', 'image': '${storageBase}categories%2Fkitchen_chimney%2Fdigital_touch.png?alt=media'},
        ]
      },
      {
        'id': 'm6',
        'name': 'Air Cooler',
        'iconName': 'wind_power_rounded',
        'subCategories': [
          {'id': 's6_1', 'name': 'Desert Cooler', 'image': '${storageBase}categories%2Fair_cooler%2Fdesert_cooler.png?alt=media'},
          {'id': 's6_2', 'name': 'Personal Tower Cooler', 'image': '${storageBase}categories%2Fair_cooler%2Fpersonal_tower_cooler.png?alt=media'},
        ]
      },
      {
        'id': 'm7',
        'name': 'Geyser',
        'iconName': 'hot_tub_rounded',
        'subCategories': [
          {'id': 's7_1', 'name': 'Instant Geyser', 'image': '${storageBase}categories%2Fgeyser%2Finstant_geyser.png?alt=media'},
          {'id': 's7_2', 'name': 'Storage Tank Geyser', 'image': '${storageBase}categories%2Fgeyser%2Fstorage_tank_geyser.png?alt=media'},
        ]
      },
      {
        'id': 'm8',
        'name': 'Microwave Oven',
        'iconName': 'microwave_rounded',
        'subCategories': [
          {'id': 's8_1', 'name': 'Convection Oven', 'image': '${storageBase}categories%2Fmicrowave_oven%2Fconvection_oven.png?alt=media'},
          {'id': 's8_2', 'name': 'Solo / Grill Microwave', 'image': '${storageBase}categories%2Fmicrowave_oven%2Fsolo_grill_microwave.png?alt=media'},
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
        'image': '${storageBase}banners%2Ftop_banner%2Fchimney_cleaning.png?alt=media',
        'placement': 'top_banner',
      },
      {
        'title': 'Washing Machine Service Special',
        'subtitle': 'Flat ₹150 OFF on Front Load servicing',
        'image': '${storageBase}banners%2Ftop_banner%2Fwashing_machine_service.png?alt=media',
        'placement': 'top_banner',
      },
      {
        'title': 'RO Water Purifier Servicing',
        'subtitle': 'Free TDS Check with filter replacement',
        'image': '${storageBase}banners%2Fbottom_banner%2Fwater_purifier_servicing.png?alt=media',
        'placement': 'bottom_banner',
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
        'image': '${storageBase}products%2Fstandard_ro%2Faquapure_economic_ro.png?alt=media'
      },
      {
        'id': 'p2',
        'name': 'LivPure UV Compact',
        'subCategory': 'UV Purifier',
        'price': '₹8,499',
        'image': '${storageBase}products%2Fuv_purifier%2Flivpure_uv_compact.png?alt=media'
      },
      {
        'id': 'p3',
        'name': 'AquaShield Copper RO',
        'subCategory': 'Standard RO',
        'price': '₹12,999',
        'image': '${storageBase}products%2Fstandard_ro%2Faquashield_copper_ro.png?alt=media'
      },
      {
        'id': 'p4',
        'name': 'HydroAlkaline Premium',
        'subCategory': 'Alkaline Special',
        'price': '₹16,500',
        'image': '${storageBase}products%2Falkaline_special%2Fhydroalkaline_premium.png?alt=media'
      },
      {
        'id': 'p5',
        'name': 'Kent Maxima Pro RO+UV',
        'subCategory': 'UV Purifier',
        'price': '₹19,999',
        'image': '${storageBase}products%2Fuv_purifier%2Fkent_maxima_pro_ro_uv.png?alt=media'
      },
      {
        'id': 'p6',
        'name': 'AquaGrand Luxury Custom',
        'subCategory': 'Alkaline Special',
        'price': '₹29,999',
        'image': '${storageBase}products%2Falkaline_special%2Faquagrand_luxury_custom.png?alt=media'
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

