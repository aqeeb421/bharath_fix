import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PayoutsTab extends StatefulWidget {
  const PayoutsTab({super.key});

  @override
  State<PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends State<PayoutsTab> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _latestDocs = [];

  static const double _platformFeePercent = 15.0; // 15% BharathFix platform fee

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

  void _exportPayoutsCsv() {
    if (_latestDocs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No payout data to export.')),
      );
      return;
    }

    final rows = <List<String>>[
      ['Technician Name', 'Phone', 'Bank Name', 'Account Holder', 'Account Number', 'IFSC Code', 'Gross Earnings (₹)', 'Platform Fee 15% (₹)', 'Net Payout 85% (₹)', 'Status'],
    ];

    for (final doc in _latestDocs) {
      final data = doc.data();
      final name = data['name'] as String? ?? 'Partner';
      final phone = data['phone'] as String? ?? '';
      final completedJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;
      final double gross = (data['walletBalance'] as num?)?.toDouble() ?? (completedJobs * 450.0);
      final double platformFee = (gross * _platformFeePercent / 100);
      final double net = gross - platformFee;
      final bankMap = data['bankDetails'] as Map<String, dynamic>? ?? {};
      final bankName = bankMap['bankName'] as String? ?? '';
      final accountHolder = bankMap['accountHolder'] as String? ?? '';
      final accountNo = bankMap['accountNumber'] as String? ?? bankMap['accountNo'] as String? ?? '';
      final ifsc = bankMap['ifscCode'] as String? ?? bankMap['ifsc'] as String? ?? '';
      final status = data['payoutStatus'] as String? ?? 'Pending';

      rows.add([name, phone, bankName, accountHolder, accountNo, ifsc, gross.toStringAsFixed(2), platformFee.toStringAsFixed(2), net.toStringAsFixed(2), status]);
    }

    final csvContent = rows.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
    final bytes = utf8.encode(csvContent);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'bharathfix_payouts_${DateTime.now().toIso8601String().substring(0, 10)}.csv')
      ..click();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Payout CSV downloaded!'), backgroundColor: Color(0xFF34A853)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 700;
              final headerText = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technician Wallet & Settlement Payouts',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: isMobile ? 20 : 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF111111),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Review and process weekly bank account settlements for verified service partners. Platform fee: 15% | Net to Technician: 85%.',
                    style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12),
                  ),
                ],
              );

              final exportBtn = ElevatedButton.icon(
                onPressed: _exportPayoutsCsv,
                icon: const Icon(Icons.download_rounded, size: 16, color: Colors.white),
                label: Text(isMobile ? 'Export CSV' : 'Export Batch CSV', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF34A853),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
              );

              if (isMobile) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    headerText,
                    const SizedBox(height: 12),
                    SizedBox(width: double.infinity, child: exportBtn),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: headerText),
                  const SizedBox(width: 16),
                  exportBtn,
                ],
              );
            },
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
                _latestDocs = docs; // Store for CSV export

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
              dataRowMinHeight: 72,
              dataRowMaxHeight: 90,
              columns: [
                DataColumn(label: Text('Technician', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Bank Details', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Completed Jobs', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Gross Earnings', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Platform 15%', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Net Payout 85%', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Status', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Action', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontWeight: FontWeight.bold))),
              ],
              rows: docs.map((doc) {
                final data = doc.data();
                final name = data['name'] as String? ?? 'Partner';
                final phone = data['phone'] as String? ?? 'N/A';
                final completedJobs = (data['completedJobs'] as num?)?.toInt() ?? 0;
                final double gross = (data['walletBalance'] as num?)?.toDouble() ?? (completedJobs * 450.0);
                final double platformFee = gross * _platformFeePercent / 100;
                final double netPayout = gross - platformFee;
                final bankMap = data['bankDetails'] as Map<String, dynamic>? ?? {};
                final bankName = bankMap['bankName'] as String? ?? 'Pending Setup';
                final accountNo = bankMap['accountNumber'] as String? ?? bankMap['accountNo'] as String? ?? '—';
                final ifsc = bankMap['ifscCode'] as String? ?? bankMap['ifsc'] as String? ?? '—';
                final payoutStatus = data['payoutStatus'] as String? ?? 'Pending';

                return DataRow(
                  cells: [
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
                    DataCell(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(bankName, style: GoogleFonts.plusJakartaSans(color: const Color(0xFF757575), fontSize: 12)),
                          if (accountNo != '—') Text('A/C: $accountNo', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9E9E9E))),
                          if (ifsc != '—') Text('IFSC: $ifsc', style: GoogleFonts.plusJakartaSans(fontSize: 11, color: const Color(0xFF9E9E9E))),
                        ],
                      ),
                    ),
                    DataCell(Text('$completedJobs', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13))),
                    DataCell(Text('₹${gross.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF111111), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${platformFee.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: Colors.orange.shade800, fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(Text('₹${netPayout.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(color: const Color(0xFF34A853), fontSize: 13, fontWeight: FontWeight.bold))),
                    DataCell(_buildStatusBadge(payoutStatus)),
                    DataCell(
                      payoutStatus != 'Settled'
                          ? ElevatedButton(
                              onPressed: () => _updatePayoutStatus(doc.id, 'Settled'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF34A853),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: const Text('Transfer Settlement', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            )
                          : const Text('Settled ✓', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
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
        final double gross = (data['walletBalance'] as num?)?.toDouble() ?? (completedJobs * 450.0);
        final double platformFee = gross * _platformFeePercent / 100;
        final double netPayout = gross - platformFee;
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
                  Expanded(
                    child: Text(
                      name,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF111111)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildStatusBadge(payoutStatus),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Bank: $bankName',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              // Commission split
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Gross: ₹${gross.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF111111), fontWeight: FontWeight.w600)),
                  Text('Fee: ₹${platformFee.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.orange.shade800, fontWeight: FontWeight.w600)),
                  Text('Net: ₹${netPayout.toStringAsFixed(0)}', style: GoogleFonts.plusJakartaSans(fontSize: 13, color: const Color(0xFF34A853), fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '$completedJobs completed services',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: const Color(0xFF757575)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
