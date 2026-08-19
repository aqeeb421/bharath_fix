import 'dart:math';
import '../../services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../models/BookingEntry.dart';
import '../../models/OrderModel.dart';
import '../../models/job_status.dart';
import '../Address/address_list_screen.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../../services/database_service.dart';
import '../../services/coupon_service.dart';
import '../../services/notification_service.dart';
import '../../utils/app_routes.dart';

class ProductCheckoutScreen extends StatefulWidget {
  final String productName;
  final String priceString;
  final String productImage;
  final String? productId;

  const ProductCheckoutScreen({
    super.key,
    required this.productName,
    required this.priceString,
    required this.productImage,
    this.productId,
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

  String _chosenAddressDetails = "Click to select delivery address";
  bool _isAddressSelected = false;
  String _userPhone = "";
  String _userEmail = "";

  List<Map<String, String>> _deliveryDates = [];

  final TextEditingController _couponTextController = TextEditingController();
  String? _appliedCouponCode;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    _generateDynamicDeliveryDates();
    _loadUserProfile();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
  }

  void _generateDynamicDeliveryDates() {
    final now = DateTime.now();
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final List<Map<String, String>> list = [];

    for (int i = 1; i <= 5; i++) {
      final d = now.add(Duration(days: i));
      list.add({
        'day': days[d.weekday % 7],
        'num': d.day.toString(),
        'month': months[d.month - 1],
        'fullDate': '${d.day} ${months[d.month - 1]} ${d.year}',
      });
    }
    _deliveryDates = list;
  }

  Future<void> _loadUserProfile() async {
    final profile = await DatabaseService().fetchProfile();
    if (profile != null && mounted) {
      setState(() {
        _userPhone = profile['phone'] ?? '';
        _userEmail = profile['email'] ?? '';
      });
    }
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    _couponTextController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  double _getRawPrice() {
    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    return double.tryParse(cleanPrice) ?? 0.0;
  }

  double _getFinalPayableAmount() {
    double total = _getRawPrice() - _discountAmount;
    return total < 0 ? 0.0 : total;
  }

  Future<void> _applyCoupon() async {
    final rawCode = _couponTextController.text.trim();
    if (rawCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a coupon code!'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final double rawPrice = _getRawPrice();
    final result = await CouponService().validateAndApplyCoupon(
      rawCode,
      rawPrice,
      targetScope: CouponScope.productSale,
    );

    if (mounted) {
      if (result['success'] == true) {
        setState(() {
          _appliedCouponCode = result['code'];
          _discountAmount = (result['discountAmount'] as num).toDouble();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Coupon applied successfully!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Invalid coupon code'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final chosenDate = _deliveryDates.isNotEmpty ? _deliveryDates[_selectedDateIndex] : {'fullDate': '24-48 Hours'};
    final formattedTimestamp = chosenDate['fullDate'] ?? '24-48 Hours';

    final double finalPayable = _getFinalPayableAmount();
    final user = FirebaseAuth.instance.currentUser;
    final otp = (1000 + Random().nextInt(9000)).toString();

    final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';

    final double unitPrice = double.tryParse(widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim()) ?? 0.0;

    final orderModel = OrderModel(
      id: orderId,
      userId: user?.uid ?? 'guest_user',
      userName: 'Customer',
      userPhone: _userPhone.isNotEmpty ? _userPhone : (user?.phoneNumber ?? ''),
      userEmail: _userEmail.isNotEmpty ? _userEmail : (user?.email ?? ''),
      deliveryAddress: _chosenAddressDetails,
      productId: widget.productId ?? '',
      productName: widget.productName,
      productImage: widget.productImage,
      price: unitPrice,
      quantity: 1,
      discountAmount: _discountAmount,
      totalPaid: finalPayable,
      orderStatus: OrderStatus.placed,
      deliveryOtp: otp,
      paymentMode: 'ONLINE_RAZORPAY',
      isPaid: true,
      createdAt: DateTime.now(),
      expectedDeliveryDate: 'Delivery by $formattedTimestamp',
    );

    try {
      await DatabaseService().insertOrder(orderModel);
      if (widget.productId != null && widget.productId!.isNotEmpty) {
        await DatabaseService().decrementProductStock(widget.productId!);
      }

      try {
        NotificationService.sendNotificationToUser(
          userId: orderModel.userId,
          title: 'Order Confirmed! 🎉',
          body: 'Your order #${orderModel.id} for ${orderModel.productName} has been placed successfully.',
          data: {'orderId': orderModel.id, 'type': 'ORDER_CONFIRMED'},
        );
        NotificationService.sendNotificationToAdmin(
          title: 'New Product Order 🛍️',
          body: 'Order #${orderModel.id} (${orderModel.productName}) placed by ${orderModel.userName}.',
          data: {'orderId': orderModel.id, 'type': 'NEW_ORDER'},
        );
      } catch (_) {}
    } catch (e) {
      debugPrint('Product order insertion error: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.orderSuccess,
        arguments: orderModel,
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

    double finalAmount = _getFinalPayableAmount();
    int amountInPaise = (finalAmount * 100).toInt();

    final user = FirebaseAuth.instance.currentUser;
    final contactPhone = _userPhone.isNotEmpty ? _userPhone : (user?.phoneNumber ?? '9876543210');
    final contactEmail = _userEmail.isNotEmpty ? _userEmail : (user?.email ?? 'user@bharathfix.com');

    var options = {
      'key': 'rzp_test_dENdzkIZ1Qkpqv',
      'amount': amountInPaise,
      'name': 'BharathFix Retail Store',
      'description': widget.productName,
      'timeout': 300,
      'prefill': {'contact': contactPhone, 'email': contactEmail}
    };
    _razorpay.open(options);
  }

  Widget _buildShippingAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Shipping Address', style: AppTextStyle.bodyBold),
        SizedBox(height: AppSpacing.small),
        InkWell(
          onTap: () async {
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
      double totalPayable = _getFinalPayableAmount();
      double basePrice = totalPayable / 1.18;
      double gstAmount = totalPayable - basePrice;
      return {
        'base': '₹${basePrice.toStringAsFixed(2)}',
        'gst': '₹${gstAmount.toStringAsFixed(2)}',
        'discount': '₹${_discountAmount.toStringAsFixed(2)}',
        'total': '₹${totalPayable.toStringAsFixed(2)}',
      };
    } catch (e) {
      return {'base': widget.priceString, 'gst': '₹0.00', 'discount': '₹0.00', 'total': widget.priceString};
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
    if (_deliveryDates.isEmpty) return const SizedBox.shrink();
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
            Expanded(
              child: TextField(
                controller: _couponTextController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'e.g. FIRST50, WELCOME50',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: AppColors.primary)),
                ),
              ),
            ),
            SizedBox(width: AppSpacing.medium),
            InkWell(
              onTap: _applyCoupon,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.medium)),
                child: Text('Apply', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              ),
            ),
          ],
        ),
        if (_appliedCouponCode != null) ...[
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 16),
              SizedBox(width: 4),
              Text(
                'Coupon $_appliedCouponCode applied! (Saved ₹${_discountAmount.toStringAsFixed(0)})',
                style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ],
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
        if (_discountAmount > 0) ...[
          SizedBox(height: AppSpacing.small),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Coupon Discount', style: AppTextStyle.subtitle.copyWith(fontSize: 14, color: Colors.green)), Text('- ${invoice['discount']!}', style: const TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.green, fontWeight: FontWeight.bold, fontSize: 14))]),
        ],
        SizedBox(height: AppSpacing.small),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery & Installation', style: AppTextStyle.subtitle.copyWith(fontSize: 14)), Text('FREE', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13))]),
        SizedBox(height: AppSpacing.small),
        Divider(color: AppColors.border, thickness: 1),
        SizedBox(height: AppSpacing.small),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Payable Amount', style: AppTextStyle.bodyBold), Text(invoice['total']!, style: AppTextStyle.mainTitle.copyWith(fontSize: 20, color: AppColors.primary))]),
      ],
    );
  }

  Widget _buildRazorpayStickyBottomBar() {
    final totalText = '₹${_getFinalPayableAmount().toStringAsFixed(0)}';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
      decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
      child: SafeArea(
        top: false,
        child: CommonButton(label: 'Pay via Razorpay $totalText', onPressed: () => _initiateProductPurchasePayment()),
      ),
    );
  }
}