// lib/Bookings/bookings_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../services/database_service.dart';
import '../../ui/widgets/rating_review_dialog.dart';
import '../Chat/chat_screen.dart';

class BookingsScreen extends StatefulWidget {

  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _dbService = DatabaseService();

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not initiate phone call.')),
        );
      }
    }
  }

  void _showBookingDetailModal(Map<String, dynamic> data, String bookingId) {
    final title = data['title'] ?? 'Appliance Service';
    final fee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
    final cost = data['cost']?.toString() ?? '₹${fee.toStringAsFixed(0)}';
    final dateTime = data['dateTime'] ?? 'Scheduled Slot';
    final address = data['address'] ?? '';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final startOtp = data['startOtp']?.toString() ?? '1234';
    final completionOtp = data['completionOtp']?.toString() ?? '5678';
    final techName = data['providerName']?.toString() ?? '';
    final techPhone = data['providerPhone']?.toString() ?? '';
    final quotation = data['quotation'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
          ),
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyle.mainTitle.copyWith(fontSize: 18)),
                    ),
                    Text(cost, style: AppTextStyle.mainTitle.copyWith(fontSize: 20, color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 8),
                Text("Booking ID: $bookingId", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                // OTP Display Box for Customer (Kept visible for all active stages)

                if (['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'in_progress', 'work_started', 'work_in_progress'].contains(status.toLowerCase()))
                  _buildCustomerOtpBox(startOtp, completionOtp, status),

                const SizedBox(height: 12),
                _buildStatusTimeline(status, techName),

                if (['completed', 'work_completed'].contains(status.toLowerCase())) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showDialog(
                          context: context,
                          builder: (context) => RatingReviewDialog(
                            bookingId: bookingId,
                            providerName: techName.isNotEmpty ? techName : 'Technician',
                            providerId: techPhone,
                          ),
                        );
                      },
                      icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      label: const Text(
                        "Rate & Review Technician ⭐",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF8E1),
                        side: const BorderSide(color: Color(0xFFFFD54F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 24),
                _buildInfoRow(Icons.schedule_rounded, "Scheduled Slot", dateTime),
                const SizedBox(height: 10),
                _buildInfoRow(Icons.location_on_outlined, "Service Address", address),


                if (techName.isNotEmpty) ...[
                  const Divider(height: 24),
                  const Text("Assigned Technician", style: AppTextStyle.bodyBold),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(techName, style: AppTextStyle.bodyBold),
                              if (techPhone.isNotEmpty)
                                Text(techPhone, style: AppTextStyle.subtitle),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => BookingChatDetailScreen(
                                  bookingId: bookingId,
                                  providerName: techName,
                                  providerPhone: techPhone,
                                  serviceTitle: title,
                                  status: status,
                                ),
                              ),
                            );
                          },
                        ),
                        if (techPhone.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.primary),
                            onPressed: () => _makePhoneCall(techPhone),
                          ),
                      ],
                    ),
                  ),
                ],

                if (quotation != null) ...[
                  const Divider(height: 24),
                  const Text("Repair Quotation & Parts Breakdown", style: AppTextStyle.bodyBold),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      children: [
                        if (quotation['items'] != null)
                          for (var item in (quotation['items'] as List))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(item['name'] ?? 'Part Item', style: const TextStyle(fontSize: 13)),
                                  Text("₹${item['price'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Total Additional Estimate", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("₹${quotation['totalAmount'] ?? '0'}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                    child: const Text("Close Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerOtpBox(String startOtp, String completionOtp, String status) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text("Service Verification OTPs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text("START OTP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        startOtp,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Text("COMPLETION OTP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                        completionOtp,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            status == 'accepted'
                ? "💡 Share the START OTP with your technician when they arrive to begin service."
                : "💡 Share the COMPLETION OTP once the technician has finished repair work.",
            style: const TextStyle(fontSize: 11, color: AppColors.subtitle, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String rawStatus, String techName) {
    final status = rawStatus.toLowerCase().trim();

    if (['on_the_way', 'in_transit'].contains(status)) {
      final name = techName.isNotEmpty ? techName : "Technician";
      return {
        'label': 'On The Way 🛵',
        'timeline': '$name is On The Way',
        'color': Colors.blue.shade700,
        'bg': Colors.blue.withValues(alpha: 0.15),
        'icon': Icons.directions_bike_rounded,
      };
    } else if (['accepted', 'assigned'].contains(status)) {
      final name = techName.isNotEmpty ? techName : "Technician";
      return {
        'label': 'Technician Assigned',
        'timeline': '$name Assigned & Confirmed',
        'color': Colors.indigo.shade600,
        'bg': Colors.indigo.withValues(alpha: 0.15),
        'icon': Icons.person_pin_circle_rounded,
      };
    } else if (status == 'arrived') {
      return {
        'label': 'Technician Arrived 📍',
        'timeline': 'Technician has Arrived at your location',
        'color': Colors.teal.shade700,
        'bg': Colors.teal.withValues(alpha: 0.15),
        'icon': Icons.location_on_rounded,
      };
    } else if (['inspection_in_progress', 'quotation_pending_approval'].contains(status)) {
      return {
        'label': 'Inspection & Quote 📋',
        'timeline': 'Inspection in progress / Quote awaiting approval',
        'color': Colors.amber.shade900,
        'bg': Colors.amber.withValues(alpha: 0.15),
        'icon': Icons.fact_check_rounded,
      };
    } else if (['in_progress', 'work_started', 'work_in_progress'].contains(status)) {
      return {
        'label': 'Service in Progress ⚙️',
        'timeline': 'Technician is performing the service',
        'color': Colors.orange.shade800,
        'bg': Colors.orange.withValues(alpha: 0.15),
        'icon': Icons.build_circle_rounded,
      };
    } else if (['completed', 'work_completed', 'paid_and_closed', 'closed'].contains(status)) {
      return {
        'label': 'Completed 🎉',
        'timeline': 'Service Completed & Closed',
        'color': Colors.green.shade700,
        'bg': Colors.green.withValues(alpha: 0.15),
        'icon': Icons.check_circle_rounded,
      };
    } else if (['cancelled', 'rejected'].contains(status)) {
      return {
        'label': 'Cancelled',
        'timeline': 'Booking Cancelled',
        'color': Colors.red.shade700,
        'bg': Colors.red.withValues(alpha: 0.15),
        'icon': Icons.cancel_rounded,
      };
    }

    return {
      'label': 'Pending Assignment',
      'timeline': 'Searching for nearby technician...',
      'color': Colors.amber.shade800,
      'bg': AppColors.statusPendingBg,
      'icon': Icons.hourglass_top_rounded,
    };
  }

  Widget _buildStatusTimeline(String status, String techName) {
    final cfg = _getStatusConfig(status, techName);
    final String statusText = cfg['timeline'];
    final Color color = cfg['color'];
    final IconData icon = cfg['icon'];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cfg['bg'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(statusText, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.subtitle),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyle.subtitle.copyWith(color: AppColors.title)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        title: const Text('My bookings', style: AppTextStyle.mainTitle),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _dbService.getUserBookingsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final docs = snapshot.data?.docs ?? [];
          final List<Map<String, dynamic>> bookingDocs = docs.map((doc) {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            return data;
          }).toList();

          if (bookingDocs.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.medium),
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            itemCount: bookingDocs.length,
            itemBuilder: (context, index) {
              final data = bookingDocs[index];
              final bookingId = data['id']?.toString() ?? 'bf_$index';
              final title = data['title']?.toString() ?? 'Appliance Repair';
              final dateTime = data['dateTime']?.toString() ?? 'Scheduled Slot';
              final fee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
              final cost = data['cost']?.toString() ?? '₹${fee.toStringAsFixed(0)}';
              final status = (data['status'] ?? 'pending').toString().toLowerCase();
              final startOtp = data['startOtp']?.toString() ?? '';
              final completionOtp = data['completionOtp']?.toString() ?? '';
              final techName = data['providerName']?.toString() ?? '';

              final IconData displayIcon = title.contains('Fridge') || title.contains('Refrigerator')
                  ? Icons.kitchen_rounded
                  : title.contains('Wash') || title.contains('Machine')
                  ? Icons.local_laundry_service_rounded
                  : title.contains('Purifier')
                  ? Icons.water_drop_rounded
                  : Icons.handyman_rounded;

              final cfg = _getStatusConfig(status, techName);
              Color statusBg = cfg['bg'];
              Color statusText = cfg['color'];
              String displayStatusText = cfg['label'];

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  onTap: () => _showBookingDetailModal(data, bookingId),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.card,
                                borderRadius: BorderRadius.circular(AppRadius.medium),
                              ),
                              child: Icon(displayIcon, color: AppColors.primary, size: 26),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(title, style: AppTextStyle.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Text(dateTime, style: AppTextStyle.subtitle),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      displayStatusText.toUpperCase(),
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: statusText,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.small),
                            Text(cost, style: AppTextStyle.mainTitle.copyWith(fontSize: 18, color: AppColors.primary)),
                          ],
                        ),

                        // Display OTP Banner on Card if technician is assigned, on the way, arrived, or in progress
                        if (['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'inspection_in_progress', 'quotation_pending_approval', 'in_progress', 'work_started', 'work_in_progress'].contains(status.toLowerCase()) && (startOtp.isNotEmpty || completionOtp.isNotEmpty)) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.key_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      ['completed', 'work_completed'].contains(status.toLowerCase())
                                          ? "End OTP: $completionOtp"
                                          : "Start OTP: $startOtp",
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                                const Text("Share with technician ►", style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],

                        if (techName.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.engineering_rounded, size: 14, color: AppColors.subtitle),
                              const SizedBox(width: 4),
                              Text("Technician: $techName", style: AppTextStyle.subtitle.copyWith(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: AppSpacing.medium),
          const Text('No active bookings', style: AppTextStyle.sectionHeader),
          const SizedBox(height: 4),
          Text('Your scheduled visits will appear here.', style: AppTextStyle.subtitle),
        ],
      ),
    );
  }
}