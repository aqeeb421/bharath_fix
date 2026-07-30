import 'package:flutter/material.dart';

class PayoutRequest {
  final String id;
  final String providerName;
  final String bankAccount;
  final String ifscCode;
  final double amount;
  final String requestedAt;
  final String status; // 'PENDING', 'APPROVED', 'REJECTED'

  PayoutRequest({
    required this.id,
    required this.providerName,
    required this.bankAccount,
    required this.ifscCode,
    required this.amount,
    required this.requestedAt,
    this.status = 'PENDING',
  });
}

class PayoutsTab extends StatefulWidget {
  const PayoutsTab({Key? key}) : super(key: key);

  @override
  State<PayoutsTab> createState() => _PayoutsTabState();
}

class _PayoutsTabState extends State<PayoutsTab> {
  final List<PayoutRequest> _payouts = [
    PayoutRequest(
      id: 'PAY-8921',
      providerName: 'Ramesh Kumar',
      bankAccount: '918239128391',
      ifscCode: 'SBIN0001234',
      amount: 4250.0,
      requestedAt: '2026-07-27 10:30 AM',
    ),
    PayoutRequest(
      id: 'PAY-8922',
      providerName: 'Suresh Verma',
      bankAccount: '501002391023',
      ifscCode: 'HDFC0004321',
      amount: 1800.0,
      requestedAt: '2026-07-27 11:15 AM',
    ),
  ];

  void _updateStatus(int index, String newStatus) {
    setState(() {
      _payouts[index] = PayoutRequest(
        id: _payouts[index].id,
        providerName: _payouts[index].providerName,
        bankAccount: _payouts[index].bankAccount,
        ifscCode: _payouts[index].ifscCode,
        amount: _payouts[index].amount,
        requestedAt: _payouts[index].requestedAt,
        status: newStatus,
      );
    });
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
                children: const [
                  Text(
                    'Technician Wallet Payouts',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Review and approve weekly withdrawal requests into bank accounts',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Export Ledger CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Payout ID', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Technician', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Bank Details', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Requested Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Requested Date', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                  rows: List.generate(_payouts.length, (index) {
                    final item = _payouts[index];
                    return DataRow(cells: [
                      DataCell(Text(item.id, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(item.providerName)),
                      DataCell(Text('${item.bankAccount} (${item.ifscCode})', style: const TextStyle(fontSize: 12))),
                      DataCell(Text('₹${item.amount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green))),
                      DataCell(Text(item.requestedAt, style: const TextStyle(fontSize: 12))),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: item.status == 'APPROVED'
                                ? Colors.green.shade50
                                : item.status == 'REJECTED'
                                    ? Colors.red.shade50
                                    : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            item.status,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: item.status == 'APPROVED'
                                  ? Colors.green
                                  : item.status == 'REJECTED'
                                      ? Colors.red
                                      : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        item.status == 'PENDING'
                            ? Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
                                    tooltip: 'Approve Payout',
                                    onPressed: () => _updateStatus(index, 'APPROVED'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.cancel_rounded, color: Colors.red),
                                    tooltip: 'Reject Payout',
                                    onPressed: () => _updateStatus(index, 'REJECTED'),
                                  ),
                                ],
                              )
                            : const Text('Settled', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    ]);
                  }),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
