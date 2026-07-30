import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/technician_firestore_service.dart';
import '../services/location_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_style.dart';

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
    final encodedAddr = Uri.encodeComponent(address);
    final googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$encodedAddr");
    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not launch Google Maps")),
        );
      }
    }
  }

  Future<void> _launchCall(String phone) async {
    final url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
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

  void _showCompletionOtpDialog() {
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

  void _showQuotationBuilderModal(List<dynamic> existingItems) {
    _partItems.clear();
    for (var item in existingItems) {
      if (item is Map) {
        _partItems.add(Map<String, dynamic>.from(item));
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.large)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            double totalEstimate = 0.0;
            for (var item in _partItems) {
              totalEstimate += (item['price'] as num? ?? 0.0);
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: AppSpacing.medium,
                right: AppSpacing.medium,
                top: AppSpacing.medium,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Spare Parts & Repair Quotation", style: AppTextStyle.sectionHeader),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Add required replacement parts and extra service charges.", style: AppTextStyle.subtitle),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _partNameController,
                          decoration: InputDecoration(
                            hintText: "Part Name (e.g. Compressor)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _partPriceController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            hintText: "Cost (₹)",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final name = _partNameController.text.trim();
                          final price = double.tryParse(_partPriceController.text) ?? 0.0;
                          if (name.isNotEmpty && price > 0) {
                            setModalState(() {
                              _partItems.add({'name': name, 'price': price});
                            });
                            _partNameController.clear();
                            _partPriceController.clear();
                          }
                        },
                        icon: const Icon(Icons.add_circle_rounded, color: AppColors.primary, size: 36),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (_partItems.isNotEmpty)
                    Container(
                      constraints: const BoxConstraints(maxHeight: 160),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _partItems.length,
                        itemBuilder: (context, idx) {
                          final item = _partItems[idx];
                          return ListTile(
                            dense: true,
                            title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("₹${item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                  onPressed: () {
                                    setModalState(() {
                                      _partItems.removeAt(idx);
                                    });
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Total Quotation Amount:", style: AppTextStyle.cardTitle),
                      Text("₹$totalEstimate", style: AppTextStyle.mainTitle.copyWith(color: AppColors.primary, fontSize: 20)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        await _firestoreService.submitQuotation(
                          widget.bookingId,
                          _partItems,
                          totalEstimate,
                        );
                        if (mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Quotation saved and submitted to booking!"), backgroundColor: AppColors.success),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text("Save & Submit Quotation", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
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
          final status = data['status'] ?? 'accepted';
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
                          Text(customerName, style: AppTextStyle.cardTitle.copyWith(fontSize: 16)),
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
                    Text("Quotation & Parts", style: AppTextStyle.sectionHeader),
                    TextButton.icon(
                      onPressed: () => _showQuotationBuilderModal(quotationItems),
                      icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                      label: Text(quotationItems.isEmpty ? "Add Quotation" : "Edit Quotation", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
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
                                Text(item['name']?.toString() ?? '', style: AppTextStyle.subtitle),
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
                if (status == 'accepted')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await _firestoreService.updateJobStatus(widget.bookingId, 'on_the_way');
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

                if (status == 'on_the_way')
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

                if (status == 'in_progress')
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _showCompletionOtpDialog,
                      icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                      label: const Text("Finish: Enter Completion OTP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                    ),
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
