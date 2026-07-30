import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize({Function(Map<String, dynamic>)? onJobAlertReceived}) async {
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Technician granted notification permission');
      await _saveTokenToFirestore();

      _messaging.onTokenRefresh.listen((newToken) async {
        await _updateTokenInFirestore(newToken);
      });

      // Foreground broadcast alert receiver
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Incoming Job Notification: ${message.notification?.title}');
        if (message.data['type'] == 'JOB_BROADCAST' && onJobAlertReceived != null) {
          onJobAlertReceived(message.data);
        }
      });
    }
  }

  static Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting provider FCM token: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('providers').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }
}
