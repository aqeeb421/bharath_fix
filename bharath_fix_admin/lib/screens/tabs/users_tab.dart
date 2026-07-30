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
          const SizedBox(height: 6),
          Text(
            'View all customers registered on the BharathFix mobile application.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Search Field
          TextField(
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by client name, email, or telephone number...',
              hintStyle: GoogleFonts.plusJakartaSans(color: const Color(0xFF9E9E9E)),
              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF757575)),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
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
          const SizedBox(height: 24),

          // Users Table
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
                      'No client accounts found matching the search query.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575)),
                    ),
                  );
                }

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
                            DataColumn(label: Text('UID', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Full Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email Address', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Mobile Phone', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredDocs.map((doc) {
                            final data = doc.data();
                            final uid = doc.id;
                            final name = data['name'] as String? ?? 'N/A';
                            final email = data['email'] as String? ?? 'N/A';
                            final phone = data['phone'] as String? ?? 'N/A';

                            return DataRow(
                              cells: [
                                DataCell(Text(uid, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12))),
                                DataCell(
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: const Color(0xFF000062).withOpacity(0.08),
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
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteUser(String uid, String name) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161230),
          title: Text('Delete User Account', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Text(
            'Are you sure you want to delete the user profile for "$name"? This is irreversible.',
            style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA29EB6)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA29EB6))),
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
