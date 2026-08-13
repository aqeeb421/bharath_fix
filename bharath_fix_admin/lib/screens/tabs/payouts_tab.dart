import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PayoutsTab extends StatefulWidget {
  const PayoutsTab({super.key});

  @override
  State<PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends State<PayoutsTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> _updatePayoutStatus(String docId, String status) async {
    await _db.collection('providers').doc(docId).set({
      'payoutStatus': status,
      'lastPayoutAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payout status updated to $status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                    'Technician Wallet & Settlement Payouts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and process weekly bank account settlements for verified service partners live.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _db.collection('providers').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF000062)));
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Center(
                    child: Text('No technician payout records found.', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575))),
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
                            DataColumn(label: Text('Partner ID', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Technician Name', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Bank Details', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Completed Jobs', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Net Earnings', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payout Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data();
                            final docId = doc.id;
                            final name = data['name'] as String? ?? 'Partner';
                            final earnings = (data['earnings'] as num? ?? 0.0).toDouble();
                            final completedJobs = (data['completedJobs'] as num? ?? 0).toInt();
                            final payoutStatus = (data['payoutStatus'] as String? ?? 'PAID').toUpperCase();

                            final bank = data['bankDetails'] as Map<String, dynamic>? ?? {};
                            final bankName = bank['bankName'] as String? ?? 'SBI';
                            final accNo = (bank['accountNumber'] ?? bank['accountNo']) as String? ?? 'Not Configured';
                            final ifsc = (bank['ifscCode'] ?? bank['ifsc']) as String? ?? 'N/A';

                            Color statusColor = const Color(0xFF34A853);
                            Color statusBg = const Color(0xFF34A853).withValues(alpha: 0.1);

                            if (payoutStatus == 'PENDING') {
                              statusColor = const Color(0xFFFF9900);
                              statusBg = const Color(0xFFFF9900).withValues(alpha: 0.1);
                            } else if (payoutStatus == 'REJECTED') {
                              statusColor = Colors.redAccent;
                              statusBg = Colors.redAccent.withValues(alpha: 0.1);
                            }

                            return DataRow(
                              cells: [
                                DataCell(Text('#${docId.substring(0, docId.length > 8 ? 8 : docId.length)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold))),
                                DataCell(Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(bankName, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 12, fontWeight: FontWeight.bold)),
                                    Text('$accNo ($ifsc)', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11)),
                                  ],
                                )),
                                DataCell(Text('$completedJobs jobs', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13))),
                                DataCell(Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 14, fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: statusBg,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                                    ),
                                    child: Text(
                                      payoutStatus,
                                      style: GoogleFonts.plusJakartaSans(color: statusColor, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.check_circle_outline_rounded, color: Color(0xFF34A853), size: 20),
                                        tooltip: 'Approve & Settle Payout',
                                        onPressed: () => _updatePayoutStatus(docId, 'PAID'),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.history_rounded, color: Color(0xFF000062), size: 20),
                                        tooltip: 'Set Pending Review',
                                        onPressed: () => _updatePayoutStatus(docId, 'PENDING'),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}
