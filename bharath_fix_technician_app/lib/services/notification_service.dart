import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'fcm_direct_service.dart';


import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:firebase_core/firebase_core.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    debugPrint('FCM Terminated/Background Message received [Technician]: ${message.messageId}');
    
    final notification = message.notification;
    final title = notification?.title ?? message.data['title'] as String? ?? 'BharatFix Partner Alert';
    final body = notification?.body ?? message.data['body'] as String? ?? '';
    
    if (title.isNotEmpty || body.isNotEmpty) {
      final localNotifications = FlutterLocalNotificationsPlugin();
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInitSettings);
      await localNotifications.initialize(initSettings);

      const channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important partner push notifications.',
        importance: Importance.max,
        playSound: true,
      );

      await localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      await localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
          ),
        ),
      );
    }
  } catch (e) {
    debugPrint('Technician App background message handler exception: $e');
  }
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important partner push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  static Future<void> initialize({
    Function(Map<String, dynamic>)? onJobAlertReceived,
  }) async {
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications settings for Android system tray
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInitSettings);
      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (details) {
          debugPrint('Technician local notification clicked: ${details.payload}');
          _handleNotificationRedirection({'type': 'SYSTEM_TRAY_CLICK'});
        },
      );

      // Listen for notification taps when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('Tech FCM Notification Clicked (Background App): ${message.data}');
        _handleNotificationRedirection(message.data);
      });

      // Listen for notification tap on cold app launch
      FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
        if (message != null) {
          debugPrint('Tech FCM Notification Clicked (Initial App Launch): ${message.data}');
          _handleNotificationRedirection(message.data);
        }
      });

      // Register high importance channel on Android OS
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);

      // Enable foreground heads-up notification presentation
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('Technician granted notification permission');
        await _saveTokenToFirestore();

        _messaging.onTokenRefresh.listen(
          (newToken) async {
            await _updateTokenInFirestore(newToken);
          },
          onError: (e) {
            debugPrint('Token refresh error: $e');
          },
        );

        // Listen to auth state changes to ensure provider fcmToken is saved on login
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            await _saveTokenToFirestore();
          }
        });

        // Foreground broadcast alert receiver -> show system tray push notification
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Incoming Job Notification: ${message.notification?.title}',
          );

          final notification = message.notification;
          if (notification != null) {
            _localNotifications.show(
              notification.hashCode,
              notification.title,
              notification.body,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  _channel.id,
                  _channel.name,
                  channelDescription: _channel.description,
                  icon: '@mipmap/ic_launcher',
                  importance: Importance.max,
                  priority: Priority.high,
                  playSound: true,
                ),
              ),
            );
          }

          if (message.data['type'] == 'JOB_BROADCAST' &&
              onJobAlertReceived != null) {
            onJobAlertReceived(message.data);
          }
        });
      }
    } catch (e) {
      debugPrint('NotificationService initialize safe catch: $e');
    }
  }

  static Function(Map<String, dynamic>)? onNotificationTap;

  static void _handleNotificationRedirection(Map<String, dynamic> data) {
    debugPrint('Technician Notification clicked with payload data: $data');
    if (onNotificationTap != null) {
      onNotificationTap!(data);
    }
  }


  static Future<void> syncFcmToken() async {
    await _saveTokenToFirestore();
  }


  static Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _messaging.getToken();
      print('\n' + '=' * 70);
      print('🔥 [TECHNICIAN APP] FCM DEVICE TOKEN:');
      print('$token');
      print('=' * 70 + '\n');
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('⚠️ Error getting provider FCM token: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _db.collection('providers').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await _db.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  // ==================== WORKFLOW NOTIFICATION DISPATCHERS ====================

  /// Send notification to Customer
  static Future<void> sendNotificationToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notifId = 'notif_u_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'id': notifId,
      'userId': userId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notifId)
        .set(payload);

    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final token = userDoc.data()?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        await FcmDirectService.sendPushNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      debugPrint('FCM direct send to user error: $e');
    }
  }


  /// Send notification to Admin Panel
  static Future<void> sendNotificationToAdmin({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notifId = 'notif_a_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'id': notifId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db.collection('admin_notifications').doc(notifId).set(payload);
  }

  /// Stream technician partner notifications in real-time
  static Stream<QuerySnapshot<Map<String, dynamic>>> getTechNotificationsStream(
    String techId,
  ) {
    return _db
        .collection('providers')
        .doc(techId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
