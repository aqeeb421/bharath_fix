import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'fcm_direct_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'This channel is used for important system push notifications.',
    importance: Importance.max,
    playSound: true,
  );

  static Function(RemoteMessage)? onNotificationReceived;

  static Future<void> initialize({Function(RemoteMessage)? onNotification}) async {
    if (onNotification != null) {
      onNotificationReceived = onNotification;
    }
    try {
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize local notifications settings for Android system tray
      const androidInitSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInitSettings);
      await _localNotifications.initialize(initSettings);

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

      // Request permission for push alerts
      NotificationSettings settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
        await _saveTokenToFirestore();

        // Listen for token refreshes
        _messaging.onTokenRefresh.listen(
          (newToken) async {
            await _updateTokenInFirestore(newToken);
          },
          onError: (e) {
            debugPrint('Token refresh error: $e');
          },
        );

        // Listen to auth changes so FCM token is saved immediately on login
        FirebaseAuth.instance.authStateChanges().listen((user) async {
          if (user != null) {
            await _saveTokenToFirestore();
          }
        });

        // Foreground message listener -> show system tray push notification
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          debugPrint(
            'Foreground Message received: ${message.notification?.title} - ${message.notification?.body}',
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

          if (onNotificationReceived != null) {
            onNotificationReceived!(message);
          }
        });
      }
    } catch (e) {
      debugPrint('NotificationService initialize safe catch: $e');
    }
  }



  static Future<void> syncFcmToken() async {
    await _saveTokenToFirestore();
  }


  static Future<void> _saveTokenToFirestore() async {
    try {
      String? token = await _messaging.getToken();
      debugPrint('FCM token: $token');
      if (token != null) {
        await _updateTokenInFirestore(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  static Future<void> _updateTokenInFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
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

  /// Send notification to Technician Partner
  static Future<void> sendNotificationToTech({
    required String techId,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final notifId = 'notif_t_${DateTime.now().millisecondsSinceEpoch}';
    final payload = {
      'id': notifId,
      'techId': techId,
      'title': title,
      'body': body,
      'data': data ?? {},
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _db
        .collection('providers')
        .doc(techId)
        .collection('notifications')
        .doc(notifId)
        .set(payload);

    try {
      final techDoc = await _db.collection('providers').doc(techId).get();
      final token = techDoc.data()?['fcmToken'] as String?;
      if (token != null && token.isNotEmpty) {
        await FcmDirectService.sendPushNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
        );
      }
    } catch (e) {
      debugPrint('FCM direct send to tech error: $e');
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

  /// Stream customer notifications in real-time
  static Stream<QuerySnapshot<Map<String, dynamic>>> getUserNotificationsStream(
    String userId,
  ) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Listen for real-time in-app operational notifications and display a banner
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>> listenForInAppNotifications({
    required String userId,
    required Function(String title, String body) onNewNotification,
  }) {
    bool isInitialLoad = true;
    return _db
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .listen((snapshot) {
      if (isInitialLoad) {
        isInitialLoad = false;
        return;
      }
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) {
            final title = data['title'] as String? ?? 'BharatFix Alert';
            final body = data['body'] as String? ?? '';
            onNewNotification(title, body);
          }
        }
      }
    });
  }

  /// Test runner to sequentially dispatch push notifications for all 7 key operations
  static Future<void> testAllOperationNotifications(String userId) async {
    final operations = [
      {
        'title': '📋 1. Job Booked Successfully',
        'body': 'Your request for RO Water Purifier Repair has been booked.',
        'type': 'BOOKED'
      },
      {
        'title': '👨‍🔧 2. Technician Assigned',
        'body': 'Technician Ramesh Kumar has accepted your service request.',
        'type': 'ACCEPTED'
      },
      {
        'title': '🚚 3. Technician En Route',
        'body': 'Technician is heading to your location.',
        'type': 'IN_TRANSIT'
      },
      {
        'title': '📍 4. Technician Arrived',
        'body': 'Technician has reached your doorstep.',
        'type': 'ARRIVED'
      },
      {
        'title': '📝 5. Quotation Pending Approval',
        'body': 'Inspection completed. Quotation of ₹850 generated.',
        'type': 'QUOTATION_PENDING_APPROVAL'
      },
      {
        'title': '✅ 6. Work Completed',
        'body': 'Service completed cleanly. Please review & pay.',
        'type': 'WORK_COMPLETED'
      },
      {
        'title': '❌ 7. Job Cancelled',
        'body': 'Service request #1029 was cancelled.',
        'type': 'CANCELLED_BY_CUSTOMER'
      },
    ];

    for (var op in operations) {
      await sendNotificationToUser(
        userId: userId,
        title: op['title']!,
        body: op['body']!,
        data: {'type': op['type']},
      );
      await Future.delayed(const Duration(seconds: 3));
    }
  }
}


