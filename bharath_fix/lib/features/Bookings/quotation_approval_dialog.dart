import 'package:flutter/material.dart';
import '../../models/BookingEntry.dart';
import '../../services/database_service.dart';
import '../../ui/theme/app_colors.dart';

class QuotationApprovalDialog extends StatefulWidget {
  final BookingEntry booking;
  final Future<void> Function(String paymentMode) onApprove;
  final VoidCallback onReject;

  const QuotationApprovalDialog({
    super.key,
    required this.booking,
    required this.onApprove,
    required this.onReject,
  });

  @override
  State<QuotationApprovalDialog> createState() => _QuotationApprovalDialogState();
}

class _QuotationApprovalDialogState extends State<QuotationApprovalDialog> {
  String _selectedPaymentMode = 'RAZORPAY';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final double quoteTotal = widget.booking.quoteTotal;
    final double visitingFee = widget.booking.visitingFee > 0 ? widget.booking.visitingFee : 199.0;
    final bool isFeePaid = widget.booking.isVisitingFeePaid;
    final double totalPayable = quoteTotal + (isFeePaid ? 0.0 : visitingFee);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.green,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verified Service Quote',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: const [
                          Icon(Icons.shield_rounded, color: Colors.green, size: 14),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Admin Rate Card Verified • Guarantee Included',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'The technician completed inspection and submitted standard rate card pricing:',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(12),
                  itemCount: widget.booking.quoteItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 12),
                  itemBuilder: (context, index) {
                    final item = widget.booking.quoteItems[index];
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                item.isSparePart
                                    ? Icons.extension_rounded
                                    : Icons.build_rounded,
                                size: 16,
                                color: item.isSparePart ? Colors.blue : Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Text(
                                      '🛡️ Official Standard Rate • 90d Warranty',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.price.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Repair & Parts Subtotal:',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Text(
                  '₹${quoteTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      const Text(
                        'Service Charge (Visiting Fee):',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isFeePaid ? Colors.green.shade50 : Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isFeePaid ? Colors.green.shade300 : Colors.orange.shade300,
                          ),
                        ),
                        child: Text(
                          isFeePaid ? 'Paid at booking ✓' : 'Unpaid at booking ⚠️',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isFeePaid ? Colors.green.shade800 : Colors.orange.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  isFeePaid ? '₹0 (Paid)' : '+ ₹${visitingFee.toStringAsFixed(0)}',
                  style: TextStyle(
                    color: isFeePaid ? Colors.green : Colors.orange.shade800,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable Amount:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '₹${totalPayable.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Text(
              'Select Payment Option',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),

            // Option 1: Razorpay / Online UPI
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _selectedPaymentMode == 'RAZORPAY' ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedPaymentMode == 'RAZORPAY' ? AppColors.primary : Colors.grey.shade300,
                  width: _selectedPaymentMode == 'RAZORPAY' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'RAZORPAY',
                groupValue: _selectedPaymentMode,
                onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMode = val!),
                activeColor: AppColors.primary,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Row(
                  children: [
                    Icon(Icons.payment_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('UPI / Cards / NetBanking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                subtitle: const Text('Google Pay, PhonePe, Paytm & All Cards', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ),

            // Option 2: Wallet Balance
            StreamBuilder<double>(
              stream: DatabaseService().walletBalanceStream(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                final bool hasBalance = balance >= totalPayable;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMode == 'WALLET' ? Colors.blue.shade50 : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _selectedPaymentMode == 'WALLET' ? AppColors.primary : Colors.grey.shade300,
                      width: _selectedPaymentMode == 'WALLET' ? 1.5 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: 'WALLET',
                    groupValue: _selectedPaymentMode,
                    onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMode = val!),
                    activeColor: AppColors.primary,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 18),
                            SizedBox(width: 8),
                            Text('BharathFix Wallet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: hasBalance ? Colors.green.shade700 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      hasBalance ? '⚡ Instant 1-Tap Payment' : 'Insufficient balance (₹${balance.toStringAsFixed(0)})',
                      style: TextStyle(fontSize: 11, color: hasBalance ? Colors.grey : Colors.red.shade700),
                    ),
                  ),
                );
              },
            ),

            // Option 3: Cash on Service
            Container(
              decoration: BoxDecoration(
                color: _selectedPaymentMode == 'COD' ? Colors.blue.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _selectedPaymentMode == 'COD' ? AppColors.primary : Colors.grey.shade300,
                  width: _selectedPaymentMode == 'COD' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'COD',
                groupValue: _selectedPaymentMode,
                onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMode = val!),
                activeColor: AppColors.primary,
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                title: const Row(
                  children: [
                    Icon(Icons.money_rounded, color: AppColors.primary, size: 18),
                    SizedBox(width: 8),
                    Text('Cash After Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ],
                ),
                subtitle: const Text('Pay technician directly upon service completion', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ),
            ),

            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isProcessing ? null : widget.onReject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('Decline Quote'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            setState(() => _isProcessing = true);
                            try {
                              await widget.onApprove(_selectedPaymentMode);
                            } finally {
                              if (mounted) {
                                setState(() => _isProcessing = false);
                              }
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Approve & Pay',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
