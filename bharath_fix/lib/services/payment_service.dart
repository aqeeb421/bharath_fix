import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'fcm_direct_service.dart';

class PaymentService {
  static const String razorpayKey = 'rzp_test_TkFIUiWC9HaAbf';

  /// Calls the backend Node.js server to create an official Razorpay order ID.
  /// If the server is reachable and Razorpay credentials are set, this returns
  /// a genuine order ID (e.g. `order_M9q2...`), preventing live mode checkout rejections.
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
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded['success'] == true && decoded['order'] != null) {
          final order = decoded['order'];
          return {
            'id': order['id'],
            'amount': order['amount'],
            'currency': order['currency'],
            'key': order['keyId'] ?? razorpayKey,
            'status': order['status'] ?? 'created',
            'isLiveOrder': decoded['isLiveOrder'] == true,
          };
        }
      }
    } catch (e) {
      debugPrint('⚠️ Warning: Backend order creation unreachable ($e). Using local fallback order.');
    }

    // Local sandbox fallback for offline or development resilience
    final String fallbackOrderId = 'order_sim_${DateTime.now().millisecondsSinceEpoch}';
    return {
      'id': fallbackOrderId,
      'amount': amountInPaise,
      'currency': currency,
      'key': razorpayKey,
      'status': 'created',
      'isLiveOrder': false,
    };
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