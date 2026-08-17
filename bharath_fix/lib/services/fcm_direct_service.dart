import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Serverless Direct FCM Push Notification Dispatcher
class FcmDirectService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';

  /// FCM Legacy Server Key (Starts with AAAA...)
  /// Found in Firebase Console -> Project Settings -> Cloud Messaging -> Cloud Messaging API (Legacy) -> Server Key
  static String fcmServerKey =
      'AAAANmaSjAs:APA91bHAYJYlPnDrR4IemlSKF_IbVud0FCw2jduQu1F3IqdGG8qXcEqfkasdYZBsgLN67QMGCyGKjZSb2xgbyarHVkZAAd0R0lJxuIVhlygXWxUxI1vBVPMfBcFKKxMSjFljq7eRmEfl';

  /// Send direct FCM Push Notification to target device token
  static Future<bool> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? serverKey,
  }) async {
    if (targetToken.trim().isEmpty) return false;

    try {
      final key = serverKey ?? fcmServerKey;
      final payload = {
        'to': targetToken,
        'priority': 'high',
        'content_available': true,
        'notification': {
          'title': title,
          'body': body,
          'sound': 'default',
          'channel_id': 'high_importance_channel',
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
        },
        'android': {
          'priority': 'high',
          'notification': {
            'channel_id': 'high_importance_channel',
            'sound': 'default',
            'priority': 'high',
            'notification_priority': 'PRIORITY_MAX',
            'default_sound': true,
            'default_vibrate_timings': true,
          },
        },
        'data': {
          'click_action': 'FLUTTER_NOTIFICATION_CLICK',
          'title': title,
          'body': body,
          ...(data ?? {}),
        },
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$key',
        },
        body: jsonEncode(payload),
      );

      debugPrint(
        'Direct FCM Push Response [${response.statusCode}]: ${response.body}',
      );
      if (response.statusCode != 200) {
        debugPrint(
          '⚠️ FCM Push failed. Ensure fcmServerKey is set to Firebase Cloud Messaging Server Key (starts with AAAA...)',
        );
      }
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending direct FCM push notification: $e');
      return false;
    }
  }

  /// Send FCM Push Notification to multiple target device tokens
  static Future<void> sendMulticastPushNotification({
    required List<String> targetTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
    String? serverKey,
  }) async {
    for (final token in targetTokens) {
      if (token.isNotEmpty) {
        await sendPushNotification(
          targetToken: token,
          title: title,
          body: body,
          data: data,
          serverKey: serverKey,
        );
      }
    }
  }
}
