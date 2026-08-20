import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/BookingEntry.dart';
import '../models/UserModel.dart';
import '../models/AddressModel.dart';
import '../models/OrderModel.dart';
import 'notification_service.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  bool _isFirebaseAvailable = false;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  // Getter for the SQLite database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  // Set Firebase availability status
  void setFirebaseAvailable(bool available) {
    _isFirebaseAvailable = available;
    if (available) {
      syncPendingData();
    }
  }

  // Get Firebase availability status
  bool get isFirebaseAvailable => _isFirebaseAvailable;

  // Dynamic user UID resolution based on active FirebaseAuth session
  String get _currentUserUid {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    return 'guest_user';
  }

  Future<Map<String, String>?> fetchProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final uid = user.uid;
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'user_profile',
      where: 'uid = ? AND isLoggedIn = 1',
      whereArgs: [uid],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      final profile = maps.first;
      return {
        'name': profile['name'] ?? '',
        'phone': profile['phone'] ?? '',
        'email': profile['email'] ?? '',
      };
    }

    // Try fetching from Firestore users/{uid} document directly
    if (_isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = data['name'] as String? ?? 'User';
          final phone = data['phone'] as String? ?? '';
          final email = data['email'] as String? ?? '';

          await saveProfile(name, phone, email);
          return {'name': name, 'phone': phone, 'email': email};
        }
      } catch (e) {
        debugPrint('Firebase fetch by UID failed: $e');
      }
    }

    final name = user.displayName ?? '';
    final email = user.email ?? '';
    final phone = user.phoneNumber ?? '';
    if (name.isNotEmpty || phone.isNotEmpty) {
      await saveProfile(name, phone, email);
      return {'name': name, 'phone': phone, 'email': email};
    }
    return null;
  }

  Future<Map<String, String>?> fetchProfileByPhone(String phone) async {
    return fetchProfile();
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, 'bharathfix.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        // Create bookings table with all columns including UID customer tracking
        await db.execute('''
          CREATE TABLE bookings(
            id TEXT PRIMARY KEY,
            title TEXT,
            dateTime TEXT,
            cost TEXT,
            visitingFee REAL,
            quoteTotal REAL,
            finalAmountPaid REAL,
            status TEXT,
            address TEXT,
            latitude REAL,
            longitude REAL,
            isSynced INTEGER DEFAULT 0,
            startOtp TEXT,
            completionOtp TEXT,
            providerId TEXT,
            providerName TEXT,
            providerPhone TEXT,
            customerId TEXT,
            customerName TEXT,
            customerPhone TEXT,
            quoteItems TEXT,
            beforePhotos TEXT,
            afterPhotos TEXT,
            paymentMode TEXT,
            isVisitingFeePaid INTEGER DEFAULT 0,
            isFinalBillPaid INTEGER DEFAULT 0
          )
        ''');

        // Create addresses table
        await db.execute('''
          CREATE TABLE addresses(
            id TEXT PRIMARY KEY,
            details TEXT,
            tag TEXT,
            isSynced INTEGER DEFAULT 0
          )
        ''');

        // Create user_profile table (indexed by Firebase Auth UID)
        await db.execute('''
          CREATE TABLE user_profile(
            uid TEXT PRIMARY KEY,
            phone TEXT,
            name TEXT,
            email TEXT,
            isLoggedIn INTEGER DEFAULT 0
          )
        ''');

        // Create orders table
        await db.execute('''
          CREATE TABLE IF NOT EXISTS orders(
            id TEXT PRIMARY KEY,
            userId TEXT,
            userName TEXT,
            userPhone TEXT,
            userEmail TEXT,
            deliveryAddress TEXT,
            productId TEXT,
            productName TEXT,
            productImage TEXT,
            price REAL,
            quantity INTEGER,
            discountAmount REAL,
            totalPaid REAL,
            orderStatus TEXT,
            deliveryPartnerId TEXT,
            deliveryPartnerName TEXT,
            deliveryPartnerPhone TEXT,
            deliveryOtp TEXT,
            paymentMode TEXT,
            isPaid INTEGER,
            createdAt TEXT,
            expectedDeliveryDate TEXT,
            deliveredAt TEXT,
            isSynced INTEGER DEFAULT 0
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        await _ensureBookingColumns(db);
      },
    );
  }

  static Future<void> _ensureBookingColumns(Database db) async {
    final columnsToEnsure = [
      'visitingFee REAL',
      'quoteTotal REAL',
      'finalAmountPaid REAL',
      'latitude REAL',
      'longitude REAL',
      'startOtp TEXT',
      'completionOtp TEXT',
      'providerId TEXT',
      'providerName TEXT',
      'providerPhone TEXT',
      'customerId TEXT',
      'customerName TEXT',
      'customerPhone TEXT',
      'quoteItems TEXT',
      'beforePhotos TEXT',
      'afterPhotos TEXT',
      'paymentMode TEXT',
      'isVisitingFeePaid INTEGER DEFAULT 0',
      'isFinalBillPaid INTEGER DEFAULT 0',
    ];

    for (final col in columnsToEnsure) {
      try {
        await db.execute('ALTER TABLE bookings ADD COLUMN $col;');
      } catch (_) {
        // Ignored if column already exists
      }
    }
  }

  // ==================== BOOKINGS WORKFLOW ====================

  Future<void> insertBooking(BookingEntry booking) async {
    final db = await database;
    final uid = _currentUserUid;
    final profile = await fetchProfile();

    final String startOtp = (booking.startOtp.isNotEmpty && booking.startOtp != '0')
        ? booking.startOtp
        : (1000 + (DateTime.now().millisecondsSinceEpoch % 9000)).toString();
    final String completionOtp = (booking.completionOtp.isNotEmpty && booking.completionOtp != '0')
        ? booking.completionOtp
        : (1000 + ((DateTime.now().millisecondsSinceEpoch + 555) % 9000)).toString();

    final scopedBooking = booking.copyWith(
      customerId: booking.customerId.isNotEmpty ? booking.customerId : uid,
      customerName: booking.customerName.isNotEmpty
          ? booking.customerName
          : (profile?['name'] ?? 'Customer'),
      customerPhone: booking.customerPhone.isNotEmpty
          ? booking.customerPhone
          : (profile?['phone'] ?? ''),
      startOtp: startOtp,
      completionOtp: completionOtp,
    );

    // Ensure all columns exist before inserting
    await _ensureBookingColumns(db);

    // Save to SQLite using toSQLiteMap() (converts Lists to JSON strings & bools to 1/0)
    try {
      await db.insert(
        'bookings',
        scopedBooking.toSQLiteMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      debugPrint(
        'SQLite full insert failed ($e). Falling back to basic legacy columns.',
      );
      final legacyMap = {
        'id': scopedBooking.id,
        'title': scopedBooking.title,
        'dateTime': scopedBooking.dateTime,
        'cost': scopedBooking.cost,
        'status': scopedBooking.status.code,
        'address': scopedBooking.address,
        'isSynced': scopedBooking.isSynced,
        'customerId': scopedBooking.customerId,
      };
      await db.insert(
        'bookings',
        legacyMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    // Attempt Firebase Firestore dual-write sync
    if (_isFirebaseAvailable) {
      try {
        final bookingData = {
          ...scopedBooking.copyWith(isSynced: 1).toMap(),
          'userId': uid,
          'userPhone': scopedBooking.customerPhone,
          'userName': scopedBooking.customerName,
          'createdAt': FieldValue.serverTimestamp(),
        };

        final batch = FirebaseFirestore.instance.batch();

        // 1. Subcollection path: users/{uid}/bookings/{id}
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .doc(scopedBooking.id);
        batch.set(userDoc, bookingData, SetOptions(merge: true));

        // 2. Root path: bookings/{id}
        final rootDoc = FirebaseFirestore.instance
            .collection('bookings')
            .doc(scopedBooking.id);
        batch.set(rootDoc, bookingData, SetOptions(merge: true));

        await batch.commit();

        // Dispatch workflow notifications
        try {
          NotificationService.sendNotificationToUser(
            userId: uid,
            title: 'Booking Confirmed! 🎯',
            body:
                'Order #${scopedBooking.id} for ${scopedBooking.title} placed. Searching for nearby technician...',
            data: {'bookingId': scopedBooking.id, 'type': 'BOOKING_CONFIRMED'},
          );
          NotificationService.sendNotificationToAdmin(
            title: 'New Booking Received 📊',
            body:
                'Booking #${scopedBooking.id} placed by ${scopedBooking.customerName} (${scopedBooking.customerPhone}).',
            data: {'bookingId': scopedBooking.id, 'type': 'NEW_BOOKING'},
          );
        } catch (_) {}

        // Update local status to synced
        await db.update(
          'bookings',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [scopedBooking.id],
        );
      } catch (e) {
        debugPrint('Firebase booking sync failed: $e');
      }
    }
  }

  Future<List<BookingEntry>> fetchBookings() async {
    final uid = _currentUserUid;
    final db = await database;

    if (_isFirebaseAvailable && uid != 'guest_user') {
      try {
        final Map<String, Map<String, dynamic>> activeMap = {};

        // 1. Fetch from root bookings collection
        final rootSnap = await FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: uid)
            .get();

        for (var doc in rootSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          activeMap[doc.id] = data;
        }

        // 2. Fetch from subcollection users/{uid}/bookings
        final subSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .get();

        for (var doc in subSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          activeMap[doc.id] = data;
        }

        // 3. Purge local SQLite DB of any bookings deleted from Firestore
        final localMaps = await db.query('bookings');
        final activeIds = activeMap.keys.toSet();

        for (var localRow in localMaps) {
          final localId = localRow['id'] as String?;
          if (localId != null && !activeIds.contains(localId)) {
            await db.delete('bookings', where: 'id = ?', whereArgs: [localId]);
          }
        }

        // 4. Update local SQLite DB with current active Firestore bookings
        for (var entryMap in activeMap.values) {
          final entry = BookingEntry.fromMap(entryMap);
          await db.insert(
            'bookings',
            entry.toSQLiteMap(),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }

        return activeMap.values.map((m) => BookingEntry.fromMap(m)).toList();
      } catch (e) {
        debugPrint('Error fetching live bookings from Firestore: $e');
      }
    }

    // Offline or fallback SQLite read
    List<Map<String, dynamic>> maps = [];
    try {
      maps = await db.query(
        'bookings',
        where: 'customerId = ? OR customerId IS NULL OR customerId = ""',
        whereArgs: [uid],
        orderBy: 'id DESC',
      );
    } catch (_) {
      maps = await db.query('bookings', orderBy: 'id DESC');
    }

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return BookingEntry.fromMap(maps[i]);
    });
  }

  // Realtime stream of customer bookings from Firestore
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserBookingsStream() {
    final uid = _currentUserUid;
    return FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: uid)
        .snapshots();
  }

  /// Delete a booking document from Firestore and local SQLite storage
  Future<void> deleteBooking(String bookingId) async {
    final uid = _currentUserUid;
    try {
      final db = await database;
      await db.delete('bookings', where: 'id = ?', whereArgs: [bookingId]);
    } catch (e) {
      debugPrint('Local SQLite booking delete failed: $e');
    }

    if (_isFirebaseAvailable) {
      try {
        final batch = FirebaseFirestore.instance.batch();

        final rootDoc = FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId);
        batch.delete(rootDoc);

        if (uid != 'guest_user') {
          final userDoc = FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('bookings')
              .doc(bookingId);
          batch.delete(userDoc);
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Firebase booking delete failed: $e');
      }
    }
  }

  // ==================== ADDRESS WORKFLOW ====================

  Future<void> insertAddress(
    String id,
    String details,
    String tag, {
    AddressModel? addressModel,
  }) async {
    final db = await database;

    final model = addressModel ??
        AddressModel(
          id: id,
          details: details,
          tag: tag,
        );

    final addressMap = {
      'id': model.id,
      'details': model.details,
      'tag': model.tag,
      'isSynced': 0,
    };

    await db.insert(
      'addresses',
      addressMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (_isFirebaseAvailable) {
      try {
        final uid = _currentUserUid;
        if (uid != 'guest_user') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('addresses')
              .doc(model.id)
              .set(model.toMap());

          if (model.isDefault) {
            await FirebaseFirestore.instance
                .collection('users')
                .doc(uid)
                .set({
              'defaultAddress': model.details,
              'address': model.details,
            }, SetOptions(merge: true));
          }

          await db.update(
            'addresses',
            {'isSynced': 1},
            where: 'id = ?',
            whereArgs: [model.id],
          );
        }
      } catch (e) {
        debugPrint('Firebase address sync failed (will retry later): $e');
      }
    }
  }

  Future<List<AddressModel>> fetchAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('addresses');
    final List<AddressModel> resultList =
        maps.map((m) => AddressModel.fromMap(m)).toList();

    if (_isFirebaseAvailable) {
      try {
        final uid = _currentUserUid;
        if (uid != 'guest_user') {
          final List<AddressModel> remoteList = [];

          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('addresses')
              .get();

          for (var doc in snap.docs) {
            remoteList.add(AddressModel.fromMap(doc.data(), docId: doc.id));
          }

          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .get();

          if (userDoc.exists && userDoc.data() != null) {
            final userModel = UserModel.fromMap(userDoc.data()!, docId: uid);
            for (var addr in userModel.addresses) {
              final existsInRemote = remoteList.any(
                (a) => a.id == addr.id || a.details.trim() == addr.details.trim(),
              );
              if (!existsInRemote) {
                remoteList.add(addr);
              }
            }
          }

          for (var remote in remoteList) {
            final alreadyInLocal = resultList.any(
              (l) => l.id == remote.id || l.details.trim() == remote.details.trim(),
            );
            if (!alreadyInLocal) {
              resultList.add(remote);
              await db.insert(
                'addresses',
                {
                  'id': remote.id,
                  'details': remote.details,
                  'tag': remote.tag,
                  'isSynced': 1,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching addresses from Firestore: $e');
      }
    }

    return resultList;
  }

  Future<void> deleteAddress(String id) async {
    final db = await database;
    await db.delete('addresses', where: 'id = ?', whereArgs: [id]);

    if (_isFirebaseAvailable) {
      try {
        final uid = _currentUserUid;
        if (uid != 'guest_user') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('addresses')
              .doc(id)
              .delete();
        }
      } catch (e) {
        debugPrint('Firebase address delete failed: $e');
      }
    }
  }

  // ==================== ORDERS WORKFLOW ====================

  Future<void> insertOrder(OrderModel order) async {
    final db = await database;

    await db.insert(
      'orders',
      {
        'id': order.id,
        'userId': order.userId,
        'userName': order.userName,
        'userPhone': order.userPhone,
        'userEmail': order.userEmail,
        'deliveryAddress': order.deliveryAddress,
        'productId': order.productId,
        'productName': order.productName,
        'productImage': order.productImage,
        'price': order.price,
        'quantity': order.quantity,
        'discountAmount': order.discountAmount,
        'totalPaid': order.totalPaid,
        'orderStatus': order.orderStatus.name,
        'deliveryPartnerId': order.deliveryPartnerId,
        'deliveryPartnerName': order.deliveryPartnerName,
        'deliveryPartnerPhone': order.deliveryPartnerPhone,
        'deliveryOtp': order.deliveryOtp,
        'paymentMode': order.paymentMode,
        'isPaid': order.isPaid ? 1 : 0,
        'createdAt': order.createdAt?.toIso8601String(),
        'expectedDeliveryDate': order.expectedDeliveryDate,
        'deliveredAt': order.deliveredAt?.toIso8601String(),
        'isSynced': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (_isFirebaseAvailable) {
      try {
        final uid = _currentUserUid;
        final firestoreMap = order.toMap();

        // 1. Dual-write to root 'orders' collection (for Delivery Partners)
        await FirebaseFirestore.instance
            .collection('orders')
            .doc(order.id)
            .set(firestoreMap);

        // 2. Dual-write to user subcollection 'users/{uid}/orders'
        if (uid != 'guest_user') {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('orders')
              .doc(order.id)
              .set(firestoreMap);
        }

        await db.update(
          'orders',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [order.id],
        );
      } catch (e) {
        debugPrint('Firebase order sync failed: $e');
      }
    }
  }

  Future<List<OrderModel>> fetchOrders() async {
    final db = await database;
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS orders(
          id TEXT PRIMARY KEY,
          userId TEXT,
          userName TEXT,
          userPhone TEXT,
          userEmail TEXT,
          deliveryAddress TEXT,
          productId TEXT,
          productName TEXT,
          productImage TEXT,
          price REAL,
          quantity INTEGER,
          discountAmount REAL,
          totalPaid REAL,
          orderStatus TEXT,
          deliveryPartnerId TEXT,
          deliveryPartnerName TEXT,
          deliveryPartnerPhone TEXT,
          deliveryOtp TEXT,
          paymentMode TEXT,
          isPaid INTEGER,
          createdAt TEXT,
          expectedDeliveryDate TEXT,
          deliveredAt TEXT,
          isSynced INTEGER DEFAULT 0
        )
      ''');
    } catch (_) {}

    final List<Map<String, dynamic>> maps =
        await db.query('orders', orderBy: 'rowid DESC');
    final List<OrderModel> resultList =
        maps.map((m) => OrderModel.fromMap(m)).toList();

    if (_isFirebaseAvailable) {
      try {
        final uid = _currentUserUid;
        if (uid != 'guest_user') {
          final snap = await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('orders')
              .get();

          for (var doc in snap.docs) {
            final remote = OrderModel.fromMap(doc.data(), docId: doc.id);
            final alreadyInLocal = resultList.any((l) => l.id == remote.id);
            if (!alreadyInLocal) {
              resultList.add(remote);
              await db.insert(
                'orders',
                {
                  'id': remote.id,
                  'userId': remote.userId,
                  'userName': remote.userName,
                  'userPhone': remote.userPhone,
                  'userEmail': remote.userEmail,
                  'deliveryAddress': remote.deliveryAddress,
                  'productId': remote.productId,
                  'productName': remote.productName,
                  'productImage': remote.productImage,
                  'price': remote.price,
                  'quantity': remote.quantity,
                  'discountAmount': remote.discountAmount,
                  'totalPaid': remote.totalPaid,
                  'orderStatus': remote.orderStatus.name,
                  'deliveryPartnerId': remote.deliveryPartnerId,
                  'deliveryPartnerName': remote.deliveryPartnerName,
                  'deliveryPartnerPhone': remote.deliveryPartnerPhone,
                  'deliveryOtp': remote.deliveryOtp,
                  'paymentMode': remote.paymentMode,
                  'isPaid': remote.isPaid ? 1 : 0,
                  'createdAt': remote.createdAt?.toIso8601String(),
                  'expectedDeliveryDate': remote.expectedDeliveryDate,
                  'deliveredAt': remote.deliveredAt?.toIso8601String(),
                  'isSynced': 1,
                },
                conflictAlgorithm: ConflictAlgorithm.replace,
              );
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching orders from Firestore: $e');
      }
    }

    return resultList;
  }

  Stream<List<OrderModel>> streamOrders() {
    final uid = _currentUserUid;
    if (uid == 'guest_user') {
      return Stream.fromFuture(fetchOrders());
    }

    return FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
      final List<OrderModel> orders = snap.docs
          .map((doc) => OrderModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      orders.sort((a, b) {
        final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
        final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
        if (aTime != 0 || bTime != 0) return bTime.compareTo(aTime);
        return b.id.compareTo(a.id);
      });
      return orders;
    });
  }

  // ==================== PROFILE WORKFLOW ====================

  Future<UserModel?> fetchUserProfile([String? uidParam]) async {
    final user = FirebaseAuth.instance.currentUser;
    final uid = uidParam ?? user?.uid ?? _currentUserUid;
    if (uid == 'guest_user' && user == null) return null;

    final db = await database;
    try {
      final maps = await db.query(
        'user_profile',
        where: 'uid = ? AND isLoggedIn = 1',
        whereArgs: [uid],
        limit: 1,
      );
      if (maps.isNotEmpty) {
        final model = UserModel.fromMap(maps.first, docId: uid);
        if (model.name.trim().isNotEmpty) {
          return model;
        }
      }
    } catch (e) {
      debugPrint('Local SQLite user query failed: $e');
    }

    if (_isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final model = UserModel.fromMap(doc.data()!, docId: uid);
          if (model.name.trim().isNotEmpty) {
            await saveUserProfile(model);
            return model;
          }
        }

        final rawPhone = (user?.phoneNumber ?? uidParam ?? '').trim();
        final cleanDigits = rawPhone.replaceAll(RegExp(r'\D'), '');

        if (cleanDigits.isNotEmpty) {
          final phoneVariants = {
            rawPhone,
            cleanDigits,
            '+91$cleanDigits',
            '+91 $cleanDigits',
            if (cleanDigits.length >= 10)
              cleanDigits.substring(cleanDigits.length - 10),
            if (cleanDigits.length >= 10)
              '+91${cleanDigits.substring(cleanDigits.length - 10)}',
            if (cleanDigits.length >= 10)
              '+91 ${cleanDigits.substring(cleanDigits.length - 10)}',
          };

          for (final variant in phoneVariants) {
            if (variant.isEmpty) continue;
            final snap = await FirebaseFirestore.instance
                .collection('users')
                .where('phone', isEqualTo: variant)
                .limit(1)
                .get();
            if (snap.docs.isNotEmpty) {
              final foundDoc = snap.docs.first;
              final model = UserModel.fromMap(
                foundDoc.data(),
                docId: foundDoc.id,
              );
              if (model.name.trim().isNotEmpty) {
                await saveUserProfile(model);
                return model;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Firebase fetch user profile failed: $e');
      }
    }

    return null;
  }

  Future<void> saveUserProfile(UserModel userModel) async {
    final db = await database;
    final uid = userModel.uid.isNotEmpty ? userModel.uid : _currentUserUid;

    final profileMap = {
      'uid': uid,
      'phone': userModel.phone,
      'name': userModel.name,
      'email': userModel.email,
      'isLoggedIn': 1,
    };

    await db.insert(
      'user_profile',
      profileMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userModel.toMap(), SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firebase profile sync failed: $e');
      }
    }
  }

  Future<void> saveProfile(String name, String phone, String email) async {
    final uid = _currentUserUid;
    final userModel = UserModel(
      uid: uid,
      name: name,
      phone: phone,
      email: email,
    );
    await saveUserProfile(userModel);
  }

  Future<void> logoutUser() async {
    try {
      final db = await database;
      await db.update('user_profile', {'isLoggedIn': 0});
      await db.delete('user_profile');
      await db.delete('bookings');
      await db.delete('addresses');
    } catch (e) {
      debugPrint('Error logging out in local DB: $e');
    }

    try {
      if (_isFirebaseAvailable) {
        await FirebaseFirestore.instance.clearPersistence();
      }
    } catch (e) {
      debugPrint('Error clearing Firestore persistence on logout: $e');
    }
  }

  Future<void> clearProfile() async {
    try {
      final db = await database;
      await db.delete('user_profile');
      await db.delete('bookings');
      await db.delete('addresses');
    } catch (e) {
      debugPrint('Error clearing profile tables: $e');
    }

    try {
      if (_isFirebaseAvailable) {
        await FirebaseFirestore.instance.clearPersistence();
      }
    } catch (e) {
      debugPrint('Error clearing Firestore persistence: $e');
    }
  }

  // ==================== AUTO-SYNCHRONIZATION WORKER ====================

  Future<void> syncPendingData() async {
    if (!_isFirebaseAvailable) return;

    final db = await database;
    final uid = _currentUserUid;

    // 1. Sync pending bookings
    final List<Map<String, dynamic>> unsyncedBookings = await db.query(
      'bookings',
      where: 'isSynced = 0',
    );

    for (var bMap in unsyncedBookings) {
      final booking = BookingEntry.fromMap(bMap);
      try {
        final profile = await fetchProfile();
        final bookingData = {
          ...booking.copyWith(isSynced: 1).toMap(),
          'userId': uid,
          'userPhone': profile?['phone'] ?? '',
          'userName': profile?['name'] ?? 'Customer',
          'createdAt': FieldValue.serverTimestamp(),
        };

        final batch = FirebaseFirestore.instance.batch();
        batch.set(
          FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .collection('bookings')
              .doc(booking.id),
          bookingData,
          SetOptions(merge: true),
        );
        batch.set(
          FirebaseFirestore.instance.collection('bookings').doc(booking.id),
          bookingData,
          SetOptions(merge: true),
        );
        await batch.commit();

        await db.update(
          'bookings',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [booking.id],
        );
      } catch (e) {
        debugPrint('Async syncing booking ${booking.id} failed: $e');
      }
    }

    // 2. Sync pending addresses
    final List<Map<String, dynamic>> unsyncedAddresses = await db.query(
      'addresses',
      where: 'isSynced = 0',
    );

    for (var aMap in unsyncedAddresses) {
      final id = aMap['id'];
      final details = aMap['details'];
      final tag = aMap['tag'] ?? 'Home';
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('addresses')
            .doc(id)
            .set({'id': id, 'details': details, 'tag': tag});

        await db.update(
          'addresses',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        debugPrint('Async syncing address $id failed: $e');
      }
    }
  }

  // ==================== WALLET WORKFLOW ====================

  /// Stream of user's live wallet balance from Firestore linked to user's UID
  Stream<double> walletBalanceStream() {
    final uid = _currentUserUid;
    if (uid == 'guest_user') {
      return Stream.value(0.0);
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final data = snapshot.data()!;
            if (data.containsKey('walletBalance')) {
              final val = data['walletBalance'];
              if (val is num) return val.toDouble();
            }
          }
          return 0.0;
        });
  }

  /// Fetch user's current wallet balance
  Future<double> getWalletBalance() async {
    final uid = _currentUserUid;
    if (uid == 'guest_user') return 0.0;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        if (data.containsKey('walletBalance')) {
          final val = data['walletBalance'];
          if (val is num) return val.toDouble();
        }
      }
    } catch (e) {
      debugPrint('Error getting wallet balance: $e');
    }
    return 0.0;
  }

  /// Stream of wallet transactions ordered by timestamp descending
  Stream<List<Map<String, dynamic>>> walletTransactionsStream() {
    final uid = _currentUserUid;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('wallet_transactions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return data;
          }).toList();
        });
  }

  /// Credit money to wallet (Top-Up, Cashback, Refund)
  Future<bool> creditWallet({
    required double amount,
    required String description,
    String? razorpayPaymentId,
  }) async {
    final uid = _currentUserUid;
    final txId = 'tx_credit_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toIso8601String();

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.set({
        'walletBalance': FieldValue.increment(amount),
      }, SetOptions(merge: true));

      // Record transaction
      await userRef.collection('wallet_transactions').doc(txId).set({
        'id': txId,
        'amount': amount,
        'type': 'CREDIT',
        'description': description,
        'timestamp': timestamp,
        'paymentId':
            razorpayPaymentId ??
            'razorpay_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'SUCCESS',
      });

      return true;
    } catch (e) {
      debugPrint('Error crediting wallet: $e');
      return false;
    }
  }

  /// Debit money from wallet (Service Payment / Purchase) atomically
  Future<bool> debitWallet({
    required double amount,
    required String description,
    String? bookingId,
  }) async {
    final uid = _currentUserUid;
    if (uid == 'guest_user') return false;

    final txId = 'tx_debit_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toIso8601String();
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    try {
      final success = await FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        double currentBalance = 0.0;
        if (userSnapshot.exists && userSnapshot.data() != null) {
          final val = userSnapshot.data()!['walletBalance'];
          if (val is num) currentBalance = val.toDouble();
        }

        if (currentBalance < amount) {
          return false; // Insufficient balance inside transaction
        }

        transaction.set(userRef, {
          'walletBalance': currentBalance - amount,
        }, SetOptions(merge: true));

        final txDocRef = userRef.collection('wallet_transactions').doc(txId);
        transaction.set(txDocRef, {
          'id': txId,
          'amount': amount,
          'type': 'DEBIT',
          'description': description,
          'timestamp': timestamp,
          'bookingId': bookingId ?? '',
          'status': 'SUCCESS',
        });

        return true;
      });

      return success;
    } catch (e) {
      debugPrint('Error debiting wallet in transaction: $e');
      return false;
    }
  }

  /// Submit rating, review comment, tags, and optional technician tip
  Future<bool> submitBookingRatingAndTip({
    required String bookingId,
    required String providerId,
    required double ratingStars,
    required List<String> tags,
    required String comment,
    required double tipAmount,
  }) async {
    try {
      final ratingData = {
        'bookingId': bookingId,
        'providerId': providerId,
        'ratingStars': ratingStars,
        'tags': tags,
        'comment': comment,
        'tipAmount': tipAmount,
        'timestamp': DateTime.now().toIso8601String(),
      };

      if (_isFirebaseAvailable) {
        await FirebaseFirestore.instance.collection('ratings').add(ratingData);
        if (bookingId.isNotEmpty) {
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({
                'ratingStars': ratingStars,
                'reviewComment': comment,
                'isRated': true,
              });
        }
      }

      if (tipAmount > 0) {
        await debitWallet(
          amount: tipAmount,
          description: 'Technician Tip for Booking #$bookingId',
          bookingId: bookingId,
        );
      }
      return true;
    } catch (e) {
      debugPrint('Error submitting rating and tip: $e');
      return false;
    }
  }

  Future<bool> isProductInStock(String productId, [int requiredQuantity = 1]) async {
    if (productId.isEmpty) return true;
    try {
      final doc = await FirebaseFirestore.instance.collection('products').doc(productId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final stock = (data['stockQuantity'] as num?)?.toInt() ?? 
                      (data['stock'] as num?)?.toInt() ?? 10;
        final bool isAvailable = data['isAvailable'] != false && data['inStock'] != false;
        return isAvailable && stock >= requiredQuantity;
      }
    } catch (e) {
      debugPrint('Error checking product stock: $e');
    }
    return true;
  }

  Future<void> decrementProductStock(String productId, [int count = 1]) async {
    if (productId.isEmpty) return;
    try {
      final docRef = FirebaseFirestore.instance.collection('products').doc(productId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snap = await transaction.get(docRef);
        if (snap.exists && snap.data() != null) {
          final currentStock = (snap.data()!['stockQuantity'] as num?)?.toInt() ??
                              (snap.data()!['stock'] as num?)?.toInt() ?? 0;
          final newStock = (currentStock - count).clamp(0, 999999);
          transaction.update(docRef, {
            'stockQuantity': newStock,
            if (newStock <= 0) 'isAvailable': false,
          });
        }
      });
      debugPrint('Successfully decremented product $productId stock by $count');
    } catch (e) {
      debugPrint('Error decrementing product stock for $productId: $e');
    }
  }

  Future<void> seedDefaultData() async {
    debugPrint("Firestore database service ready.");
  }

  Future<void> seedFirebaseIfEmpty() async {
    debugPrint("Firestore database service ready.");
  }
}

