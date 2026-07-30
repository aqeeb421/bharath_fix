// lib/screens/tabs/bookings_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final FirebaseService _service = FirebaseService();
  String _searchQuery = '';
  String _filterStatus = 'All';

  final List<String> _statuses = ['All', 'Pending', 'Processing', 'Completed', 'Cancelled'];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bookings Management',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111111),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Track customer service bookings, installations, and orders live.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 24),

          // Search and Filters Bar
          Row(
            children: [
              Expanded(
                child: TextField(
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by booking title or ID...',
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
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _filterStatus,
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF111111)),
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                    items: _statuses.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(status),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _filterStatus = value!;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Bookings Table / List
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _service.getBookingsCombinedStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF6C4CF1)));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error loading bookings: ${snapshot.error}',
                      style: GoogleFonts.plusJakartaSans(color: Colors.redAccent),
                    ),
                  );
                }

                final docs = snapshot.data ?? [];
                
                // Filtering and Searching logic
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final id = doc.id.toLowerCase();
                  final status = data['status'] as String? ?? 'Pending';

                  final matchesSearch = title.contains(_searchQuery) || id.contains(_searchQuery);
                  final matchesFilter = _filterStatus == 'All' || status.toLowerCase() == _filterStatus.toLowerCase();

                  return matchesSearch && matchesFilter;
                }).toList();

                if (filteredDocs.isEmpty) {
                  return Center(
                    child: Text(
                      'No bookings match these parameters.',
                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFFA29EB6)),
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
                          dataRowMaxHeight: 80,
                          columns: [
                            DataColumn(label: Text('Booking ID', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Appliance Service', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Scheduled Date/Time', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Price', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Delivery Address', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          ],
                          rows: filteredDocs.map((doc) {
                            final data = doc.data();
                            final id = doc.id;
                            final title = data['title'] as String? ?? '';
                            final dateTime = data['dateTime'] as String? ?? '';
                            final cost = data['cost'] as String? ?? '';
                            final address = data['address'] as String? ?? 'N/A';
                            final status = data['status'] as String? ?? 'Pending';

                            final docPath = doc.reference.path;

                            return DataRow(
                               cells: [
                                DataCell(Text('#$id', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(Text(title, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(Text(dateTime, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13))),
                                DataCell(Text(cost, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(SizedBox(
                                  width: 200,
                                  child: Text(
                                    address,
                                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                )),
                                DataCell(_buildStatusBadge(status)),
                                DataCell(
                                  DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      hint: const Text('Update'),
                                      icon: const Icon(Icons.edit_road_rounded, color: Color(0xFF000062), size: 18),
                                      dropdownColor: Colors.white,
                                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12),
                                      items: const [
                                        DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                        DropdownMenuItem(value: 'Processing', child: Text('Processing')),
                                        DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                                        DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                                      ],
                                      onChanged: (newVal) async {
                                        if (newVal != null) {
                                          await _service.updateBookingStatus(docPath, newVal);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(content: Text('Updated Booking #$id to $newVal')),
                                            );
                                          }
                                        }
                                      },
                                    ),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    Color bg;

    switch (status.toLowerCase()) {
      case 'completed':
        color = const Color(0xFF34A853);
        bg = const Color(0xFF34A853).withOpacity(0.1);
        break;
      case 'processing':
        color = const Color(0xFF00C6FF);
        bg = const Color(0xFF00C6FF).withOpacity(0.1);
        break;
      case 'cancelled':
        color = Colors.redAccent;
        bg = Colors.redAccent.withOpacity(0.1);
        break;
      case 'pending':
      default:
        color = const Color(0xFFFF9900);
        bg = const Color(0xFFFF9900).withOpacity(0.1);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
