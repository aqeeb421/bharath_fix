// lib/screens/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../screens/login_screen.dart';
import '../screens/tabs/dashboard_tab.dart';
import '../screens/tabs/bookings_tab.dart';
import '../screens/tabs/users_tab.dart';
import '../screens/tabs/providers_tab.dart';
import '../screens/tabs/catalog_tab.dart';
import '../screens/tabs/payouts_tab.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedTabIndex = 0;
  final FirebaseService _service = FirebaseService();

  final List<Map<String, dynamic>> _navigationItems = [
    {'title': 'Dashboard', 'icon': Icons.space_dashboard_rounded, 'widget': const DashboardTab()},
    {'title': 'Bookings', 'icon': Icons.assignment_rounded, 'widget': const BookingsTab()},
    {'title': 'Clients', 'icon': Icons.people_alt_rounded, 'widget': const UsersTab()},
    {'title': 'Providers', 'icon': Icons.business_center_rounded, 'widget': const ProvidersTab()},
    {'title': 'Catalog', 'icon': Icons.collections_bookmark_rounded, 'widget': const CatalogTab()},
    {'title': 'Payouts', 'icon': Icons.account_balance_wallet_rounded, 'widget': const PayoutsTab()},
  ];

  Future<void> _handleLogout() async {
    await _service.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0C20),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF000062),
              elevation: 0,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/app_icon.jpg', width: 28, height: 28, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _navigationItems[_selectedTabIndex]['title'],
                    style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent()) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 270,
              decoration: const BoxDecoration(
                color: Color(0xFF000062),
                border: Border(right: BorderSide(color: Color(0xFF1A1A80), width: 1.5)),
              ),
              child: _buildSidebarContent(),
            ),
          
          Expanded(
            child: SafeArea(
              child: Container(
                color: const Color(0xFFF7F8FA),
                child: _navigationItems[_selectedTabIndex]['widget'],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarContent() {
    return Container(
      color: const Color(0xFF000062),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Header with Live Dot
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset('assets/images/app_icon.jpg', width: 36, height: 36, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BHARATHFIX',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF00E676),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Live Operations',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),

          // Nav Items
          Expanded(
            child: ListView.builder(
              itemCount: _navigationItems.length,
              itemBuilder: (context, index) {
                final item = _navigationItems[index];
                final isSelected = _selectedTabIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? const Color(0xFF000062) : Colors.white.withValues(alpha: 0.64),
                            size: 20,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['title'],
                              style: GoogleFonts.plusJakartaSans(
                                color: isSelected ? const Color(0xFF000062) : Colors.white.withValues(alpha: 0.75),
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (item['title'] == 'Bookings')
                            StreamBuilder<QuerySnapshot>(
                              stream: FirebaseFirestore.instance
                                  .collection('bookings')
                                  .where('status', isEqualTo: 'pending')
                                  .snapshots(),
                              builder: (context, snapshot) {
                                final count = snapshot.hasData ? snapshot.data!.docs.length : 0;
                                if (count == 0) return const SizedBox();
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? const Color(0xFF000062) : Colors.amber,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Colors.black,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Logout button
          InkWell(
            onTap: _handleLogout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded, color: Color(0xFFFF8A80), size: 20),
                  const SizedBox(width: 14),
                  Text(
                    'Log Out',
                    style: GoogleFonts.plusJakartaSans(
                      color: const Color(0xFFFF8A80),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
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
}
