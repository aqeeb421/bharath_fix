import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/technician_order_model.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../../theme/app_text_style.dart';
import '../../widgets/technician_state_widgets.dart';
import '../order_delivery_detail_screen.dart';

class DeliveriesTab extends StatefulWidget {
  final String techId;

  const DeliveriesTab({super.key, required this.techId});

  @override
  State<DeliveriesTab> createState() => _DeliveriesTabState();
}

class _DeliveriesTabState extends State<DeliveriesTab> {
  String _filterStatus = 'all'; // 'all', 'pending', 'completed'

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchMaps(String address) async {
    final Uri queryUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}',
    );
    if (await canLaunchUrl(queryUri)) {
      await launchUrl(queryUri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.medium,
            vertical: AppSpacing.small,
          ),
          child: Row(
            children: [
              _buildFilterChip('All Deliveries', 'all'),
              const SizedBox(width: 8),
              _buildFilterChip('Active / Out for Delivery', 'pending'),
              const SizedBox(width: 8),
              _buildFilterChip('Delivered', 'completed'),
            ],
          ),
        ),

        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('orders')
                .where('deliveryPartnerId', isEqualTo: widget.techId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const TechLoadingStateWidget(message: 'Loading assigned deliveries...');
              }

              if (snapshot.hasError) {
                return TechErrorStateWidget(
                  title: 'Deliveries Sync Error',
                  errorMessage: snapshot.error.toString(),
                );
              }

              final docs = snapshot.data?.docs ?? [];
              List<TechnicianOrderModel> orders = docs
                  .map((doc) => TechnicianOrderModel.fromFirestore(doc))
                  .toList();

              // Sort newest first
              orders.sort((a, b) {
                final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
                final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
                return bTime.compareTo(aTime);
              });

              // Apply Filter
              if (_filterStatus == 'pending') {
                orders = orders
                    .where((o) => o.orderStatus != 'delivered' && o.orderStatus != 'cancelled')
                    .toList();
              } else if (_filterStatus == 'completed') {
                orders = orders.where((o) => o.orderStatus == 'delivered').toList();
              }

              if (orders.isEmpty) {
                return TechEmptyStateWidget(
                  title: _filterStatus == 'completed'
                      ? 'No Delivered Orders Yet'
                      : 'No Pending Deliveries',
                  message: _filterStatus == 'completed'
                      ? 'Completed appliance deliveries will appear here.'
                      : 'You have no assigned appliance delivery tasks at the moment.',
                  icon: Icons.local_shipping_rounded,
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.medium),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return _buildDeliveryCard(order);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return InkWell(
      onTap: () => setState(() => _filterStatus = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.title,
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryCard(TechnicianOrderModel order) {
    Color statusColor = Colors.orange.shade800;
    Color statusBg = Colors.orange.shade50;
    String statusLabel = 'ASSIGNED';

    if (order.orderStatus.contains('out')) {
      statusColor = Colors.indigo.shade800;
      statusBg = Colors.indigo.shade50;
      statusLabel = 'OUT FOR DELIVERY';
    } else if (order.orderStatus == 'delivered') {
      statusColor = Colors.green.shade800;
      statusBg = Colors.green.shade50;
      statusLabel = 'DELIVERED';
    } else if (order.orderStatus == 'cancelled') {
      statusColor = Colors.red.shade800;
      statusBg = Colors.red.shade50;
      statusLabel = 'CANCELLED';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.large),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDeliveryDetailScreen(order: order),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.medium),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Status & ID
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.id}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 18),

              // Product Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    child: Image.network(
                      order.productImage.isNotEmpty
                          ? order.productImage
                          : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56,
                        height: 56,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.inventory_2_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.productName,
                          style: AppTextStyle.cardTitle.copyWith(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Qty: ${order.quantity} • Total: ₹${order.totalPaid.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bundled Installation Tag
              if (order.requiresInstallation)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.handyman_rounded, size: 13, color: Colors.blue.shade800),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'Bundled Installation Required on Delivery',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              // Customer & Address
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.subtitle),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.userName,
                            style: AppTextStyle.subtitle.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.title,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (order.userPhone.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _makePhoneCall(order.userPhone),
                    ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 16, color: AppColors.subtitle),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order.deliveryAddress.isNotEmpty
                          ? order.deliveryAddress
                          : 'Hassan, Karnataka',
                      style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (order.deliveryAddress.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.directions_rounded, color: Colors.green, size: 20),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(4),
                      onPressed: () => _launchMaps(order.deliveryAddress),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Action Button
              SizedBox(
                width: double.infinity,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDeliveryDetailScreen(order: order),
                      ),
                    );
                  },
                  icon: Icon(
                    order.orderStatus == 'delivered'
                        ? Icons.check_circle_outline_rounded
                        : Icons.local_shipping_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  label: Text(
                    order.orderStatus == 'delivered'
                        ? 'View Completed Delivery Details'
                        : (order.orderStatus.contains('out')
                            ? 'Verify Customer OTP & Handover'
                            : 'Open Delivery & Navigate'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: order.orderStatus == 'delivered'
                        ? Colors.grey.shade700
                        : AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
