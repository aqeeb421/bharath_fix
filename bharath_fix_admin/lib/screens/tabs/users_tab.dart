// lib/screens/tabs/users_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/firebase_service.dart';

class UsersTab extends StatefulWidget {
  const UsersTab({super.key});

  @override
  State<UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<UsersTab> {
  final FirebaseService _service = FirebaseService();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
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
            'View and manage registered customers on the BharathFix platform.',
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
                DataColumn(label: Text('User UID', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
              ],
              rows: filteredDocs.map((doc) {
                final data = doc.data();
                final uid = doc.id;
                final name = data['name'] as String? ?? 'Valued Customer';
                final email = data['email'] as String? ?? 'N/A';
                final phone = data['phone'] as String? ?? 'N/A';

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
                    DataCell(Text(uid, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11))),
                    DataCell(
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        onPressed: () => _confirmDeleteUser(uid, name),
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
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                onPressed: () => _confirmDeleteUser(uid, name),
              ),
            ],
          ),
        );
      },
    );
  }

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
