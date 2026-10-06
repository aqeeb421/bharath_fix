import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/technician_firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../../models/technician_booking_lifecycle.dart';
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

class _JobsTabState extends State<JobsTab> {
  final _firestoreService = TechnicianFirestoreService();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _assignedJobsStream;

  @override
  void initState() {
    super.initState();
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
  Widget build(BuildContext context) {
    return _buildAssignedJobsList();
  }

  Widget _buildAssignedJobsList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _assignedJobsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Error loading jobs: ${snapshot.error}",
              style: AppTextStyle.subtitle,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  "No repair jobs assigned yet",
                  style: AppTextStyle.cardTitle,
                ),
                const SizedBox(height: 6),
                Text(
                  "New customer repair requests will appear here.",
                  style: AppTextStyle.subtitle,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.medium),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return _buildJobCard(doc.id, doc.data());
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
