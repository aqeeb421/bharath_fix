// lib/screens/tabs/bookings_tab.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firebase_service.dart';
import '../../services/admin_invoice_service.dart';
import '../../widgets/admin_state_widgets.dart';

class BookingsTab extends StatefulWidget {
  const BookingsTab({super.key});

  @override
  State<BookingsTab> createState() => _BookingsTabState();
}

class _BookingsTabState extends State<BookingsTab> {
  final FirebaseService _service = FirebaseService();
  String _searchQuery = '';
  String _filterStatus = 'All';

  final List<String> _quickFilterPills = [
    'All',
    'pending',
    'accepted',
    'quotation_pending',
    'repair_in_progress',
    'completed',
  ];

  final List<String> _allStatuses = [
    'All',
    'Draft',
    'Booked',
    'Unfulfilled (Refunded)',
    'Accepted',
    'On The Way',
    'Arrived',
    'Customer Unreachable',
    'Inspection In Progress',
    'Quotation Pending',
    'Quotation Rejected',
    'Visit Only Completed',
    'Repair In Progress',
    'Parts Awaited (Paused)',
    'Unrepairable / BER',
    'Safety Hazard Halt',
    'Payment Pending Verification',
    'Completed',
    'Reviewed',
    'Warranty Claimed',
    'Warranty Rework',
    'Warranty Refunded',
    'Emergency Released (Re-pooled)',
    'Admin Audit Hold',
  ];

  String _mapStatusToUppercase(String uiStatus) {
    if (uiStatus == 'On The Way') return 'IN_TRANSIT';
    if (uiStatus == 'Repair In Progress') return 'WORK_IN_PROGRESS';
    if (uiStatus == 'Completed') return 'WORK_COMPLETED';
    if (uiStatus == 'Parts Awaited (Paused)') return 'PAUSED_PARTS_SOURCING';
    if (uiStatus == 'Unrepairable / BER') return 'UNREPAIRABLE_BER';
    if (uiStatus == 'Emergency Released (Re-pooled)') return 'EMERGENCY_RELEASED';
    if (uiStatus == 'Unfulfilled (Refunded)') return 'UNFULFILLED_REFUNDED';
    if (uiStatus == 'Payment Pending Verification') return 'PENDING_PAYMENT';
    return uiStatus.toUpperCase().replaceAll(' ', '_');
  }

  double _calculateBookingTotal(Map<String, dynamic> data) {
    final double visitingFee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
    final quotationMap = data['quotation'] as Map<String, dynamic>?;
    final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ??
        (data['quoteTotal'] as num?)?.toDouble() ??
        (data['additionalCost'] as num?)?.toDouble() ??
        0.0;
    final double finalAmount = (data['finalAmountPaid'] as num?)?.toDouble() ?? 0.0;

    if (finalAmount > 0) return finalAmount;
    if (quoteTotal > 0) {
      final bool isFeePaid = data['isVisitingFeePaid'] == true || data['isVisitingFeePaid'] == 1;
      return quoteTotal + (isFeePaid ? 0.0 : visitingFee);
    }
    return visitingFee;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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
          const SizedBox(height: 4),
          Text(
            'Track customer service bookings, repair quotations, and orders live.',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF757575),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),

          // Search and Dropdown Filter Bar
          LayoutBuilder(
            builder: (context, barConstraints) {
              final isWide = barConstraints.maxWidth > 650;
              final searchWidget = TextField(
                style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search by title, ID, or phone...',
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
              );

              final dropdownWidget = Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAEAEA)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _allStatuses.contains(_filterStatus) ? _filterStatus : 'All',
                    dropdownColor: Colors.white,
                    icon: const Icon(Icons.arrow_drop_down_rounded, color: Color(0xFF111111)),
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.w600),
                    items: _allStatuses.map((status) {
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
              );

              if (isWide) {
                return Row(
                  children: [
                    Expanded(child: searchWidget),
                    const SizedBox(width: 12),
                    dropdownWidget,
                  ],
                );
              } else {
                return Column(
                  children: [
                    searchWidget,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: dropdownWidget),
                  ],
                );
              }
            },
          ),
          const SizedBox(height: 16),

          // Quick Filter Pills Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _quickFilterPills.map((pill) {
                final isSelected = _filterStatus.toLowerCase() == pill.toLowerCase();
                final label = pill == 'All'
                    ? 'All'
                    : pill.replaceAll('_', ' ').toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(label),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _filterStatus = pill == 'All' ? 'All' : pill;
                      });
                    },
                    selectedColor: const Color(0xFF000062),
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF555555),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 11,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? const Color(0xFF000062) : const Color(0xFFEAEAEA),
                      ),
                    ),
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),

          // Bookings Main Stream Content
          Expanded(
            child: StreamBuilder<List<QueryDocumentSnapshot<Map<String, dynamic>>>>(
              stream: _service.getBookingsCombinedStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const AdminLoadingStateWidget(message: 'Syncing Admin Command Bookings...');
                }

                if (snapshot.hasError) {
                  return AdminErrorStateWidget(
                    title: 'Booking Data Sync Error',
                    errorMessage: snapshot.error.toString(),
                  );
                }

                final docs = snapshot.data ?? [];
                
                // Filtering and Searching logic
                final filteredDocs = docs.where((doc) {
                  final data = doc.data();
                  final title = (data['title'] as String? ?? '').toLowerCase();
                  final id = doc.id.toLowerCase();
                  final phone = (data['customerPhone'] ?? data['userPhone'] ?? '').toString().toLowerCase();
                  final status = (data['status'] as String? ?? 'Pending').toLowerCase();

                  final matchesSearch = title.contains(_searchQuery) || id.contains(_searchQuery) || phone.contains(_searchQuery);
                  final matchesFilter = _filterStatus == 'All' || status == _filterStatus.toLowerCase();

                  return matchesSearch && matchesFilter;
                }).toList();

                // Sort latest booking at top
                filteredDocs.sort((a, b) {
                  final aTime = (a.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  final bTime = (b.data()['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
                  if (aTime != 0 || bTime != 0) return bTime.compareTo(aTime);
                  return b.id.compareTo(a.id);
                });

                if (filteredDocs.isEmpty) {
                  if (_searchQuery.isNotEmpty) {
                    return AdminNoSearchResultsWidget(
                      query: _searchQuery,
                      onClearSearch: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    );
                  }
                  return const AdminEmptyStateWidget(
                    title: 'No Bookings Found',
                    message: 'Customer service orders will appear here in real-time.',
                  );
                }

                return LayoutBuilder(
                  builder: (context, contentConstraints) {
                    final isDesktop = contentConstraints.maxWidth > 800;
                    if (isDesktop) {
                      return _buildDesktopDataTable(filteredDocs);
                    } else {
                      return _buildMobileCardListView(filteredDocs);
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

  // Desktop Data Table View
  Widget _buildDesktopDataTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs) {
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
                DataColumn(label: Text('Total Price', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Address', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
              ],
              rows: filteredDocs.map((doc) {
                final data = doc.data();
                final id = doc.id;
                final title = data['title'] as String? ?? '';
                final dateTime = data['dateTime'] as String? ?? '';
                final double totalCost = _calculateBookingTotal(data);
                final cost = '₹${totalCost.toStringAsFixed(0)}';
                final address = data['address'] as String? ?? 'N/A';
                final status = data['status'] as String? ?? 'Pending';
                final docPath = doc.reference.path;
                final bool isCompleted = ['completed', 'work_completed', 'paid_and_closed'].contains(status.toLowerCase());

                return DataRow(
                  cells: [
                    DataCell(Text('#$id', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(Text(title, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(Text(dateTime, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13))),
                    DataCell(Text(cost, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(SizedBox(
                      width: 180,
                      child: Text(
                        address,
                        style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )),
                    DataCell(_buildStatusBadge(status)),
                    DataCell(
                      Row(
                        children: [
                          if (isCompleted) ...[
                            IconButton(
                              icon: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF000062), size: 20),
                              tooltip: 'View / Download PDF Invoice',
                              onPressed: () {
                                AdminInvoiceService.generateAndShowInvoice(
                                  context: context,
                                  bookingData: data,
                                  bookingId: id,
                                );
                              },
                            ),
                            const SizedBox(width: 4),
                          ],
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              hint: const Text('Update'),
                              icon: const Icon(Icons.edit_note_rounded, color: Color(0xFF000062)),
                              items: _allStatuses.where((s) => s != 'All').map((statusValue) {
                                return DropdownMenuItem(
                                  value: _mapStatusToUppercase(statusValue),
                                  child: Text(
                                    statusValue,
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12),
                                  ),
                                );
                              }).toList(),
                              onChanged: (newStatus) async {
                                if (newStatus != null) {
                                  await FirebaseFirestore.instance.doc(docPath).update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Updated #$id status to $newStatus')),
                                    );
                                  }
                                }
                              },
                            ),
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

  // Mobile Touch Card List View
  Widget _buildMobileCardListView(List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredDocs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: filteredDocs.length,
      itemBuilder: (context, index) {
        final doc = filteredDocs[index];
        final data = doc.data();
        final id = doc.id;
        final title = data['title'] as String? ?? '';
        final dateTime = data['dateTime'] as String? ?? '';
        final double totalCost = _calculateBookingTotal(data);
        final address = data['address'] as String? ?? 'N/A';
        final status = data['status'] as String? ?? 'Pending';
        final docPath = doc.reference.path;
        final bool isCompleted = ['completed', 'work_completed', 'paid_and_closed'].contains(status.toLowerCase());

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('#$id', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontWeight: FontWeight.bold, fontSize: 13)),
                  _buildStatusBadge(status),
                ],
              ),
              const SizedBox(height: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111111))),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.event_rounded, size: 14, color: Color(0xFF757575)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      dateTime,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('₹${totalCost.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF34A853))),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Color(0xFF757575)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      address,
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if ((data['startOtp']?.toString() ?? '').isNotEmpty || (data['completionOtp']?.toString() ?? '').isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF000062).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF000062).withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.key_rounded, size: 14, color: Color(0xFF000062)),
                      const SizedBox(width: 6),
                      Text(
                        'Start OTP: ${data['startOtp'] ?? "----"}   •   End OTP: ${data['completionOtp'] ?? "----"}',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF000062)),
                      ),
                    ],
                  ),
                ),
              ],
              const Divider(height: 20),
              Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (isCompleted)
                    TextButton.icon(
                      onPressed: () {
                        AdminInvoiceService.generateAndShowInvoice(
                          context: context,
                          bookingData: data,
                          bookingId: id,
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, size: 16, color: Color(0xFF000062)),
                      label: const Text('Invoice PDF', style: TextStyle(color: Color(0xFF000062), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      hint: Text('Update Status', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF000062))),
                      items: _allStatuses.where((s) => s != 'All').map((statusValue) {
                        return DropdownMenuItem(
                          value: _mapStatusToUppercase(statusValue),
                          child: Text(
                            statusValue,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12),
                          ),
                        );
                      }).toList(),
                      onChanged: (newStatus) async {
                        if (newStatus != null) {
                          await FirebaseFirestore.instance.doc(docPath).update({'status': newStatus, 'updatedAt': FieldValue.serverTimestamp()});
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Updated #$id status to $newStatus')),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    final s = status.toLowerCase();

    if (['completed', 'work_completed', 'paid_and_closed'].contains(s)) {
      bg = Colors.green.shade50;
      fg = Colors.green.shade800;
    } else if (['repair_in_progress', 'on_the_way', 'accepted'].contains(s)) {
      bg = Colors.blue.shade50;
      fg = Colors.blue.shade900;
    } else if (['quotation_pending'].contains(s)) {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade900;
    } else {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade900;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: GoogleFonts.plusJakartaSans(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}
