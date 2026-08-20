import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('FCM Terminated/Background Message received [Customer]: ${message.messageId}');
  } catch (e) {
    debugPrint('Error handling background notification: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static Function(Map<String, dynamic>)? onNotificationTap;

  FirebaseFirestore? get _db {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  static Future<void> initialize() async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    } catch (e) {
      debugPrint('Failed to register FCM background message handler: $e');
    }
    debugPrint('NotificationService initialized.');
  }

  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (userId.isEmpty || userId == 'guest_user') return;
    try {
      final notifDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc();

      await notifDoc.set({
        'id': notifDoc.id,
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'CUSTOMER_ALERT',
        'data': data,
        'bookingId': data?['bookingId'],
        'orderId': data?['orderId'],
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Notification sent to user $userId: $title');
    } catch (e) {
      debugPrint('Error sending user notification: $e');
    }
  }

  static Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    try {
      final notifDoc = FirebaseFirestore.instance.collection('admin_notifications').doc();
      await notifDoc.set({
        'id': notifDoc.id,
        'title': title,
        'body': body,
        'type': data?['type'] ?? 'ADMIN_ALERT',
        'data': data,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint('Admin notification logged: $title');
    } catch (e) {
      debugPrint('Error logging admin notification: $e');
    }
  }

  static StreamSubscription? listenForInAppNotifications({
    required String userId,
    Function(String title, String body)? onNewNotification,
  }) {
    if (userId.isEmpty || userId == 'guest_user') return null;

    try {
      return FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .snapshots()
          .listen((snap) {
        if (snap.docs.isNotEmpty) {
          final data = snap.docs.first.data();
          final title = data['title'] as String? ?? 'Notification';
          final body = data['body'] as String? ?? '';
          if (onNewNotification != null) {
            onNewNotification(title, body);
          }
        }
      });
    } catch (e) {
      debugPrint('Error listening for notifications: $e');
      return null;
    }
  }

  Future<void> sendUserNotification({
    required String userId,
    required String title,
    required String body,
    required String type,
    String? orderId,
    String? bookingId,
  }) async {
    await sendNotificationToUser(
      userId: userId,
      title: title,
      body: body,
      data: {'type': type, 'orderId': orderId, 'bookingId': bookingId},
    );
  }

  Stream<QuerySnapshot>? streamUserNotifications(String userId) {
    if (userId.isEmpty || userId == 'guest_user' || _db == null) return null;
    return _db!
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  static Future<void> saveFcmToken(String userId, String token) async {
    if (userId.isEmpty || userId == 'guest_user' || token.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'fcmToken': token,
        'lastActive': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('Saved FCM token for user $userId');
    } catch (e) {
      debugPrint('Failed to save FCM token: $e');
    }
  }
}
