import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/invoice_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../services/database_service.dart';
import '../../models/booking_lifecycle_state.dart';
import '../../ui/widgets/rating_review_dialog.dart';
import '../../ui/widgets/app_state_widgets.dart';
import '../Chat/chat_screen.dart';
import 'quotation_checkout_screen.dart';
import '../../models/OrderModel.dart';
import 'tax_invoice_widget.dart';


class BookingsScreen extends StatefulWidget {

  const BookingsScreen({super.key});

  @override
  State<BookingsScreen> createState() => _BookingsScreenState();
}

class _BookingsScreenState extends State<BookingsScreen> {
  final _dbService = DatabaseService();
  late Stream<List<OrderModel>> _ordersStream;

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    _ordersStream = _dbService.streamOrders().asBroadcastStream();
  }

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

  Future<void> _rejectQuotation(String bookingId, [Map<String, dynamic>? bookingData]) async {
    try {
      final data = bookingData ?? {};
      final double visitingFee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
      final bool isVisitingFeePaid = data['isVisitingFeePaid'] == true || data['isVisitingFeePaid'] == 1;

      final updates = <String, dynamic>{
        'quotation.status': 'rejected',
        'quotationStatus': 'rejected',
        'quotation.items': [],
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isVisitingFeePaid) {
        updates['status'] = 'paid_and_closed';
        updates['finalAmountPaid'] = visitingFee;
        updates['isFinalBillPaid'] = true;
      } else {
        updates['status'] = 'quotation_rejected';
      }

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(updates);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .doc(bookingId)
            .set(updates, SetOptions(merge: true));
      }

      final providerId = data['providerId']?.toString();
      if (providerId != null && providerId.isNotEmpty) {
        final notifId = 'notif_t_${DateTime.now().millisecondsSinceEpoch}';
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('notifications')
            .doc(notifId)
            .set({
          'id': notifId,
          'techId': providerId,
          'title': 'Quotation Declined ✗',
          'body': 'Customer declined quotation. Service closed for inspection only.',
          'data': {'bookingId': bookingId, 'type': 'QUOTATION_REJECTED'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isVisitingFeePaid
                  ? "Quotation Declined. Inspection fee (₹${visitingFee.toStringAsFixed(0)}) paid. Job closed."
                  : "Quotation Declined. Inspection fee (₹${visitingFee.toStringAsFixed(0)}) due.",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to decline quotation: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _openQuotationCheckoutScreen(Map<String, dynamic> data, String bookingId) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => QuotationCheckoutScreen(
          bookingData: data,
          bookingId: bookingId,
        ),
      ),
    );
    if (result == true && mounted) {
      // If detail sheet is open, pop it so customer sees updated booking list with payment done
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  double _calculateBookingTotal(Map<String, dynamic> data) {
    final double visitingFee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
    final quotationMap = data['quotation'] as Map<String, dynamic>?;
    final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ??
        (data['quoteTotal'] as num?)?.toDouble() ??
        (data['additionalCost'] as num?)?.toDouble() ??
        0.0;
    final double finalAmount = (data['finalAmountPaid'] as num?)?.toDouble() ?? 0.0;

    if (finalAmount > 0) return finalAmount;
    if (quoteTotal > 0) {
      final bool isFeePaid = data['isVisitingFeePaid'] == true || data['isVisitingFeePaid'] == 1;
      return quoteTotal + (isFeePaid ? 0.0 : visitingFee);
    }
    return visitingFee;
  }

  void _showBookingDetailModal(Map<String, dynamic> data, String bookingId) {
    final title = data['title'] ?? 'Appliance Service';
    final double totalAmount = _calculateBookingTotal(data);
    final cost = '₹${totalAmount.toStringAsFixed(0)}';
    final dateTime = data['dateTime'] ?? 'Scheduled Slot';
    final address = data['address'] ?? '';
    final status = (data['status'] ?? 'pending').toString().toLowerCase();
    final startOtp = data['startOtp']?.toString() ?? '1234';
    final completionOtp = data['completionOtp']?.toString() ?? '5678';
    final String rawTechName = (data['providerName'] ?? data['techName'] ?? data['technicianName'] ?? data['provider_name'])?.toString() ?? '';
    final String rawTechPhone = (data['providerPhone'] ?? data['techPhone'] ?? data['technicianPhone'] ?? data['provider_phone'])?.toString() ?? '';
    final bool isAssigned = (data['providerId']?.toString() ?? '').isNotEmpty ||
        ['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'inspection_in_progress', 'quotation_pending', 'quotation_pending_approval', 'repair_in_progress', 'in_progress', 'work_started', 'work_in_progress', 'completed', 'work_completed'].contains(status.toLowerCase());

    final techName = rawTechName.isNotEmpty ? rawTechName : (isAssigned ? 'Master Technician' : '');
    final techPhone = rawTechPhone.isNotEmpty ? rawTechPhone : (isAssigned ? '+91 9876543210' : '');
    final quotation = data['quotation'] as Map<String, dynamic>?;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(AppSpacing.medium),
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
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(title, style: AppTextStyle.mainTitle.copyWith(fontSize: 18)),
                    ),
                    Text(cost, style: AppTextStyle.mainTitle.copyWith(fontSize: 20, color: AppColors.primary)),
                  ],
                ),
                SizedBox(height: 8),
                Text("Booking ID: $bookingId", style: TextStyle(fontSize: 12, color: Colors.grey)),
                // OTP Display Box for Customer (Kept visible for all active stages)

                if (['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'inspection_in_progress', 'quotation_pending', 'quotation_pending_approval', 'repair_in_progress', 'in_progress', 'work_started', 'work_in_progress'].contains(status.toLowerCase()))
                  _buildCustomerOtpBox(startOtp, completionOtp, status),

                SizedBox(height: 12),
                _buildStatusTimeline(status, techName),

                if (['completed', 'work_completed', 'paid_and_closed'].contains(status.toLowerCase())) ...[
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        InvoiceService.generateAndShowInvoice(
                          context: context,
                          bookingData: data,
                          bookingId: bookingId,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.primary, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary, size: 20),
                      label: Text(
                        "Download / View Tax Invoice (PDF)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),
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
                      icon: Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                      label: Text(
                        "Rate & Review Technician ⭐",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.title),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFF8E1),
                        side: BorderSide(color: Color(0xFFFFD54F)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                      ),
                    ),
                  ),
                ],

                const Divider(height: 24),
                _buildInfoRow(Icons.schedule_rounded, "Scheduled Slot", dateTime),
                SizedBox(height: 10),
                _buildInfoRow(Icons.location_on_outlined, "Service Address", address),


                if (techName.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text("Assigned Technician", style: AppTextStyle.bodyBold),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
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
                        SizedBox(width: 12),
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
                          icon: Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
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
                            icon: Icon(Icons.phone_rounded, color: AppColors.primary),
                            onPressed: () => _makePhoneCall(techPhone),
                          ),
                      ],
                    ),
                  ),
                ],

                if (quotation != null) ...[
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text("Repair Quotation & Parts Breakdown", style: AppTextStyle.bodyBold),
                      ),
                      SizedBox(width: 8),
                      Builder(builder: (context) {
                        final qStatus = (quotation['status'] ?? data['quotationStatus'] ?? 'pending').toString().toLowerCase();
                        Color bg = Colors.orange;
                        String label = "AWAITING APPROVAL";
                        if (qStatus == 'approved') {
                          bg = Colors.green;
                          label = "APPROVED ✓";
                        } else if (qStatus == 'rejected') {
                          bg = Colors.red;
                          label = "DECLINED ✗";
                        }
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: bg.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: bg.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            label,
                            style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10),
                          ),
                        );
                      }),
                    ],
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: Colors.green.shade300),
                    ),
                    child: Column(
                      children: [
                        if (quotation['items'] != null)
                          for (var item in (quotation['items'] as List))
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (item['title'] ?? item['name'] ?? 'Spare Part').toString(),
                                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          "🛡️ Verified • ${item['warrantyDays'] ?? 90}d Warranty",
                                          style: TextStyle(fontSize: 10, color: Colors.green.shade700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text("₹${item['price'] ?? '0'}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ],
                              ),
                            ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Repair Estimate", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text(
                              "₹${quotation['totalAmount'] ?? '0'}",
                              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                        Builder(builder: (context) {
                          final qStatus = (quotation['status'] ?? data['quotationStatus'] ?? 'pending').toString().toLowerCase();
                          final isJobClosed = ['completed', 'work_completed', 'paid_and_closed', 'closed', 'cancelled', 'cancelled_by_customer'].contains(status.toLowerCase());
                          if (qStatus != 'approved' && qStatus != 'rejected' && !isJobClosed) {
                            return Column(
                              children: [
                                SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => _rejectQuotation(bookingId, data),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.red,
                                          side: BorderSide(color: Colors.red),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text("Decline Quote"),
                                      ),
                                    ),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () => _openQuotationCheckoutScreen(data, bookingId),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green.shade700,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text("Approve & Pay", style: TextStyle(fontWeight: FontWeight.bold)),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        }),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                    child: Text("Close Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCustomerOtpBox(String startOtp, String completionOtp, String status) {
    return Container(
      padding: EdgeInsets.all(14),
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [Icon(Icons.verified_user_rounded, color: AppColors.primary, size: 20),
              SizedBox(width: 8),
              Text("Service Verification OTPs", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text("START OTP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      SizedBox(height: 4),
                      Text(
                        startOtp,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Text("COMPLETION OTP", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                      SizedBox(height: 4),
                      Text(
                        completionOtp,
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 4, color: Colors.green),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            status == 'accepted'
                ? "💡 Share the START OTP with your technician when they arrive to begin service."
                : "💡 Share the COMPLETION OTP once the technician has finished repair work.",
            style: TextStyle(fontSize: 11, color: AppColors.subtitle, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig(String rawStatus, String techName) {
    final state = BookingLifecycleState.parse(rawStatus);
    final name = techName.isNotEmpty ? techName : "Technician";

    switch (state) {
      case BookingLifecycleState.draft:
        return {
          'label': 'Draft',
          'timeline': 'Booking in draft mode',
          'color': Colors.grey.shade700,
          'bg': Colors.grey.shade100,
          'icon': Icons.edit_note_rounded,
        };
      case BookingLifecycleState.booked:
        return {
          'label': 'Booked & Paid',
          'timeline': 'Searching for nearby technician...',
          'color': Colors.amber.shade900,
          'bg': Colors.amber.shade50,
          'icon': Icons.hourglass_top_rounded,
        };
      case BookingLifecycleState.unfulfilledRefunded:
        return {
          'label': 'Unfulfilled (Refunded)',
          'timeline': 'No technician available. Full refund issued to wallet.',
          'color': Colors.red.shade800,
          'bg': Colors.red.shade50,
          'icon': Icons.currency_exchange_rounded,
        };
      case BookingLifecycleState.accepted:
        return {
          'label': 'Technician Assigned',
          'timeline': '$name Assigned & Confirmed',
          'color': Colors.indigo.shade700,
          'bg': Colors.indigo.shade50,
          'icon': Icons.person_pin_circle_rounded,
        };
      case BookingLifecycleState.onTheWay:
        return {
          'label': 'On The Way 🛵',
          'timeline': '$name is On The Way',
          'color': Colors.orange.shade900,
          'bg': Colors.orange.shade50,
          'icon': Icons.directions_bike_rounded,
        };
      case BookingLifecycleState.arrived:
        return {
          'label': 'Technician Arrived 📍',
          'timeline': '$name has arrived at your location',
          'color': Colors.purple.shade700,
          'bg': Colors.purple.shade50,
          'icon': Icons.location_on_rounded,
        };
      case BookingLifecycleState.inspectionInProgress:
        return {
          'label': 'Inspection In Progress 🔍',
          'timeline': 'Technician is inspecting your appliance',
          'color': Colors.amber.shade900,
          'bg': Colors.amber.shade50,
          'icon': Icons.search_rounded,
        };
      case BookingLifecycleState.quotationPending:
        return {
          'label': 'Quotation Pending 📋',
          'timeline': 'Estimate submitted & awaiting your approval',
          'color': Colors.amber.shade900,
          'bg': Colors.amber.shade100,
          'icon': Icons.fact_check_rounded,
        };
      case BookingLifecycleState.visitOnlyCompleted:
        return {
          'label': 'Inspection Only Completed',
          'timeline': 'Quotation declined. Service closed with visiting fee.',
          'color': Colors.teal.shade700,
          'bg': Colors.teal.shade50,
          'icon': Icons.check_circle_outline_rounded,
        };
      case BookingLifecycleState.repairInProgress:
        return {
          'label': 'Repair In Progress 🛠️',
          'timeline': '$name is executing the repair work',
          'color': Colors.orange.shade800,
          'bg': Colors.orange.shade50,
          'icon': Icons.build_circle_rounded,
        };
      case BookingLifecycleState.completed:
        return {
          'label': 'Service Completed ✅',
          'timeline': 'Service Completed & Final Bill Paid',
          'color': Colors.green.shade700,
          'bg': Colors.green.shade50,
          'icon': Icons.check_circle_rounded,
        };
      case BookingLifecycleState.reviewed:
        return {
          'label': 'Service Reviewed ⭐',
          'timeline': 'Thank you for your 5-star rating!',
          'color': Colors.green.shade800,
          'bg': Colors.green.shade100,
          'icon': Icons.star_rounded,
        };
      case BookingLifecycleState.customerUnreachable:
        return {
          'label': 'Customer Unreachable 📵',
          'timeline': 'Technician arrived but customer was unreachable',
          'color': Colors.red.shade800,
          'bg': Colors.red.shade50,
          'icon': Icons.phone_missed_rounded,
        };
      case BookingLifecycleState.quotationRejected:
        return {
          'label': 'Quotation Rejected ❌',
          'timeline': 'Estimate rejected by customer',
          'color': Colors.red.shade700,
          'bg': Colors.red.shade50,
          'icon': Icons.cancel_rounded,
        };
      case BookingLifecycleState.incrementalQuotePending:
        return {
          'label': 'Additional Part Quote 📋',
          'timeline': 'Additional part estimate awaiting approval',
          'color': Colors.amber.shade900,
          'bg': Colors.amber.shade100,
          'icon': Icons.post_add_rounded,
        };
      case BookingLifecycleState.partsAwaitedPaused:
        return {
          'label': 'Parts Procurement 📦',
          'timeline': 'Job paused while spare part is procured',
          'color': Colors.indigo.shade700,
          'bg': Colors.indigo.shade50,
          'icon': Icons.inventory_2_rounded,
        };
      case BookingLifecycleState.unrepairableClosed:
        return {
          'label': 'Unrepairable (Closed)',
          'timeline': 'Appliance unrepairable / BER. Service closed.',
          'color': Colors.grey.shade800,
          'bg': Colors.grey.shade100,
          'icon': Icons.build_circle_outlined,
        };
      case BookingLifecycleState.categoryReclassified:
        return {
          'label': 'Category Updated 🔄',
          'timeline': 'Appliance service category reclassified on-site',
          'color': Colors.deepPurple.shade700,
          'bg': Colors.deepPurple.shade50,
          'icon': Icons.sync_rounded,
        };
      case BookingLifecycleState.safetyHaltCancelled:
        return {
          'label': 'Safety Halt ⚠️',
          'timeline': 'Job halted due to unsafe site conditions',
          'color': Colors.red.shade900,
          'bg': Colors.red.shade50,
          'icon': Icons.warning_amber_rounded,
        };
      case BookingLifecycleState.cancelledEnroute:
      case BookingLifecycleState.cancelledAtSite:
        return {
          'label': 'Cancelled',
          'timeline': 'Booking cancelled',
          'color': Colors.red.shade700,
          'bg': Colors.red.shade50,
          'icon': Icons.cancel_rounded,
        };
      case BookingLifecycleState.paymentPendingVerification:
        return {
          'label': 'Payment Verification ⏳',
          'timeline': 'Verifying payment with bank server...',
          'color': Colors.amber.shade800,
          'bg': Colors.amber.shade50,
          'icon': Icons.account_balance_rounded,
        };
      case BookingLifecycleState.warrantyClaimed:
        return {
          'label': 'Warranty Claim Active 🛡️',
          'timeline': '7-Day Warranty Claim active. Support team assigned.',
          'color': Colors.indigo.shade800,
          'bg': Colors.indigo.shade50,
          'icon': Icons.shield_rounded,
        };
      case BookingLifecycleState.warrantyReworkAssigned:
        return {
          'label': 'Free Warranty Rework 🛠️',
          'timeline': 'Technician assigned for free warranty inspection',
          'color': Colors.indigo.shade800,
          'bg': Colors.indigo.shade50,
          'icon': Icons.handyman_rounded,
        };
      case BookingLifecycleState.warrantyRefunded:
        return {
          'label': 'Warranty Refunded 💰',
          'timeline': 'Warranty refund credited to wallet',
          'color': Colors.green.shade800,
          'bg': Colors.green.shade50,
          'icon': Icons.account_balance_wallet_rounded,
        };
      case BookingLifecycleState.rePooled:
        return {
          'label': 'Re-assigning Partner 🔄',
          'timeline': 'Re-pooling job for another nearby technician',
          'color': Colors.blue.shade800,
          'bg': Colors.blue.shade50,
          'icon': Icons.swap_horizontal_circle_rounded,
        };
      case BookingLifecycleState.adminAuditHold:
        return {
          'label': 'Admin Audit Hold 🚨',
          'timeline': 'Quotation under admin price review',
          'color': Colors.deepOrange.shade800,
          'bg': Colors.deepOrange.shade50,
          'icon': Icons.admin_panel_settings_rounded,
        };
    }
  }

  Widget _buildStatusTimeline(String status, String techName) {
    final cfg = _getStatusConfig(status, techName);
    final String statusText = cfg['timeline'];
    final Color color = cfg['color'];
    final IconData icon = cfg['icon'];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cfg['bg'],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          SizedBox(width: 8),
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
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
              SizedBox(height: 2),
              Text(value, style: AppTextStyle.subtitle.copyWith(color: AppColors.title)),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int initialTab = (ModalRoute.of(context)?.settings.arguments as int?) ?? 0;

    return DefaultTabController(
      length: 2,
      initialIndex: initialTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          title: Text('My Bookings & Orders', style: AppTextStyle.mainTitle),
          bottom: TabBar(
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.subtitle,
            labelStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            tabs: const [
              Tab(text: 'Service Bookings'),
              Tab(text: 'My Orders'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildServiceBookingsTab(),
            _buildProductOrdersTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceBookingsTab() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _dbService.getUserBookingsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget(message: 'Syncing your bookings...');
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Booking Sync Error',
            errorMessage: snapshot.error.toString(),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final List<Map<String, dynamic>> bookingDocs = docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          return data;
        }).toList();

        bookingDocs.sort((a, b) {
          final aTime = (a['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              (a['timestamp'] as num?)?.toInt() ??
              0;
          final bTime = (b['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ??
              (b['timestamp'] as num?)?.toInt() ??
              0;
          if (aTime != 0 || bTime != 0) {
            return bTime.compareTo(aTime);
          }
          return b['id'].toString().compareTo(a['id'].toString());
        });

        if (bookingDocs.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Active Bookings',
            message: 'Your scheduled service appointments will appear here.',
            icon: Icons.calendar_today_rounded,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.medium),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: bookingDocs.length,
          itemBuilder: (context, index) {
            final data = bookingDocs[index];
            final bookingId = data['id']?.toString() ?? 'bf_$index';
            final title = data['title']?.toString() ?? 'Appliance Repair';
            final dateTime = data['dateTime']?.toString() ?? 'Scheduled Slot';
            final double totalAmount = _calculateBookingTotal(data);
            final cost = '₹${totalAmount.toStringAsFixed(0)}';
            final status = (data['status'] ?? 'pending').toString().toLowerCase();
            final startOtp = data['startOtp']?.toString() ?? '';
            final completionOtp = data['completionOtp']?.toString() ?? '';
            final String rawTechName = (data['providerName'] ?? data['techName'] ?? data['technicianName'] ?? data['provider_name'])?.toString() ?? '';
            final bool isAssigned = (data['providerId']?.toString() ?? '').isNotEmpty ||
                ['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'inspection_in_progress', 'quotation_pending', 'quotation_pending_approval', 'repair_in_progress', 'in_progress', 'work_started', 'work_in_progress', 'completed', 'work_completed'].contains(status.toLowerCase());
            final techName = rawTechName.isNotEmpty ? rawTechName : (isAssigned ? 'Master Technician' : '');

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
              margin: EdgeInsets.only(bottom: AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.large),
                onTap: () => _showBookingDetailModal(data, bookingId),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.medium),
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
                          SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(title, style: AppTextStyle.cardTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                                SizedBox(height: 4),
                                Text(dateTime, style: AppTextStyle.subtitle),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                          SizedBox(width: AppSpacing.small),
                          Text(cost, style: AppTextStyle.mainTitle.copyWith(fontSize: 18, color: AppColors.primary)),
                        ],
                      ),

                      if (['accepted', 'assigned', 'on_the_way', 'in_transit', 'arrived', 'inspection_in_progress', 'quotation_pending', 'quotation_pending_approval', 'repair_in_progress', 'in_progress', 'work_started', 'work_in_progress'].contains(status.toLowerCase()) && (startOtp.isNotEmpty || completionOtp.isNotEmpty)) ...[
                        SizedBox(height: 12),
                        Builder(builder: (context) {
                          final bool showEndOtp = ['repair_in_progress', 'in_progress', 'work_started', 'work_in_progress'].contains(status.toLowerCase());
                          final String otpVal = showEndOtp ? (completionOtp.isNotEmpty ? completionOtp : startOtp) : startOtp;
                          final String otpLabel = showEndOtp ? "End OTP" : "Start OTP";

                          return Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: showEndOtp ? Colors.green.shade50 : AppColors.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: showEndOtp ? Colors.green.shade300 : AppColors.primary.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.key_rounded, size: 16, color: showEndOtp ? Colors.green.shade800 : AppColors.primary),
                                    SizedBox(width: 6),
                                    Text(
                                      "$otpLabel: $otpVal",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: showEndOtp ? Colors.green.shade900 : AppColors.primary),
                                    ),
                                  ],
                                ),
                                Text(
                                  showEndOtp ? "Share upon completion ►" : "Share with technician ►",
                                  style: TextStyle(fontSize: 11, color: showEndOtp ? Colors.green.shade800 : AppColors.primary, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      if (techName.isNotEmpty) ...[
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.engineering_rounded, size: 14, color: AppColors.subtitle),
                            SizedBox(width: 4),
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
    );
  }

  Widget _buildProductOrdersTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LoadingStateWidget(message: 'Loading your orders...');
        }

        if (snapshot.hasError) {
          return ErrorStateWidget(
            title: 'Order Sync Error',
            errorMessage: snapshot.error.toString(),
          );
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return const EmptyStateWidget(
            title: 'No Orders Placed Yet',
            message: 'Your purchased appliances and store orders will appear here.',
            icon: Icons.local_shipping_outlined,
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(AppSpacing.medium),
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final statusStr = order.orderStatus.toDisplayString();

            Color statusColor = Colors.orange.shade800;
            Color statusBg = Colors.orange.shade50;
            if (order.orderStatus == OrderStatus.shipped) {
              statusColor = Colors.blue.shade800;
              statusBg = Colors.blue.shade50;
            } else if (order.orderStatus == OrderStatus.outForDelivery) {
              statusColor = Colors.indigo.shade800;
              statusBg = Colors.indigo.shade50;
            } else if (order.orderStatus == OrderStatus.delivered) {
              statusColor = Colors.green.shade800;
              statusBg = Colors.green.shade50;
            } else if (order.orderStatus == OrderStatus.cancelled) {
              statusColor = Colors.red.shade800;
              statusBg = Colors.red.shade50;
            }

            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.large),
                border: Border.all(color: AppColors.border),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.large),
                onTap: () => _showOrderDetailModal(order),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.medium),
                            child: Image.network(
                              order.productImage.isNotEmpty
                                  ? order.productImage
                                  : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: Icon(Icons.inventory_2_rounded, color: Colors.grey),
                              ),
                            ),
                          ),
                          SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  order.productName,
                                  style: AppTextStyle.cardTitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  order.expectedDeliveryDate ?? 'Delivery in 2-3 Days',
                                  style: AppTextStyle.subtitle,
                                ),
                                SizedBox(height: 6),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusBg,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    statusStr,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      color: statusColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: AppSpacing.small),
                          Text(
                            '₹${order.totalPaid.toStringAsFixed(0)}',
                            style: AppTextStyle.mainTitle.copyWith(
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: AppSpacing.medium),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.vpn_key_rounded, size: 16, color: AppColors.primary),
                                SizedBox(width: 6),
                                Text(
                                  'Delivery OTP: ${order.deliveryOtp}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Tap for details ►',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (order.deliveryPartnerName != null &&
                          order.deliveryPartnerName!.isNotEmpty &&
                          (order.orderStatus == OrderStatus.shipped ||
                              order.orderStatus == OrderStatus.outForDelivery ||
                              order.orderStatus == OrderStatus.delivered)) ...[
                        SizedBox(height: 8),
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: AppColors.primary,
                                child: Icon(Icons.engineering_rounded, size: 16, color: Colors.white),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery & Installation Agent',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.subtitle,
                                      ),
                                    ),
                                    Text(
                                      order.deliveryPartnerName!,
                                      style: AppTextStyle.bodyBold.copyWith(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                              if (order.deliveryPartnerPhone != null && order.deliveryPartnerPhone!.isNotEmpty)
                                IconButton(
                                  icon: Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                                  onPressed: () => _makePhoneCall(order.deliveryPartnerPhone!),
                                ),
                            ],
                          ),
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
    );
  }

  void _showOrderDetailModal(OrderModel order) {
    final statusStr = order.orderStatus.toDisplayString();

    Color statusColor = Colors.orange.shade800;
    Color statusBg = Colors.orange.shade50;
    IconData statusIcon = Icons.inventory_2_rounded;

    if (order.orderStatus == OrderStatus.shipped) {
      statusColor = Colors.blue.shade800;
      statusBg = Colors.blue.shade50;
      statusIcon = Icons.local_shipping_rounded;
    } else if (order.orderStatus == OrderStatus.outForDelivery) {
      statusColor = Colors.indigo.shade800;
      statusBg = Colors.indigo.shade50;
      statusIcon = Icons.directions_bike_rounded;
    } else if (order.orderStatus == OrderStatus.delivered) {
      statusColor = Colors.green.shade800;
      statusBg = Colors.green.shade50;
      statusIcon = Icons.check_circle_rounded;
    } else if (order.orderStatus == OrderStatus.cancelled) {
      statusColor = Colors.red.shade800;
      statusBg = Colors.red.shade50;
      statusIcon = Icons.cancel_rounded;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.all(AppSpacing.medium),
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
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        order.productName,
                        style: AppTextStyle.mainTitle.copyWith(fontSize: 18),
                      ),
                    ),
                    Text(
                      '₹${order.totalPaid.toStringAsFixed(0)}',
                      style: AppTextStyle.mainTitle.copyWith(
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text("Order ID: #${order.id}", style: TextStyle(fontSize: 12, color: Colors.grey)),
                SizedBox(height: 12),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(statusIcon, color: statusColor, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              statusStr,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: statusColor,
                              ),
                            ),
                            Text(
                              order.expectedDeliveryDate ?? 'Expected delivery within 2-3 business days',
                              style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 12),

                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_rounded, color: AppColors.primary, size: 22),
                      SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery Verification OTP',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.subtitle,
                              ),
                            ),
                            Text(
                              order.deliveryOtp,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 4,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'Share at delivery',
                        style: TextStyle(fontSize: 11, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 24),

                if (order.deliveryPartnerName != null &&
                    order.deliveryPartnerName!.isNotEmpty &&
                    (order.orderStatus == OrderStatus.shipped ||
                        order.orderStatus == OrderStatus.outForDelivery ||
                        order.orderStatus == OrderStatus.delivered)) ...[
                  Text("Assigned Delivery & Setup Agent", style: AppTextStyle.bodyBold),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: Icon(Icons.person_rounded, color: Colors.white),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.deliveryPartnerName!, style: AppTextStyle.bodyBold),
                              if (order.deliveryPartnerPhone != null && order.deliveryPartnerPhone!.isNotEmpty)
                                Text(order.deliveryPartnerPhone!, style: AppTextStyle.subtitle),
                            ],
                          ),
                        ),
                        if (order.deliveryPartnerPhone != null && order.deliveryPartnerPhone!.isNotEmpty)
                          IconButton(
                            icon: Icon(Icons.phone_rounded, color: AppColors.primary),
                            onPressed: () => _makePhoneCall(order.deliveryPartnerPhone!),
                          ),
                      ],
                    ),
                  ),
                  const Divider(height: 24),
                ],

                _buildInfoRow(Icons.location_on_outlined, "Delivery Address", order.deliveryAddress),
                SizedBox(height: 10),
                _buildInfoRow(
                  Icons.payment_rounded,
                  "Payment Summary",
                  "Item Price: ₹${order.price.toStringAsFixed(0)} • Total Paid: ₹${order.totalPaid.toStringAsFixed(0)} (${order.paymentMode})",
                ),
                if (order.orderStatus == OrderStatus.delivered) ...[
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        InvoiceService.generateAndShowOrderInvoice(
                          context: context,
                          order: order,
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                      label: const Text(
                        "Download Tax Invoice (PDF)",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline_rounded, size: 18, color: Colors.amber.shade900),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Tax Invoice PDF download will be available once delivery & setup is completed.',
                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                    ),
                    child: Text("Close Details", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_late_outlined, size: 56, color: Colors.grey),
          SizedBox(height: AppSpacing.medium),
          Text('No active bookings', style: AppTextStyle.sectionHeader),
          SizedBox(height: 4),
          Text('Your scheduled visits will appear here.', style: AppTextStyle.subtitle),
        ],
      ),
    );
  }
}