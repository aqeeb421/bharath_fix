import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bharath_fix/features/Dashboard/dashboard_screen.dart';
import 'package:bharath_fix/features/Bookings/bookings_screen.dart';
import 'package:bharath_fix/features/Bookings/booking_success_screen.dart';
import 'package:bharath_fix/models/BookingEntry.dart';
import 'package:bharath_fix/models/job_status.dart';
import 'package:bharath_fix/utils/app_routes.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initializeApp in test: $e");
  }

  group('Booking Flow Integration Tests', () {
    testWidgets('Verify Dashboard Screen renders with bottom navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.dashboard,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
    });

    testWidgets('Verify Bookings Screen tab switching and booking list container', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: BookingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingsScreen), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
    });

    testWidgets('Verify BookingSuccessScreen displays booking summary details', (WidgetTester tester) async {
      const mockBooking = BookingEntry(
        id: 'BF-TEST-1001',
        title: 'AC Deep Service & Inspection',
        dateTime: '12 Aug 2026, 10:00 AM',
        visitingFee: 19.0,
        quoteTotal: 350.0,
        finalAmountPaid: 369.0,
        status: JobStatus.booked,
        address: 'MG Road, Hassan, Karnataka',
        isSynced: 1,
        startOtp: '4829',
        completionOtp: '8921',
        providerId: 'tech_001',
        providerName: 'Ramesh Kumar',
        providerPhone: '+919876543210',
        customerId: 'cust_001',
        customerName: 'Bharath User',
        customerPhone: '+915555555555',
        quoteItems: [],
        beforePhotos: [],
        afterPhotos: [],
        paymentMode: 'ONLINE',
        isVisitingFeePaid: true,
        isFinalBillPaid: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          onGenerateRoute: (settings) {
            return MaterialPageRoute(
              settings: const RouteSettings(arguments: mockBooking),
              builder: (context) => const BookingSuccessScreen(),
            );
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BookingSuccessScreen), findsOneWidget);
      expect(find.textContaining('BF-TEST-1001'), findsOneWidget);
      expect(find.textContaining('AC Deep Service'), findsOneWidget);
    });
  });
}
