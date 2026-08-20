import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/technician_firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';
import 'chat/technician_chat_screen.dart';
import 'quotation_builder_screen.dart';

class JobDetailScreen extends StatefulWidget {
  final String bookingId;
  final String techId;

  const JobDetailScreen({
    super.key,
    required this.bookingId,
    required this.techId,
  });

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  final _firestoreService = TechnicianFirestoreService();
  final _locationService = LocationService();

  final _startOtpController = TextEditingController();
  final _completionOtpController = TextEditingController();

  // Quotation fields
  final List<Map<String, dynamic>> _partItems = [];
  final _partNameController = TextEditingController();
  final _partPriceController = TextEditingController();

  @override
  void dispose() {
    _startOtpController.dispose();
    _completionOtpController.dispose();
    _partNameController.dispose();
    _partPriceController.dispose();
    super.dispose();
  }

  Future<void> _launchDirections(String address) async {
    final cleanAddr = address.trim().isEmpty ? "Hassan, Karnataka" : address.trim();
    final encodedAddr = Uri.encodeComponent(cleanAddr);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddr");

    try {
      final launched = await launchUrl(
        googleMapsUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(googleMapsUrl, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      debugPrint("Google Maps HTTPS launch failed: $e");
      try {
        final geoUrl = Uri.parse("geo:0,0?q=$encodedAddr");
        await launchUrl(geoUrl, mode: LaunchMode.externalApplication);
      } catch (err) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Could not launch Google Maps for address: $cleanAddr")),
          );
        }
      }
    }
  }

  Future<void> _launchCall(String rawPhone) async {
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleanPhone.isEmpty) return;
    final Uri url = Uri(scheme: 'tel', path: cleanPhone);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        await launchUrl(url);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch phone dialer for $cleanPhone")),
        );
      }
    }
  }


  void _showStartOtpDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text("Enter Start Service OTP", style: AppTextStyle.sectionHeader),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ask the customer for their 4-digit Start OTP to begin service.", style: AppTextStyle.subtitle),
              const SizedBox(height: 16),
              TextField(
                controller: _startOtpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: "0000",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _firestoreService.validateStartOtp(
                  widget.bookingId,
                  _startOtpController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _locationService.setActiveBookingId(widget.bookingId);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Start OTP Verified! Service is now In Progress."), backgroundColor: AppColors.success),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid OTP code. Please ask the customer."), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Verify & Start", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showCompletionOtpDialog({String? paymentMode, bool? isFinalBillPaid, double? totalAmount}) {
    final bool isCash = (paymentMode == 'COD' || paymentMode == 'CASH' || isFinalBillPaid == false);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: Text("Enter Completion OTP", style: AppTextStyle.sectionHeader),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Ask the customer for their 4-digit Completion OTP once work is done.", style: AppTextStyle.subtitle),
              if (isCash && totalAmount != null && totalAmount > 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: Colors.amber.shade400),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.payments_rounded, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Collect ₹${totalAmount.toStringAsFixed(0)} Cash from customer upon completion.",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _completionOtpController,
                keyboardType: TextInputType.number,
                maxLength: 4,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8),
                decoration: InputDecoration(
                  hintText: "0000",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final success = await _firestoreService.validateCompletionOtp(
                  widget.bookingId,
                  _completionOtpController.text,
                );
                if (mounted) {
                  Navigator.pop(context);
                  if (success) {
                    _locationService.setActiveBookingId(null);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Job Completed Successfully! Great job."), backgroundColor: AppColors.success),
                    );
                    Navigator.pop(context);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Invalid OTP code."), backgroundColor: AppColors.error),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
              child: const Text("Verify & Complete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showQuotationBuilderModal(List<dynamic> existingItems, String categoryName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuotationBuilderScreen(
          jobId: widget.bookingId,
          categoryName: categoryName,
          initialItems: existingItems,
          onSubmitQuote: (items) async {
            final partMaps = items
                .map((i) => {
                      'name': i.title,
                      'title': i.title,
                      'price': i.price,
                      'isSparePart': i.isSparePart,
                      'isVerified': i.isVerified,
                      'warrantyDays': i.warrantyDays,
                    })
                .toList();

            final total = items.fold(0.0, (sum, i) => sum + i.price);

            await _firestoreService.submitQuotation(
              widget.bookingId,
              partMaps,
              total,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Standard Rate Card Quotation submitted to customer!"),
                  backgroundColor: AppColors.success,
                ),
              );
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Service Visit Details"),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Booking details not found."));
          }

          final data = snapshot.data!.data()!;
          final category = data['categoryName'] ?? data['applianceType'] ?? 'Appliance Service';
          final subCategory = data['subCategoryName'] ?? data['serviceType'] ?? 'General Repair';
          final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
          final customerPhone = data['userPhone'] ?? data['phone'] ?? '+91 9876543210';
          final address = data['address'] ?? data['fullAddress'] ?? 'Hassan, Karnataka';
          final status = data['status'] ?? 'ACCEPTED';
          final startOtp = data['startOtp'] ?? '1234';
          final completionOtp = data['completionOtp'] ?? '5678';

          final quotationMap = data['quotation'] as Map<String, dynamic>?;
          final quotationItems = (quotationMap?['items'] as List<dynamic>?) ?? [];
          final quotationTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Status Card
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Current Job Status", style: AppTextStyle.subtitle),
                            Text(
                              status.toUpperCase().replaceAll('_', ' '),
                              style: AppTextStyle.cardTitle.copyWith(color: AppColors.primary, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Service Info
                Text("Service Requirements", style: AppTextStyle.sectionHeader),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Appliance Category:", style: AppTextStyle.subtitle),
                          Text(category, style: AppTextStyle.cardTitle),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Sub-Category:", style: AppTextStyle.subtitle),
                          Text(subCategory, style: AppTextStyle.cardTitle),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Customer Info Card
                Text("Customer & Location", style: AppTextStyle.sectionHeader),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(customerName, style: AppTextStyle.cardTitle.copyWith(fontSize: 16)),
                          ),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => TechnicianChatDetailScreen(
                                    bookingId: widget.bookingId,
                                    customerName: customerName,
                                    customerPhone: customerPhone,
                                    serviceTitle: category,
                                    status: status,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary),
                          ),
                          IconButton(
                            onPressed: () => _launchCall(customerPhone),
                            icon: const Icon(Icons.phone_in_talk_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(address, style: AppTextStyle.subtitle.copyWith(fontSize: 13, height: 1.4)),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchDirections(address),
                          icon: const Icon(Icons.directions_rounded, color: Colors.white),
                          label: const Text("Get Directions in Google Maps", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Customer OTP Codes Display Card (For testing reference)
                // Container(
                //   padding: const EdgeInsets.all(AppSpacing.medium),
                //   decoration: BoxDecoration(
                //     color: Colors.amber.withOpacity(0.1),
                //     borderRadius: BorderRadius.circular(AppRadius.medium),
                //     border: Border.all(color: Colors.amber),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceAround,
                //     children: [
                //       Column(
                //         children: [
                //           Text("Customer Start OTP", style: AppTextStyle.subtitle),
                //           Text(startOtp, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                //         ],
                //       ),
                //       Column(
                //         children: [
                //           Text("Customer Completion OTP", style: AppTextStyle.subtitle),
                //           Text(completionOtp, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                //         ],
                //       ),
                //     ],
                //   ),
                // ),
                // const SizedBox(height: 20),

                // Quotation Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          Text("Quotation & Parts", style: AppTextStyle.sectionHeader),
                          if (quotationItems.isNotEmpty) ...[
                            Builder(builder: (context) {
                              final qStatus = (quotationMap?['status'] ?? data['quotationStatus'] ?? 'pending').toString().toLowerCase();
                              Color bg = Colors.orange;
                              String label = "AWAITING APPROVAL ⏳";
                              if (qStatus == 'approved') {
                                bg = Colors.green;
                                label = "APPROVED ✓";
                              } else if (qStatus == 'rejected') {
                                bg = Colors.red;
                                label = "DECLINED ✗";
                              }
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: bg.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: bg.withOpacity(0.4)),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(color: bg, fontWeight: FontWeight.bold, fontSize: 10),
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    Builder(builder: (context) {
                      final statusLower = status.toLowerCase();
                      final isJobClosed = [
                        'completed',
                        'work_completed',
                        'paid_and_closed',
                        'closed',
                        'cancelled',
                        'cancelled_by_customer',
                      ].contains(statusLower);
                      final isStarted = [
                        'in_progress',
                        'work_in_progress',
                        'work_started',
                        'repair_in_progress',
                        'inspection_in_progress',
                        'quotation_pending_approval',
                      ].contains(statusLower);
                      final qStatus = (quotationMap?['status'] ??
                              data['quotationStatus'] ??
                              '')
                          .toString()
                          .toLowerCase();
                      final isApproved = qStatus == 'approved';

                      if (isJobClosed) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade400),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_outline_rounded,
                                size: 14,
                                color: Colors.grey,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Job Completed • Locked 🔒",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (isApproved) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle_rounded,
                                size: 14,
                                color: Colors.green,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Approved by Customer ✓",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!isStarted) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.lock_clock_rounded,
                                size: 14,
                                color: Colors.orange,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Verify Start OTP to Unlock Quote 🔒",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return TextButton.icon(
                        onPressed: () => _showQuotationBuilderModal(
                          quotationItems,
                          category,
                        ),
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: AppColors.primary,
                        ),
                        label: Text(
                          quotationItems.isEmpty
                              ? "Add Quotation"
                              : "Edit Quotation",
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
                if (quotationItems.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        for (var item in quotationItems)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item['name']?.toString() ?? item['title']?.toString() ?? '', style: AppTextStyle.subtitle),
                                Text("₹${item['price']}", style: AppTextStyle.cardTitle),
                              ],
                            ),
                          ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total Spare/Labor:", style: AppTextStyle.cardTitle),
                            Text("₹$quotationTotal", style: AppTextStyle.cardTitle.copyWith(color: AppColors.primary, fontSize: 16)),
                          ],
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Status Action Buttons
                if (status.toLowerCase() == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _firestoreService.updateJobStatus(widget.bookingId, 'IN_TRANSIT');
                        _locationService.startLiveTracking(widget.techId, activeBookingId: widget.bookingId);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Status updated: On the Way to customer location.")),
                          );
                        }
                      },
                      icon: const Icon(Icons.directions_car_rounded, color: Colors.white),
                      label: const Text("Mark 'On the Way'", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),

                if (status.toLowerCase() == 'on_the_way' || status.toLowerCase() == 'in_transit')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showStartOtpDialog,
                      icon: const Icon(Icons.play_circle_fill_rounded, color: Colors.white),
                      label: const Text("Arrived: Enter Start Service OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    ),
                  ),

                if (['in_progress', 'work_in_progress', 'repair_in_progress', 'work_started', 'inspection_in_progress'].contains(status.toLowerCase()))
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () => _showCompletionOtpDialog(
                        paymentMode: data['paymentMode']?.toString(),
                        isFinalBillPaid: data['isFinalBillPaid'] == true,
                        totalAmount: (data['finalAmountPaid'] as num?)?.toDouble() ?? (data['quoteTotal'] as num?)?.toDouble() ?? quotationTotal,
                      ),
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text("Finish: Enter Completion OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    ),
                  ),

                if (['completed', 'work_completed', 'paid_and_closed'].contains(status.toLowerCase()))
                  Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.success.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Job Completed & Closed",
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "This job has been finalized and recorded in your Earnings tab.",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.primary),
                          label: const Text("Return to My Jobs", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }
}
