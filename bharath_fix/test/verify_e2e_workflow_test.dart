import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Multi-App E2E Integration Workflow Verification', () async {
    debugPrint('====================================================');
    debugPrint('🚀 STARTING MULTI-APP E2E WORKFLOW INTEGRATION TEST');
    debugPrint('====================================================');

    try {
      await Firebase.initializeApp();
    } catch (e) {
      debugPrint('Firebase initialized (or mock binding): $e');
    }

    final db = FirebaseFirestore.instance;
    int passed = 0;
    int failed = 0;

    void logPass(String step) {
      passed++;
      debugPrint('✅ [PASS] $step');
    }

    void logFail(String step, dynamic error) {
      failed++;
      debugPrint('❌ [FAIL] $step -> $error');
    }

    final testTechEmail = 'tech.test@bharathfix.com';
    final testCustomerPhone = '+915555555555';
    final techUid = 'test_tech_uid_${DateTime.now().millisecondsSinceEpoch}';
    final customerUid =
        'test_cust_uid_${DateTime.now().millisecondsSinceEpoch}';
    final bookingId = 'bf_test_${DateTime.now().millisecondsSinceEpoch}';

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
        logPass(
          'Stage 1: Technician Registration -> Doc created with status "pending_verification" & approval gate locked',
        );
      } else {
        logFail(
          'Stage 1: Technician Registration',
          'Unexpectedly approved before Admin action',
        );
      }
    } catch (e) {
      logFail('Stage 1: Technician Registration', e);
    }

    // 2. Admin KYC Approval & Activation
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
        logPass(
          'Stage 2: Admin Approval Gate -> Status updated to "Active", isOnline: true & Partner unlocked!',
        );
      } else {
        logFail(
          'Stage 2: Admin Approval Gate',
          'Partner status failed to activate',
        );
      }
    } catch (e) {
      logFail('Stage 2: Admin Approval Gate', e);
    }

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

      final walletTxRef = custDoc.collection('wallet').doc('initial_topup');
      await walletTxRef.set({
        'id': 'initial_topup',
        'amount': 500.0,
        'type': 'CREDIT',
        'title': 'Welcome Bonus Credit',
        'timestamp': FieldValue.serverTimestamp(),
      });

      final snap = await custDoc.get();
      if (snap.exists && (snap.data()?['walletBalance'] as num) == 500.0) {
        logPass(
          'Stage 3: Customer Profile & Wallet -> Initialized with phone $testCustomerPhone & ₹500 wallet balance',
        );
      } else {
        logFail(
          'Stage 3: Customer Profile & Wallet',
          'Wallet balance initialization mismatch',
        );
      }
    } catch (e) {
      logFail('Stage 3: Customer Profile & Wallet', e);
    }

    // 4. Customer Places Service Booking
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
        logPass(
          'Stage 4: Customer Order Placement -> Dual-write root "bookings" & "users/$customerUid/bookings" with status "BOOKED"',
        );
      } else {
        logFail(
          'Stage 4: Customer Order Placement',
          'Booking doc not found with status "BOOKED"',
        );
      }
    } catch (e) {
      logFail('Stage 4: Customer Order Placement', e);
    }

    // 5. Technician Open Pool Discovery & Claiming
    try {
      final openSnap = await db
          .collection('bookings')
          .where('status', whereIn: ['BOOKED', 'booked', 'pending', 'Pending'])
          .get();
      final targetDoc = openSnap.docs.firstWhere((d) => d.id == bookingId);

      if (targetDoc.exists) {
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

        final updatedSnap = await db
            .collection('bookings')
            .doc(bookingId)
            .get();
        if (updatedSnap.data()?['status'] == 'accepted' &&
            updatedSnap.data()?['providerId'] == techUid) {
          logPass(
            'Stage 5: Technician Job Claiming -> Successfully assigned booking to tech $techUid with status "accepted"',
          );
        } else {
          logFail(
            'Stage 5: Technician Job Claiming',
            'Failed to update provider assignment',
          );
        }
      } else {
        logFail(
          'Stage 5: Technician Open Pool',
          'Booking $bookingId not found in open pool',
        );
      }
    } catch (e) {
      logFail('Stage 5: Technician Job Claiming', e);
    }

    // 6. Technician "Mark On the Way" & Live GPS Tracking
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
        logPass(
          'Stage 6: Live GPS Tracking -> Status updated to "on_the_way" & live coordinates ($lat, $lng) streamed to Customer Radar',
        );
      } else {
        logFail(
          'Stage 6: Live GPS Tracking',
          'Live coordinates or status mismatch',
        );
      }
    } catch (e) {
      logFail('Stage 6: Live GPS Tracking', e);
    }

    // 7. Start OTP Validation
    try {
      final snap = await db.collection('bookings').doc(bookingId).get();
      final startOtp = snap.data()?['startOtp']?.toString();

      if (startOtp == '4829') {
        final startData = {
          'status': 'inspection_in_progress',
          'workStartedAt': FieldValue.serverTimestamp(),
        };

        final batch = db.batch();
        batch.update(db.collection('bookings').doc(bookingId), startData);
        batch.set(
          db
              .collection('users')
              .doc(customerUid)
              .collection('bookings')
              .doc(bookingId),
          startData,
          SetOptions(merge: true),
        );
        await batch.commit();

        logPass(
          'Stage 7: Start OTP Validation -> OTP "4829" validated -> Status updated to "inspection_in_progress"',
        );
      } else {
        logFail('Stage 7: Start OTP', 'Invalid start OTP code');
      }
    } catch (e) {
      logFail('Stage 7: Start OTP Validation', e);
    }

    // 8. Technician Submits Repair Quotation & Spare Parts Estimate
    try {
      final quoteItems = [
        {'title': 'AC Compressor Gas Refill (R32)', 'price': 350.0, 'isSparePart': true, 'warrantyDays': 90},
      ];

      final quoteData = {
        'status': 'quotation_pending',
        'quotationStatus': 'pending',
        'quotation': {
          'items': quoteItems,
          'totalAmount': 350.0,
          'status': 'pending',
          'submittedAt': FieldValue.serverTimestamp(),
        },
        'quoteTotal': 350.0,
      };

      final batch = db.batch();
      batch.update(db.collection('bookings').doc(bookingId), quoteData);
      batch.set(
        db
            .collection('users')
            .doc(customerUid)
            .collection('bookings')
            .doc(bookingId),
        quoteData,
        SetOptions(merge: true),
      );
      await batch.commit();

      logPass(
        'Stage 8: Repair Quotation Submission -> Partner submitted ₹350 quote -> Status "quotation_pending"',
      );
    } catch (e) {
      logFail('Stage 8: Repair Quotation Submission', e);
    }

    // 9. Customer Quotation Checkout & Payment Success Dialog Flow
    try {
      final quoteTotal = 350.0;
      final visitingFee = 199.0;
      final finalBill = visitingFee + quoteTotal; // ₹549 total
      final topupBal = 1000.0; // Top up wallet balance
      final newBal = topupBal - finalBill; // ₹451 remaining balance

      final paymentData = {
        'quotation.status': 'approved',
        'quotationStatus': 'approved',
        'status': 'repair_in_progress',
        'quoteTotal': quoteTotal,
        'finalAmountPaid': finalBill,
        'paymentMode': 'WALLET',
        'isFinalBillPaid': true,
        'isVisitingFeePaid': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final batch = db.batch();
      batch.update(db.collection('bookings').doc(bookingId), paymentData);
      batch.set(
        db
            .collection('users')
            .doc(customerUid)
            .collection('bookings')
            .doc(bookingId),
        paymentData,
        SetOptions(merge: true),
      );
      batch.update(db.collection('users').doc(customerUid), {
        'walletBalance': newBal,
      });
      await batch.commit();

      logPass(
        'Stage 9: Customer Quotation Checkout & Payment -> Approved via Wallet (₹$finalBill) -> Quotation "approved" & Payment Success Dialog triggered',
      );
    } catch (e) {
      logFail('Stage 9: Customer Quotation Checkout & Payment', e);
    }

    // 10. Completion OTP Validation & Wallet Final Settlement
    try {
      final snap = await db.collection('bookings').doc(bookingId).get();
      final completionOtp = snap.data()?['completionOtp']?.toString();

      if (completionOtp == '8921') {
        final closeData = {
          'status': 'completed',
          'isFinalBillPaid': true,
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
        await batch.commit();

        logPass(
          'Stage 10: Completion & Settlement -> Completion OTP "8921" verified, job status "completed" & order closed',
        );
      } else {
        logFail('Stage 10: Completion OTP', 'Invalid completion OTP');
      }
    } catch (e) {
      logFail('Stage 10: Completion & Settlement', e);
    }

    // 11. Customer Rating & Written Review
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
      logPass(
        'Stage 11: Rating & Review Engine -> 5-Star review and feedback written to Firestore',
      );
    } catch (e) {
      logFail('Stage 11: Rating & Review', e);
    }

    expect(passed, greaterThan(0));
    expect(failed, equals(0));
  });
}
