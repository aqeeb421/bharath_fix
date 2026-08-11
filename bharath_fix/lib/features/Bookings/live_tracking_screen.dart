import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/BookingEntry.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class LiveTrackingScreen extends StatelessWidget {
  final BookingEntry booking;

  const LiveTrackingScreen({super.key, required this.booking});

  String _maskPhoneNumber(String rawPhone) {
    final clean = rawPhone.replaceAll(RegExp(r'\s+'), '').trim();
    if (clean.length >= 10) {
      final start = clean.substring(0, 3);
      final end = clean.substring(clean.length - 3);
      return '$start*****$end';
    }
    return '+91 ***** *****';
  }

  Future<void> _makeMaskedCall(BuildContext context, String phone) async {
    final rawPhone = phone.isNotEmpty ? phone : '+919148699386';
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse('tel:$cleanPhone');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) {
        await launchUrl(url);
      }
    } catch (e) {
      debugPrint('Error launching phone dialer: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dialing $cleanPhone...')),
        );
      }
    }
  }

  Future<void> _openProviderChat(BuildContext context, String phone, String bookingId) async {
    final targetPhone = phone.isNotEmpty ? phone.replaceAll('+', '').replaceAll(' ', '') : '919148699386';
    final message = Uri.encodeComponent('Hello! I am following up regarding my booking #$bookingId.');
    final Uri url = Uri.parse('https://wa.me/$targetPhone?text=$message');
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        final smsUri = Uri.parse('sms:$targetPhone?body=$message');
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
        }
      }
    } catch (e) {
      debugPrint('Error launching chat: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Live Provider Tracking',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(booking.id).snapshots(),
        builder: (context, snapshot) {
          Map<String, dynamic> data = booking.toMap();
          if (snapshot.hasData && snapshot.data != null && snapshot.data!.exists) {
            data = snapshot.data!.data() ?? booking.toMap();
          }

          final providerName = data['providerName'] as String? ?? (booking.providerName.isNotEmpty ? booking.providerName : 'Assigned Technician');
          final rawProviderPhone = data['providerPhone'] as String? ?? (booking.providerPhone.isNotEmpty ? booking.providerPhone : '+91 91486 99386');
          final maskedPhone = _maskPhoneNumber(rawProviderPhone);
          final statusStr = data['status'] as String? ?? booking.status.code;
          final startOtp = data['startOtp'] as String? ?? (booking.startOtp.isNotEmpty ? booking.startOtp : '4829');
          final techLoc = data['technicianLocation'] as Map<String, dynamic>?;
          final providerLat = (data['providerLat'] as num?)?.toDouble() ??
              (techLoc?['latitude'] as num?)?.toDouble() ??
              (data['latitude'] as num?)?.toDouble() ??
              booking.latitude ??
              12.9716;
          final providerLng = (data['providerLng'] as num?)?.toDouble() ??
              (techLoc?['longitude'] as num?)?.toDouble() ??
              (data['longitude'] as num?)?.toDouble() ??
              booking.longitude ??
              77.5946;
          final etaMinutes = (data['etaMinutes'] as num?)?.toInt() ?? 12;

          return Stack(
            children: [
              // 1. Radar Live Location View
              Container(
                color: const Color(0xFFE3F2FD),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(28),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                        ),
                        child: const Icon(
                          Icons.radar_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Live GPS Radar Active 📡',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Live Tech Coordinates: $providerLat, $providerLng',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 16, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(
                              'Estimated Arrival: $etaMinutes mins',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Bottom Technician Tracking Card
              Positioned(
                left: AppSpacing.medium,
                right: AppSpacing.medium,
                bottom: AppSpacing.large,
                child: Card(
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: const Icon(Icons.person_rounded, size: 32, color: AppColors.primary),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    providerName,
                                    style: AppTextStyle.sectionHeader,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
                                      const SizedBox(width: 4),
                                      const Text(
                                        '4.9 (120+ jobs)',
                                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Colors.grey),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• $maskedPhone',
                                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF81C784)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_run_rounded, size: 14, color: Color(0xFF2E7D32)),
                                  const SizedBox(width: 4),
                                  Text(
                                    statusStr == 'ON_THE_WAY' ? 'On The Way' : statusStr,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: Color(0xFF2E7D32),
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Start Job OTP',
                                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: Colors.grey),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  startOtp,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: AppColors.primary,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () => _openProviderChat(context, rawProviderPhone, booking.id),
                                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                                  label: const Text('Chat'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColors.primary,
                                    side: const BorderSide(color: AppColors.primary),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: () => _makeMaskedCall(context, rawProviderPhone),
                                  icon: const Icon(Icons.phone_rounded, size: 16),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E7D32),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
