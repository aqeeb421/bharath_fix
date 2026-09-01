import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/technician_firestore_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStreams();
  }

  void _initStreams() {
    _assignedJobsStream = _firestoreService.getAssignedJobsStream(widget.techId);
  }

  @override
  void didUpdateWidget(JobsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techId != widget.techId) {
      _initStreams();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
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
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: "Assigned Repairs"),
            Tab(text: "Deliveries & Setup"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignedJobsList(),
              _buildApplianceDeliveriesList(),
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
            message: 'New repairs and service orders will be assigned directly to you by the BharathFix Operations team.',
            icon: Icons.assignment_turned_in_rounded,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: activeDocs.length,
          itemBuilder: (context, index) {
            final doc = activeDocs[index];
            final data = doc.data();
            return _buildJobCard(doc.id, data);
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





  Widget _buildJobCard(String bookingId, Map<String, dynamic> data) {
    final title = data['title'] ?? (data['categoryName'] != null ? "${data['categoryName']} • ${data['subCategoryName'] ?? 'General'}" : 'Appliance Repair Service');
    final cost = data['cost'] ?? (data['visitingFee'] != null ? "₹${data['visitingFee']}" : '₹19');
    final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
    final address = data['address'] ?? data['fullAddress'] ?? 'Hassan, Karnataka';
    final date = data['dateTime'] ?? data['date'] ?? 'Scheduled Slot';
    final status = (data['status'] ?? 'pending').toString();

    final techStatus = TechBookingStatus.parse(status);
    final Color statusColor = techStatus.color;

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
                    color: statusColor.withValues(alpha: 0.12),
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
