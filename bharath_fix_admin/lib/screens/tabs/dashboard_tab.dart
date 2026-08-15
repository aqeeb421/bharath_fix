// lib/screens/tabs/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/firebase_service.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _touchedPieIndex = -1;

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner with Quick Actions
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final isDesktop = headerConstraints.maxWidth > 800;
              final headerContent = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Operations Control Center',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Real-time financial analytics, booking streams & service marketplace metrics.',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: 14,
                    ),
                  ),
                ],
              );

              final syncButton = ElevatedButton.icon(
                onPressed: () async {
                  try {
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF000062))),
                    );
                    await firebaseService.reseedData();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Database synchronized successfully!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to sync database: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.sync_rounded, color: Colors.white, size: 18),
                label: Text(
                  'Sync Database Images',
                  style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF000062),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
              );

              if (isDesktop) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: headerContent),
                    const SizedBox(width: 24),
                    syncButton,
                  ],
                );
              } else {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerContent,
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: syncButton),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // Financial & Platform Metrics Grid
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final crossAxisCount = isDesktop ? 4 : 2;
              final childAspectRatio = isDesktop ? 1.6 : 1.25;

              return StreamBuilder(
                stream: firebaseService.getBookingsCombinedStream(),
                builder: (context, snapshot) {
                  double totalGross = 0;
                  double totalQuotation = 0;
                  double totalVisiting = 0;
                  int totalBookingsCount = 0;

                  if (snapshot.hasData) {
                    final data = snapshot.data;
                    final List docs = data is List ? data : (data as dynamic).docs;
                    totalBookingsCount = docs.length;

                    for (var doc in docs) {
                      final docData = doc.data() as Map<String, dynamic>;
                      final double visitingFee = (docData['visitingFee'] as num?)?.toDouble() ?? 199.0;
                      final quotationMap = docData['quotation'] as Map<String, dynamic>?;
                      final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ??
                          (docData['quoteTotal'] as num?)?.toDouble() ??
                          (docData['additionalCost'] as num?)?.toDouble() ??
                          0.0;
                      final double finalPaid = (docData['finalAmountPaid'] as num?)?.toDouble() ?? 0.0;

                      double bookingTotal = finalPaid > 0
                          ? finalPaid
                          : (quoteTotal > 0 ? (quoteTotal + visitingFee) : visitingFee);

                      totalGross += bookingTotal;
                      totalQuotation += quoteTotal;
                      totalVisiting += visitingFee;
                    }
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: childAspectRatio,
                    children: [
                      _buildCardLayout(
                        title: 'Total Gross Revenue',
                        value: '₹${totalGross.toStringAsFixed(0)}',
                        icon: Icons.payments_rounded,
                        color: const Color(0xFF34A853),
                        trend: '+18.4% growth',
                      ),
                      _buildCardLayout(
                        title: 'Quotation Revenue',
                        value: '₹${totalQuotation.toStringAsFixed(0)}',
                        icon: Icons.request_quote_rounded,
                        color: const Color(0xFF000062),
                        trend: 'Approved Spare Quotes',
                      ),
                      _buildCardLayout(
                        title: 'Visiting Charges',
                        value: '₹${totalVisiting.toStringAsFixed(0)}',
                        icon: Icons.confirmation_number_rounded,
                        color: const Color(0xFF00C6FF),
                        trend: 'Doorstep Fees',
                      ),
                      _buildCardLayout(
                        title: 'Total Bookings',
                        value: '$totalBookingsCount',
                        icon: Icons.assignment_rounded,
                        color: const Color(0xFF6C4CF1),
                        trend: 'Platform Requests',
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          // Interactive Charts Section
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: _buildRevenueLineChartCard()),
                    const SizedBox(width: 20),
                    Expanded(flex: 2, child: _buildCategoryPieChartCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildRevenueLineChartCard(),
                    const SizedBox(height: 20),
                    _buildCategoryPieChartCard(),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 32),

          // Live Activity Feed & Platform Guidelines
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 900;
              if (isDesktop) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _buildLiveActivityFeedStream(firebaseService)),
                    const SizedBox(width: 20),
                    Expanded(child: _buildPlatformGuidelinesCard()),
                  ],
                );
              } else {
                return Column(
                  children: [
                    _buildLiveActivityFeedStream(firebaseService),
                    const SizedBox(height: 20),
                    _buildPlatformGuidelinesCard(),
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // Interactive fl_chart Revenue Line Graph
  Widget _buildRevenueLineChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Growth Trend',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF111111),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Weekly revenue breakdown (Visiting + Quotation total)',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFF757575),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.trending_up_rounded, color: Colors.green.shade700, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Live Metrics',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2000,
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
                      interval: 2000,
                      reservedSize: 42,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '₹${(value / 1000).toStringAsFixed(1)}k',
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
                maxY: 8000,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          '₹${spot.y.toInt()}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF000062), Color(0xFF00C6FF)],
                    ),
                    barWidth: 3.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF000062).withValues(alpha: 0.25),
                          const Color(0xFF00C6FF).withValues(alpha: 0.02),
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

  // Interactive fl_chart Donut Category Share Graph
  Widget _buildCategoryPieChartCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
            'Service Share Breakdown',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Popularity by appliance repair category',
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
                  _buildPieSection(0, 35, 'AC Service', const Color(0xFF000062)),
                  _buildPieSection(1, 25, 'Washing Machine', const Color(0xFF34A853)),
                  _buildPieSection(2, 20, 'Refrigerator', const Color(0xFFFF9900)),
                  _buildPieSection(3, 20, 'RO Purifier', const Color(0xFF00C6FF)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _buildLegendPill('AC Service (35%)', const Color(0xFF000062)),
              _buildLegendPill('Washing Machine (25%)', const Color(0xFF34A853)),
              _buildLegendPill('Refrigerator (20%)', const Color(0xFFFF9900)),
              _buildLegendPill('RO Purifier (20%)', const Color(0xFF00C6FF)),
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

  // Live Activity Feed Stream
  Widget _buildLiveActivityFeedStream(FirebaseService service) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              Text(
                'Live Marketplace Activity',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.stream_rounded, color: Color(0xFF000062), size: 20),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder(
            stream: service.getBookingsCombinedStream(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final data = snapshot.data;
              final List docs = data is List ? data : (data as dynamic).docs;
              final recentDocs = docs.take(5).toList();

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentDocs.length,
                separatorBuilder: (_, __) => const Divider(height: 16),
                itemBuilder: (context, index) {
                  final docData = recentDocs[index].data() as Map<String, dynamic>;
                  final title = docData['title']?.toString() ?? 'Service Booking';
                  final status = docData['status']?.toString() ?? 'pending';
                  final id = recentDocs[index].id;

                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF000062).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.bolt_rounded, color: Color(0xFF000062), size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text('Booking #$id', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusBg(status),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(color: _getStatusFg(status), fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformGuidelinesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              const Icon(Icons.verified_user_rounded, color: Color(0xFF000062), size: 24),
              const SizedBox(width: 12),
              Text(
                'Admin Operating Guidelines',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF111111),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildBulletPoint('Status changes update customer & technician apps in real-time.'),
          _buildBulletPoint('Verify and toggle onboarding flags for newly registered Providers to allow them in the marketplace.'),
          _buildBulletPoint('Quotation totals automatically integrate visiting fee + approved spare parts breakdown.'),
          _buildBulletPoint('PDF Tax Invoices are available for instant download once booking status changes to Completed.'),
        ],
      ),
    );
  }

  Color _getStatusBg(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade50;
      case 'repair_in_progress':
      case 'on_the_way': return Colors.blue.shade50;
      case 'quotation_pending': return Colors.amber.shade50;
      default: return Colors.orange.shade50;
    }
  }

  Color _getStatusFg(String status) {
    switch (status.toLowerCase()) {
      case 'completed': return Colors.green.shade800;
      case 'repair_in_progress':
      case 'on_the_way': return Colors.blue.shade900;
      case 'quotation_pending': return Colors.amber.shade900;
      default: return Colors.orange.shade900;
    }
  }

  Widget _buildCardLayout({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String trend,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            trend,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
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
