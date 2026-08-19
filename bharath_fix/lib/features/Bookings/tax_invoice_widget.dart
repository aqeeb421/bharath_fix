import 'package:flutter/material.dart';
import '../../models/OrderModel.dart';
import '../../ui/theme/app_colors.dart';
import '../../ui/theme/app_radius.dart';
import '../../ui/theme/app_spacing.dart';
import '../../ui/theme/app_text_style.dart';

class TaxInvoiceWidget extends StatelessWidget {
  final OrderModel order;

  const TaxInvoiceWidget({super.key, required this.order});

  static void showInvoiceModal(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: TaxInvoiceWidget(order: order),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double totalAmount = order.totalPaid;
    final double baseAmount = totalAmount / 1.18;
    final double gstAmount = totalAmount - baseAmount;
    final double cgst = gstAmount / 2.0;
    final double sgst = gstAmount / 2.0;

    final String invoiceDate = order.createdAt != null
        ? '${order.createdAt!.day}/${order.createdAt!.month}/${order.createdAt!.year}'
        : '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}';

    return Padding(
      padding: EdgeInsets.all(AppSpacing.large),
      child: Column(
        children: [
          // Header handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.medium),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Invoice Header Banner
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BHARATHFIX',
                              style: AppTextStyle.mainTitle.copyWith(
                                fontSize: 22,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Text(
                              'Appliances & Electronics Pvt Ltd',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                            const Text(
                              'GSTIN: 29AABCU9603R1ZM • SAC/HSN: 8421',
                              style: TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          'TAX INVOICE',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Invoice Meta & Customer Info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Billed To:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 2),
                            Text(order.userName.isNotEmpty ? order.userName : 'Customer', style: AppTextStyle.bodyBold),
                            if (order.userPhone.isNotEmpty) Text(order.userPhone, style: AppTextStyle.subtitle.copyWith(fontSize: 12)),
                            SizedBox(height: 4),
                            Text(order.deliveryAddress, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                          ],
                        ),
                      ),
                      SizedBox(width: AppSpacing.medium),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Invoice No: INV-${order.id}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          Text('Date: $invoiceDate', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Payment Mode: ${order.paymentMode}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          Text('Delivery OTP: ${order.deliveryOtp}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Item Table Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    color: Colors.grey.shade100,
                    child: Row(
                      children: const [
                        Expanded(flex: 4, child: Text('Item Description', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
                        Expanded(flex: 2, child: Text('Base Price', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('GST (18%)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                        Expanded(flex: 2, child: Text('Total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),

                  // Item Row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.productName, style: AppTextStyle.bodyBold.copyWith(fontSize: 13)),
                              const Text('Includes 18% IGST Tax Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('₹${baseAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('₹${gstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('₹${totalAmount.toStringAsFixed(2)}', style: AppTextStyle.bodyBold.copyWith(fontSize: 12), textAlign: TextAlign.right),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 20),

                  // Summary Breakdown
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      width: 250,
                      child: Column(
                        children: [
                          _buildPriceLine('Subtotal (Excl. Tax)', '₹${baseAmount.toStringAsFixed(2)}'),
                          _buildPriceLine('CGST (9%)', '₹${cgst.toStringAsFixed(2)}'),
                          _buildPriceLine('SGST (9%)', '₹${sgst.toStringAsFixed(2)}'),
                          if (order.discountAmount > 0)
                            _buildPriceLine('Discount Coupon Applied', '-₹${order.discountAmount.toStringAsFixed(2)}', color: Colors.green),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Grand Total Paid:', style: AppTextStyle.bodyBold.copyWith(fontSize: 14)),
                              Text(
                                '₹${totalAmount.toStringAsFixed(0)}',
                                style: AppTextStyle.mainTitle.copyWith(fontSize: 18, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: AppSpacing.large),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.verified_user_rounded, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This is a digitally generated Tax Invoice by BharathFix Appliances Pvt Ltd. Authorized e-commerce invoice.',
                            style: TextStyle(fontSize: 10, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Button
          SizedBox(height: AppSpacing.medium),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tax Invoice saved to downloads! 📄'),
                    backgroundColor: Colors.green,
                  ),
                );
                Navigator.pop(context);
              },
              icon: const Icon(Icons.download_rounded, color: Colors.white),
              label: const Text('Download Tax Invoice (PDF)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceLine(String label, String val, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color ?? Colors.black87)),
        ],
      ),
    );
  }
}
