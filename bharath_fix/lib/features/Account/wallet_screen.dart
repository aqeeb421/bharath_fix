import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class WalletScreen extends StatefulWidget {
  final double? initialAmount;
  const WalletScreen({super.key, this.initialAmount});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  late Razorpay _razorpay;
  late final TextEditingController _amountController;
  late double _pendingTopUpAmount;
  bool _isProcessing = false;
  String _selectedTxFilter = 'ALL'; // 'ALL', 'CREDIT', 'DEBIT'

  final List<double> _quickChips = [100, 500, 1000, 2000];

  @override
  void initState() {
    super.initState();
    final startAmt = (widget.initialAmount != null && widget.initialAmount! > 0)
        ? widget.initialAmount!.ceil().toDouble()
        : 500.0;
    _pendingTopUpAmount = startAmt;
    _amountController = TextEditingController(text: startAmt.toStringAsFixed(0));
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handleRazorpaySuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handleRazorpayError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
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

    if (_pendingTopUpAmount >= 500) {
      await DatabaseService().creditWallet(
        amount: 50.0,
        description: '₹50 Automated Cashback Reward 🎉',
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        if (_pendingTopUpAmount >= 500) {
          _showGPayScratchCardDialog(context, 50.0);
        } else {
          _showSuccessSnackBar(
            'Successfully added ₹${_pendingTopUpAmount.toStringAsFixed(0)} to your service credits!',
          );
        }
      } else {
        _showErrorSnackBar(
          'Failed to update credits balance. Please contact support.',
        );
      }
    }
  }

  void _handleRazorpayError(PaymentFailureResponse response) {
    if (mounted) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar(
        'Top-up failed: ${response.message ?? "Transaction cancelled"}',
      );
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
      'key': PaymentService.razorpayKey,
      'amount': amountInPaise,
      'name': 'BharathFix Wallet',
      'description': 'Add ₹${amount.toStringAsFixed(0)} to Wallet',
      'timeout': 300,
      'prefill': {'contact': '', 'email': 'customer@bharathfix.in'},
      'theme': {'color': '#000062'},
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

    if (amount >= 500) {
      await DatabaseService().creditWallet(
        amount: 50.0,
        description: '₹50 Automated Cashback Reward 🎉',
      );
    }

    if (mounted) {
      setState(() => _isProcessing = false);
      if (success) {
        if (amount >= 500) {
          _showGPayScratchCardDialog(context, 50.0);
        } else {
          _showSuccessSnackBar(
            'Added ₹${amount.toStringAsFixed(0)} to BharathFix Wallet!',
          );
        }
      } else {
        _showErrorSnackBar('Failed to update wallet.');
      }
    }
  }

  void _showGPayScratchCardDialog(BuildContext context, double bonusAmount) {
    bool isScratched = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF4A148C),
                      Color(0xFF7B1FA2),
                      Color(0xFF311B92),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.purple.withValues(alpha: 0.5),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFD54F),
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Google Pay Rewards',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(
                          Icons.auto_awesome,
                          color: Color(0xFFFFD54F),
                          size: 24,
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Text(
                      'You unlocked a Cashback Scratch Card! 🎉',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),

                    // Scratch Card Box
                    GestureDetector(
                      onTap: () {
                        if (!isScratched) {
                          setModalState(() {
                            isScratched = true;
                          });
                        }
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeInOutBack,
                        width: 220,
                        height: 220,
                        decoration: BoxDecoration(
                          gradient: isScratched
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFFFFF8E1),
                                    Color(0xFFFFECB3),
                                  ],
                                )
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD54F),
                                    Color(0xFFFFB300),
                                    Color(0xFFFF8F00),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isScratched
                                ? const Color(0xFFFFD54F)
                                : Colors.white,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: isScratched
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.emoji_events_rounded,
                                    size: 56,
                                    color: Color(0xFFFF8F00),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'YOU WON!',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF5D4037),
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  Text(
                                    '₹${bonusAmount.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 38,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                  Text(
                                    'Cashback Balance',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      color: Color(0xFF795548),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [Icon(
                                    Icons.touch_app_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 12),
                                  Text(
                                    'TAP TO SCRATCH',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Guaranteed Reward Inside',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        if (isScratched) {
                          _showSuccessSnackBar(
                            'Claimed ₹${bonusAmount.toStringAsFixed(0)} cashback reward!',
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD54F),
                        foregroundColor: const Color(0xFF3E2723),
                        elevation: 4,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isScratched
                            ? 'Claim Reward & Add to Wallet'
                            : 'Scratch Later',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
        ),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
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
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.title,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Service Credits & Refunds',
          style: AppTextStyle.sectionHeader,
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(AppSpacing.medium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. CRED / PhonePe Metallic Wallet Card
            _buildMetallicWalletCard(),

            SizedBox(height: AppSpacing.large),

            // 2. Add Money Section
            Text(
              'Add Service Credits',
              style: AppTextStyle.sectionHeader,
            ),
            SizedBox(height: AppSpacing.small),
            Text(
              'Use your service credits for instant 1-tap checkout on all home services & spare parts.',
              style: AppTextStyle.subtitle.copyWith(fontSize: 12),
            ),
            SizedBox(height: AppSpacing.medium),

            // Amount Input & Quick Chips
            _buildAddMoneyInputSection(),

            SizedBox(height: AppSpacing.large),

            // 3. Scratch & Earn Cashback Banner
            _buildScratchRewardsBanner(),

            SizedBox(height: AppSpacing.extraLarge),

            // 4. Real-time Transaction History Feed
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [Text('Transaction History', style: AppTextStyle.sectionHeader),
                Icon(
                  Icons.history_rounded,
                  color: AppColors.subtitle,
                  size: 20,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.medium),

            _buildTransactionHistoryFeed(),

            SizedBox(height: AppSpacing.medium),
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
          padding: EdgeInsets.all(AppSpacing.large),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF000062), Color(0xFF1A1A80), Color(0xFF000040)],
            ),
            boxShadow: [BoxShadow(
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
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.account_balance_wallet_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'BHARATHFIX CREDITS',
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
                    padding: EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFFFD700),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: Color(0xFFFFD700),
                          size: 14,
                        ),
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
              SizedBox(height: 24),
              Text(
                'Available Balance',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                '₹${balance.toStringAsFixed(2)}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [Text(
                    'Instant 1-Tap Checkout Active',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white60,
                      fontSize: 11,
                    ),
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
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
            decoration: InputDecoration(
              prefixIcon: Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Text(
                  '₹',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 0,
                minHeight: 0,
              ),
              hintText: 'Enter amount',
              filled: true,
              fillColor: AppColors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
                borderSide: BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.medium),

          // Quick Amount Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: _quickChips.map((val) {
                final isSelected =
                    _amountController.text == val.toInt().toString();
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
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
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w600,
                      color: isSelected ? AppColors.primary : AppColors.title,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          SizedBox(height: AppSpacing.large),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: _isProcessing ? null : _initiateRazorpayTopUp,
                  icon: Icon(
                    Icons.payment_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  label: _isProcessing
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Add Money (Razorpay)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isProcessing ? null : _performInstantTestTopUp,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Instant Test',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
      padding: EdgeInsets.all(AppSpacing.medium),
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
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.card_giftcard_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scratch & Win Cashbacks! 🎉',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF5D4037),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Get up to ₹500 guaranteed cashback added to your wallet on top-ups above ₹500.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF795548),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTransactionReceiptModal(
    BuildContext context,
    Map<String, dynamic> tx,
  ) {
    final bool isCredit = tx['type'] == 'CREDIT';
    final double amount = (tx['amount'] as num? ?? 0).toDouble();
    final String desc =
        tx['description'] ?? (isCredit ? 'Wallet Credit' : 'Service Payment');
    final String timeStr = tx['timestamp'] ?? DateTime.now().toString();
    final String txId =
        tx['id'] ??
        tx['razorpayPaymentId'] ??
        'TXN${DateTime.now().millisecondsSinceEpoch}';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(AppSpacing.medium),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
                SizedBox(width: 8),
                Text(
                  'BharathFix Digital Tax Invoice',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.title,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Transaction Reference:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        txId,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Description:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: AppColors.subtitle,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          desc,
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date & Time:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: AppColors.subtitle,
                        ),
                      ),
                      Text(
                        timeStr.length > 19
                            ? timeStr.substring(0, 19)
                            : timeStr,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          color: AppColors.title,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Status:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: AppColors.subtitle,
                        ),
                      ),
                      Text(
                        'SUCCESSFUL ✅',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount:',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.title,
                        ),
                      ),
                      Text(
                        '${isCredit ? "+" : "-"}₹${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isCredit
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFFC62828),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Downloading Tax Receipt PDF for $txId...'),
                    backgroundColor: AppColors.primary,
                  ),
                );
              },
              icon: Icon(
                Icons.download_rounded,
                color: Colors.white,
                size: 18,
              ),
              label: Text(
                'Download Receipt / PDF',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionHistoryFeed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transaction History',
              style: AppTextStyle.sectionHeader,
            ),
            Row(
              children: [
                _buildFilterChip('All', 'ALL'),
                SizedBox(width: 4),
                _buildFilterChip('Credits', 'CREDIT'),
                SizedBox(width: 4),
                _buildFilterChip('Debits', 'DEBIT'),
              ],
            ),
          ],
        ),
        SizedBox(height: AppSpacing.medium),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: DatabaseService().walletTransactionsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            final rawTxs = snapshot.data ?? [];
            final txs = rawTxs.where((tx) {
              if (_selectedTxFilter == 'CREDIT') return tx['type'] == 'CREDIT';
              if (_selectedTxFilter == 'DEBIT') return tx['type'] == 'DEBIT';
              return true;
            }).toList();

            if (txs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: EdgeInsets.all(AppSpacing.large),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 40,
                      color: AppColors.subtitle,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'No Matching Transactions',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontWeight: FontWeight.bold,
                        color: AppColors.title,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'No transactions found for the selected filter.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: AppColors.subtitle,
                      ),
                    ),
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
                final String desc =
                    tx['description'] ??
                    (isCredit ? 'Wallet Credit' : 'Service Payment');
                final String timeStr = tx['timestamp'] ?? '';

                return InkWell(
                  onTap: () => _showTransactionReceiptModal(context, tx),
                  child: Container(
                    margin: EdgeInsets.only(bottom: AppSpacing.small),
                    padding: EdgeInsets.all(AppSpacing.medium),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isCredit
                                ? const Color(0xFFE8F5E9)
                                : const Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCredit
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: isCredit
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                            size: 18,
                          ),
                        ),
                        SizedBox(width: AppSpacing.medium),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                desc,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.title,
                                ),
                              ),
                              SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    timeStr.length > 10
                                        ? timeStr.substring(0, 10)
                                        : timeStr,
                                    style: AppTextStyle.subtitle.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    '• Receipt',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 11,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
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
                            color: isCredit
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedTxFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedTxFilter = value),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.subtitle,
          ),
        ),
      ),
    );
  }
}