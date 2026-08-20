import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../utils/app_routes.dart';

class AuthEnforcementService {
  static final AuthEnforcementService _instance = AuthEnforcementService._internal();
  factory AuthEnforcementService() => _instance;
  AuthEnforcementService._internal();

  StreamSubscription? _authSub;
  StreamSubscription? _userDocSub;

  void startMonitoring() {
    _authSub?.cancel();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        _monitorFcmToken(user.uid);
      } else {
        _userDocSub?.cancel();
      }
    });
  }

  Future<void> _monitorFcmToken(String uid) async {
    _userDocSub?.cancel();
    
    await Future.delayed(const Duration(seconds: 2));
    
    String? currentDeviceToken;
    try {
      currentDeviceToken = await FirebaseMessaging.instance.getToken();
    } catch (_) {}

    if (currentDeviceToken == null) return;

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': currentDeviceToken,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}

    _userDocSub = FirebaseFirestore.instance.collection('users').doc(uid).snapshots().listen((doc) {
      if (!doc.exists) return;
      
      final dbToken = doc.data()?['fcmToken'] as String?;
      if (dbToken != null && dbToken.isNotEmpty && dbToken != currentDeviceToken) {
        _handleLogout();
      }
    });
  }

  void _handleLogout() async {
    _userDocSub?.cancel();
    await FirebaseAuth.instance.signOut();
    
    if (navigatorKey.currentContext != null) {
      showDialog(
        context: navigatorKey.currentContext!,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Session Expired"),
          content: const Text("Your account was logged in from another device. You have been automatically logged out."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(navigatorKey.currentContext!).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
              },
              child: const Text("OK"),
            )
          ],
        ),
      );
    }
  }
}
