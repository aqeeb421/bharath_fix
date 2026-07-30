import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/BookingEntry.dart';
import '../models/UserModel.dart';

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
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          final name = data['name'] as String? ?? 'User';
          final phone = data['phone'] as String? ?? '';
          final email = data['email'] as String? ?? '';
          
          await saveProfile(name, phone, email);
          return {
            'name': name,
            'phone': phone,
            'email': email,
          };
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
      return {
        'name': name,
        'phone': phone,
        'email': email,
      };
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

    final scopedBooking = booking.copyWith(
      customerId: booking.customerId.isNotEmpty ? booking.customerId : uid,
      customerName: booking.customerName.isNotEmpty ? booking.customerName : (profile?['name'] ?? 'Customer'),
      customerPhone: booking.customerPhone.isNotEmpty ? booking.customerPhone : (profile?['phone'] ?? ''),
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
      debugPrint('SQLite full insert failed ($e). Falling back to basic legacy columns.');
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
    final db = await database;
    final uid = _currentUserUid;
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
        .collection('users')
        .doc(uid)
        .collection('bookings')
        .snapshots();
  }

  // ==================== ADDRESS WORKFLOW ====================

  Future<void> insertAddress(String id, String details, String tag) async {
    final db = await database;

    final addressMap = {
      'id': id,
      'details': details,
      'tag': tag,
      'isSynced': 0,
    };

    await db.insert(
      'addresses',
      addressMap,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserUid)
            .collection('addresses')
            .doc(id)
            .set({
              'id': id,
              'details': details,
              'tag': tag,
            });

        await db.update(
          'addresses',
          {'isSynced': 1},
          where: 'id = ?',
          whereArgs: [id],
        );
      } catch (e) {
        debugPrint('Firebase address sync failed (will retry later): $e');
      }
    }
  }

  Future<List<Map<String, String>>> fetchAddresses() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('addresses');
    
    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return {
        'id': maps[i]['id'] as String? ?? '',
        'details': maps[i]['details'] as String? ?? '',
        'tag': maps[i]['tag'] as String? ?? 'Home',
      };
    });
  }

  Future<void> deleteAddress(String id) async {
    final db = await database;
    await db.delete('addresses', where: 'id = ?', whereArgs: [id]);
    
    if (_isFirebaseAvailable) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserUid)
            .collection('addresses')
            .doc(id)
            .delete();
      } catch (e) {
        debugPrint('Firebase address delete failed: $e');
      }
    }
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
        return UserModel.fromMap(maps.first, docId: uid);
      }
    } catch (e) {
      debugPrint('Local SQLite user query failed: $e');
    }

    if (_isFirebaseAvailable) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
        if (doc.exists && doc.data() != null) {
          final model = UserModel.fromMap(doc.data()!, docId: uid);
          if (model.name.isNotEmpty) {
            await saveUserProfile(model);
            return model;
          }
        }
      } catch (e) {
        debugPrint('Firebase fetch user profile failed: $e');
      }
    }

    if (user != null) {
      final name = user.displayName ?? '';
      final phone = user.phoneNumber ?? '';
      final email = user.email ?? '';
      if (name.isNotEmpty || phone.isNotEmpty) {
        final model = UserModel(
          uid: uid,
          name: name,
          phone: phone,
          email: email,
        );
        await saveUserProfile(model);
        return model;
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

  Future<void> clearProfile() async {
    final db = await database;
    await db.delete('user_profile');
    await db.delete('bookings');
    await db.delete('addresses');
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
          FirebaseFirestore.instance.collection('users').doc(uid).collection('bookings').doc(booking.id),
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
            .set({
              'id': id,
              'details': details,
              'tag': tag,
            });

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
      final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
        'paymentId': razorpayPaymentId ?? 'razorpay_${DateTime.now().millisecondsSinceEpoch}',
        'status': 'SUCCESS',
      });

      return true;
    } catch (e) {
      debugPrint('Error crediting wallet: $e');
      return false;
    }
  }

  /// Debit money from wallet (Service Payment / Purchase)
  Future<bool> debitWallet({
    required double amount,
    required String description,
    String? bookingId,
  }) async {
    final uid = _currentUserUid;
    final currentBalance = await getWalletBalance();

    if (currentBalance < amount) {
      return false; // Insufficient balance
    }

    final txId = 'tx_debit_${DateTime.now().millisecondsSinceEpoch}';
    final timestamp = DateTime.now().toIso8601String();

    try {
      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

      await userRef.set({
        'walletBalance': FieldValue.increment(-amount),
      }, SetOptions(merge: true));

      // Record transaction
      await userRef.collection('wallet_transactions').doc(txId).set({
        'id': txId,
        'amount': amount,
        'type': 'DEBIT',
        'description': description,
        'timestamp': timestamp,
        'bookingId': bookingId ?? '',
        'status': 'SUCCESS',
      });

      return true;
    } catch (e) {
      debugPrint('Error debiting wallet: $e');
      return false;
    }
  }

  Future<void> seedDefaultData() async {
    debugPrint("Firestore database service ready.");
  }

  Future<void> seedFirebaseIfEmpty() async {
    debugPrint("Firestore database service ready.");
  }
}
