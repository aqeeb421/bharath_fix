import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/technician_order_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';

class OrderDeliveryDetailScreen extends StatefulWidget {
  final TechnicianOrderModel order;

  const OrderDeliveryDetailScreen({super.key, required this.order});

  @override
  State<OrderDeliveryDetailScreen> createState() => _OrderDeliveryDetailScreenState();
}

class _OrderDeliveryDetailScreenState extends State<OrderDeliveryDetailScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isSubmitting = false;
  String? _otpError;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final Uri queryUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    if (await canLaunchUrl(queryUri)) {
      await launchUrl(queryUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _markOutForDelivery() async {
    setState(() => _isSubmitting = true);
    try {
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({
        'orderStatus': 'outForDelivery',
        'updatedAt': now,
      });

      if (widget.order.userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.order.userId)
            .collection('orders')
            .doc(widget.order.id)
            .set({'orderStatus': 'outForDelivery', 'updatedAt': now}, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.order.userId)
            .collection('notifications')
            .add({
          'title': 'Out for Delivery 🛵',
          'body': 'Your order #${widget.order.id} (${widget.order.productName}) is out for delivery with setup agent.',
          'type': 'ORDER_UPDATE',
          'orderId': widget.order.id,
          'isRead': false,
          'createdAt': now,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order marked as Out for Delivery!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showVerifyOtpDialog() {
    _otpController.clear();
    _otpError = null;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
            title: Row(
              children: const [
                Icon(Icons.security_rounded, color: AppColors.primary),
                SizedBox(width: 8),
                Text('Enter Customer OTP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ask the customer for their 4-digit Delivery Verification OTP to complete delivery & setup.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: AppColors.primary),
                  decoration: InputDecoration(
                    hintText: '••••',
                    counterText: '',
                    errorText: _otpError,
                    filled: true,
                    fillColor: AppColors.primary.withValues(alpha: 0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        final inputOtp = _otpController.text.trim();
                        if (inputOtp != widget.order.deliveryOtp) {
                          setDialogState(() {
                            _otpError = 'Invalid OTP! Please check with customer.';
                          });
                          return;
                        }

                        Navigator.pop(context);
                        await _completeDeliveryAndInstallation();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
                child: const Text('Verify & Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _completeDeliveryAndInstallation() async {
    setState(() => _isSubmitting = true);
    try {
      final now = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance.collection('orders').doc(widget.order.id).update({
        'orderStatus': 'delivered',
        'deliveredAt': now,
        'updatedAt': now,
      });

      if (widget.order.userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.order.userId)
            .collection('orders')
            .doc(widget.order.id)
            .set({
          'orderStatus': 'delivered',
          'deliveredAt': now,
          'updatedAt': now,
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.order.userId)
            .collection('notifications')
            .add({
          'title': 'Delivered & Installed! 🎉',
          'body': 'Your order #${widget.order.id} (${widget.order.productName}) has been delivered & set up successfully.',
          'type': 'ORDER_DELIVERED',
          'orderId': widget.order.id,
          'isRead': false,
          'createdAt': now,
        });
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
            title: const Text('Delivery Completed! 🎉', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text(
              'Product delivery and installation verified successfully.',
              textAlign: TextAlign.center,
            ),
            actions: [
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // Close dialog
                    Navigator.pop(context); // Return to Jobs tab
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                  child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error completing delivery: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isOutForDelivery = widget.order.orderStatus == 'outfordelivery';
    final bool isDelivered = widget.order.orderStatus == 'delivered';

    return Scaffold(
      appBar: AppBar(
        title: Text('Order #${widget.order.id}', style: AppTextStyle.mainTitle.copyWith(fontSize: 18, color: Colors.white)),
        backgroundColor: AppColors.primary,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDelivered ? Colors.green.shade50 : (isOutForDelivery ? Colors.blue.shade50 : Colors.orange.shade50),
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: isDelivered ? Colors.green : (isOutForDelivery ? Colors.blue : Colors.orange)),
              ),
              child: Row(
                children: [
                  Icon(
                    isDelivered ? Icons.check_circle_rounded : (isOutForDelivery ? Icons.directions_bike_rounded : Icons.local_shipping_rounded),
                    color: isDelivered ? Colors.green.shade800 : (isOutForDelivery ? Colors.blue.shade800 : Colors.orange.shade800),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDelivered ? 'DELIVERED & INSTALLED' : (isOutForDelivery ? 'OUT FOR DELIVERY' : 'ASSIGNED FOR DELIVERY'),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDelivered ? Colors.green.shade800 : (isOutForDelivery ? Colors.blue.shade800 : Colors.orange.shade800),
                          ),
                        ),
                        Text(
                          widget.order.requiresInstallation ? 'Requires Appliance Setup & Water/Power Connection' : 'Standard Delivery',
                          style: const TextStyle(fontSize: 11, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Product Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      child: Image.network(
                        widget.order.productImage.isNotEmpty
                            ? widget.order.productImage
                            : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(width: 70, height: 70, color: Colors.grey.shade200, child: const Icon(Icons.inventory_2_rounded)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.order.productName, style: AppTextStyle.cardTitle.copyWith(fontSize: 15)),
                          const SizedBox(height: 4),
                          Text('Quantity: ${widget.order.quantity} • Paid: ₹${widget.order.totalPaid.toStringAsFixed(0)}', style: AppTextStyle.subtitle),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Customer Details & Map Navigation Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.medium),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer & Delivery Address', style: AppTextStyle.cardTitle),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.person_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(widget.order.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Spacer(),
                        if (widget.order.userPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                            onPressed: () => _makePhoneCall(widget.order.userPhone),
                          ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_rounded, size: 18, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(widget.order.deliveryAddress, style: const TextStyle(fontSize: 13, color: Colors.black87)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: OutlinedButton.icon(
                        onPressed: () => _launchMaps(widget.order.deliveryAddress),
                        icon: const Icon(Icons.map_rounded, color: AppColors.primary, size: 18),
                        label: const Text('Open in Google Maps', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!isDelivered) ...[
              if (!isOutForDelivery) ...[
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSubmitting ? null : _markOutForDelivery,
                    icon: const Icon(Icons.directions_bike_rounded, color: Colors.white),
                    label: const Text('Mark Out for Delivery', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade800,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _showVerifyOtpDialog,
                  icon: const Icon(Icons.verified_user_rounded, color: Colors.white),
                  label: const Text('Verify Customer OTP & Complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
