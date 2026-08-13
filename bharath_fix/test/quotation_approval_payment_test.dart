import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/models/BookingEntry.dart';
import 'package:bharath_fix/models/job_status.dart';

void main() {
  group('Quotation Approval & Service Charge Payment Logic Tests', () {
    test('Case 1: Service charge PAID during booking', () {
      final booking = BookingEntry(
        id: 'booking_101',
        title: 'AC Servicing',
        dateTime: 'Today 10:00 AM',
        visitingFee: 199.0,
        quoteTotal: 350.0,
        isVisitingFeePaid: true,
        quoteItems: [
          QuoteItem(title: 'Gas Top-up', price: 350.0),
        ],
      );

      // Since visiting fee was ALREADY paid during booking (₹199),
      // the total payable after quotation approval is ONLY the quotation amount (₹350).
      expect(booking.isVisitingFeePaid, isTrue);
      expect(booking.unpaidVisitingFee, equals(0.0));
      expect(booking.quoteTotal, equals(350.0));
      expect(booking.totalPayableAmount, equals(350.0));
    });

    test('Case 2: Service charge NOT paid during booking (COD / Pay after service)', () {
      final booking = BookingEntry(
        id: 'booking_102',
        title: 'Washing Machine Repair',
        dateTime: 'Tomorrow 2:00 PM',
        visitingFee: 199.0,
        quoteTotal: 450.0,
        isVisitingFeePaid: false,
        paymentMode: 'COD',
        quoteItems: [
          QuoteItem(title: 'Drain Pump Replacement', price: 450.0),
        ],
      );

      // Since visiting fee was NOT paid during booking (₹0 paid so far),
      // total payable after quotation approval includes Quotation Amount (₹450) + Visiting Fee (₹199) = ₹649.
      expect(booking.isVisitingFeePaid, isFalse);
      expect(booking.unpaidVisitingFee, equals(199.0));
      expect(booking.quoteTotal, equals(450.0));
      expect(booking.totalPayableAmount, equals(649.0));
    });

    test('Case 3: Quotation Decline with Paid Service Charge', () {
      final booking = BookingEntry(
        id: 'booking_103',
        title: 'Refrigerator Repair',
        dateTime: 'Today 4:00 PM',
        visitingFee: 199.0,
        quoteTotal: 1200.0,
        isVisitingFeePaid: true,
        status: JobStatus.quotationPendingApproval,
      );

      // On decline, if visiting fee was paid upfront, remaining due is ₹0.
      final remainingDue = booking.isVisitingFeePaid ? 0.0 : booking.visitingFee;
      expect(remainingDue, equals(0.0));
    });

    test('Case 4: Quotation Decline with Unpaid Service Charge', () {
      final booking = BookingEntry(
        id: 'booking_104',
        title: 'TV Repair',
        dateTime: 'Today 5:00 PM',
        visitingFee: 199.0,
        quoteTotal: 1500.0,
        isVisitingFeePaid: false,
        paymentMode: 'COD',
        status: JobStatus.quotationPendingApproval,
      );

      // On decline, if visiting fee was NOT paid upfront, customer must pay inspection fee (₹199).
      final remainingDue = booking.isVisitingFeePaid ? 0.0 : booking.visitingFee;
      expect(remainingDue, equals(199.0));
    });
  });
}
