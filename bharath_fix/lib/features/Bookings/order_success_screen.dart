import 'package:flutter/material.dart';
import '../../models/OrderModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';
import '../../ui/widgets/common_button.dart';
import '../../utils/app_routes.dart';

class OrderSuccessScreen extends StatelessWidget {
  final OrderModel order;

  const OrderSuccessScreen({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Order Status',
          style: AppTextStyle.sectionHeader,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    SizedBox(height: AppSpacing.medium),
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.shopping_bag_rounded,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.medium),
                    Text(
                      'Order Confirmed! 🎉',
                      style: AppTextStyle.mainTitle.copyWith(
                        fontSize: 24,
                        color: AppColors.primary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Your order #${order.id} has been placed successfully and is being prepared for dispatch.',
                      style: AppTextStyle.subtitle,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Delivery OTP Card
                    Container(
                      padding: EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.security_rounded, color: AppColors.primary, size: 28),
                          SizedBox(width: AppSpacing.medium),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery Verification OTP',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.subtitle,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  order.deliveryOtp,
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 4,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Share at delivery',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11,
                              color: AppColors.subtitle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: AppSpacing.large),

                    // Item & Order Card
                    Container(
                      padding: EdgeInsets.all(AppSpacing.medium),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(AppRadius.large),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  order.productImage.isNotEmpty
                                      ? order.productImage
                                      : 'https://images.unsplash.com/photo-1585771724684-38269d6639fd?w=200',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey.shade200,
                                    child: Icon(Icons.dry_cleaning_rounded, color: Colors.grey),
                                  ),
                                ),
                              ),
                              SizedBox(width: AppSpacing.medium),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.productName,
                                      style: AppTextStyle.bodyBold,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Qty: ${order.quantity} • ₹${order.totalPaid.toStringAsFixed(0)} Paid',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          Divider(height: AppSpacing.large * 2),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.local_shipping_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Expected Delivery', style: AppTextStyle.bodyBold),
                                    SizedBox(height: 2),
                                    Text(
                                      order.expectedDeliveryDate ?? 'Within 2-3 business days',
                                      style: AppTextStyle.subtitle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: AppSpacing.medium),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Delivery Address', style: AppTextStyle.bodyBold),
                                    SizedBox(height: 2),
                                    Text(
                                      order.deliveryAddress,
                                      style: AppTextStyle.subtitle,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Actions
            Padding(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: Column(
                children: [
                  CommonButton(
                    label: 'Track Order',
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.bookings,
                        (route) => false,
                        arguments: 1, // Open Orders tab
                      );
                    },
                  ),
                  SizedBox(height: AppSpacing.small),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.home,
                        (route) => false,
                      );
                    },
                    child: Text(
                      'Back to Home',
                      style: AppTextStyle.bodyBold.copyWith(color: AppColors.subtitle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
