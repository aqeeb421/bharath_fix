import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/technician_firestore_service.dart';
import '../../services/job_matching_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../../models/technician_booking_lifecycle.dart';
import '../../models/technician_order_model.dart';
import '../../widgets/technician_state_widgets.dart';
import '../job_detail_screen.dart';
import '../order_delivery_detail_screen.dart';

class JobsTab extends StatefulWidget {
  final String techId;
  final bool isOnline;

  const JobsTab({
    super.key,
    required this.techId,
    required this.isOnline,
  });

  @override
  State<JobsTab> createState() => _JobsTabState();
}

class _JobsTabState extends State<JobsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestoreService = TechnicianFirestoreService();

  late Stream<QuerySnapshot<Map<String, dynamic>>> _assignedJobsStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _openJobsStream;

  StreamSubscription? _techSub;
  Map<String, dynamic> _techData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initStreams();
    _subscribeTechProfile();
  }

  void _initStreams() {
    _assignedJobsStream = _firestoreService.getAssignedJobsStream(widget.techId);
    _openJobsStream = _firestoreService.getAvailableOpenJobsStream();
  }

  void _subscribeTechProfile() {
    _techSub?.cancel();
    if (widget.techId.isNotEmpty) {
      _techSub = FirebaseFirestore.instance
          .collection('providers')
          .doc(widget.techId)
          .snapshots()
          .listen((snap) {
        if (snap.exists && snap.data() != null && mounted) {
          setState(() {
            _techData = snap.data()!;
          });
        } else {
          FirebaseFirestore.instance
              .collection('providers')
              .doc(widget.techId)
              .get()
              .then((techSnap) {
            if (techSnap.exists && techSnap.data() != null && mounted) {
              setState(() {
                _techData = techSnap.data()!;
              });
            }
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(JobsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techId != widget.techId) {
      _initStreams();
      _subscribeTechProfile();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _techSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: "Assigned Repairs"),
            Tab(text: "Deliveries"),
            Tab(text: "Open Pool"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignedJobsList(),
              _buildApplianceDeliveriesList(),
              _buildOpenPoolJobsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedJobsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _assignedJobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const TechLoadingStateWidget(message: 'Loading assigned tasks...');
        }

        if (snapshot.hasError) {
          return TechErrorStateWidget(
            title: 'Assigned Jobs Sync Error',
            errorMessage: snapshot.error.toString(),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final activeDocs = docs.where((doc) {
          final status = (doc.data()['status'] ?? '').toString().toLowerCase().trim();
          return !['completed', 'work_completed', 'paid_and_closed', 'closed', 'cancelled', 'cancelled_by_customer', 'cancelled_by_technician', 'unrepairable_closed'].contains(status);
        }).toList();
        activeDocs.sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          if (aTime != 0 || bTime != 0) return bTime.compareTo(aTime);
          return b.id.compareTo(a.id);
        });

        if (activeDocs.isEmpty) {
          return const TechEmptyStateWidget(
            title: 'No Active Assigned Jobs',
            message: 'Check the Available Open Pool tab to claim new customer requests.',
            icon: Icons.assignment_turned_in_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: activeDocs.length,
          itemBuilder: (context, index) {
            final doc = activeDocs[index];
            final data = doc.data();
            return _buildJobCard(doc.id, data, isClaimable: false);
          },
        );
      },
    );
  }

  Widget _buildApplianceDeliveriesList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('deliveryPartnerId', isEqualTo: widget.techId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const TechLoadingStateWidget(message: 'Loading assigned deliveries...');
        }

        final docs = snapshot.data?.docs ?? [];
        final activeOrders = docs
            .map((doc) => TechnicianOrderModel.fromFirestore(doc))
            .where((order) => order.orderStatus != 'delivered' && order.orderStatus != 'cancelled')
            .toList();

        if (activeOrders.isEmpty) {
          return const TechEmptyStateWidget(
            title: 'No Pending Deliveries',
            message: 'You have no assigned appliance delivery tasks at the moment.',
            icon: Icons.local_shipping_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.local_shipping_rounded, color: AppColors.primary),
                ),
                title: Text(order.productName, style: AppTextStyle.cardTitle),
                subtitle: Text(
                  'Customer: ${order.userName}\nStatus: ${order.orderStatus.toUpperCase()} • OTP Required',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDeliveryDetailScreen(order: order),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildOpenPoolJobsList() {
    if (!widget.isOnline) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.power_settings_new_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text("You are currently offline", style: AppTextStyle.sectionHeader),
            const SizedBox(height: 4),
            Text("Toggle 'ONLINE' in the top right to claim jobs.", style: AppTextStyle.subtitle),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _openJobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        final openDocs = docs.where((doc) {
          final data = doc.data();
          final providerId = (data['providerId'] ?? '').toString().trim();
          final status = (data['status'] ?? '').toString().toLowerCase().trim();
          final isUnassigned = providerId.isEmpty || providerId == 'null' || providerId == 'none';
          final isClosed = status == 'completed' || status == 'cancelled' || status == 'paid_and_closed' || status == 'cancelled_by_customer' || status == 'cancelled_by_technician';

          if (!isUnassigned || isClosed) return false;

          // STRICT SKILL MATCHING RULE: Job must match technician's active skills array
          return JobMatchingService.isTechnicianExpertForJob(_techData, data);
        }).toList();

        openDocs.sort((a, b) {
          final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
          if (aTime != 0 || bTime != 0) return bTime.compareTo(aTime);
          return b.id.compareTo(a.id);
        });

        if (openDocs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text("No matching open jobs", style: AppTextStyle.sectionHeader),
                  const SizedBox(height: 8),
                  Text(
                    "Jobs in the open pool are filtered strictly based on your enabled skills. New requests matching your skill categories will appear here in real-time.",
                    textAlign: TextAlign.center,
                    style: AppTextStyle.subtitle,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: openDocs.length,
          itemBuilder: (context, index) {
            final doc = openDocs[index];
            final data = doc.data();
            return _buildJobCard(doc.id, data, isClaimable: true);
          },
        );
      },
    );
  }

  void _showOpenJobDetailsModal(String bookingId, Map<String, dynamic> data) {
    final title = data['title'] ?? (data['categoryName'] != null ? "${data['categoryName']} • ${data['subCategoryName'] ?? 'General'}" : 'Appliance Repair Service');
    final cost = data['cost'] ?? '₹499';
    final address = data['address'] ?? data['fullAddress'] ?? 'Hassan, Karnataka';
    final dateTime = data['dateTime'] ?? data['date'] ?? 'Scheduled Visit';
    final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
    final customerPhone = data['userPhone'] ?? data['phone'] ?? 'N/A';

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
                    child: Text(
                      title,
                      style: AppTextStyle.mainTitle.copyWith(fontSize: 18),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      cost,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Text(
                  "STATUS: OPEN UNASSIGNED POOL",
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
              const Divider(height: 24),
              _buildDetailRow(Icons.schedule_rounded, "Scheduled Slot", dateTime),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.location_on_outlined, "Service Address", address),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.person_outline_rounded, "Customer Name", customerName),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.phone_iphone_rounded, "Contact Number", customerPhone),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    String techName = "Technician Partner";
                    String techPhone = "+91 9876543210";
                    try {
                      final doc = await FirebaseFirestore.instance.collection('providers').doc(widget.techId).get();
                      if (doc.exists && doc.data() != null) {
                        techName = doc.data()?['name'] as String? ?? techName;
                        techPhone = doc.data()?['phone'] as String? ?? techPhone;
                      }
                    } catch (_) {}

                    final success = await _firestoreService.claimJob(
                      bookingId,
                      widget.techId,
                      techName,
                      techPhone,
                    );
                    if (mounted) {
                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Job claimed successfully! Opening job dashboard..."),
                            backgroundColor: AppColors.success,
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => JobDetailScreen(
                              bookingId: bookingId,
                              techId: widget.techId,
                            ),
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Sorry, this job was already claimed by another technician!"),
                            backgroundColor: Colors.orange,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
                  label: const Text("CLAIM THIS JOB NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(value, style: AppTextStyle.cardTitle.copyWith(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildJobCard(String bookingId, Map<String, dynamic> data, {required bool isClaimable}) {
    final title = data['title'] ?? (data['categoryName'] != null ? "${data['categoryName']} • ${data['subCategoryName'] ?? 'General'}" : 'Appliance Repair Service');
    final cost = data['cost'] ?? (data['visitingFee'] != null ? "₹${data['visitingFee']}" : '₹199');
    final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
    final address = data['address'] ?? data['fullAddress'] ?? 'Hassan, Karnataka';
    final date = data['dateTime'] ?? data['date'] ?? 'Scheduled Slot';
    final status = (data['status'] ?? 'pending').toString();

    final techStatus = TechBookingStatus.parse(status);
    final Color statusColor = techStatus.color;
    final String displayStatusLabel = techStatus.label;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        onTap: () {
          if (isClaimable) {
            _showOpenJobDetailsModal(bookingId, data);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => JobDetailScreen(
                  bookingId: bookingId,
                  techId: widget.techId,
                ),
              ),
            );
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyle.cardTitle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    status.toUpperCase().replaceAll('_', ' '),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.subtitle),
                    const SizedBox(width: 6),
                    Text(customerName, style: AppTextStyle.subtitle.copyWith(fontWeight: FontWeight.bold, color: AppColors.title)),
                  ],
                ),
                Text(
                  cost,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.subtitle),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    address,
                    style: AppTextStyle.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.schedule_rounded, size: 16, color: AppColors.subtitle),
                const SizedBox(width: 6),
                Text(date, style: AppTextStyle.subtitle),
              ],
            ),
            const SizedBox(height: 16),

            if (isClaimable)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showOpenJobDetailsModal(bookingId, data),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                      ),
                      child: const Text("View Details", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        String tName = "Technician Partner";
                        String tPhone = "+91 9876543210";
                        try {
                          final doc = await FirebaseFirestore.instance.collection('providers').doc(widget.techId).get();
                          if (doc.exists && doc.data() != null) {
                            tName = doc.data()?['name'] as String? ?? tName;
                            tPhone = doc.data()?['phone'] as String? ?? tPhone;
                          }
                        } catch (_) {}

                        final success = await _firestoreService.claimJob(
                          bookingId,
                          widget.techId,
                          tName,
                          tPhone,
                        );
                        if (mounted) {
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Job claimed successfully! Check your Assigned Jobs."),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => JobDetailScreen(
                                  bookingId: bookingId,
                                  techId: widget.techId,
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Sorry, this job was already claimed by another technician!"),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.add_task_rounded, color: Colors.white, size: 18),
                      label: const Text("Claim Job", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                      ),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JobDetailScreen(
                          bookingId: bookingId,
                          techId: widget.techId,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.navigation_rounded, color: AppColors.primary, size: 18),
                  label: const Text("Open Job & Start Service", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
