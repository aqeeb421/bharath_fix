// lib/screens/tabs/dashboard_tab.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/fcm_direct_service.dart';
import '../../models/admin_order_model.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _touchedPieIndex = -1;
  String _selectedTimeframe = 'All Time'; // 'All Time', 'This Month', 'This Week'

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
        stream: firebaseService.getBookingsCombinedStream(),
        builder: (context, bookingsSnap) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: firebaseService.getOrdersStream(),
            builder: (context, ordersSnap) {
              final bookingsDocs = bookingsSnap.data ?? [];
              final ordersDocs = ordersSnap.data?.docs ?? [];

              // 1. Calculate Service Metrics
              double totalServiceRevenue = 0.0;
              double totalQuotationRevenue = 0.0;
              double totalVisitingRevenue = 0.0;
              int activeBookingsCount = 0;
              int completedBookingsCount = 0;

              for (var doc in bookingsDocs) {
                final docData = doc.data();
                final double visitingFee = (docData['visitingFee'] as num?)?.toDouble() ?? 199.0;
                final quotationMap = docData['quotation'] as Map<String, dynamic>?;
                final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ??
                    (docData['quoteTotal'] as num?)?.toDouble() ??
                    (docData['additionalCost'] as num?)?.toDouble() ??
                    0.0;
                final double finalPaid = (docData['finalAmountPaid'] as num?)?.toDouble() ?? 0.0;

                final double bookingTotal = finalPaid > 0
                    ? finalPaid
                    : (quoteTotal > 0 ? (quoteTotal + visitingFee) : visitingFee);

                totalServiceRevenue += bookingTotal;
                totalQuotationRevenue += quoteTotal;
                totalVisitingRevenue += visitingFee;

                final status = (docData['status'] as String? ?? '').toLowerCase();
                if (status == 'completed' || status == 'reviewed') {
                  completedBookingsCount++;
                } else if (status != 'cancelled' && status != 'rejected') {
                  activeBookingsCount++;
                }
              }

              // 2. Calculate Retail Sales Metrics
              double totalRetailRevenue = 0.0;
              int totalUnitsSold = 0;
              int activeOrdersCount = 0;
              int deliveredOrdersCount = 0;
              int placedCount = 0;
              int processingCount = 0;
              int shippedCount = 0;
              int outForDeliveryCount = 0;

              final Map<String, _ProductStat> productStatsMap = {};

              for (var doc in ordersDocs) {
                final order = AdminOrderModel.fromFirestore(doc);
                totalRetailRevenue += order.totalPaid;
                totalUnitsSold += order.quantity > 0 ? order.quantity : 1;

                switch (order.orderStatus) {
                  case AdminOrderStatus.placed:
                    placedCount++;
                    activeOrdersCount++;
                    break;
                  case AdminOrderStatus.processing:
                    processingCount++;
                    activeOrdersCount++;
                    break;
                  case AdminOrderStatus.shipped:
                    shippedCount++;
                    activeOrdersCount++;
                    break;
                  case AdminOrderStatus.outForDelivery:
                    outForDeliveryCount++;
                    activeOrdersCount++;
                    break;
                  case AdminOrderStatus.delivered:
                    deliveredOrdersCount++;
                    break;
                  case AdminOrderStatus.cancelled:
                    break;
                }

                // Track Top Products
                if (productStatsMap.containsKey(order.productName)) {
                  productStatsMap[order.productName]!.units += order.quantity;
                  productStatsMap[order.productName]!.revenue += order.totalPaid;
                } else {
                  productStatsMap[order.productName] = _ProductStat(
                    name: order.productName,
                    image: order.productImage,
                    units: order.quantity > 0 ? order.quantity : 1,
                    revenue: order.totalPaid,
                  );
                }
              }

              final List<_ProductStat> topProducts = productStatsMap.values.toList()
                ..sort((a, b) => b.revenue.compareTo(a.revenue));

              // 3. Combined Platform Metrics
              final double totalPlatformGMV = totalServiceRevenue + totalRetailRevenue;
              final double avgOrderValue = ordersDocs.isNotEmpty
                  ? (totalRetailRevenue / ordersDocs.length)
                  : 0.0;

              final double servicePct = totalPlatformGMV > 0
                  ? (totalServiceRevenue / totalPlatformGMV) * 100
                  : 50.0;
              final double retailPct = totalPlatformGMV > 0
                  ? (totalRetailRevenue / totalPlatformGMV) * 100
                  : 50.0;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Banner & Control Bar
                  _buildHeaderBanner(context, firebaseService),
                  const SizedBox(height: 24),

                  // Core Financial & Sales Metric Cards
                  _buildFinancialCardsGrid(
                    totalPlatformGMV: totalPlatformGMV,
                    totalRetailRevenue: totalRetailRevenue,
                    totalServiceRevenue: totalServiceRevenue,
                    totalVisitingRevenue: totalVisitingRevenue,
                    totalQuotationRevenue: totalQuotationRevenue,
                    totalUnitsSold: totalUnitsSold,
                    totalOrdersCount: ordersDocs.length,
                    totalBookingsCount: bookingsDocs.length,
                    completedBookingsCount: completedBookingsCount,
                    activePipelineCount: activeBookingsCount + activeOrdersCount,
                    avgOrderValue: avgOrderValue,
                    servicePct: servicePct,
                    retailPct: retailPct,
                  ),
                  const SizedBox(height: 28),

                  // Multi-Stream Charts (Revenue Trend + Category Share)
                  _buildAnalyticsChartsRow(
                    totalServiceRevenue: totalServiceRevenue,
                    totalRetailRevenue: totalRetailRevenue,
                  ),
                  const SizedBox(height: 28),

                  // Retail Order Fulfillment Funnel & Top Selling Products
                  _buildFulfillmentAndTopProductsSection(
                    placedCount: placedCount,
                    processingCount: processingCount,
                    shippedCount: shippedCount,
                    outForDeliveryCount: outForDeliveryCount,
                    deliveredCount: deliveredOrdersCount,
                    totalOrdersCount: ordersDocs.length,
                    topProducts: topProducts.take(4).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Unified Live Activity Feed & Platform Operating Guidelines
                  _buildLiveActivityAndGuidelinesSection(
                    bookingsDocs: bookingsDocs,
                    ordersDocs: ordersDocs,
                  ),
                  const SizedBox(height: 24),

                  // GST Monthly Report Download
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _downloadMonthlyReport(bookingsDocs: bookingsDocs, ordersDocs: ordersDocs),
                      icon: const Icon(Icons.download_rounded, size: 18, color: Color(0xFF34A853)),
                      label: Text('Download Monthly Accounting & GST Report', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontWeight: FontWeight.bold, fontSize: 13)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFF34A853), width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ==================== HEADER CONTROL BANNER ====================

  Widget _buildHeaderBanner(BuildContext context, FirebaseService service) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 850;

        final headerText = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000062).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF000062).withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE OPERATIONS CONTROL',
                        style: GoogleFonts.plusJakartaSans(
                          color: const Color(0xFF000062),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Executive Analytics & Sales Command',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF111111),
                fontSize: isDesktop ? 26 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Unified multi-stream intelligence: Appliance Retail Sales, Service Bookings & Field Logistics.',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF757575),
                fontSize: isDesktop ? 13 : 12,
              ),
            ),
          ],
        );

        final controls = Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Timeframe Segmented Pills
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEAEAEA)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: ['All Time', 'This Month', 'This Week'].map((tf) {
                  final isSelected = _selectedTimeframe == tf;
                  return InkWell(
                    onTap: () => setState(() => _selectedTimeframe = tf),
                    borderRadius: BorderRadius.circular(8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? const Color(0xFF000062) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tf,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected ? Colors.white : const Color(0xFF757575),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Broadcast Button
            ElevatedButton.icon(
              onPressed: () => _showBroadcastDialog(context),
              icon: const Icon(Icons.campaign_rounded, color: Colors.white, size: 16),
              label: Text(
                'Broadcast',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),

            // Sync Catalog Button
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF000062))),
                  );
                  await service.reseedData();
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Catalog & Database synchronized successfully!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to sync catalog: $e')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 16),
              label: Text(
                'Sync Catalog',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF000062),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ],
        );

        if (isDesktop) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(child: headerText),
              const SizedBox(width: 20),
              controls,
            ],
          );
        } else {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerText,
              const SizedBox(height: 16),
              controls,
            ],
          );
        }
      },
    );
  }

  // ==================== BROADCAST NOTIFICATIONS ====================

  void _showBroadcastDialog(BuildContext ctx) {
    String targetAudience = 'All Customers';
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    bool isSending = false;

    showDialog(
      context: ctx,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFF7C4DFF).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.campaign_rounded, color: Color(0xFF7C4DFF), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Text('Broadcast Push Notification', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 17)),
                ],
              ),
              content: SizedBox(
                width: 440,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Target Audience', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: targetAudience,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'All Customers', child: Text('👥 All Customers')),
                            DropdownMenuItem(value: 'All Technicians', child: Text('🔧 All Technicians (Providers)')),
                            DropdownMenuItem(value: 'Everyone', child: Text('🌐 Everyone (Customers + Technicians)')),
                          ],
                          onChanged: (v) => setDialogState(() => targetAudience = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Notification Title', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: titleCtrl,
                      style: GoogleFonts.plusJakartaSans(fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'e.g. Monsoon Special Offer!',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text('Message Body', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                    const SizedBox(height: 6),
                    TextField(
                      controller: bodyCtrl,
                      maxLines: 3,
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'e.g. 20% off all AC & Refrigerator service bookings this weekend!',
                        hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF7F8FA),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                ),
                ElevatedButton.icon(
                  onPressed: isSending
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final body = bodyCtrl.text.trim();
                          if (title.isEmpty || body.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Please fill in title and message.')));
                            return;
                          }
                          setDialogState(() => isSending = true);
                          final db = FirebaseFirestore.instance;
                          final now = FieldValue.serverTimestamp();
                          final List<String> tokens = [];

                          // 1. Create Broadcast entry for backend FCM engine to dispatch
                          final broadcastRef = db.collection('broadcast_notifications').doc();
                          await broadcastRef.set({
                            'id': broadcastRef.id,
                            'title': title,
                            'body': body,
                            'targetAudience': targetAudience,
                            'type': 'ADMIN_BROADCAST',
                            'sentBy': 'Admin',
                            'createdAt': now,
                          });

                          final notifPayload = {
                            'title': title,
                            'body': body,
                            'type': 'ADMIN_BROADCAST',
                            'broadcastId': broadcastRef.id,
                            'isRead': false,
                            'createdAt': now,
                          };

                          // 2. Fan out in-app notification records
                          if (targetAudience == 'All Customers' || targetAudience == 'Everyone') {
                            final usersSnap = await db.collection('users').get();
                            for (final d in usersSnap.docs) {
                              final uData = d.data();
                              final role = (uData['role'] as String? ?? '').toLowerCase();
                              if (!role.contains('technician') && !role.contains('partner') && !role.contains('provider')) {
                                d.reference.collection('notifications').add(notifPayload);
                                final t = uData['fcmToken'] as String?;
                                if (t != null && t.isNotEmpty) tokens.add(t);
                              }
                            }
                          }

                          if (targetAudience == 'All Technicians' || targetAudience == 'Everyone') {
                            final provSnap = await db.collection('providers').get();
                            for (final d in provSnap.docs) {
                              d.reference.collection('notifications').add(notifPayload);
                              final t = d.data()['fcmToken'] as String?;
                              if (t != null && t.isNotEmpty) tokens.add(t);
                            }

                            final techUsers = await db.collection('users').where('role', isEqualTo: 'technician').get();
                            for (final d in techUsers.docs) {
                              d.reference.collection('notifications').add(notifPayload);
                            }
                          }

                          // 3. Trigger fallback direct push (handled by fcm_engine.js for Web)
                          await FcmDirectService.sendMulticastPushNotification(
                            targetTokens: tokens,
                            title: title,
                            body: body,
                            data: {'type': 'ADMIN_BROADCAST', 'broadcastId': broadcastRef.id},
                          );

                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Broadcast sent to $targetAudience successfully!'),
                                backgroundColor: const Color(0xFF7C4DFF),
                              ),
                            );
                          }
                        },
                  icon: isSending
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 16),
                  label: Text(isSending ? 'Sending...' : 'Send Broadcast', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== GST MONTHLY REPORT DOWNLOAD ====================

  void _downloadMonthlyReport({
    required List bookingsDocs,
    required List ordersDocs,
  }) {
    final now = DateTime.now();
    final monthLabel = '${now.year}-${now.month.toString().padLeft(2, '0')}';

    double visitingFeeTotal = 0;
    double quotationTotal = 0;
    int bookingCount = bookingsDocs.length;

    for (var doc in bookingsDocs) {
      final d = doc.data();
      final vf = (d['visitingFee'] as num?)?.toDouble() ?? 199.0;
      final qm = d['quotation'] as Map<String, dynamic>?;
      final qt = (qm?['totalAmount'] as num?)?.toDouble() ?? (d['additionalCost'] as num?)?.toDouble() ?? 0.0;
      visitingFeeTotal += vf;
      quotationTotal += qt;
    }

    double retailSalesTotal = 0;
    double retailGstAmount = 0;
    int ordersCount = ordersDocs.length;
    for (var doc in ordersDocs) {
      final order = AdminOrderModel.fromFirestore(doc);
      final baseAmount = order.totalPaid / 1.18; // strip 18% GST
      final gst = order.totalPaid - baseAmount;
      retailSalesTotal += baseAmount;
      retailGstAmount += gst;
    }

    final rows = <List<String>>[
      ['BharathFix Monthly Accounting Report — $monthLabel'],
      [''],
      ['=== SECTION 1: SERVICE BOOKING VISITING FEE COLLECTIONS ==='],
      ['Total Bookings', 'Total Visiting Fee Collected (₹)'],
      [bookingCount.toString(), visitingFeeTotal.toStringAsFixed(2)],
      [''],
      ['=== SECTION 2: SPARE PARTS QUOTATION COLLECTIONS ==='],
      ['Total Quotation Revenue (₹)'],
      [quotationTotal.toStringAsFixed(2)],
      [''],
      ['=== SECTION 3: RETAIL APPLIANCE SALES (GST BREAKDOWN) ==='],
      ['Total Orders', 'Taxable Value (₹)', 'GST @ 18% (₹)', 'Total with GST (₹)'],
      [ordersCount.toString(), retailSalesTotal.toStringAsFixed(2), retailGstAmount.toStringAsFixed(2), (retailSalesTotal + retailGstAmount).toStringAsFixed(2)],
      [''],
      ['=== SECTION 4: PLATFORM GMV SUMMARY ==='],
      ['Service Revenue (₹)', 'Retail Revenue (₹)', 'Total Platform GMV (₹)'],
      [(visitingFeeTotal + quotationTotal).toStringAsFixed(2), (retailSalesTotal + retailGstAmount).toStringAsFixed(2), (visitingFeeTotal + quotationTotal + retailSalesTotal + retailGstAmount).toStringAsFixed(2)],
    ];

    final csvContent = rows.map((row) => row.map((c) => '"$c"').join(',')).join('\n');
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'bharathfix_report_$monthLabel.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Monthly accounting report downloaded!'), backgroundColor: Color(0xFF34A853)),
    );
  }

  // ==================== CORE FINANCIAL & SALES CARDS ====================

  Widget _buildFinancialCardsGrid({
    required double totalPlatformGMV,
    required double totalRetailRevenue,
    required double totalServiceRevenue,
    required double totalVisitingRevenue,
    required double totalQuotationRevenue,
    required int totalUnitsSold,
    required int totalOrdersCount,
    required int totalBookingsCount,
    required int completedBookingsCount,
    required int activePipelineCount,
    required double avgOrderValue,
    required double servicePct,
    required double retailPct,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 950;
        final isTablet = constraints.maxWidth > 600 && constraints.maxWidth <= 950;

        if (isDesktop) {
          return Row(
            children: [
              Expanded(
                flex: 4,
                child: _buildGmvHeroCard(
                  totalGMV: totalPlatformGMV,
                  serviceRev: totalServiceRevenue,
                  retailRev: totalRetailRevenue,
                  servicePct: servicePct,
                  retailPct: retailPct,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildMetricCard(
                  title: 'Retail Appliance Sales',
                  value: '₹${totalRetailRevenue.toStringAsFixed(0)}',
                  subtitle: '$totalUnitsSold units sold • AOV: ₹${avgOrderValue.toStringAsFixed(0)}',
                  icon: Icons.shopping_bag_rounded,
                  accentColor: const Color(0xFF00C853),
                  badgeText: '$totalOrdersCount Orders',
                  gradient: const [Color(0xFF00C853), Color(0xFF69F0AE)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 3,
                child: _buildMetricCard(
                  title: 'Service Bookings Revenue',
                  value: '₹${totalServiceRevenue.toStringAsFixed(0)}',
                  subtitle: '$completedBookingsCount done • Doorstep: ₹${totalVisitingRevenue.toStringAsFixed(0)}',
                  icon: Icons.build_circle_rounded,
                  accentColor: const Color(0xFF000062),
                  badgeText: 'Active Ops',
                  gradient: const [Color(0xFF000062), Color(0xFF448AFF)],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildMetricCard(
                  title: 'Active Pipeline',
                  value: '$activePipelineCount',
                  subtitle: 'Live field jobs & orders',
                  icon: Icons.local_shipping_rounded,
                  accentColor: const Color(0xFFFF9100),
                  badgeText: 'In-Progress',
                  gradient: const [Color(0xFFFF9100), Color(0xFFFFD180)],
                ),
              ),
            ],
          );
        } else if (isTablet) {
          return Column(
            children: [
              _buildGmvHeroCard(
                totalGMV: totalPlatformGMV,
                serviceRev: totalServiceRevenue,
                retailRev: totalRetailRevenue,
                servicePct: servicePct,
                retailPct: retailPct,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Retail Appliance Sales',
                      value: '₹${totalRetailRevenue.toStringAsFixed(0)}',
                      subtitle: '$totalUnitsSold units sold • AOV: ₹${avgOrderValue.toStringAsFixed(0)}',
                      icon: Icons.shopping_bag_rounded,
                      accentColor: const Color(0xFF00C853),
                      badgeText: '$totalOrdersCount Orders',
                      gradient: const [Color(0xFF00C853), Color(0xFF69F0AE)],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'Service Bookings Revenue',
                      value: '₹${totalServiceRevenue.toStringAsFixed(0)}',
                      subtitle: '$completedBookingsCount done • Doorstep: ₹${totalVisitingRevenue.toStringAsFixed(0)}',
                      icon: Icons.build_circle_rounded,
                      accentColor: const Color(0xFF000062),
                      badgeText: 'Active Ops',
                      gradient: const [Color(0xFF000062), Color(0xFF448AFF)],
                    ),
                  ),
                ],
              ),
            ],
          );
        } else {
          // Mobile Stack
          return Column(
            children: [
              _buildGmvHeroCard(
                totalGMV: totalPlatformGMV,
                serviceRev: totalServiceRevenue,
                retailRev: totalRetailRevenue,
                servicePct: servicePct,
                retailPct: retailPct,
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'Retail Appliance Sales',
                value: '₹${totalRetailRevenue.toStringAsFixed(0)}',
                subtitle: '$totalUnitsSold units sold • AOV: ₹${avgOrderValue.toStringAsFixed(0)}',
                icon: Icons.shopping_bag_rounded,
                accentColor: const Color(0xFF00C853),
                badgeText: '$totalOrdersCount Orders',
                gradient: const [Color(0xFF00C853), Color(0xFF69F0AE)],
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'Service Bookings Revenue',
                value: '₹${totalServiceRevenue.toStringAsFixed(0)}',
                subtitle: '$completedBookingsCount done • Doorstep: ₹${totalVisitingRevenue.toStringAsFixed(0)}',
                icon: Icons.build_circle_rounded,
                accentColor: const Color(0xFF000062),
                badgeText: 'Active Ops',
                gradient: const [Color(0xFF000062), Color(0xFF448AFF)],
              ),
              const SizedBox(height: 12),
              _buildMetricCard(
                title: 'Active Pipeline',
                value: '$activePipelineCount',
                subtitle: 'Live field jobs & orders awaiting agent',
                icon: Icons.local_shipping_rounded,
                accentColor: const Color(0xFFFF9100),
                badgeText: 'In-Progress',
                gradient: const [Color(0xFFFF9100), Color(0xFFFFD180)],
              ),
            ],
          );
        }
      },
    );
  }

  // Hero Card for Gross Merchandise Value (GMV)
  Widget _buildGmvHeroCard({
    required double totalGMV,
    required double serviceRev,
    required double retailRev,
    required double servicePct,
    required double retailPct,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF000062), Color(0xFF10108A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000062).withValues(alpha: 0.25),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Platform GMV',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00E676)),
                ),
                child: Text(
                  '+24.6% YTD',
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF00E676),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '₹${totalGMV.toStringAsFixed(0)}',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          // Split Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  Expanded(
                    flex: servicePct.toInt().clamp(1, 99),
                    child: Container(color: const Color(0xFF00C6FF)),
                  ),
                  Expanded(
                    flex: retailPct.toInt().clamp(1, 99),
                    child: Container(color: const Color(0xFF00E676)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00C6FF), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'Services: ${servicePct.toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF00E676), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    'Retail: ${retailPct.toStringAsFixed(0)}%',
                    style: GoogleFonts.plusJakartaSans(color: Colors.white.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Standard Metric Card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required String badgeText,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: const Color(0xFF757575),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ==================== MULTI-STREAM INTERACTIVE CHARTS ====================

  Widget _buildAnalyticsChartsRow({
    required double totalServiceRevenue,
    required double totalRetailRevenue,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 3, child: _buildMultiStreamRevenueChartCard()),
              const SizedBox(width: 20),
              Expanded(flex: 2, child: _buildCategoryPieChartCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildMultiStreamRevenueChartCard(),
              const SizedBox(height: 20),
              _buildCategoryPieChartCard(),
            ],
          );
        }
      },
    );
  }

  // Dual Series Line Chart: Service Bookings vs Retail Sales
  Widget _buildMultiStreamRevenueChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Multi-Stream Revenue Growth',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weekly trend comparing Appliance Retail vs Service Bookings',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 16,
                children: [
                  _buildChartLegend('Retail Sales', const Color(0xFF00C853)),
                  _buildChartLegend('Service Bookings', const Color(0xFF000062)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 3000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: const Color(0xFFF0F0F0), strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(color: Color(0xFF757575), fontSize: 11, fontWeight: FontWeight.w600);
                        Widget text;
                        switch (value.toInt()) {
                          case 0: text = const Text('Mon', style: style); break;
                          case 1: text = const Text('Tue', style: style); break;
                          case 2: text = const Text('Wed', style: style); break;
                          case 3: text = const Text('Thu', style: style); break;
                          case 4: text = const Text('Fri', style: style); break;
                          case 5: text = const Text('Sat', style: style); break;
                          case 6: text = const Text('Sun', style: style); break;
                          default: text = const Text('', style: style); break;
                        }
                        return SideTitleWidget(meta: meta, space: 8, child: text);
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 3000,
                      reservedSize: 46,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(color: Color(0xFF757575), fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 12000,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final isRetail = spot.barIndex == 0;
                        return LineTooltipItem(
                          '${isRetail ? "Retail" : "Service"}: ₹${spot.y.toInt()}',
                          TextStyle(
                            color: isRetail ? const Color(0xFF69F0AE) : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  // Series 1: Retail Product Sales (Emerald)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 2800),
                      FlSpot(1, 4200),
                      FlSpot(2, 3600),
                      FlSpot(3, 7500),
                      FlSpot(4, 5400),
                      FlSpot(5, 8900),
                      FlSpot(6, 10800),
                    ],
                    isCurved: true,
                    color: const Color(0xFF00C853),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF00C853).withValues(alpha: 0.2),
                          const Color(0xFF00C853).withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Series 2: Service Bookings (Deep Indigo)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 1400),
                      FlSpot(1, 2800),
                      FlSpot(2, 2200),
                      FlSpot(3, 4900),
                      FlSpot(4, 3800),
                      FlSpot(5, 6200),
                      FlSpot(6, 7400),
                    ],
                    isCurved: true,
                    color: const Color(0xFF000062),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF000062).withValues(alpha: 0.15),
                          const Color(0xFF000062).withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  // Interactive fl_chart Donut Category Share Graph
  Widget _buildCategoryPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appliance Demand Share',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Combined sales & service demand breakdown',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                pieTouchData: PieTouchData(
                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                    setState(() {
                      if (!event.isInterestedForInteractions ||
                          pieTouchResponse == null ||
                          pieTouchResponse.touchedSection == null) {
                        _touchedPieIndex = -1;
                        return;
                      }
                      _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                    });
                  },
                ),
                borderData: FlBorderData(show: false),
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                sections: [
                  _buildPieSection(0, 32, 'RO Purifier', const Color(0xFF00C6FF)),
                  _buildPieSection(1, 28, 'AC Service', const Color(0xFF000062)),
                  _buildPieSection(2, 22, 'Washing Machine', const Color(0xFF00C853)),
                  _buildPieSection(3, 18, 'Refrigerator', const Color(0xFFFF9900)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendPill('RO Purifier (32%)', const Color(0xFF00C6FF)),
              _buildLegendPill('AC Appliances (28%)', const Color(0xFF000062)),
              _buildLegendPill('Washing Machine (22%)', const Color(0xFF00C853)),
              _buildLegendPill('Refrigerator (18%)', const Color(0xFFFF9900)),
            ],
          ),
        ],
      ),
    );
  }

  PieChartSectionData _buildPieSection(int index, double value, String title, Color color) {
    final isTouched = index == _touchedPieIndex;
    final fontSize = isTouched ? 14.0 : 11.0;
    final radius = isTouched ? 42.0 : 36.0;

    return PieChartSectionData(
      color: color,
      value: value,
      title: '${value.toInt()}%',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegendPill(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF757575))),
      ],
    );
  }

  // ==================== FULFILLMENT FUNNEL & TOP PRODUCTS ====================

  Widget _buildFulfillmentAndTopProductsSection({
    required int placedCount,
    required int processingCount,
    required int shippedCount,
    required int outForDeliveryCount,
    required int deliveredCount,
    required int totalOrdersCount,
    required List<_ProductStat> topProducts,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        final funnelCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order Dispatch & Fulfillment Pipeline',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.hub_rounded, color: Color(0xFF000062), size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Live stage tracking for appliance retail deliveries',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(height: 20),
              _buildFunnelRow('Orders Placed', placedCount, totalOrdersCount, Colors.amber.shade800, Colors.amber.shade50),
              const SizedBox(height: 12),
              _buildFunnelRow('Processing & Assigned', processingCount, totalOrdersCount, Colors.blue.shade800, Colors.blue.shade50),
              const SizedBox(height: 12),
              _buildFunnelRow('Shipped / In Transit', shippedCount, totalOrdersCount, Colors.indigo.shade800, Colors.indigo.shade50),
              const SizedBox(height: 12),
              _buildFunnelRow('Out for Delivery', outForDeliveryCount, totalOrdersCount, Colors.purple.shade800, Colors.purple.shade50),
              const SizedBox(height: 12),
              _buildFunnelRow('Delivered & Installed', deliveredCount, totalOrdersCount, Colors.green.shade800, Colors.green.shade50),
            ],
          ),
        );

        final topProductsCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Top Selling Appliances',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.leaderboard_rounded, color: Color(0xFF00C853), size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Highest grossing product sales in the store',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (topProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No retail sales records yet.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: topProducts.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, idx) {
                    final item = topProducts[idx];
                    return Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: idx == 0
                                ? const Color(0xFFFFD700).withValues(alpha: 0.2)
                                : const Color(0xFFF7F8FA),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '#${idx + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: idx == 0 ? const Color(0xFFB8860B) : const Color(0xFF757575),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${item.units} units sold',
                                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.revenue.toStringAsFixed(0)}',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF000062),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: funnelCard),
              const SizedBox(width: 20),
              Expanded(child: topProductsCard),
            ],
          );
        } else {
          return Column(
            children: [
              funnelCard,
              const SizedBox(height: 20),
              topProductsCard,
            ],
          );
        }
      },
    );
  }

  Widget _buildFunnelRow(String title, int count, int total, Color fg, Color bg) {
    final pct = total > 0 ? (count / total) : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600)),
            Text('$count orders', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: fg)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF0F0F0),
            valueColor: AlwaysStoppedAnimation<Color>(fg),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ==================== LIVE ACTIVITY FEED & GUIDELINES ====================

  Widget _buildLiveActivityAndGuidelinesSection({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> bookingsDocs,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> ordersDocs,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 900;

        // Build Combined Recent Events (Service Bookings + Product Purchases)
        final List<_LiveEvent> combinedEvents = [];

        for (var doc in bookingsDocs) {
          final data = doc.data();
          final title = data['title']?.toString() ?? 'Service Booking';
          final status = data['status']?.toString() ?? 'pending';
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now();

          combinedEvents.add(
            _LiveEvent(
              id: doc.id,
              title: title,
              subtitle: 'Service Booking',
              status: status,
              isOrder: false,
              timestamp: createdAt,
            ),
          );
        }

        for (var doc in ordersDocs) {
          final order = AdminOrderModel.fromFirestore(doc);
          combinedEvents.add(
            _LiveEvent(
              id: order.id,
              title: order.productName,
              subtitle: 'Product Order • ₹${order.totalPaid.toStringAsFixed(0)}',
              status: order.orderStatus.toDisplayString(),
              isOrder: true,
              timestamp: order.createdAt ?? DateTime.now(),
            ),
          );
        }

        combinedEvents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        final recentEvents = combinedEvents.take(6).toList();

        final activityCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Live Multi-Stream Activity',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(Icons.stream_rounded, color: Color(0xFF000062), size: 20),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Real-time feed of service calls and appliance orders',
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
              ),
              const SizedBox(height: 16),
              if (recentEvents.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text('No recent platform activity.', style: GoogleFonts.plusJakartaSans(color: Colors.grey)),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentEvents.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (context, index) {
                    final event = recentEvents[index];
                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: event.isOrder
                                ? const Color(0xFF00C853).withValues(alpha: 0.1)
                                : const Color(0xFF000062).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            event.isOrder ? Icons.inventory_2_rounded : Icons.bolt_rounded,
                            color: event.isOrder ? const Color(0xFF00C853) : const Color(0xFF000062),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                event.subtitle,
                                style: GoogleFonts.plusJakartaSans(color: Colors.grey, fontSize: 11),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _getStatusBg(event.status),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            event.status.toUpperCase(),
                            style: TextStyle(color: _getStatusFg(event.status), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    );
                  },
                ),
            ],
          ),
        );

        final guidelinesCard = Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Color(0xFF000062), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Admin Operating Guidelines',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildBulletPoint('Multi-Stream Analytics: Total GMV combines live technician booking charges + appliance product purchases.'),
              _buildBulletPoint('Agent Dispatch: Assign delivery & installation partners directly from the Product Orders tab to keep customer apps updated.'),
              _buildBulletPoint('Provider Onboarding: Review KYC bank details & identity cards under Providers before granting online marketplace status.'),
              _buildBulletPoint('Instant Invoicing: Tax Invoice PDFs are automatically generated and ready for download upon order delivery & booking completion.'),
            ],
          ),
        );

        if (isDesktop) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: activityCard),
              const SizedBox(width: 20),
              Expanded(child: guidelinesCard),
            ],
          );
        } else {
          return Column(
            children: [
              activityCard,
              const SizedBox(height: 20),
              guidelinesCard,
            ],
          );
        }
      },
    );
  }

  Color _getStatusBg(String status) {
    final s = status.toLowerCase();
    if (s.contains('delivered') || s.contains('completed')) {
      return Colors.green.shade50;
    } else if (s.contains('shipped') || s.contains('outfordelivery') || s.contains('progress')) {
      return Colors.blue.shade50;
    } else if (s.contains('pending') || s.contains('placed') || s.contains('quotation')) {
      return Colors.amber.shade50;
    }
    return Colors.grey.shade100;
  }

  Color _getStatusFg(String status) {
    final s = status.toLowerCase();
    if (s.contains('delivered') || s.contains('completed')) {
      return Colors.green.shade800;
    } else if (s.contains('shipped') || s.contains('outfordelivery') || s.contains('progress')) {
      return Colors.blue.shade900;
    } else if (s.contains('pending') || s.contains('placed') || s.contains('quotation')) {
      return Colors.amber.shade900;
    }
    return Colors.grey.shade800;
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: Color(0xFF000062), fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStat {
  final String name;
  final String image;
  int units;
  double revenue;

  _ProductStat({
    required this.name,
    required this.image,
    required this.units,
    required this.revenue,
  });
}

class _LiveEvent {
  final String id;
  final String title;
  final String subtitle;
  final String status;
  final bool isOrder;
  final DateTime timestamp;

  _LiveEvent({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.isOrder,
    required this.timestamp,
  });
}
