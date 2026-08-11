import 'package:flutter/material.dart';
import '../../models/BookingEntry.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';

class BookingSuccessScreen extends StatefulWidget {
  const BookingSuccessScreen({super.key});

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = ModalRoute.of(context)?.settings.arguments as BookingEntry?;

    if (booking == null) {
      return const Scaffold(
        body: Center(child: Text("No booking details found.")),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.large,
            vertical: AppSpacing.medium,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Animated Success Check Circle
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  height: 96,
                  width: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.accentGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 64,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.large),

              ScaleTransition(
                scale: _scaleAnimation,
                child: const Text(
                  'Booking Successful!',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: AppColors.title,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.small),

              Text(
                'We have logged your order. A background-verified professional is being assigned.',
                style: AppTextStyle.subtitle,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.extraLarge),

              // Detailed Bill Details Receipt Card
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Booking ID: ${booking.id}',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          color: AppColors.subtitle,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),

                      _buildReceiptRow(
                        'Service / Product',
                        booking.title,
                        isBold: true,
                      ),
                      const SizedBox(height: AppSpacing.small),
                      _buildReceiptRow('Schedule Date', booking.dateTime),
                      const SizedBox(height: AppSpacing.small),
                      _buildReceiptRow(
                        'Total Paid',
                        booking.cost,
                        valueColor: AppColors.primary,
                        isBold: true,
                      ),

                      if (booking.address.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.small),
                        _buildReceiptRow('Location', booking.address),
                      ],
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Sticky bottom action buttons
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    CommonButton(
                      label: 'Track Booking',
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/dashboard',
                          (route) => false,
                          arguments: 1,
                        );
                      },
                    ),

                    const SizedBox(height: AppSpacing.small),
                    OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/dashboard',
                          (route) => false,
                          arguments: 0,
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        side: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.button),
                        ),
                      ),
                      child: const Text(
                        'Back to Home',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: AppColors.subtitle,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: AppSpacing.large),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: valueColor ?? AppColors.title,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
