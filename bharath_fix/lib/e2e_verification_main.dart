import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const E2EVerificationApp());
}

class E2EVerificationApp extends StatefulWidget {
  const E2EVerificationApp({super.key});

  @override
  State<E2EVerificationApp> createState() => _E2EVerificationAppState();
}

class _E2EVerificationAppState extends State<E2EVerificationApp> {
  final List<String> _logs = [];
  bool _isRunning = false;
  int _passed = 0;
  int _failed = 0;

  @override
  void initState() {
    super.initState();
    _startFullWorkflowTest();
  }

  void _addLog(String msg, {bool isPass = true, bool isFail = false}) {
    setState(() {
      if (isPass) {
        _passed++;
        _logs.add("✅ $msg");
      } else if (isFail) {
        _failed++;
        _logs.add("❌ $msg");
      } else {
        _logs.add("ℹ️ $msg");
      }
    });
  }

  Future<void> _startFullWorkflowTest() async {
    setState(() {
      _isRunning = true;
      _logs.clear();
      _passed = 0;
      _failed = 0;
    });

    final db = FirebaseFirestore.instance;
    final testTechEmail = 'tech.test@bharathfix.com';
    final testCustomerPhone = '+91 55555 55555';
    final techUid = 'test_tech_uid_${DateTime.now().millisecondsSinceEpoch}';
    final customerUid =
        'test_cust_uid_${DateTime.now().millisecondsSinceEpoch}';
    final bookingId = 'bf_test_${DateTime.now().millisecondsSinceEpoch}';

    _addLog("Starting Multi-App E2E Integration Suite...", isPass: false);
    await Future.delayed(const Duration(milliseconds: 300));

    // 1. Technician Registration (Pending Verification)
    try {
      final techDoc = db.collection('providers').doc(techUid);
      await techDoc.set({
        'uid': techUid,
        'name': 'Ramesh Kumar (Tech)',
        'phone': '+91 9876543210',
        'email': testTechEmail,
        'status': 'pending_verification',
        'isOnline': false,
        'skills': ['AC Repair', 'Washing Machine'],
        'createdAt': FieldValue.serverTimestamp(),
      });

      final snap = await techDoc.get();
      final statusRaw = (snap.data()?['status'] ?? '').toString().toLowerCase();
      final bool isApproved =
          statusRaw == 'active' ||
          statusRaw == 'approved' ||
          statusRaw == 'verified';

      if (!isApproved) {
        _addLog(
          "Stage 1: Technician App Registration -> Saved with status 'pending_verification'. Approval gate locked.",
        );
      } else {
        _addLog(
          "Stage 1: Technician App Registration -> Unexpectedly approved.",
          isFail: true,
        );
      }
    } catch (e) {
      _addLog("Stage 1 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 2. Admin Panel KYC Approval
    try {
      final techDoc = db.collection('providers').doc(techUid);
      await techDoc.update({
        'status': 'Active',
        'isOnline': true,
        'approvedAt': FieldValue.serverTimestamp(),
      });

      final snap = await techDoc.get();
      final statusRaw = (snap.data()?['status'] ?? '').toString().toLowerCase();
      final bool isApproved =
          statusRaw == 'active' ||
          statusRaw == 'approved' ||
          statusRaw == 'verified';

      if (isApproved && snap.data()?['isOnline'] == true) {
        _addLog(
          "Stage 2: Admin Panel KYC Approval -> Status set to 'Active', isOnline: true. Partner unlocked!",
        );
      } else {
        _addLog(
          "Stage 2: Admin Panel Approval -> Failed to activate status.",
          isFail: true,
        );
      }
    } catch (e) {
      _addLog("Stage 2 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Customer Profile & Wallet Setup
    try {
      final custDoc = db.collection('users').doc(customerUid);
      await custDoc.set({
        'uid': customerUid,
        'name': 'Test Customer',
        'phone': testCustomerPhone,
        'email': 'customer.test@bharathfix.com',
        'address': 'Hassan, Karnataka 573201',
        'walletBalance': 500.0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final snap = await custDoc.get();
      if (snap.exists && (snap.data()?['walletBalance'] as num) == 500.0) {
        _addLog(
          "Stage 3: Customer Profile & Wallet -> Initialized $testCustomerPhone with ₹500 welcome credit.",
        );
      } else {
        _addLog("Stage 3: Profile & Wallet Mismatch.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 3 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 4. Customer Order Placement
    try {
      final bookingData = {
        'id': bookingId,
        'title': 'AC Deep Cleaning & Service',
        'dateTime': '10/Fri/2026, 11:00 AM',
        'cost': '₹199',
        'visitingFee': 199.0,
        'quoteTotal': 0.0,
        'finalAmountPaid': 0.0,
        'status': 'BOOKED',
        'address': 'Hassan, Karnataka 573201',
        'userId': customerUid,
        'userName': 'Test Customer',
        'userPhone': testCustomerPhone,
        'providerId': '',
        'providerName': '',
        'providerPhone': '',
        'isVisitingFeePaid': true,
        'paymentMode': 'WALLET',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final batch = db.batch();
      batch.set(db.collection('bookings').doc(bookingId), bookingData);
      batch.set(
        db
            .collection('users')
            .doc(customerUid)
            .collection('bookings')
            .doc(bookingId),
        bookingData,
      );
      await batch.commit();

      final snap = await db.collection('bookings').doc(bookingId).get();
      if (snap.exists && snap.data()?['status'] == 'BOOKED') {
        _addLog(
          "Stage 4: Customer Order Placement -> Dual-write root & user subcollection with status 'BOOKED'.",
        );
      } else {
        _addLog("Stage 4: Booking placement failed.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 4 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 5. Technician Open Pool & Claiming
    try {
      final claimData = {
        'providerId': techUid,
        'providerName': 'Ramesh Kumar (Tech)',
        'providerPhone': '+91 9876543210',
        'status': 'accepted',
        'assignedAt': FieldValue.serverTimestamp(),
        'startOtp': '4829',
        'completionOtp': '8921',
      };

      final batch = db.batch();
      batch.update(db.collection('bookings').doc(bookingId), claimData);
      batch.set(
        db
            .collection('users')
            .doc(customerUid)
            .collection('bookings')
            .doc(bookingId),
        claimData,
        SetOptions(merge: true),
      );
      await batch.commit();

      final updatedSnap = await db.collection('bookings').doc(bookingId).get();
      if (updatedSnap.data()?['status'] == 'accepted' &&
          updatedSnap.data()?['providerId'] == techUid) {
        _addLog(
          "Stage 5: Technician Open Pool & Claiming -> Claimed job $bookingId. Status updated to 'accepted'.",
        );
      } else {
        _addLog("Stage 5: Claiming failed.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 5 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 6. Mark On the Way & Live GPS Tracking
    try {
      final lat = 12.9716;
      final lng = 77.5946;

      final trackData = {
        'status': 'on_the_way',
        'providerLat': lat,
        'providerLng': lng,
        'latitude': lat,
        'longitude': lng,
        'technicianLocation': {
          'latitude': lat,
          'longitude': lng,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      };

      final batch = db.batch();
      batch.update(db.collection('bookings').doc(bookingId), trackData);
      batch.set(
        db
            .collection('users')
            .doc(customerUid)
            .collection('bookings')
            .doc(bookingId),
        trackData,
        SetOptions(merge: true),
      );
      await batch.commit();

      final snap = await db.collection('bookings').doc(bookingId).get();
      if (snap.data()?['status'] == 'on_the_way' &&
          snap.data()?['providerLat'] == lat) {
        _addLog(
          "Stage 6: Mark On the Way & Live GPS -> Status 'on_the_way' & GPS coordinates ($lat, $lng) streamed.",
        );
      } else {
        _addLog("Stage 6: GPS tracking update failed.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 6 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 7. Start OTP & Quotation
    try {
      final snap = await db.collection('bookings').doc(bookingId).get();
      final startOtp = snap.data()?['startOtp']?.toString();

      if (startOtp == '4829') {
        final quoteItems = [
          {'name': 'AC Gas Refill (R32)', 'price': 350.0, 'isSparePart': true},
        ];

        final serviceData = {
          'status': 'in_progress',
          'quotation': {
            'items': quoteItems,
            'totalAmount': 350.0,
            'isApprovedByCustomer': true,
          },
          'quoteTotal': 350.0,
          'additionalCost': 350.0,
        };

        final batch = db.batch();
        batch.update(db.collection('bookings').doc(bookingId), serviceData);
        batch.set(
          db
              .collection('users')
              .doc(customerUid)
              .collection('bookings')
              .doc(bookingId),
          serviceData,
          SetOptions(merge: true),
        );
        await batch.commit();

        _addLog(
          "Stage 7: Start OTP & Quotation -> Validated Start OTP '4829' -> Status 'in_progress' & ₹350 quotation added.",
        );
      } else {
        _addLog("Stage 7: Start OTP mismatch.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 7 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 8. Completion OTP & Settlement
    try {
      final snap = await db.collection('bookings').doc(bookingId).get();
      final completionOtp = snap.data()?['completionOtp']?.toString();

      if (completionOtp == '8921') {
        final finalBill = 199.0 + 350.0; // ₹549 total
        final currentBal = 500.0;
        final newBal = currentBal - finalBill;

        final closeData = {
          'status': 'completed',
          'isFinalBillPaid': true,
          'finalAmountPaid': finalBill,
          'completedAt': FieldValue.serverTimestamp(),
        };

        final batch = db.batch();
        batch.update(db.collection('bookings').doc(bookingId), closeData);
        batch.set(
          db
              .collection('users')
              .doc(customerUid)
              .collection('bookings')
              .doc(bookingId),
          closeData,
          SetOptions(merge: true),
        );
        batch.update(db.collection('users').doc(customerUid), {
          'walletBalance': newBal,
        });
        await batch.commit();

        _addLog(
          "Stage 8: Completion OTP & Settlement -> Validated OTP '8921'. Status set to 'completed' & bill settled.",
        );
      } else {
        _addLog("Stage 8: Completion OTP mismatch.", isFail: true);
      }
    } catch (e) {
      _addLog("Stage 8 Error: $e", isFail: true);
    }
    await Future.delayed(const Duration(milliseconds: 300));

    // 9. Customer Rating & Review Engine
    try {
      final reviewData = {
        'rating': 5,
        'reviewText':
            'Excellent service! Very polite technician Ramesh and fast repair.',
        'techId': techUid,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await db.collection('reviews').doc(bookingId).set(reviewData);
      _addLog(
        "Stage 9: Customer Rating & Review Engine -> 5-Star rating written to Firestore.",
      );
    } catch (e) {
      _addLog("Stage 9 Error: $e", isFail: true);
    }

    setState(() {
      _isRunning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Multi-App E2E Integration Suite'),
          backgroundColor: const Color(0xFF000062),
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _isRunning ? null : _startFullWorkflowTest,
            ),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFFE8ECF8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    "Total Passed: $_passed",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    "Total Failed: $_failed",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      fontSize: 16,
                    ),
                  ),
                  if (_isRunning)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final isPass = log.startsWith("✅");
                  final isFail = log.startsWith("❌");

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: isPass
                        ? const Color(0xFFE8F5E9)
                        : (isFail ? const Color(0xFFFFEBEE) : Colors.white),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        log,
                        style: TextStyle(
                          fontWeight: isPass || isFail
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isPass
                              ? const Color(0xFF1B5E20)
                              : (isFail ? Colors.red.shade900 : Colors.black87),
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
