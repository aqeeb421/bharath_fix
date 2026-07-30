import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/database_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Razorpay _razorpay;
  final TextEditingController _amountController = TextEditingController(text: '500');
  double _pendingTopUpAmount = 500.0;
  bool _isProcessing = false;

  final List<double> _quickChips = [100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _handleRazorpaySuccess(PaymentSuccessResponse response) async {
    final success = await DatabaseService().creditWallet(
      amount: _pendingTopUpAmount,
      description: 'Wallet Top-Up via Razorpay',
      razorpayPaymentId: response.paymentId,
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showSuccessSnackBar('Successfully added ₹${_pendingTopUpAmount.toStringAsFixed(0)} to your wallet!');
      } else {
        _showErrorSnackBar('Failed to update wallet balance. Please contact support.');
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Top-up failed: ${response.message ?? "Transaction cancelled"}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  void _initiateRazorpayTopUp() {
    final text = _amountController.text.trim();
    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid top-up amount');
      return;
    }

    setState(() {
      _pendingTopUpAmount = amount;
      _isProcessing = true;
    });

    final int amountInPaise = (amount * 100).toInt();

    var options = {
      'key': 'rzp_test_dENdzkIZ1Qkpqv',
      'amount': amountInPaise,
      'name': 'BharathFix Wallet',
      'description': 'Add ₹${amount.toStringAsFixed(0)} to Wallet',
      'timeout': 300,
      'prefill': {
        'contact': '',
        'email': 'customer@bharathfix.in',
      },
      'theme': {
        'color': '#000062',
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Unable to launch payment gateway: $e');
    }
  }

  Future<void> _performInstantTestTopUp() async {
    final text = _amountController.text.trim();
    final double? amount = double.tryParse(text);
    if (amount == null || amount <= 0) {
      _showErrorSnackBar('Please enter a valid top-up amount');
      return;
    }

    setState(() => _isProcessing = true);

    final success = await DatabaseService().creditWallet(
      amount: amount,
      description: 'Instant Wallet Add (Test Payment)',
    );

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        _showSuccessSnackBar('Added ₹${amount.toStringAsFixed(0)} to BharathFix Wallet!');
      } else {
        _showErrorSnackBar('Failed to update wallet.');
      }
    }
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w600))),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontFamily: 'Plus Jakarta Sans')),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('BharathFix Wallet', style: AppTextStyle.sectionHeader),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CRED / PhonePe Metallic Wallet Card
            _buildMetallicWalletCard(),

            const SizedBox(height: AppSpacing.large),

            // 2. Add Money Section
            const Text('Add Money to Wallet', style: AppTextStyle.sectionHeader),
            const SizedBox(height: AppSpacing.small),
            Text(
              'Use your wallet balance for instant 1-tap checkout on all home services & spare parts.',
              style: AppTextStyle.subtitle.copyWith(fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.medium),

            // Amount Input & Quick Chips
            _buildAddMoneyInputSection(),

            const SizedBox(height: AppSpacing.large),

            // 3. Scratch & Earn Cashback Banner
            _buildScratchRewardsBanner(),

            const SizedBox(height: AppSpacing.extraLarge),

            // 4. Real-time Transaction History Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Transaction History', style: AppTextStyle.sectionHeader),
                Icon(Icons.history_rounded, color: AppColors.subtitle, size: 20),
              ],
            ),
            const SizedBox(height: AppSpacing.medium),

            _buildTransactionHistoryFeed(),

            const SizedBox(height: AppSpacing.medium),
          ],
        ),
      ),
    );
  }

  Widget _buildMetallicWalletCard() {
    return StreamBuilder<double>(
      stream: DatabaseService().walletBalanceStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF000062),
                Color(0xFF1A1A80),
                Color(0xFF000040),
              ],
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x3F000062),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'BHARATHFIX PAY',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFD700), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.stars_rounded, color: Color(0xFFFFD700), size: 14),
                        SizedBox(width: 4),
                        Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFD700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Available Balance',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Instant 1-Tap Checkout Active',
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white60, fontSize: 11),
                  ),
                  Icon(Icons.nfc_rounded, color: Colors.white54, size: 24),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAddMoneyInputSection() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.title),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text('₹', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              hintText: 'Enter amount',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _quickChips.map((val) {
                final isSelected = _amountController.text == val.toInt().toString();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text('+ ₹${val.toInt()}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _amountController.text = val.toInt().toString();
                      });
                    },
                    selectedColor: AppColors.accentGreen,
                    backgroundColor: AppColors.card,
                    labelStyle: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.title,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: AppSpacing.large),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _initiateRazorpayTopUp,
                  icon: const Icon(Icons.payment_rounded, color: Colors.white, size: 18),
                  label: _isProcessing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Add Money (Razorpay)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _performInstantTestTopUp,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Instant Test', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScratchRewardsBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF8E1), Color(0xFFFFECB3)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: const Color(0xFFFFD54F)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.medium),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Scratch & Win Cashbacks! 🎉', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF5D4037))),
                SizedBox(height: 2),
                Text('Get up to ₹500 guaranteed cashback added to your wallet on top-ups above ₹500.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: Color(0xFF795548))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionHistoryFeed() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: DatabaseService().walletTransactionsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primary));
        }

        final txs = snapshot.data ?? [];
        if (txs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.large),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined, size: 40, color: AppColors.subtitle),
                SizedBox(height: 8),
                Text('No Wallet Transactions Yet', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: AppColors.title)),
                SizedBox(height: 4),
                Text('Add money to get started with instant bookings.', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle)),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          itemBuilder: (context, index) {
            final tx = txs[index];
            final bool isCredit = tx['type'] == 'CREDIT';
            final double amount = (tx['amount'] as num? ?? 0).toDouble();
            final String desc = tx['description'] ?? (isCredit ? 'Wallet Credit' : 'Service Payment');
            final String timeStr = tx['timestamp'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.small),
              padding: const EdgeInsets.all(AppSpacing.medium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCredit ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.medium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          desc,
                          style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.title),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeStr.length > 10 ? timeStr.substring(0, 10) : timeStr,
                          style: AppTextStyle.subtitle.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isCredit ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
