import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/technician_firestore_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';

class EarningsTab extends StatefulWidget {
  final String techId;

  const EarningsTab({super.key, required this.techId});

  @override
  State<EarningsTab> createState() => _EarningsTabState();
}

class _EarningsTabState extends State<EarningsTab> {
  final _firestoreService = TechnicianFirestoreService();
  late Stream<QuerySnapshot<Map<String, dynamic>>> _earningsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    _earningsStream = _firestoreService.getCompletedJobsStream(widget.techId);
  }

  @override
  void didUpdateWidget(EarningsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techId != widget.techId) {
      _initStream();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _earningsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final allDocs = snapshot.data?.docs ?? [];
        final docs = allDocs.where((doc) {
          final status = (doc.data()['status'] ?? '').toString().toLowerCase().trim();
          return status == 'completed' || status == 'paid_and_closed';
        }).toList();

        double totalEarnings = 0.0;

        for (var doc in docs) {
          final data = doc.data();
          final amount = (data['amount'] as num?)?.toDouble() ??
              (data['totalAmount'] as num?)?.toDouble() ??
              (data['cost'] as num?)?.toDouble() ??
              499.0;
          final addCost = (data['additionalCost'] as num?)?.toDouble() ?? 0.0;
          totalEarnings += (amount + addCost);
        }

        return ListView(
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: [
            // Earnings Summary Banner Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.large),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Total Net Earnings",
                    style: AppTextStyle.subtitle.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "₹${totalEarnings.toStringAsFixed(2)}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat("Completed Jobs", "${docs.length}"),
                      _buildMiniStat("Payout Status", "Weekly Direct"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text("Completed Service Visits", style: AppTextStyle.sectionHeader),
            const SizedBox(height: 12),

            if (docs.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    const Icon(Icons.history_rounded, size: 48, color: Colors.grey),
                    const SizedBox(height: 12),
                    Text("No completed jobs yet", style: AppTextStyle.subtitle),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data();
                  final category = data['title'] ??
                      data['categoryName'] ??
                      data['applianceType'] ??
                      'Appliance Repair';
                  final customer = data['userName'] ?? data['customerName'] ?? 'Customer';
                  final basePrice = (data['amount'] as num?)?.toDouble() ??
                      (data['totalAmount'] as num?)?.toDouble() ??
                      499.0;
                  final extraPrice = (data['additionalCost'] as num?)?.toDouble() ?? 0.0;
                  final totalJobVal = basePrice + extraPrice;

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.small),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category, style: AppTextStyle.cardTitle),
                            const SizedBox(height: 4),
                            Text("Customer: $customer", style: AppTextStyle.subtitle),
                          ],
                        ),
                        Text(
                          "+ ₹${totalJobVal.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
