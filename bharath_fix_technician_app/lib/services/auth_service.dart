import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/technician_model.dart';

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

    if (credential != null && credential.user != null) {
      final user = credential.user!;
      final uid = user.uid;
      final doc = await _db.collection('providers').doc(uid).get();
      if (!doc.exists) {
        final newModel = TechnicianModel(
          uid: uid,
          name: email.split('@').first,
          email: email.trim(),
          phone: '+91 9876543210',
          category: 'All Appliances Specialist',
          status: 'active',
          isOnline: true,
          earnings: 0.0,
          completedJobs: 0,
          rating: 5.0,
        );
        await _db.collection('providers').doc(uid).set(newModel.toMap(), SetOptions(merge: true));
      }
    }

    return credential;
  }

  Future<TechnicianModel?> fetchTechnicianProfile() async {
    final uid = currentUser?.uid;
    if (uid == null) return null;
    try {
      final doc = await _db.collection('providers').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        return TechnicianModel.fromMap(doc.data()!, doc.id);
      }
    } catch (e) {
      debugPrint("Error fetching technician profile: $e");
    }
    return null;
  }

  Future<void> saveTechnicianProfile(TechnicianModel model) async {
    final uid = currentUser?.uid ?? model.uid;
    try {
      await _db.collection('providers').doc(uid).set(model.toMap(), SetOptions(merge: true));
    } catch (e) {
      debugPrint("Error saving technician profile: $e");
    }
  }

  Future<void> setOnlineStatus(bool isOnline) async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db.collection('providers').doc(uid).update({'isOnline': isOnline});
    }
  }

  Future<void> signOut() async {
    final uid = currentUser?.uid;
    if (uid != null) {
      await _db.collection('providers').doc(uid).update({'isOnline': false});
    }
    await _auth.signOut();
  }
}
