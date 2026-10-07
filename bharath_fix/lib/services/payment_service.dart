import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'fcm_direct_service.dart';

class PaymentService {
  // Debug / Sandbox testing key. Commented out for production safety.
  // To re-enable manual test sandbox mode in the future, uncomment the line below:
  // static const String? _debugTestKey = 'rzp_test_TkFIUiWC9HaAbf';
  static const String? _debugTestKey = null;

  /// Returns the active Razorpay key (null in production when relying on Render backend)
  static String? get razorpayKey => _debugTestKey;

  /// Calls the backend Node.js server to create an official Razorpay order ID.
  /// The server dynamically injects the live RAZORPAY_KEY_ID configured on Render.com.
  /// If the server is unreachable or offline, this returns null so the app can display
  /// a graceful "Service temporarily unavailable" message.
  static Future<Map<String, dynamic>?> createOrder({
    required int amountInPaise,
    required String currency,
    String? receipt,
    Map<String, dynamic>? notes,
  }) async {
    try {
      final url = Uri.parse('${FcmDirectService.backendUrl.trimRight()}/api/payment/create-order');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'amountInPaise': amountInPaise,
              'currency': currency,
              'receipt': receipt ?? 'rcpt_${DateTime.now().millisecondsSinceEpoch}',
              'notes': notes ?? {},
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['order'] != null) {
          final order = decoded['order'];
          final String? keyId = order['keyId'] as String? ?? _debugTestKey;
          if (keyId != null && keyId.isNotEmpty) {
            return {
              'id': order['id'],
              'amount': order['amount'],
              'currency': order['currency'],
              'key': keyId,
              'status': order['status'] ?? 'created',
              'isLiveOrder': decoded['isLiveOrder'] == true,
            };
          }
        }
      }
    } catch (e) {
      debugPrint('⚠️ Payment backend order creation unreachable: $e');
    }

    // If sandbox debug test key is explicitly enabled:
    if (_debugTestKey != null) {
      final String fallbackOrderId = 'order_sim_${DateTime.now().millisecondsSinceEpoch}';
      return {
        'id': fallbackOrderId,
        'amount': amountInPaise,
        'currency': currency,
        'key': _debugTestKey,
        'status': 'created',
        'isLiveOrder': false,
      };
    }

    // In production, return null if backend order creation was not successful
    return null;
  }

  /// Verifies client-side payment success with the backend server via HMAC-SHA256
  static Future<bool> verifyPayment({
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
    required String paymentType,
    double? amount,
    String? jobId,
    String? orderId,
    String? userId,
  }) async {
    try {
      final url = Uri.parse('${FcmDirectService.backendUrl.trimRight()}/api/payment/verify-payment');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'razorpay_order_id': razorpayOrderId,
              'razorpay_payment_id': razorpayPaymentId,
              'razorpay_signature': razorpaySignature,
              'paymentType': paymentType,
              if (amount != null) 'amount': amount,
              'jobId': jobId,
              'orderId': orderId,
              'userId': userId,
            }),
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded['success'] == true;
      }
    } catch (e) {
      debugPrint('⚠️ Payment verification server check error: $e');
    }
    return false;
  }
}