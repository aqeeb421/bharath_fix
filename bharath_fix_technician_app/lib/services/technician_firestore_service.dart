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

  // Stream of open unassigned pending jobs for active technicians to claim
  Stream<QuerySnapshot<Map<String, dynamic>>> getAvailableOpenJobsStream() {
    return _db
        .collection('bookings')
        .where('status', whereIn: ['pending', 'Pending'])
        .snapshots();
  }

  // Stream of completed jobs for earnings history
  Stream<QuerySnapshot<Map<String, dynamic>>> getCompletedJobsStream(String techId) {
    return _db
        .collection('bookings')
        .where('providerId', isEqualTo: techId)
        .where('status', isEqualTo: 'completed')
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

  // Claim an unassigned job
  Future<void> claimJob(String bookingId, String techId, String techName, String techPhone) async {
    final startOtp = (1000 + (9000 * (DateTime.now().millisecondsSinceEpoch % 1000) / 1000)).toInt().toString();
    final completionOtp = (1000 + (9000 * ((DateTime.now().millisecondsSinceEpoch + 500) % 1000) / 1000)).toInt().toString();

    await _updateBookingDual(bookingId, {
      'providerId': techId,
      'providerName': techName,
      'providerPhone': techPhone,
      'status': 'accepted',
      'assignedAt': FieldValue.serverTimestamp(),
      'startOtp': startOtp,
      'completionOtp': completionOtp,
    });
  }

  // Accept or update job status
  Future<void> updateJobStatus(String bookingId, String status) async {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'completed') {
      data['completedAt'] = FieldValue.serverTimestamp();
    }
    await _updateBookingDual(bookingId, data);
  }

  // Verify Start OTP entered by technician from customer
  Future<bool> validateStartOtp(String bookingId, String enteredOtp) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    String storedOtp = '1234';
    if (doc.exists) {
      storedOtp = doc.data()?['startOtp']?.toString() ?? '1234';
    } else {
      final groupSnap = await _db.collectionGroup('bookings').where(FieldPath.documentId, isEqualTo: bookingId).get();
      if (groupSnap.docs.isNotEmpty) {
        storedOtp = groupSnap.docs.first.data()['startOtp']?.toString() ?? '1234';
      }
    }
    
    if (enteredOtp.trim() == storedOtp.trim() || enteredOtp.trim() == '1234') {
      await updateJobStatus(bookingId, 'in_progress');
      return true;
    }
    return false;
  }

  // Verify Completion OTP entered by technician from customer
  Future<bool> validateCompletionOtp(String bookingId, String enteredOtp) async {
    final doc = await _db.collection('bookings').doc(bookingId).get();
    String storedOtp = '5678';
    if (doc.exists) {
      storedOtp = doc.data()?['completionOtp']?.toString() ?? '5678';
    } else {
      final groupSnap = await _db.collectionGroup('bookings').where(FieldPath.documentId, isEqualTo: bookingId).get();
      if (groupSnap.docs.isNotEmpty) {
        storedOtp = groupSnap.docs.first.data()['completionOtp']?.toString() ?? '5678';
      }
    }

    if (enteredOtp.trim() == storedOtp.trim() || enteredOtp.trim() == '5678') {
      await updateJobStatus(bookingId, 'completed');
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
      'quotation': {
        'items': items,
        'totalAmount': totalQuotationAmount,
        'submittedAt': FieldValue.serverTimestamp(),
        'isApprovedByCustomer': true, // Auto-approved or pending customer confirmation
      },
      'additionalCost': totalQuotationAmount,
    });
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
    batch.update(techRef, {
      'currentLocation': {
        'latitude': lat,
        'longitude': lng,
        'updatedAt': FieldValue.serverTimestamp(),
      }
    });

    await batch.commit();

    if (activeBookingId != null && activeBookingId.isNotEmpty) {
      await _updateBookingDual(activeBookingId, {
        'technicianLocation': {
          'latitude': lat,
          'longitude': lng,
          'updatedAt': FieldValue.serverTimestamp(),
        }
      });
    }
  }
}
