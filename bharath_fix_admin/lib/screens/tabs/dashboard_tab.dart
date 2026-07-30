// lib/screens/tabs/dashboard_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseService = FirebaseService();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    'Real-time overview of the BharathFix service marketplace platform.',
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
                      Navigator.pop(context); // Close loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Database seeded successfully with clean, relevant images!')),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context); // Close loading indicator
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to seed database: $e')),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
          const SizedBox(height: 36),
          
          // Stats Row
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              final crossAxisCount = isDesktop ? 4 : 2;
              final childAspectRatio = isDesktop ? 1.6 : 1.3;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: childAspectRatio,
                children: [
                  _buildStatCardFromStream(
                    title: 'Total Bookings',
                    icon: Icons.assignment_rounded,
                    color: const Color(0xFF6C4CF1),
                    stream: firebaseService.getBookingsCombinedStream(),
                  ),
                  _buildStatCardFromStream(
                    title: 'Registered Clients',
                    icon: Icons.people_alt_rounded,
                    color: const Color(0xFF34A853),
                    stream: firebaseService.getUsersStream(),
                  ),
                  _buildStatCardFromStream(
                    title: 'Service Providers',
                    icon: Icons.business_center_rounded,
                    color: const Color(0xFFFF9900),
                    stream: firebaseService.getProvidersStream(),
                  ),
                  _buildRevenueCardFromStream(
                    title: 'Estimated Revenue',
                    icon: Icons.payments_rounded,
                    color: const Color(0xFF00C6FF),
                    stream: firebaseService.getBookingsCombinedStream(),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 48),

          // Platform Service guidelines
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEAEAEA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
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
                    const Icon(Icons.info_outline_rounded, color: Color(0xFF000062), size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Admin Console Guidelines',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF111111),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildBulletPoint('Bookings status changes are synced live to user application screens.'),
                _buildBulletPoint('Verify and toggle onboarding flags for newly registered Providers to allow them in the provider marketplace.'),
                _buildBulletPoint('Ensure correct JSON formats for subcategories lists in Categories documents to avoid parsing crashes on mobile frontends.'),
                _buildBulletPoint('Product pricing strings should retain currency formats (e.g. ₹6,999) matching application UI components.'),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCardFromStream({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<dynamic> stream,
  }) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          final data = snapshot.data;
          if (data is List) {
            value = data.length.toString();
          } else {
            value = (data as dynamic).docs.length.toString();
          }
        }
        return _buildCardLayout(title: title, value: value, icon: icon, color: color);
      },
    );
  }

  Widget _buildRevenueCardFromStream({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<dynamic> stream,
  }) {
    return StreamBuilder(
      stream: stream,
      builder: (context, snapshot) {
        String value = '₹0';
        if (snapshot.hasData) {
          final data = snapshot.data;
          final List docs = data is List ? data : (data as dynamic).docs;
          double total = 0;
          for (var doc in docs) {
            final docData = doc.data() as Map<String, dynamic>;
            final costStr = docData['cost'] as String? ?? '0';
            final cleanCost = costStr.replaceAll('₹', '').replaceAll(',', '').trim();
            total += double.tryParse(cleanCost) ?? 0;
          }
          value = '₹${total.toStringAsFixed(0)}';
        }
        return _buildCardLayout(title: title, value: value, icon: icon, color: color);
      },
    );
  }

  Widget _buildCardLayout({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAEAEA)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF757575),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
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
              fontSize: 28,
              fontWeight: FontWeight.bold,
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
