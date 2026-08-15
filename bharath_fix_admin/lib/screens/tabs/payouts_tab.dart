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

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth > 800;
                    if (isDesktop) {
                      return _buildDesktopPayoutsTable(docs);
                    } else {
                      return _buildMobilePayoutsList(docs);
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

  Widget _buildDesktopPayoutsTable(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
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
                final name = data['name'] as String? ?? 'Partner';
                final phone = data['phone'] as String? ?? 'N/A';
                final completedJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;
                final double earnings = (data['walletBalance'] as num?)?.toDouble() ?? (completedJobs * 450.0);
                final bankMap = data['bankDetails'] as Map<String, dynamic>? ?? {};
                final bankName = bankMap['bankName'] as String? ?? 'Pending Setup';
                final payoutStatus = data['payoutStatus'] as String? ?? 'Pending';

                return DataRow(
                  cells: [
                    DataCell(Text('#${doc.id.substring(0, doc.id.length > 8 ? 8 : doc.id.length)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF000062), fontSize: 12, fontWeight: FontWeight.bold))),
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(name, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold)),
                          Text(phone, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 11)),
                        ],
                      ),
                    ),
                    DataCell(Text(bankName, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12))),
                    DataCell(Text('$completedJobs Services', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13))),
                    DataCell(Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(_buildStatusBadge(payoutStatus)),
                    DataCell(
                      Row(
                        children: [
                          if (payoutStatus != 'Settled')
                            ElevatedButton(
                              onPressed: () => _updatePayoutStatus(doc.id, 'Settled'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34A853),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Transfer Settlement', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          else
                            const Text('Settled', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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

  Widget _buildMobilePayoutsList(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final name = data['name'] as String? ?? 'Partner';
        final completedJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;
        final double earnings = (data['walletBalance'] as num?)?.toDouble() ?? (completedJobs * 450.0);
        final bankMap = data['bankDetails'] as Map<String, dynamic>? ?? {};
        final bankName = bankMap['bankName'] as String? ?? 'Pending Setup';
        final payoutStatus = data['payoutStatus'] as String? ?? 'Pending';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEAEAEA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(name, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111111))),
                  _buildStatusBadge(payoutStatus),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text('Bank: $bankName', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575))),
                  const Spacer(),
                  Text('₹${earnings.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16, color: const Color(0xFF34A853))),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('$completedJobs completed services', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575))),
                  if (payoutStatus != 'Settled')
                    ElevatedButton(
                      onPressed: () => _updatePayoutStatus(doc.id, 'Settled'),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF34A853)),
                      child: const Text('Settle Payout', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
    Color bg = status == 'Settled' ? Colors.green.shade50 : Colors.amber.shade50;
    Color fg = status == 'Settled' ? Colors.green.shade800 : Colors.amber.shade900;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(status.toUpperCase(), style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}
