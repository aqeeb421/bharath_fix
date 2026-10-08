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
import '../screens/tabs/orders_tab.dart';

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
    {'title': 'Product Orders', 'icon': Icons.local_shipping_rounded, 'widget': const OrdersTab()},
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

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 950;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: !isDesktop
          ? AppBar(
              backgroundColor: const Color(0xFF000062),
              elevation: 0,
              centerTitle: false,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/images/app_icon.jpg', width: 28, height: 28, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _navigationItems[_selectedTabIndex]['title'],
                      style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              iconTheme: const IconThemeData(color: Colors.white),
              actions: [
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF00E676),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Live',
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Log Out',
                  icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirm Logout'),
                        content: const Text('Are you sure you want to sign out of the Admin Console?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(ctx, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF000062),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Log Out'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      _handleLogout();
                    }
                  },
                ),
              ],
            )
          : null,
      drawer: !isDesktop ? Drawer(child: _buildSidebarContent()) : null,
      bottomNavigationBar: !isDesktop ? _buildMobileBottomBar() : null,
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

  Widget _buildMobileBottomBar() {
    int currentBottomIndex;
    if (_selectedTabIndex == 0) {
      currentBottomIndex = 0;
    } else if (_selectedTabIndex == 1) {
      currentBottomIndex = 1;
    } else if (_selectedTabIndex == 2) {
      currentBottomIndex = 2;
    } else if (_selectedTabIndex == 5) {
      currentBottomIndex = 3;
    } else {
      currentBottomIndex = 4; // Clients, Providers, or Payouts maps to More
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: const Color(0xFFEAEAEA), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: NavigationBar(
          height: 64,
          elevation: 0,
          backgroundColor: Colors.white,
          indicatorColor: const Color(0xFF000062).withValues(alpha: 0.12),
          selectedIndex: currentBottomIndex,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) {
            if (index == 0) {
              setState(() => _selectedTabIndex = 0);
            } else if (index == 1) {
              setState(() => _selectedTabIndex = 1);
            } else if (index == 2) {
              setState(() => _selectedTabIndex = 2);
            } else if (index == 3) {
              setState(() => _selectedTabIndex = 5); // Catalog
            } else if (index == 4) {
              _scaffoldKey.currentState?.openDrawer();
            }
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.space_dashboard_outlined, size: 22),
              selectedIcon: const Icon(Icons.space_dashboard_rounded, color: Color(0xFF000062), size: 22),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_shipping_outlined, size: 22),
              selectedIcon: const Icon(Icons.local_shipping_rounded, color: Color(0xFF000062), size: 22),
              label: 'Orders',
            ),
            NavigationDestination(
              icon: const Icon(Icons.assignment_outlined, size: 22),
              selectedIcon: const Icon(Icons.assignment_rounded, color: Color(0xFF000062), size: 22),
              label: 'Bookings',
            ),
            NavigationDestination(
              icon: const Icon(Icons.collections_bookmark_outlined, size: 22),
              selectedIcon: const Icon(Icons.collections_bookmark_rounded, color: Color(0xFF000062), size: 22),
              label: 'Catalog',
            ),
            NavigationDestination(
              icon: const Icon(Icons.menu_rounded, size: 22),
              selectedIcon: const Icon(Icons.menu_open_rounded, color: Color(0xFF000062), size: 22),
              label: 'More',
            ),
          ],
        ),
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
