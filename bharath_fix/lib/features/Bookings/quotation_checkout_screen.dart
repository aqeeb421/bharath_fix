import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../services/database_service.dart';

class QuotationCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final String bookingId;

  const QuotationCheckoutScreen({
    super.key,
    required this.bookingData,
    required this.bookingId,
  });

  @override
  State<QuotationCheckoutScreen> createState() => _QuotationCheckoutScreenState();
}

class _QuotationCheckoutScreenState extends State<QuotationCheckoutScreen> {
  String _selectedPaymentMethod = 'RAZORPAY';
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.bookingData;
    final quotation = data['quotation'] as Map<String, dynamic>? ?? {};
    final List<dynamic> items = (quotation['items'] as List<dynamic>?) ?? [];
    final double quoteTotal = (quotation['totalAmount'] as num?)?.toDouble() ??
        (data['quoteTotal'] as num?)?.toDouble() ??
        0.0;
    final double visitingFee = (data['visitingFee'] as num?)?.toDouble() ?? 199.0;
    final bool isFeePaid = data['isVisitingFeePaid'] == true || data['isVisitingFeePaid'] == 1;

    final double totalPayable = quoteTotal + (isFeePaid ? 0.0 : visitingFee);
    final String serviceTitle = data['title']?.toString() ?? 'Appliance Repair Service';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Quotation Checkout', style: AppTextStyle.mainTitle),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Header Card
            Container(
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                    ),
                    child: const Icon(Icons.build_circle_rounded, color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(serviceTitle, style: AppTextStyle.cardTitle),
                        const SizedBox(height: 4),
                        Text(
                          'Booking ID: #${widget.bookingId}',
                          style: AppTextStyle.subtitle.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Itemized Bill Summary
            Text('Inspection & Rate Card Summary', style: AppTextStyle.sectionHeader),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final name = (item['title'] ?? item['name'] ?? 'Spare Part').toString();
                      final price = (item['price'] as num?)?.toDouble() ?? 0.0;
                      final isSpare = item['isSparePart'] == true;

                      return Row(
                        children: [
                          Icon(
                            isSpare ? Icons.extension_rounded : Icons.build_rounded,
                            color: isSpare ? Colors.blue : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppTextStyle.cardTitle.copyWith(fontSize: 13)),
                                Text(
                                  '🛡️ Admin Rate Card Verified • Guarantee Included',
                                  style: TextStyle(color: Colors.green.shade700, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₹${price.toStringAsFixed(0)}',
                            style: AppTextStyle.cardTitle.copyWith(fontSize: 14),
                          ),
                        ],
                      );
                    },
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.medium),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Repair Subtotal:', style: AppTextStyle.subtitle),
                            Text('₹${quoteTotal.toStringAsFixed(0)}', style: AppTextStyle.cardTitle),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text('Visiting Fee:', style: AppTextStyle.subtitle),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isFeePaid ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    isFeePaid ? 'Paid at Booking ✓' : 'Unpaid ⚠️',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isFeePaid ? Colors.green.shade800 : Colors.orange.shade900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isFeePaid ? '₹0' : '+ ₹${visitingFee.toStringAsFixed(0)}',
                              style: AppTextStyle.cardTitle.copyWith(
                                color: isFeePaid ? Colors.green : Colors.orange.shade800,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Total Payable Amount', style: AppTextStyle.mainTitle.copyWith(fontSize: 16)),
                            Text(
                              '₹${totalPayable.toStringAsFixed(0)}',
                              style: AppTextStyle.mainTitle.copyWith(fontSize: 20, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Select Payment Method
            Text('Select Payment Method', style: AppTextStyle.sectionHeader),
            const SizedBox(height: 8),

            // Option 1: Razorpay / Online UPI
            Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.small),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'RAZORPAY' ? const Color(0xFFE8ECF8) : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _selectedPaymentMethod == 'RAZORPAY' ? AppColors.primary : AppColors.border,
                  width: _selectedPaymentMethod == 'RAZORPAY' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'RAZORPAY',
                groupValue: _selectedPaymentMethod,
                onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMethod = val!),
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: const Row(
                  children: [
                    Icon(Icons.payment_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'UPI / Cards / NetBanking',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Google Pay, PhonePe, Paytm & All Cards (Instant Receipt)',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ),
            ),

            // Option 2: Wallet Balance
            StreamBuilder<double>(
              stream: DatabaseService().walletBalanceStream(),
              builder: (context, snapshot) {
                final balance = snapshot.data ?? 0.0;
                final bool hasBalance = balance >= totalPayable;
                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.small),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'WALLET' ? const Color(0xFFE8ECF8) : AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: _selectedPaymentMethod == 'WALLET' ? AppColors.primary : AppColors.border,
                      width: _selectedPaymentMethod == 'WALLET' ? 1.5 : 1,
                    ),
                  ),
                  child: RadioListTile<String>(
                    value: 'WALLET',
                    groupValue: _selectedPaymentMethod,
                    onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMethod = val!),
                    activeColor: AppColors.primary,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.green, size: 22),
                            SizedBox(width: 10),
                            Text(
                              'BharathFix Wallet',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        Text(
                          '₹${balance.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: hasBalance ? Colors.green.shade700 : Colors.red,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      hasBalance
                          ? '⚡ Instant 1-Tap Payment'
                          : 'Insufficient balance (Current: ₹${balance.toStringAsFixed(0)})',
                      style: TextStyle(
                        fontSize: 12,
                        color: hasBalance ? AppColors.subtitle : Colors.red.shade700,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Option 3: Cash on Service
            Container(
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'COD' ? const Color(0xFFE8ECF8) : AppColors.card,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _selectedPaymentMethod == 'COD' ? AppColors.primary : AppColors.border,
                  width: _selectedPaymentMethod == 'COD' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'COD',
                groupValue: _selectedPaymentMethod,
                onChanged: _isProcessing ? null : (val) => setState(() => _selectedPaymentMethod = val!),
                activeColor: AppColors.primary,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                title: const Row(
                  children: [
                    Icon(Icons.money_rounded, color: AppColors.primary, size: 22),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cash After Service',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                subtitle: const Text(
                  'Pay technician directly upon service completion',
                  style: TextStyle(fontSize: 12, color: AppColors.subtitle),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),

      // Bottom Payment Action Bar
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: AppColors.card,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Payable', style: AppTextStyle.subtitle.copyWith(fontSize: 11)),
                  Text(
                    '₹${totalPayable.toStringAsFixed(0)}',
                    style: AppTextStyle.mainTitle.copyWith(color: AppColors.primary, fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : () => _processQuotationPayment(totalPayable),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.medium),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Pay & Approve Quotation',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _processQuotationPayment(double totalPayableAmount) async {
    setState(() => _isProcessing = true);
    try {
      final bookingId = widget.bookingId;
      final data = widget.bookingData;
      final quotation = data['quotation'] as Map<String, dynamic>?;
      final double quoteTotal = (quotation?['totalAmount'] as num?)?.toDouble() ??
          (data['quoteTotal'] as num?)?.toDouble() ??
          0.0;

      // Wallet deduction check
      if (_selectedPaymentMethod == 'WALLET') {
        final currentWallet = await DatabaseService().getWalletBalance();
        if (currentWallet < totalPayableAmount) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Insufficient wallet balance. Please top up wallet or select another payment option."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }

        final debited = await DatabaseService().debitWallet(
          amount: totalPayableAmount,
          description: "Payment for Repair Quotation #$bookingId",
          bookingId: bookingId,
        );

        if (!debited) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Wallet payment failed. Please try another payment mode."),
                backgroundColor: Colors.red,
              ),
            );
          }
          setState(() => _isProcessing = false);
          return;
        }
      }

      final bool isPaidOnline = _selectedPaymentMethod == 'WALLET' || _selectedPaymentMethod == 'RAZORPAY';

      final updates = <String, dynamic>{
        'quotation.status': 'approved',
        'quotationStatus': 'approved',
        'status': 'in_progress',
        'quoteTotal': quoteTotal,
        'finalAmountPaid': totalPayableAmount,
        'paymentMode': _selectedPaymentMethod,
        'isFinalBillPaid': isPaidOnline,
        'isVisitingFeePaid': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update(updates);

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('bookings')
            .doc(bookingId)
            .set(updates, SetOptions(merge: true));
      }

      // Notify technician
      final providerId = data['providerId']?.toString();
      if (providerId != null && providerId.isNotEmpty) {
        final notifId = 'notif_t_${DateTime.now().millisecondsSinceEpoch}';
        final modeLabel = _selectedPaymentMethod == 'WALLET' ? 'Wallet' : _selectedPaymentMethod == 'RAZORPAY' ? 'Online' : 'Cash';
        await FirebaseFirestore.instance
            .collection('providers')
            .doc(providerId)
            .collection('notifications')
            .doc(notifId)
            .set({
          'id': notifId,
          'techId': providerId,
          'title': 'Quotation Approved! 🎉',
          'body': 'Customer approved quotation (₹${totalPayableAmount.toStringAsFixed(0)} total via $modeLabel). You can proceed with repair.',
          'data': {'bookingId': bookingId, 'type': 'QUOTATION_APPROVED'},
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Quotation Approved! ₹${totalPayableAmount.toStringAsFixed(0)} ($_selectedPaymentMethod). Technician starting repair.",
            ),
            backgroundColor: Colors.green,
          ),
        );
        // Cleanly redirect back to Bookings Screen
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to process payment: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}
