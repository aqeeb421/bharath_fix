import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// FCM Push Notification Dispatcher
/// Routes through BharathFix backend (FCM v1 API via firebase-admin).
/// No legacy server key needed — all auth handled server-side.
class FcmDirectService {
  /// Your deployed backend URL.
  /// Web / Local Dev → 'http://localhost:5000'
  static String backendUrl = 'https://bharath-fix-backend.onrender.com';

  static Uri get _notifyUrl =>
      Uri.parse('${backendUrl.trimRight()}/api/admin/notify');

  /// Send a push notification to a single FCM device token.
  static Future<bool> sendPushNotification({
    required String targetToken,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    if (targetToken.trim().isEmpty) return false;

    try {
      final response = await http
          .post(
            _notifyUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'token': targetToken,
              'title': title,
              'body': body,
              if (data != null) 'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('FCM Notify Response [${response.statusCode}]: ${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('FcmDirectService error: $e');
      return false;
    }
  }

  /// Send a push notification to multiple FCM device tokens.
  static Future<void> sendMulticastPushNotification({
    required List<String> targetTokens,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final tokens = targetTokens.where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return;

    try {
      final response = await http
          .post(
            _notifyUrl,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'tokens': tokens,
              'title': title,
              'body': body,
              if (data != null) 'data': data,
            }),
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('FCM Multicast Response [${response.statusCode}]: ${response.body}');
    } catch (e) {
      debugPrint('FcmDirectService multicast error: $e');
    }
  }
}
