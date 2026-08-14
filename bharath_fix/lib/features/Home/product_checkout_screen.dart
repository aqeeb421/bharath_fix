import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/BookingEntry.dart';
import '../../models/job_status.dart';
import '../Address/address_list_screen.dart'; // Import address pipeline
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../../services/database_service.dart';
import '../../utils/app_routes.dart';

class ProductCheckoutScreen extends StatefulWidget {
  final String productName;
  final String priceString;
  final String productImage;

  const ProductCheckoutScreen({
    super.key,
    required this.productName,
    required this.priceString,
    required this.productImage,
  });

  @override
  State<ProductCheckoutScreen> createState() => _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends State<ProductCheckoutScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  late Razorpay _razorpay;
  int _selectedDateIndex = 0;

  // Track selected address object state
  String _chosenAddressDetails = "Click to select delivery address";
  bool _isAddressSelected = false;

  final List<Map<String, String>> _deliveryDates = [
    {'day': 'Wed', 'num': '15', 'month': 'Jul'},
    {'day': 'Thu', 'num': '16', 'month': 'Jul'},
    {'day': 'Fri', 'num': '17', 'month': 'Jul'},
  ];

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    _razorpay.clear();
    super.dispose();
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final chosenDate = _deliveryDates[_selectedDateIndex];
    final formattedTimestamp = '${chosenDate['num']} ${chosenDate['month']} 2026';

    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    double priceVal = double.tryParse(cleanPrice) ?? 6999.0;

    final successBooking = BookingEntry(
      id: response.paymentId ?? 'bf_prod_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Order: ${widget.productName}',
      dateTime: 'Delivery by $formattedTimestamp',
      visitingFee: priceVal,
      address: _chosenAddressDetails,
      status: JobStatus.booked,
      isSynced: 0,
    );

    try {
      await DatabaseService().insertBooking(successBooking);
    } catch (e) {
      debugPrint('Product booking insertion error: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingSuccess,
        arguments: successBooking,
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment Failed: ${response.message ?? "Transaction declined"}'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<bool> _checkGuestAndPromptLogin() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.account_circle_rounded, color: AppColors.primary, size: 26),
              SizedBox(width: 8),
              Text('Login Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'You are exploring in Guest Mode. Please sign in with your mobile number to complete your product purchase.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Sign In to Proceed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }

    final userModel = await DatabaseService().fetchUserProfile();
    if (userModel == null || userModel.name.trim().isEmpty) {
      if (!mounted) return false;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.assignment_ind_rounded, color: AppColors.primary, size: 26),
              SizedBox(width: 8),
              Text('Registration Required', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            'Please complete your profile registration details before purchasing a product.',
            style: TextStyle(fontSize: 14, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  AppRoutes.register,
                  arguments: {'phone': currentUser.phoneNumber ?? ''},
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text('Complete Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
      return false;
    }

    return true;
  }

  void _initiateProductPurchasePayment() async {
    final canProceed = await _checkGuestAndPromptLogin();
    if (!canProceed || !mounted) return;

    if (!_isAddressSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a valid delivery address first!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Existing Razorpay options setup remains identical...
    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    int amountInPaise = (double.parse(cleanPrice) * 100).toInt();

    var options = {
      'key': 'rzp_test_dENdzkIZ1Qkpqv',
      'amount': amountInPaise,
      'name': 'BharathFix Retail Store',
      'description': widget.productName,
      'timeout': 300,
      'prefill': {'contact': '9876543210', 'email': 'user@bharathfix.com'}
    };
    _razorpay.open(options);
  }

  // Update checkout's address selector card layout to listen for return values
  Widget _buildShippingAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping Address', style: AppTextStyle.bodyBold),
        SizedBox(height: AppSpacing.small),
        InkWell(
          onTap: () async {
            // Wait for user to tap an address inside AddressListScreen
            final selectedAddress = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddressListScreen(isSelectionMode: true)),
            );
            if (selectedAddress != null && mounted) {
              setState(() {
                _chosenAddressDetails = selectedAddress;
                _isAddressSelected = true;
              });
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: _isAddressSelected ? AppColors.primary : AppColors.border, width: _isAddressSelected ? 1.5 : 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _chosenAddressDetails,
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w500, fontSize: 14, color: _isAddressSelected ? AppColors.title : AppColors.subtitle),
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primary),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Map<String, String> _calculateInvoiceDetails() {
    try {
      String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
      double totalPayable = double.parse(cleanPrice);
      double basePrice = totalPayable / 1.18;
      double gstAmount = totalPayable - basePrice;
      return {'base': '₹${basePrice.toStringAsFixed(2)}', 'gst': '₹${gstAmount.toStringAsFixed(2)}'};
    } catch (e) {
      return {'base': widget.priceString, 'gst': '₹0.00'};
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _calculateInvoiceDetails();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.title, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Summary', style: AppTextStyle.sectionHeader),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProductSummaryCard(),
                  SizedBox(height: AppSpacing.large),
                  _buildShippingAddressSection(),
                  SizedBox(height: AppSpacing.large),
                  Text('Select Delivery Slot', style: AppTextStyle.bodyBold),
                  SizedBox(height: AppSpacing.small),
                  _buildDeliveryDateCarousel(),
                  SizedBox(height: AppSpacing.large),
                  _buildPromoCouponSection(),
                  SizedBox(height: AppSpacing.large),
                  Text('Delivery Instructions (Optional)', style: AppTextStyle.bodyBold),
                  SizedBox(height: AppSpacing.small),
                  const CommonTextField(hintText: 'Gate code, drop off with security, etc.'),
                  SizedBox(height: AppSpacing.large),
                  _buildItemizedTaxInvoiceSection(invoice),
                  SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),
          ),
          _buildRazorpayStickyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildProductSummaryCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.large), border: Border.all(color: AppColors.border)),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.medium), image: DecorationImage(image: NetworkImage(widget.productImage), fit: BoxFit.contain)),
          ),
          SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.productName, style: AppTextStyle.cardTitle),
                SizedBox(height: 4),
                Text('Includes Free Delivery & On-Site Installation', style: AppTextStyle.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryDateCarousel() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _deliveryDates.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDateIndex == index;
          return GestureDetector(
            onTap: () => setState(() => _selectedDateIndex = index),
            child: Container(
              width: 85,
              margin: EdgeInsets.only(right: AppSpacing.small),
              decoration: BoxDecoration(color: isSelected ? AppColors.primary : AppColors.background, borderRadius: BorderRadius.circular(AppRadius.medium), border: Border.all(color: isSelected ? AppColors.primary : AppColors.border)),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('${_deliveryDates[index]['day']}, ${_deliveryDates[index]['month']}', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 11, color: isSelected ? Colors.white70 : AppColors.subtitle, fontWeight: FontWeight.w500)),
                  SizedBox(height: 4),
                  Text(_deliveryDates[index]['num']!, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, color: isSelected ? Colors.white : AppColors.title, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromoCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apply Coupon', style: AppTextStyle.bodyBold),
        SizedBox(height: AppSpacing.small),
        Row(
          children: [
            Expanded(child: CommonTextField(hintText: 'PURIFIER20')),
            SizedBox(width: AppSpacing.medium),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.medium)),
                child: Text('Apply', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildItemizedTaxInvoiceSection(Map<String, String> invoice) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Details (Inclusive of Taxes)', style: AppTextStyle.bodyBold),
        SizedBox(height: AppSpacing.medium),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Item Base Price', style: AppTextStyle.subtitle.copyWith(fontSize: 14)), Text(invoice['base']!, style: AppTextStyle.subtitle.copyWith(fontSize: 14, color: AppColors.title))]),
        SizedBox(height: AppSpacing.small),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Integrated GST (18%)', style: AppTextStyle.subtitle.copyWith(fontSize: 14)), Text(invoice['gst']!, style: AppTextStyle.subtitle.copyWith(fontSize: 14, color: AppColors.title))]),
        SizedBox(height: AppSpacing.small),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery & Installation', style: AppTextStyle.subtitle.copyWith(fontSize: 14)), Text('FREE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))]),
        SizedBox(height: AppSpacing.small),
        Divider(color: AppColors.border, thickness: 1),
        SizedBox(height: AppSpacing.small),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Payable Amount', style: AppTextStyle.bodyBold), Text(widget.priceString, style: AppTextStyle.mainTitle.copyWith(fontSize: 20, color: AppColors.primary))]),
      ],
    );
  }

  Widget _buildRazorpayStickyBottomBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
      child: SafeArea(
        top: false,
        child: CommonButton(label: 'Pay via Razorpay ${widget.priceString}', onPressed: () => _initiateProductPurchasePayment()),
      ),
    );
  }
}