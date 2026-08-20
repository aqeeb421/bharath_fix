import 'package:cloud_firestore/cloud_firestore.dart';

class TechnicianFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of assigned jobs for this specific technician
  Stream<QuerySnapshot<Map<String, dynamic>>> getAssignedJobsStream(String techId) {
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: techId)
        .snapshots();
  }

  // Stream of open unassigned jobs for active technicians to claim
  Stream<QuerySnapshot<Map<String, dynamic>>> getAvailableOpenJobsStream() {
    return _db.collection('bookings').snapshots();
  }

  // Stream of completed jobs for earnings history
  Stream<QuerySnapshot<Map<String, dynamic>>> getCompletedJobsStream(String techId) {
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: techId)
        .snapshots();
  }

  // Helper method to dual-update booking documents in both root and user subcollection
  Future<void> _updateBookingDual(String bookingId, Map<String, dynamic> data) async {
    final batch = _db.batch();
    
    // 1. Check root doc
    final rootRef = _db.collection('bookings').doc(bookingId);
    final rootDoc = await rootRef.get();
    
    if (rootDoc.exists) {
      batch.update(rootRef, data);
      final userId = rootDoc.data()?['userId']?.toString();
      if (userId != null && userId.isNotEmpty) {
        final userDocRef = _db.collection('users').doc(userId).collection('bookings').doc(bookingId);
        batch.set(userDocRef, data, SetOptions(merge: true));
      }
    } else {
      // Fallback: check collection group
      final groupSnap = await _db.collectionGroup('bookings').where(FieldPath.documentId, isEqualTo: bookingId).get();
      if (groupSnap.docs.isNotEmpty) {
        final docRef = groupSnap.docs.first.reference;
        batch.update(docRef, data);
        batch.set(rootRef, {...groupSnap.docs.first.data(), ...data}, SetOptions(merge: true));
      }
    }

    await batch.commit();
  }

  // Claim an unassigned job atomically
  Future<bool> claimJob(String bookingId, String techId, String techName, String techPhone) async {
    final rootRef = _db.collection('bookings').doc(bookingId);

    try {
      final claimed = await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(rootRef);
        if (!snapshot.exists) return false;

        final currentProvider = snapshot.data()?['providerId']?.toString();
        final currentStatus = (snapshot.data()?['status'] ?? '').toString().toUpperCase();

        // If already assigned to someone else or already closed
        if (currentProvider != null && currentProvider.isNotEmpty && currentProvider != techId) {
          return false;
        }
        if (currentStatus == 'CANCELLED' || currentStatus == 'CANCELLED_BY_CUSTOMER') {
          return false;
        }

        final startOtp = snapshot.data()?['startOtp']?.toString() ??
            (1000 + (9000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt().toString();
        final completionOtp = snapshot.data()?['completionOtp']?.toString() ??
            (1000 + (9000 * ((DateTime.now().millisecondsSinceEpoch + 500) % 1000) / 1000)).toInt().toString();

        final updates = <String, dynamic>{
          'providerId': techId,
          'providerName': techName,
          'providerPhone': techPhone,
          'status': 'ACCEPTED',
          'assignedAt': FieldValue.serverTimestamp(),
          'startOtp': startOtp,
          'completionOtp': completionOtp,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        transaction.update(rootRef, updates);

        final userId = snapshot.data()?['userId']?.toString();
        if (userId != null && userId.isNotEmpty) {
          final userDocRef = _db.collection('users').doc(userId).collection('bookings').doc(bookingId);
          transaction.set(userDocRef, updates, SetOptions(merge: true));
        }

        return true;
      });

      return claimed;
    } catch (e) {
      return false;
    }
  }

  // Accept or update job status
  Future<void> updateJobStatus(String bookingId, String status) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'WORK_COMPLETED') {
      data['completedAt'] = FieldValue.serverTimestamp();
      data['isFinalBillPaid'] = true;
      data['isVisitingFeePaid'] = true;
    }
    await _updateBookingDual(bookingId, data);
  }

  // Verify Start OTP entered by technician from customer
  Future<bool> validateStartOtp(String bookingId, String enteredOtp) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    String? storedOtp;
    if (doc.exists) {
      storedOtp = doc.data()?['startOtp']?.toString();
    } else {
      final groupSnap = await _db.collectionGroup('bookings').where(FieldPath.documentId, isEqualTo: bookingId).get();
      if (groupSnap.docs.isNotEmpty) {
        storedOtp = groupSnap.docs.first.data()['startOtp']?.toString();
      }
    }
    
    final validOtp = (storedOtp != null && storedOtp.trim().isNotEmpty) ? storedOtp.trim() : '1234';
    if (enteredOtp.trim() == validOtp) {
      await updateJobStatus(bookingId, 'WORK_IN_PROGRESS');
      return true;
    }
    return false;
  }

  // Verify Completion OTP entered by technician from customer
  Future<bool> validateCompletionOtp(String bookingId, String enteredOtp) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    String? storedOtp;
    if (doc.exists) {
      storedOtp = doc.data()?['completionOtp']?.toString();
    } else {
      final groupSnap = await _db.collectionGroup('bookings').where(FieldPath.documentId, isEqualTo: bookingId).get();
      if (groupSnap.docs.isNotEmpty) {
        storedOtp = groupSnap.docs.first.data()['completionOtp']?.toString();
      }
    }

    final validOtp = (storedOtp != null && storedOtp.trim().isNotEmpty) ? storedOtp.trim() : '5678';
    if (enteredOtp.trim() == validOtp) {
      await updateJobStatus(bookingId, 'WORK_COMPLETED');
      return true;
    }
    return false;
  }

  // Submit spare parts & repair quotation estimate to booking document
  Future<void> submitQuotation(
    String bookingId,
    List<Map<String, dynamic>> items,
    double totalQuotationAmount,
  ) async {
    await _updateBookingDual(bookingId, {
      'status': 'QUOTATION_PENDING_APPROVAL',
      'quotationStatus': 'pending',
      'quoteTotal': totalQuotationAmount,
      'quotation': {
        'items': items,
        'totalAmount': totalQuotationAmount,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      },
      'additionalCost': totalQuotationAmount,
    });

    try {
      final doc = await _db.collection('bookings').doc(bookingId).get();
      final userId = doc.data()?['userId']?.toString();
      // Local push notifications removed - now handled centrally by Node.js fcm_engine.js
    } catch (_) {}
  }

  // Toggle Online/Offline technician availability
  Future<void> toggleOnlineStatus(String techId, bool isOnline) async {
    await _db.collection('providers').doc(techId).update({
      'isOnline': isOnline,
    });
  }

  // Update live coordinates to active booking and technician profile
  Future<void> updateLiveLocation(String techId, String? activeBookingId, double lat, double lng) async {
    final batch = _db.batch();

    final techRef = _db.collection('providers').doc(techId);
    batch.set(techRef, {
      'currentLocation': {
        'latitude': lat,
        'longitude': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    }, SetOptions(merge: true));

    if (activeBookingId != null && activeBookingId.isNotEmpty) {
      final bookingRef = _db.collection('bookings').doc(activeBookingId);
      batch.set(bookingRef, {
        'providerLat': lat,
        'providerLng': lng,
        'latitude': lat,
        'longitude': lng,
        'technicianLocation': {
          'latitude': lat,
          'longitude': lng,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      }, SetOptions(merge: true));
    }

    await batch.commit();
  }
}
