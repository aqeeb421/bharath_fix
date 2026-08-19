// lib/screens/tabs/orders_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/admin_order_model.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  String _searchQuery = "";
  AdminOrderStatus? _selectedStatusFilter;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading orders: ${snapshot.error}',
              style: GoogleFonts.plusJakartaSans(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final allOrders = docs.map((doc) => AdminOrderModel.fromFirestore(doc)).toList();

        // Calculate statistics
        final double totalRevenue = allOrders.fold(0.0, (acc, o) => acc + o.totalPaid);
        final int unassignedCount = allOrders.where((o) => o.deliveryPartnerId == null || o.deliveryPartnerId!.isEmpty).length;
        final int activeCount = allOrders.where((o) => o.orderStatus != AdminOrderStatus.delivered && o.orderStatus != AdminOrderStatus.cancelled).length;
        final int deliveredCount = allOrders.where((o) => o.orderStatus == AdminOrderStatus.delivered).length;

        // Apply filters & search query
        final filteredOrders = allOrders.where((o) {
          if (_selectedStatusFilter != null && o.orderStatus != _selectedStatusFilter) {
            return false;
          }
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            final matchesId = o.id.toLowerCase().contains(query);
            final matchesCustomer = o.userName.toLowerCase().contains(query) || o.userPhone.contains(query);
            final matchesProduct = o.productName.toLowerCase().contains(query);
            final matchesAddress = o.deliveryAddress.toLowerCase().contains(query);
            return matchesId || matchesCustomer || matchesProduct || matchesAddress;
          }
          return true;
        }).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Title (Responsive)
                    LayoutBuilder(builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      final headerText = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Orders & Agent Dispatch',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: isMobile ? 20 : 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000062),
                            ),
                          ),
                          Text(
                            'Manage appliance sales, dispatch status, and assign delivery & installation agents.',
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      );

                      final refreshBtn = ElevatedButton.icon(
                        onPressed: () => setState(() {}),
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('Refresh Live Pool', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000062),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerText,
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: refreshBtn),
                          ],
                        );
                      }

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: headerText),
                          const SizedBox(width: 16),
                          refreshBtn,
                        ],
                      );
                    }),
                    const SizedBox(height: 16),

                    // Stat Cards Overview (Horizontal scroll on mobile, Wrap on desktop)
                    LayoutBuilder(builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      if (isMobile) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: Row(
                            children: [
                              _buildStatCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.green, width: 170),
                              const SizedBox(width: 12),
                              _buildStatCard('Active Orders', '$activeCount', Icons.local_shipping_rounded, Colors.blue, width: 150),
                              const SizedBox(width: 12),
                              _buildStatCard('Awaiting Agent', '$unassignedCount', Icons.person_add_rounded, Colors.orange, width: 150),
                              const SizedBox(width: 12),
                              _buildStatCard('Completed', '$deliveredCount', Icons.check_circle_rounded, Colors.teal, width: 150),
                            ],
                          ),
                        );
                      }
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildStatCard('Total Revenue', '₹${totalRevenue.toStringAsFixed(0)}', Icons.monetization_on_rounded, Colors.green, width: 220),
                          _buildStatCard('Active Orders', '$activeCount', Icons.local_shipping_rounded, Colors.blue, width: 220),
                          _buildStatCard('Awaiting Agent', '$unassignedCount', Icons.person_add_rounded, Colors.orange, width: 220),
                          _buildStatCard('Completed Deliveries', '$deliveredCount', Icons.check_circle_rounded, Colors.teal, width: 220),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),

                    // Search & Filter Toolbar (Responsive)
                    LayoutBuilder(builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 700;
                      final searchField = TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search Order ID, Customer, Phone, Product...',
                          hintStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[400]),
                          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF000062)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      );

                      final filterDropdown = Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<AdminOrderStatus?>(
                            value: _selectedStatusFilter,
                            hint: Text('Filter by Status', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600)),
                            items: [
                              DropdownMenuItem<AdminOrderStatus?>(
                                value: null,
                                child: Text('All Statuses', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold)),
                              ),
                              ...AdminOrderStatus.values.map((st) {
                                return DropdownMenuItem<AdminOrderStatus?>(
                                  value: st,
                                  child: Text(st.toDisplayString(), style: GoogleFonts.plusJakartaSans(fontSize: 13)),
                                );
                              }),
                            ],
                            onChanged: (val) => setState(() => _selectedStatusFilter = val),
                          ),
                        ),
                      );

                      if (isMobile) {
                        return Column(
                          children: [
                            searchField,
                            const SizedBox(height: 12),
                            SizedBox(width: double.infinity, child: filterDropdown),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: searchField),
                          const SizedBox(width: 16),
                          filterDropdown,
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Orders List Sliver
              if (filteredOrders.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No product orders found matching search criteria',
                            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final order = filteredOrders[index];
                      return _buildOrderCard(context, order);
                    },
                    childCount: filteredOrders.length,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: const Color(0xFF000062)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, AdminOrderModel order) {
    final statusStr = order.orderStatus.toDisplayString();
    Color statusColor = Colors.orange.shade800;
    Color statusBg = Colors.orange.shade50;

    if (order.orderStatus == AdminOrderStatus.shipped) {
      statusColor = Colors.blue.shade800;
      statusBg = Colors.blue.shade50;
    } else if (order.orderStatus == AdminOrderStatus.outForDelivery) {
      statusColor = Colors.indigo.shade800;
      statusBg = Colors.indigo.shade50;
    } else if (order.orderStatus == AdminOrderStatus.delivered) {
      statusColor = Colors.green.shade800;
      statusBg = Colors.green.shade50;
    } else if (order.orderStatus == AdminOrderStatus.cancelled) {
      statusColor = Colors.red.shade800;
      statusBg = Colors.red.shade50;
    }

    final bool isAssigned = order.deliveryPartnerName != null && order.deliveryPartnerName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        final productImageWidget = ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.network(
            order.productImage.isNotEmpty
                ? order.productImage
                : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              width: 70,
              height: 70,
              color: Colors.grey[200],
              child: const Icon(Icons.inventory_2_rounded, color: Colors.grey),
            ),
          ),
        );

        final productInfoWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              order.productName,
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: const Color(0xFF000062),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unit Price: ₹${order.price.toStringAsFixed(0)} | Quantity: ${order.quantity}',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.vpn_key_rounded, size: 14, color: Colors.green[700]),
                const SizedBox(width: 4),
                Text(
                  'Delivery OTP: ${order.deliveryOtp}',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ],
        );

        final customerInfoWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Info',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              order.userName.isNotEmpty ? order.userName : 'Customer',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            if (order.userPhone.isNotEmpty)
              Text(order.userPhone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Text(
              order.deliveryAddress,
              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        final agentActionWidget = Column(
          crossAxisAlignment: isMobile ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (isAssigned) ...[
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF000062).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF000062).withOpacity(0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircleAvatar(
                      radius: 12,
                      backgroundColor: Color(0xFF000062),
                      child: Icon(Icons.person_rounded, size: 14, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery & Setup Agent',
                          style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[600]),
                        ),
                        Text(
                          order.deliveryPartnerName!,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Row(
              mainAxisAlignment: isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
              children: [
                // Assign / Re-assign Button
                ElevatedButton.icon(
                  onPressed: () => _showAssignPartnerModal(context, order),
                  icon: Icon(isAssigned ? Icons.swap_horiz_rounded : Icons.person_add_alt_1_rounded, size: 16),
                  label: Text(
                    isAssigned ? 'Reassign Agent' : 'Assign Agent / Tech',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAssigned ? Colors.grey[800] : const Color(0xFF000062),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),

                // Advance Order Status Menu
                PopupMenuButton<AdminOrderStatus>(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: const Icon(Icons.more_vert_rounded, color: Color(0xFF000062), size: 18),
                  ),
                  onSelected: (newStatus) => _updateOrderStatus(context, order, newStatus),
                  itemBuilder: (context) {
                    return AdminOrderStatus.values.map((st) {
                      return PopupMenuItem<AdminOrderStatus>(
                        value: st,
                        child: Text('Mark as ${st.toDisplayString()}', style: GoogleFonts.plusJakartaSans(fontSize: 12)),
                      );
                    }).toList();
                  },
                ),
              ],
            ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Card Header Row
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF000062).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#${order.id}',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: const Color(0xFF000062),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    'Total Paid: ₹${order.totalPaid.toStringAsFixed(0)} (${order.paymentMode})',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: const Color(0xFF000062),
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Order Details & Customer Body
            if (isMobile) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productImageWidget,
                  const SizedBox(width: 12),
                  Expanded(child: productInfoWidget),
                ],
              ),
              const SizedBox(height: 14),
              customerInfoWidget,
              const SizedBox(height: 14),
              agentActionWidget,
            ] else ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  productImageWidget,
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: productInfoWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: customerInfoWidget),
                  const SizedBox(width: 16),
                  Expanded(flex: 3, child: agentActionWidget),
                ],
              ),
            ],
          ],
        );
      }),
    );
  }

  void _showAssignPartnerModal(BuildContext context, AdminOrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assign Agent for Delivery & Installation',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF000062),
                        ),
                      ),
                      Text(
                        'Order #${order.id} • ${order.productName}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),

              Text(
                'Available Technicians & Delivery Partners',
                style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey[700]),
              ),
              const SizedBox(height: 10),

              // Stream of Technicians / Partners from `users` collection
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
                    }

                    final userDocs = snapshot.data?.docs ?? [];
                    // Filter technicians or partners who can deliver
                    final partners = userDocs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>? ?? {};
                      final role = (data['role'] as String? ?? '').toLowerCase();
                      final canDeliver = data['canDeliver'] == true || data['isDeliveryPartner'] == true;
                      return role.contains('technician') || role.contains('partner') || role.contains('provider') || canDeliver;
                    }).toList();

                    if (partners.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.engineering_outlined, size: 44, color: Colors.grey[400]),
                            const SizedBox(height: 10),
                            Text(
                              'No active technicians or delivery partners found.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: partners.length,
                      itemBuilder: (context, index) {
                        final pDoc = partners[index];
                        final pData = pDoc.data() as Map<String, dynamic>? ?? {};
                        final pId = pDoc.id;
                        final pName = pData['name'] as String? ?? pData['fullName'] as String? ?? 'Technician Agent';
                        final pPhone = pData['phone'] as String? ?? pData['phoneNumber'] as String? ?? '';
                        final pRole = pData['role'] as String? ?? 'Technician';
                        final canDeliver = pData['canDeliver'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey[200]!),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: const Color(0xFF000062),
                                child: Text(
                                  pName.isNotEmpty ? pName[0].toUpperCase() : 'T',
                                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(pName, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14)),
                                        if (canDeliver) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green.shade50,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Can Deliver & Install',
                                              style: GoogleFonts.plusJakartaSans(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text('$pRole • $pPhone', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              ElevatedButton(
                                onPressed: () => _assignPartnerToOrder(context, order, pId, pName, pPhone),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF000062),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: Text('Assign Agent', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _assignPartnerToOrder(
    BuildContext context,
    AdminOrderModel order,
    String partnerId,
    String partnerName,
    String partnerPhone,
  ) async {
    try {
      final now = FieldValue.serverTimestamp();

      // Update root `orders` document
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'deliveryPartnerId': partnerId,
        'deliveryPartnerName': partnerName,
        'deliveryPartnerPhone': partnerPhone,
        'assignedByAdmin': true,
        'assignedAt': now,
        'orderStatus': AdminOrderStatus.shipped.name,
      });

      // Update user subcollection `users/{userId}/orders/{orderId}` if present
      if (order.userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .collection('orders')
            .doc(order.id)
            .set({
          'deliveryPartnerId': partnerId,
          'deliveryPartnerName': partnerName,
          'deliveryPartnerPhone': partnerPhone,
          'assignedByAdmin': true,
          'assignedAt': now,
          'orderStatus': AdminOrderStatus.shipped.name,
        }, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .collection('notifications')
            .add({
          'title': 'Order Dispatched 🚚',
          'body': 'Your order #${order.id} (${order.productName}) has been assigned to $partnerName for delivery & installation.',
          'type': 'ORDER_UPDATE',
          'orderId': order.id,
          'isRead': false,
          'createdAt': now,
        });
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully assigned $partnerName to Order #${order.id}!'),
            backgroundColor: Colors.green.shade800,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to assign partner: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateOrderStatus(BuildContext context, AdminOrderModel order, AdminOrderStatus newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(order.id).update({
        'orderStatus': newStatus.name,
      });

      if (order.userId.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .collection('orders')
            .doc(order.id)
            .set({'orderStatus': newStatus.name}, SetOptions(merge: true));

        await FirebaseFirestore.instance
            .collection('users')
            .doc(order.userId)
            .collection('notifications')
            .add({
          'title': 'Order Update: ${newStatus.toDisplayString()}',
          'body': 'Your order #${order.id} (${order.productName}) is now ${newStatus.toDisplayString()}.',
          'type': 'ORDER_UPDATE',
          'orderId': order.id,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order #${order.id} marked as ${newStatus.toDisplayString()}'),
            backgroundColor: const Color(0xFF000062),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
