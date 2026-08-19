// lib/screens/tabs/users_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final FirebaseService _service = FirebaseService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Client User Management',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'View customer profiles, lifetime value, and manage wallet credits.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Search Field
          TextField(
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by client name, email, or phone number...',
              hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEAEAEA)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF000062)),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.toLowerCase();
              });
            },
          ),
          const SizedBox(height: 20),

          // Users Main Stream Content
          Expanded(
            child: StreamBuilder(
              stream: _service.getUsersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading clients: ${snapshot.error}',
                      style: GoogleFonts.plusJakartaSans(color: Colors.redAccent),
                    ),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final name = (data['name'] as String? ?? '').toLowerCase();
                  final email = (data['email'] as String? ?? '').toLowerCase();
                  final phone = (data['phone'] as String? ?? '').toLowerCase();

                  return name.contains(_searchQuery) ||
                      email.contains(_searchQuery) ||
                      phone.contains(_searchQuery);
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No client accounts found matching search query.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return _buildDesktopUsersTable(filteredDocs);
                    } else {
                      return _buildMobileUsersList(filteredDocs);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopUsersTable(List filteredDocs) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEAEAEA)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(const Color(0xFFF7F8FA)),
              dataRowMinHeight: 64,
              dataRowMaxHeight: 76,
              columns: [
                DataColumn(label: Text('Client Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Email Address', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Mobile Phone', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Wallet Balance', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
              ],
              rows: filteredDocs.map((doc) {
                final data = doc.data();
                final uid = doc.id;
                final name = data['name'] as String? ?? 'Valued Customer';
                final email = data['email'] as String? ?? 'N/A';
                final phone = data['phone'] as String? ?? 'N/A';
                final walletBalance = (data['walletBalance'] as num?)?.toDouble() ?? 0.0;

                return DataRow(
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF000062).withValues(alpha: 0.08),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : 'U',
                              style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    DataCell(Text(email, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13))),
                    DataCell(Text(phone, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13))),
                    DataCell(Text('₹${walletBalance.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.person_search_rounded, color: Color(0xFF000062), size: 20),
                            tooltip: 'View CRM Profile & LTV',
                            onPressed: () => _showCustomerProfileModal(uid, name, phone, email),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                            onPressed: () => _confirmDeleteUser(uid, name),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUsersList(List filteredDocs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data();
        final uid = doc.id;
        final name = data['name'] as String? ?? 'Valued Customer';
        final email = data['email'] as String? ?? 'N/A';
        final phone = data['phone'] as String? ?? 'N/A';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFF000062).withValues(alpha: 0.08),
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : 'U',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF111111))),
                    const SizedBox(height: 2),
                    Text(phone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575))),
                    if (email.isNotEmpty && email != 'N/A')
                      Text(email, style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9E9E9E))),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.person_search_rounded, color: Color(0xFF000062), size: 20),
                onPressed: () => _showCustomerProfileModal(uid, name, phone, email),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                onPressed: () => _confirmDeleteUser(uid, name),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===================== CRM PROFILE MODAL =====================

  void _showCustomerProfileModal(String uid, String name, String phone, String email) {
    showDialog(
      context: context,
      builder: (ctx) {
        return FutureBuilder<List<dynamic>>(
          future: Future.wait([
            _db.collection('users').doc(uid).collection('bookings').get(),
            _db.collection('orders').where('userId', isEqualTo: uid).get(),
            _db.collection('users').doc(uid).get(),
          ]),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
            }

            final bookingsSnap = snap.data?[0] as QuerySnapshot?;
            final ordersSnap = snap.data?[1] as QuerySnapshot?;
            final userDoc = snap.data?[2] as DocumentSnapshot?;

            final bookingsCount = bookingsSnap?.docs.length ?? 0;
            final ordersCount = ordersSnap?.docs.length ?? 0;
            double totalSpent = 0;
            for (final o in ordersSnap?.docs ?? []) {
              final d = o.data() as Map<String, dynamic>? ?? {};
              totalSpent += (d['totalPaid'] as num?)?.toDouble() ?? 0.0;
            }
            final walletBal = (userDoc?.data() as Map<String, dynamic>?)?['walletBalance'] as num? ?? 0;
            final walletCreditCtrl = TextEditingController();

            return StatefulBuilder(
              builder: (context, setDialogState) {
                return AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF000062).withValues(alpha: 0.1),
                        child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(phone, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575))),
                          ],
                        ),
                      ),
                    ],
                  ),
                  content: SizedBox(
                    width: 460,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // LTV Stats Row
                          Row(
                            children: [
                              _ltvCard('Total Bookings', '$bookingsCount', Icons.calendar_today_rounded, const Color(0xFF000062)),
                              const SizedBox(width: 10),
                              _ltvCard('Product Orders', '$ordersCount', Icons.shopping_bag_rounded, const Color(0xFF7C4DFF)),
                              const SizedBox(width: 10),
                              _ltvCard('LTV Spend', '₹${totalSpent.toStringAsFixed(0)}', Icons.currency_rupee_rounded, const Color(0xFF34A853)),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Current Wallet Balance
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: const Color(0xFFF7F8FA), borderRadius: BorderRadius.circular(10)),
                            child: Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF34A853), size: 20),
                                const SizedBox(width: 8),
                                Text('Current Wallet Balance: ₹$walletBal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF111111))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Issue Wallet Credits
                          Text('Issue Wallet Credits', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF111111))),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: walletCreditCtrl,
                                  keyboardType: TextInputType.number,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: 'Amount (₹)',
                                    hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E), fontSize: 13),
                                    prefixText: '₹ ',
                                    filled: true,
                                    fillColor: const Color(0xFFF7F8FA),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () async {
                                  final amount = double.tryParse(walletCreditCtrl.text.trim());
                                  if (amount == null || amount <= 0) return;
                                  final newBalance = walletBal.toDouble() + amount;
                                  await _db.collection('users').doc(uid).set({'walletBalance': newBalance}, SetOptions(merge: true));
                                  if (ctx.mounted) Navigator.pop(ctx);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('₹${amount.toStringAsFixed(0)} credited to $name\'s wallet!'), backgroundColor: const Color(0xFF34A853)),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF34A853),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text('Add Credits', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  actions: [
                    // WhatsApp Quick Contact
                    if (phone != 'N/A' && phone.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.chat_rounded, size: 16, color: Color(0xFF25D366)),
                        label: Text('WhatsApp', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF25D366), fontWeight: FontWeight.bold, fontSize: 12)),
                        style: OutlinedButton.styleFrom(side: const BorderSide(color: Color(0xFF25D366))),
                      ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('Close', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _ltvCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 10, color: const Color(0xFF757575))),
          ],
        ),
      ),
    );
  }

  // ===================== DELETE USER =====================

  void _confirmDeleteUser(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Delete User Account', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete the user profile for "$name"? This action is permanent.',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await _service.deleteUser(uid);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Deleted profile for $name.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: Text('Delete', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }
}
