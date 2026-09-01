import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminInvoiceService {
  /// Generate and launch interactive PDF Invoice Viewer / Download / Print modal for Admin
  static Future<void> generateAndShowInvoice({
    required BuildContext context,
    required Map<String, dynamic> bookingData,
    required String bookingId,
  }) async {
    final pdfBytes = await buildInvoicePdf(
      bookingData: bookingData,
      bookingId: bookingId,
    );

    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdfBytes,
        name: 'BharathFix_Admin_Invoice_$bookingId.pdf',
      );
    } catch (e) {
      debugPrint('Admin Printing layoutPdf safe catch: $e');
      try {
        await Printing.sharePdf(
          bytes: pdfBytes,
          filename: 'BharathFix_Admin_Invoice_$bookingId.pdf',
        );
      } catch (err) {
        debugPrint('Admin Printing sharePdf safe catch: $err');
        if (context.mounted) {
          _showMaterialInvoiceDialog(context, bookingData, bookingId);
        }
      }
    }
  }

  /// Material Fallback Invoice Dialog when native printing plugin requires app restart
  static void _showMaterialInvoiceDialog(
    BuildContext context,
    Map<String, dynamic> bookingData,
    String bookingId,
  ) {
    final title = bookingData['title']?.toString() ?? 'Appliance Repair Service';
    final dateTime = bookingData['dateTime']?.toString() ?? 'Completed Visit';
    final double visitingFee = (bookingData['visitingFee'] as num?)?.toDouble() ?? 19.0;
    final quotationMap = bookingData['quotation'] as Map<String, dynamic>?;
    final List<dynamic> quoteItems = (quotationMap?['items'] as List<dynamic>?) ?? [];
    final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ?? 0.0;
    final double grandTotal = (bookingData['finalAmountPaid'] as num?)?.toDouble() ?? (quoteTotal + visitingFee);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset('assets/images/app_icon.jpg', width: 32, height: 32, fit: BoxFit.cover),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'BHARATHFIX TAX INVOICE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Invoice ID: #INV-$bookingId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF000062))),
              Text('Date: $dateTime', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const Divider(height: 20),
              Text('Service: $title', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 10),
              const Text('Itemized Billing:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Visiting & Inspection Fee'),
                  Text('INR ${visitingFee.toStringAsFixed(0)}'),
                ],
              ),
              for (var item in quoteItems)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text((item['title'] ?? item['name'] ?? 'Part/Labor').toString()),
                      Text('INR ${((item['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(0)}'),
                    ],
                  ),
                ),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Grand Total Paid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('INR ${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green)),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('90-DAY GUARANTEE CERTIFICATE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFFB78103))),
                    SizedBox(height: 4),
                    Text('Backed by 90-Day Free Replacement & Labor Warranty.', style: TextStyle(fontSize: 11)),
                    SizedBox(height: 6),
                    Text('Terms & Conditions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                    Text('- Valid ONLY if used with suitable voltage stabilizer where applicable.', style: TextStyle(fontSize: 10)),
                    Text('- Physical damage or 3rd party tampering voids warranty.', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Build PDF document byte array
  static Future<Uint8List> buildInvoicePdf({
    required Map<String, dynamic> bookingData,
    required String bookingId,
  }) async {
    final pdf = pw.Document();

    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/images/app_icon.jpg');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {}

    final title = bookingData['title']?.toString() ?? bookingData['categoryName']?.toString() ?? 'Appliance Repair Service';
    final dateTime = bookingData['dateTime']?.toString() ?? 'Completed Visit';
    final customerName = bookingData['customerName']?.toString() ?? bookingData['userName']?.toString() ?? 'Valued Customer';
    final customerPhone = bookingData['customerPhone']?.toString() ?? bookingData['userPhone']?.toString() ?? bookingData['phone']?.toString() ?? 'N/A';
    final address = bookingData['address']?.toString() ?? bookingData['fullAddress']?.toString() ?? 'Hassan, KA';
    final techName = bookingData['providerName']?.toString() ?? bookingData['techName']?.toString() ?? 'Master Technician';
    final techPhone = bookingData['providerPhone']?.toString() ?? bookingData['techPhone']?.toString() ?? '';
    final paymentMode = (bookingData['paymentMode']?.toString() ?? 'COD').toUpperCase();

    final double visitingFee = (bookingData['visitingFee'] as num?)?.toDouble() ?? 19.0;
    final bool isFeePaid = bookingData['isVisitingFeePaid'] == true || bookingData['isVisitingFeePaid'] == 1;

    final quotationMap = bookingData['quotation'] as Map<String, dynamic>?;
    final List<dynamic> quoteItems = (quotationMap?['items'] as List<dynamic>?) ?? [];
    final double quoteTotal = (quotationMap?['totalAmount'] as num?)?.toDouble() ??
        (bookingData['quoteTotal'] as num?)?.toDouble() ??
        0.0;

    final double grandTotal = (bookingData['finalAmountPaid'] as num?)?.toDouble() ??
        (quoteTotal + (isFeePaid ? 0.0 : visitingFee));

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          buildBackground: (pw.Context context) {
            if (logoImage == null) return pw.SizedBox();
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Center(
                child: pw.Opacity(
                  opacity: 0.06, // Subtle logo watermark
                  child: pw.Image(logoImage, width: 280, height: 280),
                ),
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner with Logo Branding
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#000062'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (logoImage != null) ...[
                          pw.Container(
                            width: 36,
                            height: 36,
                            decoration: pw.BoxDecoration(
                              shape: pw.BoxShape.circle,
                              image: pw.DecorationImage(image: logoImage, fit: pw.BoxFit.cover),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                        ],
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              'BHARATHFIX',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 22,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'Doorstep Appliance Service Solutions',
                              style: const pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'TAX INVOICE',
                          style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '#INV-$bookingId',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 11,
                          ),
                        ),
                        pw.Text(
                          'Date: $dateTime',
                          style: const pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Customer & Technician Details Section
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('CUSTOMER DETAILS', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(customerName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Phone: $customerPhone', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Address: $address', style: const pw.TextStyle(fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('SERVICE PROVIDER', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                          pw.SizedBox(height: 4),
                          pw.Text(techName, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                          if (techPhone.isNotEmpty) pw.Text('Phone: $techPhone', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Service: $title', style: const pw.TextStyle(fontSize: 10)),
                          pw.Text('Payment Mode: $paymentMode', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // Itemized Bill Table
              pw.Text('ITEMIZED BILLING SUMMARY', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Warranty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount (INR)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Row 1: Doorstep Inspection Fee
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Doorstep Inspection & Appliance Diagnosis Fee', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Standard Visit', style: const pw.TextStyle(fontSize: 10)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('INR ${visitingFee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                      ),
                    ],
                  ),
                  // Quote Items
                  for (var item in quoteItems)
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text((item['title'] ?? item['name'] ?? 'Spare Part / Labor').toString(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${item['warrantyDays'] ?? 90} Days Guarantee', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green800)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('INR ${((item['price'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                ],
              ),
              pw.SizedBox(height: 12),

              // Total Payable Box
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      border: pw.Border.all(color: PdfColors.grey400),
                      borderRadius: pw.BorderRadius.circular(6),
                    ),
                    child: pw.Column(
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Subtotal / Repair Quote:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('INR ${quoteTotal.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.SizedBox(height: 4),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Visiting Inspection Fee:', style: const pw.TextStyle(fontSize: 10)),
                            pw.Text('INR ${visitingFee.toStringAsFixed(2)}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Divider(height: 12),
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('Grand Total Paid:', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                            pw.Text('INR ${grandTotal.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),

              // 90-Day Warranty Certificate Box
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.amber50,
                  border: pw.Border.all(color: PdfColors.amber400),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      children: [
                        pw.Text('BHARATHFIX 90-DAY SERVICE GUARANTEE CERTIFICATE', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.amber900)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'All replaced spare parts and repair workmanship listed in this invoice are backed by our 90-Day Free Replacement & Labor Warranty from the date of service completion.',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey900),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),

              // Terms & Conditions Section (Strict ASCII Text Lines)
              pw.Text('TERMS & CONDITIONS', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
              pw.SizedBox(height: 4),
              pw.Text('1. Warranty is valid ONLY if the appliance is operated with a suitable voltage stabilizer (where applicable) and according to manufacturer guidelines.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text('2. Physical damage, electrical power surges/spikes, water damage, or unauthorized third-party technician tampering will render this warranty null and void.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.SizedBox(height: 2),
              pw.Text('3. For warranty claims or service support, present this digital invoice or Booking ID (#$bookingId) within 90 days of issue.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),

              pw.Spacer(),

              // Footer
              pw.Divider(color: PdfColors.grey300),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Thank you for choosing BharathFix!', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#000062'))),
                  pw.Text('Helpline: +91 9876543210 | www.bharathfix.com', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }
}
