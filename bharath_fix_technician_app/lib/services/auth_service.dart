import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserCredential?> signInWithEmailAndPassword(String email, String password) async {
    UserCredential? credential;
    try {
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'invalid-credential' || e.code == 'channel-error') {
        try {
          credential = await _auth.createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint("Error signing in technician: $e");
      rethrow;
    }

    final user = credential?.user;
    if (user != null) {
      final uid = user.uid;
      final doc = await _db.collection('providers').doc(uid).get();
      if (!doc.exists) {
        await _db.collection('providers').doc(uid).set({
          'id': uid,
          'name': email.split('@').first,
          'email': email.trim(),
          'phone': '+91 9876543210',
          'category': 'All Appliances Specialist',
          'status': 'Active',
          'isOnline': true,
          'earnings': 0.0,
          'completedJobs': 0,
          'rating': 5.0,
          'createdAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }

    return credential;
  }

  Future<Map<String, dynamic>?> fetchTechnicianProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('providers').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint("Error fetching technician profile: $e");
      return null;
    }
  }

  Future<void> signOut() async {
    // Set offline before signing out
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db.collection('providers').doc(uid).update({'isOnline': false});
    }
    await _auth.signOut();
  }
}
