import '../../services/theme_service.dart';
// lib/Home/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart'; // Import official package
import '../../models/BookingEntry.dart';
import '../../models/job_status.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../ui/widgets/common_textfield.dart';
import '../Address/address_list_screen.dart';
import '../../services/database_service.dart';
import '../../services/coupon_service.dart';
import '../../utils/app_routes.dart';
import '../Account/offers_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final String serviceTitle;
  final String priceString;
  final String bannerImage;

  const CheckoutScreen({
    super.key,
    required this.serviceTitle,
    required this.priceString,
    required this.bannerImage
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  void _onThemeChanged() {
    if (mounted) setState(() {});
  }

  late Razorpay _razorpay;
  int _selectedDateIndex = 0;
  int _selectedTimeIndex = 0;

  // Address and profile session fields
  String _chosenAddressDetails = "No address selected yet";
  bool _isAddressSelected = false;
  String _userPhone = "";
  String _userEmail = "";

  String? _appliedCouponCode;
  double _discountAmount = 0.0;
  final TextEditingController _couponTextController = TextEditingController(text: '');


  List<Map<String, dynamic>> _dates = [];

  final List<String> _timeSlots = [
    '9:00 AM', '11:00 AM', '1:00 PM',
    '3:00 PM', '5:00 PM', '7:00 PM'
  ];

  @override
  void initState() {
    super.initState();
    ThemeService().themeModeNotifier.addListener(_onThemeChanged);
    super.initState();
    _generate30DaysList();
    _razorpay = Razorpay();

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _loadUserProfileAndAddresses();
  }

  void _generate30DaysList() {
    final now = DateTime.now();
    final List<Map<String, dynamic>> list = [];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

    for (int i = 0; i < 30; i++) {
      final d = now.add(Duration(days: i));
      String dayStr;
      if (i == 0) {
        dayStr = 'Today';
      } else if (i == 1) {
        dayStr = 'Tomorrow';
      } else {
        dayStr = days[d.weekday % 7];
      }
      list.add({
        'fullDate': d,
        'day': dayStr,
        'num': d.day.toString(),
        'month': months[d.month - 1],
      });
    }
    _dates = list;
  }

  Future<void> _openCalendarPicker() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dates[_selectedDateIndex]['fullDate'] as DateTime? ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.title,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && mounted) {
      final index = _dates.indexWhere((d) {
        final dt = d['fullDate'] as DateTime;
        return dt.year == pickedDate.year &&
            dt.month == pickedDate.month &&
            dt.day == pickedDate.day;
      });

      if (index != -1) {
        setState(() {
          _selectedDateIndex = index;
        });
        _fetchBookedSlotsForSelectedDate();
      }
    }
  }

  Future<void> _openClockTimePicker() async {
    final now = DateTime.now();
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.title,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime != null && mounted) {
      final selectedFullDate = _dates[_selectedDateIndex]['fullDate'] as DateTime;
      final isToday = selectedFullDate.year == now.year &&
          selectedFullDate.month == now.month &&
          selectedFullDate.day == now.day;

      if (isToday) {
        final currentTime = TimeOfDay.now();
        if (pickedTime.hour < currentTime.hour ||
            (pickedTime.hour == currentTime.hour && pickedTime.minute < currentTime.minute)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a future time slot for today!'),
              backgroundColor: Colors.redAccent,
            ),
          );
          return;
        }
      }

      final formattedTime = pickedTime.format(context);
      setState(() {
        if (!_timeSlots.contains(formattedTime)) {
          _timeSlots.add(formattedTime);
        }
        _selectedTimeIndex = _timeSlots.indexOf(formattedTime);
      });
    }
  }


  Future<void> _loadUserProfileAndAddresses() async {
    final profile = await DatabaseService().fetchProfile();
    if (profile != null && mounted) {
      setState(() {
        _userPhone = profile['phone'] ?? "";
        _userEmail = profile['email'] ?? "";
      });
    }

    final addresses = await DatabaseService().fetchAddresses();
    if (addresses.isNotEmpty && mounted) {
      setState(() {
        _chosenAddressDetails = addresses.first['details'] ?? '';
        _isAddressSelected = true;
      });
    }
  }

  @override
  void dispose() {
    ThemeService().themeModeNotifier.removeListener(_onThemeChanged);
    // Clean up channel links to prevent context thread leaks
    _razorpay.clear();
    super.dispose();
  }

  void _openRazorpayGateway() {
    if (!_isAddressSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid service address first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    double finalAmount = _getFinalPayableAmount();
    int amountInPaise = (finalAmount * 100).toInt();

    var options = {
      'key': 'rzp_test_dENdzkIZ1Qkpqv', // Your exact provided live workflow testing key
      'amount': amountInPaise,
      'name': 'BharathFix',
      'description': widget.serviceTitle,
      'timeout': 300, // 5 minutes window
      'prefill': {
        'contact': _userPhone,
        'email': _userEmail
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error launching Razorpay: $e');
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final chosenDate = _dates[_selectedDateIndex];
    final chosenTime = _timeSlots[_selectedTimeIndex];
    final formattedTimestamp = '${chosenDate['num']}/${chosenDate['day']}/2026, $chosenTime';

    final successBooking = BookingEntry(
      id: response.paymentId ?? 'bf_${DateTime.now().millisecondsSinceEpoch}',
      title: widget.serviceTitle,
      dateTime: formattedTimestamp,
      visitingFee: _getFinalPayableAmount(),
      address: _chosenAddressDetails,
      status: JobStatus.booked,
      paymentMode: 'ONLINE',
      isVisitingFeePaid: true,
      isSynced: 0,
    );

    try {
      // Save to local sqflite & Firebase Firestore
      await DatabaseService().insertBooking(successBooking);
    } catch (e) {
      debugPrint('Booking insertion error (proceeding to success screen): $e');
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

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('External Wallet Selected: ${response.walletName}'),
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: Text('Checkout', style: AppTextStyle.sectionHeader),
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
                  _buildServiceSummaryCard(),
                  SizedBox(height: AppSpacing.large),
                  _buildAddressSection(),
                  SizedBox(height: AppSpacing.large),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Choose date', style: AppTextStyle.bodyBold),
                      InkWell(
                        onTap: _openCalendarPicker,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Calendar 📅',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.small),
                  _buildDateCarousel(),
                  SizedBox(height: AppSpacing.large),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Choose time', style: AppTextStyle.bodyBold),
                      InkWell(
                        onTap: _openClockTimePicker,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.access_time_rounded, size: 16, color: AppColors.primary),
                              SizedBox(width: 4),
                              Text(
                                'Custom Time ⏰',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: AppSpacing.small),
                  _buildTimeGrid(),

                  SizedBox(height: AppSpacing.large),
                  _buildCouponSection(),
                  SizedBox(height: AppSpacing.large),
                  Text('Notes for provider (optional)', style: AppTextStyle.bodyBold),
                  SizedBox(height: AppSpacing.small),
                  const CommonTextField(hintText: 'Any specific instructions?'),
                  SizedBox(height: AppSpacing.large),
                  _buildPaymentMethodsSection(),
                  SizedBox(height: AppSpacing.large),
                  _buildBillDetailsSection(),
                  SizedBox(height: AppSpacing.medium),
                ],
              ),
            ),
          ),
          _buildPaymentStickyBottomBar(),
        ],
      ),
    );
  }

  Widget _buildServiceSummaryCard() {
    return Container(
      padding: EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(AppRadius.large)),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              image: DecorationImage(image: NetworkImage(widget.bannerImage), fit: BoxFit.cover),
            ),
          ),
          SizedBox(width: AppSpacing.medium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.serviceTitle, style: AppTextStyle.cardTitle),
                SizedBox(height: 4),
                Text('Visit & Inspection Charge • ${widget.priceString}', style: AppTextStyle.subtitle),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Address', style: AppTextStyle.bodyBold),
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
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: _isAddressSelected ? AppColors.title : AppColors.subtitle,
                    ),
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

  Widget _buildDateCarousel() {
    return SizedBox(
      height: 76,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _dates.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedDateIndex == index;
          final item = _dates[index];
          return GestureDetector(
            onTap: () {
              setState(() => _selectedDateIndex = index);
              _fetchBookedSlotsForSelectedDate();
            },
            child: Container(
              width: 68,
              margin: EdgeInsets.only(right: AppSpacing.small),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item['day'].toString(),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : AppColors.subtitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    item['num'].toString(),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      color: isSelected ? Colors.white : AppColors.title,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item['month'].toString(),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      color: isSelected ? Colors.white70 : AppColors.subtitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }


  Set<String> _bookedTimeSlots = {};

  Future<void> _fetchBookedSlotsForSelectedDate() async {
    final selectedDateNum = _dates[_selectedDateIndex]['num'];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .get();
      
      final Set<String> bookedSlots = {};
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dt = data['dateTime'] as String? ?? '';
        final status = data['status'] as String? ?? '';
        if (status != 'CANCELLED' && dt.contains(selectedDateNum!)) {
          for (final slot in _timeSlots) {
            if (dt.contains(slot)) {
              bookedSlots.add(slot);
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _bookedTimeSlots = bookedSlots;
        });
      }
    } catch (e) {
      debugPrint('Error fetching booked slots: $e');
    }
  }

  Widget _buildTimeGrid() {
    return Wrap(
      spacing: AppSpacing.small,
      runSpacing: AppSpacing.small,
      children: List.generate(_timeSlots.length, (index) {
        final slot = _timeSlots[index];
        final isSelected = _selectedTimeIndex == index;
        final isBooked = _bookedTimeSlots.contains(slot);

        return GestureDetector(
          onTap: isBooked ? null : () => setState(() => _selectedTimeIndex = index),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isBooked
                  ? Colors.grey.shade200
                  : (isSelected ? AppColors.primary : AppColors.background),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isBooked
                    ? Colors.grey.shade300
                    : (isSelected ? AppColors.primary : AppColors.border),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  slot,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isBooked
                        ? Colors.grey.shade500
                        : (isSelected ? Colors.white : AppColors.title),
                    decoration: isBooked ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (isBooked) ...[
                  SizedBox(width: 6),
                  Text(
                    '(Full)',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.red.shade400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }),
    );
  }

  String _selectedPaymentMethod = 'WALLET'; // Default to WALLET for 1-tap experience

  void _handleWalletPayment(double orderAmount, double availableBalance) async {
    if (!_isAddressSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid service address first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (availableBalance < orderAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Insufficient wallet balance (₹${availableBalance.toStringAsFixed(0)}). Please add money or choose another payment method.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    final bookingId = 'bf_w_${DateTime.now().millisecondsSinceEpoch}';
    final success = await DatabaseService().debitWallet(
      amount: orderAmount,
      description: 'Paid for ${widget.serviceTitle}',
      bookingId: bookingId,
    );

    if (mounted) {
      Navigator.pop(context); // Dismiss loading
    }

    if (success) {
      final chosenDate = _dates[_selectedDateIndex];
      final chosenTime = _timeSlots[_selectedTimeIndex];
      final formattedTimestamp = '${chosenDate['num']}/${chosenDate['day']}/2026, $chosenTime';

      final successBooking = BookingEntry(
        id: bookingId,
        title: widget.serviceTitle,
        dateTime: formattedTimestamp,
        visitingFee: _getFinalPayableAmount(),
        address: _chosenAddressDetails,
        status: JobStatus.booked,
        paymentMode: 'WALLET',
        isVisitingFeePaid: true,
        isSynced: 0,
      );

      try {
        await DatabaseService().insertBooking(successBooking);
      } catch (e) {
        debugPrint('Booking insertion error: $e');
      }

      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.bookingSuccess,
          arguments: successBooking,
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wallet debit failed. Please try again.'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _confirmAndProcessCODPayment() {
    if (!_isAddressSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid service address first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final payableAmount = _getFinalPayableAmount();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
          title: Row(
            children: [Icon(Icons.payments_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text("Confirm Cash Payment", style: AppTextStyle.sectionHeader),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Pay on Service Completion",
                style: AppTextStyle.bodyBold,
              ),
              SizedBox(height: 8),
              Text(
                "Please pay ₹${payableAmount.toStringAsFixed(0)} in cash directly to your technician after job completion.",
                style: AppTextStyle.subtitle.copyWith(fontSize: 14, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _handleCODPayment();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
              child: Text("Confirm & Book", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _handleCODPayment() async {
    if (!_isAddressSelected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid service address first!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }


    final chosenDate = _dates[_selectedDateIndex];
    final chosenTime = _timeSlots[_selectedTimeIndex];
    final formattedTimestamp = '${chosenDate['num']}/${chosenDate['day']}/2026, $chosenTime';

    final successBooking = BookingEntry(
      id: 'bf_cod_${DateTime.now().millisecondsSinceEpoch}',
      title: widget.serviceTitle,
      dateTime: formattedTimestamp,
      visitingFee: _getFinalPayableAmount(),
      address: _chosenAddressDetails,
      status: JobStatus.booked,
      paymentMode: 'COD',
      isVisitingFeePaid: false,
      isSynced: 0,
    );

    try {
      await DatabaseService().insertBooking(successBooking);
    } catch (e) {
      debugPrint('Booking insertion error: $e');
    }

    if (mounted) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.bookingSuccess,
        arguments: successBooking,
      );
    }
  }

  Widget _buildPaymentMethodsSection() {
    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    double orderAmount = double.tryParse(cleanPrice) ?? 199.0;

    return StreamBuilder<double>(
      stream: DatabaseService().walletBalanceStream(),
      builder: (context, snapshot) {
        final walletBalance = snapshot.data ?? 0.0;
        final hasSufficientWallet = walletBalance >= orderAmount;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Payment Method', style: AppTextStyle.bodyBold),
            SizedBox(height: AppSpacing.medium),

            // Option 1: BharathFix Wallet
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.small),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'WALLET' ? const Color(0xFFE8ECF8) : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _selectedPaymentMethod == 'WALLET' ? AppColors.primary : AppColors.border,
                  width: _selectedPaymentMethod == 'WALLET' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'WALLET',
                groupValue: _selectedPaymentMethod,
                onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                title: Row(
                  children: [
                    Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'BharathFix Wallet',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 4),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: hasSufficientWallet ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '₹${walletBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: hasSufficientWallet ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  hasSufficientWallet ? '⚡ 1-Tap Instant Payment' : 'Insufficient balance. Top-up in Wallet.',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle),
                ),
              ),
            ),

            // Option 2: Razorpay / Online UPI / Cards
            Container(
              margin: EdgeInsets.only(bottom: AppSpacing.small),
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'RAZORPAY' ? const Color(0xFFE8ECF8) : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _selectedPaymentMethod == 'RAZORPAY' ? AppColors.primary : AppColors.border,
                  width: _selectedPaymentMethod == 'RAZORPAY' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'RAZORPAY',
                groupValue: _selectedPaymentMethod,
                onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                title: Row(
                  children: [
                    Icon(Icons.payment_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'UPI / Cards / NetBanking',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Text('Google Pay, PhonePe, Paytm & All Cards', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle)),
              ),
            ),

            // Option 3: Cash on Service
            Container(
              decoration: BoxDecoration(
                color: _selectedPaymentMethod == 'COD' ? const Color(0xFFE8ECF8) : AppColors.background,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _selectedPaymentMethod == 'COD' ? AppColors.primary : AppColors.border,
                  width: _selectedPaymentMethod == 'COD' ? 1.5 : 1,
                ),
              ),
              child: RadioListTile<String>(
                value: 'COD',
                groupValue: _selectedPaymentMethod,
                onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                title: Row(
                  children: [
                    Icon(Icons.money_rounded, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cash After Service',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                subtitle: Text('Pay technician directly upon service completion', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 12, color: AppColors.subtitle)),
              ),
            ),
          ],
        );
      },
    );
  }

  double _getFinalPayableAmount() {
    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    double basePrice = double.tryParse(cleanPrice) ?? 199.0;
    double finalAmt = basePrice - _discountAmount;
    return finalAmt < 0 ? 0.0 : finalAmt;
  }

  void _applyCouponCode(String code) async {
    final upper = code.trim().toUpperCase();
    if (upper.isEmpty) return;

    String cleanPrice = widget.priceString.replaceAll('₹', '').replaceAll(',', '').trim();
    double basePrice = double.tryParse(cleanPrice) ?? 199.0;

    final result = await CouponService().validateAndApplyCoupon(upper, basePrice);

    if (!mounted) return;

    if (result['success'] == true) {
      final double discount = (result['discountAmount'] as num?)?.toDouble() ?? 0.0;
      setState(() {
        _appliedCouponCode = upper;
        _discountAmount = discount;
        _couponTextController.text = upper;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.stars_rounded, color: Color(0xFFFFD700)),
              SizedBox(width: 10),
              Expanded(child: Text(result['message'] ?? 'Coupon applied successfully!')),
            ],
          ),
          backgroundColor: const Color(0xFF2E7D32),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Failed to apply coupon.'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
        ),
      );
    }
  }

  void _removeCoupon() {
    setState(() {
      _appliedCouponCode = null;
      _discountAmount = 0.0;
      _couponTextController.clear();
    });
  }

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Coupon', style: AppTextStyle.bodyBold),
            InkWell(
              onTap: () async {
                final selectedCode = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(builder: (context) => const OffersScreen(isSelectionMode: true)),
                );
                if (selectedCode != null && selectedCode.isNotEmpty) {
                  _applyCouponCode(selectedCode);
                }
              },
              child: Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text('View All Coupons', style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.small),
        if (_appliedCouponCode != null)
          Container(
            padding: EdgeInsets.all(AppSpacing.medium),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: const Color(0xFF81C784)),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 22),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Code "$_appliedCouponCode" Applied',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: Color(0xFF1B5E20), fontSize: 13),
                      ),
                      Text(
                        'You are saving ₹${_discountAmount.toStringAsFixed(0)} on this booking!',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', color: Color(0xFF2E7D32), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Color(0xFF2E7D32), size: 20),
                  onPressed: _removeCoupon,
                ),
              ],
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _couponTextController,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.bold, color: AppColors.title),
                  decoration: InputDecoration(
                    hintText: 'ENTER CODE',
                    hintStyle: TextStyle(fontFamily: 'Plus Jakarta Sans', color: AppColors.subtitle, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.card,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: AppColors.border)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.medium),
              InkWell(
                onTap: () => _applyCouponCode(_couponTextController.text),
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

  Widget _buildBillDetailsSection() {
    double finalPayable = _getFinalPayableAmount();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bill Details', style: AppTextStyle.bodyBold),
        SizedBox(height: AppSpacing.medium),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Inspection Visit Fee', style: AppTextStyle.subtitle.copyWith(fontSize: 14)),
            Text(widget.priceString, style: AppTextStyle.bodyBold),
          ],
        ),
        if (_appliedCouponCode != null && _discountAmount > 0) ...[
          SizedBox(height: AppSpacing.small),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Coupon Discount ($_appliedCouponCode)', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 13, color: Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
              Text('-₹${_discountAmount.toStringAsFixed(0)}', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: Color(0xFF2E7D32), fontWeight: FontWeight.bold)),
            ],
          ),
        ],
        SizedBox(height: AppSpacing.small),
        Divider(color: AppColors.border, thickness: 1),
        SizedBox(height: AppSpacing.small),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total payable', style: AppTextStyle.bodyBold),
            Text('₹${finalPayable.toStringAsFixed(0)}', style: AppTextStyle.mainTitle.copyWith(fontSize: 18, color: AppColors.primary)),
          ],
        ),
      ],
    );
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
            'You are exploring in Guest Mode. Please sign in with your mobile number to complete your booking.',
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
            'Please complete your profile registration details before placing a booking.',
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

  Widget _buildPaymentStickyBottomBar() {
    double orderAmount = _getFinalPayableAmount();

    return StreamBuilder<double>(
      stream: DatabaseService().walletBalanceStream(),
      builder: (context, snapshot) {
        final walletBalance = snapshot.data ?? 0.0;

        return Container(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.medium, vertical: AppSpacing.small),
          decoration: BoxDecoration(color: AppColors.card, border: Border(top: BorderSide(color: AppColors.border, width: 1))),
          child: SafeArea(
            top: false,
            child: CommonButton(
              label: _selectedPaymentMethod == 'WALLET'
                  ? 'Pay ₹${orderAmount.toStringAsFixed(0)} with Wallet ⚡'
                  : (_selectedPaymentMethod == 'COD' ? 'Confirm Booking (Cash)' : 'Proceed to Pay ₹${orderAmount.toStringAsFixed(0)}'),
              onPressed: () async {
                final canProceed = await _checkGuestAndPromptLogin();
                if (!canProceed) return;

                if (_selectedPaymentMethod == 'WALLET') {
                  _handleWalletPayment(orderAmount, walletBalance);
                } else if (_selectedPaymentMethod == 'COD') {
                  _confirmAndProcessCODPayment();
                } else {

                  _openRazorpayGateway();
                }
              },
            ),
          ),
        );
      },
    );
  }
}