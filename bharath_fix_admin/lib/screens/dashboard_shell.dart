// lib/screens/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
      backgroundColor: const Color(0xFF0F0C20), // Premium Dark space background
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF000062),
              elevation: 0,
              title: Text(
                _navigationItems[_selectedTabIndex]['title'],
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent()) : null,
      body: Row(
        children: [
          if (isDesktop)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: Color(0xFF000062), // Royal Blue desktop drawer
                border: Border(right: BorderSide(color: Color(0xFF1A1A80), width: 1.5)),
              ),
              child: _buildSidebarContent(),
            ),
          
          Expanded(
            child: SafeArea(
              child: Container(
                color: const Color(0xFFF7F8FA), // Light background for main contents
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
          // Logo Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.handyman_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'BharathFix Console',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

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
                        Navigator.pop(context); // Close mobile drawer if open
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'],
                            color: isSelected ? const Color(0xFF000062) : Colors.white.withOpacity(0.64),
                            size: 20,
                          ),
                          const SizedBox(width: 16),
                          Text(
                            item['title'],
                            style: GoogleFonts.plusJakartaSans(
                              color: isSelected ? const Color(0xFF000062) : Colors.white.withOpacity(0.64),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
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
                  const SizedBox(width: 16),
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
