import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  StreamSubscription? _bookingsSub;
  StreamSubscription? _ordersSub;

  List<Map<String, dynamic>> _completedRepairs = [];
  List<Map<String, dynamic>> _completedDeliveries = [];
  bool _isLoading = true;
  String _filter = 'all'; // 'all', 'repairs', 'deliveries', 'cod'

  @override
  void initState() {
    super.initState();
    _initStreams();
  }

  void _initStreams() {
    _bookingsSub?.cancel();
    _ordersSub?.cancel();

    // 1. Stream completed repair bookings
    _bookingsSub = FirebaseFirestore.instance
        .collection('bookings')
        .where('technicianId', isEqualTo: widget.techId)
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((d) => {...d.data(), 'id': d.id, '_type': 'repair'})
          .where((data) {
        final s = (data['status'] ?? '').toString().toLowerCase().trim();
        return s == 'completed' || s == 'work_completed' || s == 'paid_and_closed';
      }).toList();

      if (mounted) {
        setState(() {
          _completedRepairs = list;
          _isLoading = false;
        });
      }
    });

    // 2. Stream completed product orders (retail deliveries)
    _ordersSub = FirebaseFirestore.instance
        .collection('orders')
        .where('deliveryPartnerId', isEqualTo: widget.techId)
        .snapshots()
        .listen((snap) {
      final list = snap.docs
          .map((d) => {...d.data(), 'id': d.id, '_type': 'delivery'})
          .where((data) {
        final s = (data['orderStatus'] ?? '').toString().toLowerCase().trim();
        return s == 'delivered';
      }).toList();

      if (mounted) {
        setState(() {
          _completedDeliveries = list;
          _isLoading = false;
        });
      }
    });
  }

  @override
  void didUpdateWidget(EarningsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.techId != widget.techId) {
      _initStreams();
    }
  }

  @override
  void dispose() {
    _bookingsSub?.cancel();
    _ordersSub?.cancel();
    super.dispose();
  }

  double _toDouble(dynamic val, [double defaultVal = 0.0]) {
    if (val == null) return defaultVal;
    if (val is num) return val.toDouble();
    if (val is String) {
      final clean = val.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(clean) ?? defaultVal;
    }
    return defaultVal;
  }

  double _getRepairEarnings(Map<String, dynamic> data) {
    double base = 0.0;
    if (data['amount'] != null) {
      base = _toDouble(data['amount']);
    } else if (data['totalAmount'] != null) {
      base = _toDouble(data['totalAmount']);
    } else if (data['cost'] != null) {
      base = _toDouble(data['cost']);
    } else if (data['visitingFee'] != null) {
      base = _toDouble(data['visitingFee']);
    } else {
      base = 199.0;
    }

    final addCost = _toDouble(data['additionalCost']);
    double quoteTotal = 0.0;
    if (data['quotation'] is Map) {
      quoteTotal = _toDouble(data['quotation']['totalAmount']);
    }

    return base + addCost + quoteTotal;
  }

  double _getDeliveryEarnings(Map<String, dynamic> data) {
    // Base dispatch incentive: ₹150
    double payout = 150.0;
    final bool requiresInstall = (data['isInstallationRequired'] ?? data['requiresInstallation']) != false;
    if (requiresInstall) {
      payout += 200.0; // ₹200 bundled setup fee
    }
    return payout;
  }

  double _getRepairCodCash(Map<String, dynamic> data) {
    final mode = (data['paymentMode'] ?? '').toString().toUpperCase();
    if (mode == 'COD' || mode == 'CASH') {
      return _getRepairEarnings(data);
    }
    double cod = 0.0;
    if (data['isVisitingFeePaid'] == false && data['visitingFee'] != null) {
      cod += _toDouble(data['visitingFee']);
    }
    return cod;
  }

  double _getDeliveryCodCash(Map<String, dynamic> data) {
    final mode = (data['paymentMode'] ?? '').toString().toUpperCase();
    if (mode == 'COD') {
      return _toDouble(data['totalPaid'] ?? data['finalAmountPaid']);
    }
    return 0.0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    // Compute aggregate figures
    double totalRepairEarnings = 0.0;
    double totalRepairCod = 0.0;
    for (final r in _completedRepairs) {
      totalRepairEarnings += _getRepairEarnings(r);
      totalRepairCod += _getRepairCodCash(r);
    }

    double totalDeliveryEarnings = 0.0;
    double totalDeliveryCod = 0.0;
    for (final d in _completedDeliveries) {
      totalDeliveryEarnings += _getDeliveryEarnings(d);
      totalDeliveryCod += _getDeliveryCodCash(d);
    }

    final double totalNetEarnings = totalRepairEarnings + totalDeliveryEarnings;
    final double totalCashInHand = totalRepairCod + totalDeliveryCod;
    final double netSettlement = totalNetEarnings - totalCashInHand;
    final bool adminOwesTech = netSettlement >= 0;

    // Filter list
    List<Map<String, dynamic>> displayItems = [];
    if (_filter == 'all') {
      displayItems = [..._completedRepairs, ..._completedDeliveries];
    } else if (_filter == 'repairs') {
      displayItems = _completedRepairs;
    } else if (_filter == 'deliveries') {
      displayItems = _completedDeliveries;
    } else if (_filter == 'cod') {
      displayItems = [
        ..._completedRepairs.where((r) => _getRepairCodCash(r) > 0),
        ..._completedDeliveries.where((d) => _getDeliveryCodCash(d) > 0),
      ];
    }

    // Sort by timestamp desc
    displayItems.sort((a, b) {
      final aDate = (a['completedAt'] ?? a['deliveredAt'] ?? a['createdAt']) as Timestamp?;
      final bDate = (b['completedAt'] ?? b['deliveredAt'] ?? b['createdAt']) as Timestamp?;
      if (aDate == null || bDate == null) return 0;
      return bDate.compareTo(aDate);
    });

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.medium),
      children: [
        // Total Net Earnings Banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(AppRadius.large),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Earned Payouts",
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                "₹${totalNetEarnings.toStringAsFixed(0)}",
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
                  _buildStatPill(
                    icon: Icons.handyman_rounded,
                    label: "Repairs Payout",
                    value: "₹${totalRepairEarnings.toStringAsFixed(0)}",
                    count: "${_completedRepairs.length} jobs",
                  ),
                  _buildStatPill(
                    icon: Icons.local_shipping_rounded,
                    label: "Deliveries Payout",
                    value: "₹${totalDeliveryEarnings.toStringAsFixed(0)}",
                    count: "${_completedDeliveries.length} orders",
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Cash In Hand & Settlement Card
        Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: Border.all(
              color: adminOwesTech ? Colors.green.shade200 : Colors.amber.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_rounded,
                        color: Colors.amber.shade800,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Cash In Hand (COD Collected)",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "₹${totalCashInHand.toStringAsFixed(0)}",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    adminOwesTech ? Icons.account_balance_rounded : Icons.info_outline_rounded,
                    color: adminOwesTech ? AppColors.success : Colors.orange.shade800,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminOwesTech
                              ? "Net Direct Bank Transfer Due: ₹${netSettlement.abs().toStringAsFixed(0)}"
                              : "Cash Settlement Due to Admin: ₹${netSettlement.abs().toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: adminOwesTech ? AppColors.success : Colors.orange.shade900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          adminOwesTech
                              ? "Admin transfers remaining payout directly to your bank account."
                              : "Collected COD cash exceeds commission. Deposit cash with Admin office.",
                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Activity Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterChip('All Activities', 'all', _completedRepairs.length + _completedDeliveries.length),
              const SizedBox(width: 8),
              _buildFilterChip('Repairs', 'repairs', _completedRepairs.length),
              const SizedBox(width: 8),
              _buildFilterChip('Deliveries', 'deliveries', _completedDeliveries.length),
              const SizedBox(width: 8),
              _buildFilterChip('Cash Collected', 'cod', null),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Transactions List Header
        Text("Payout & Settlement Ledger", style: AppTextStyle.sectionHeader),
        const SizedBox(height: 10),

        if (displayItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.history_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text("No transactions found for this filter", style: AppTextStyle.subtitle),
              ],
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              final bool isRepair = item['_type'] == 'repair';
              final String title = isRepair
                  ? (item['title'] ?? item['categoryName'] ?? item['applianceType'] ?? 'Appliance Repair')
                  : (item['productName'] ?? 'Appliance Delivery & Setup');
              final String customer = item['userName'] ?? item['customerName'] ?? 'Customer';
              final double earned = isRepair ? _getRepairEarnings(item) : _getDeliveryEarnings(item);
              final double codCash = isRepair ? _getRepairCodCash(item) : _getDeliveryCodCash(item);

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.small),
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isRepair
                            ? AppColors.primary.withValues(alpha: 0.1)
                            : Colors.blue.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isRepair ? Icons.handyman_rounded : Icons.local_shipping_rounded,
                        color: isRepair ? AppColors.primary : Colors.blue.shade700,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTextStyle.cardTitle.copyWith(fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Customer: $customer",
                            style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                          ),
                          if (codCash > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              "💵 Collected ₹${codCash.toStringAsFixed(0)} Cash (COD)",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.amber.shade900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "+ ₹${earned.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppColors.success,
                          ),
                        ),
                        Text(
                          isRepair ? "Service Payout" : "Delivery Payout",
                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String label,
    required String value,
    required String count,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          Text(count, style: const TextStyle(fontSize: 10, color: Colors.white60)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, int? count) {
    final isSelected = _filter == value;
    return InkWell(
      onTap: () => setState(() => _filter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          count != null ? "$label ($count)" : label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.title,
          ),
        ),
      ),
    );
  }
}
