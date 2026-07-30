import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/technician_firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../job_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
            Tab(text: "Assigned Jobs"),
            Tab(text: "Available Open Pool"),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAssignedJobsList(),
              _buildOpenPoolJobsList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAssignedJobsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestoreService.getAssignedJobsStream(widget.techId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];
        final activeDocs = docs.where((doc) => doc.data()['status'] != 'completed' && doc.data()['status'] != 'cancelled').toList();

        if (activeDocs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text("No active assigned jobs", style: AppTextStyle.sectionHeader),
                const SizedBox(height: 4),
                Text("Check the Available Open Pool to claim new requests.", style: AppTextStyle.subtitle),
              ],
            ),
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
      stream: _firestoreService.getAvailableOpenJobsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off_rounded, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text("No open jobs available", style: AppTextStyle.sectionHeader),
                const SizedBox(height: 4),
                Text("New service requests will appear here in real-time.", style: AppTextStyle.subtitle),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
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
                    await _firestoreService.claimJob(
                      bookingId,
                      widget.techId,
                      "Technician Partner",
                      "+91 9876543210",
                    );
                    if (mounted) {
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
    final cost = data['cost'] ?? '₹499';
    final customerName = data['userName'] ?? data['customerName'] ?? 'Customer';
    final address = data['address'] ?? data['fullAddress'] ?? 'Hassan, Karnataka';
    final date = data['dateTime'] ?? data['date'] ?? 'Scheduled Slot';
    final status = data['status'] ?? 'pending';

    Color statusColor = AppColors.primary;
    if (status == 'pending') statusColor = Colors.amber.shade800;
    if (status == 'accepted') statusColor = Colors.blue;
    if (status == 'in_progress') statusColor = Colors.orange;
    if (status == 'completed') statusColor = Colors.green;

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
                        await _firestoreService.claimJob(
                          bookingId,
                          widget.techId,
                          "Technician Partner",
                          "+91 9876543210",
                        );
                        if (mounted) {
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
