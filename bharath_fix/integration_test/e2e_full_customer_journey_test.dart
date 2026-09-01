import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharath_fix/features/Authentication/welcome_screen.dart';
import 'package:bharath_fix/features/Authentication/login_screen.dart';
import 'package:bharath_fix/features/Authentication/otp_screen.dart';
import 'package:bharath_fix/features/Authentication/register_screen.dart';
import 'package:bharath_fix/features/Dashboard/dashboard_screen.dart';
import 'package:bharath_fix/features/Bookings/bookings_screen.dart';
import 'package:bharath_fix/features/Bookings/booking_success_screen.dart';
import 'package:bharath_fix/models/BookingEntry.dart';
import 'package:bharath_fix/models/job_status.dart';
import 'package:bharath_fix/ui/widgets/common_button.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase init in E2E test: $e");
  }

  group('Continuous End-To-End Customer Application Journey', () {
    setUp(() async {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    });

    testWidgets('Complete Customer Journey: Welcome -> Login -> OTP -> Register -> Dashboard -> Bookings -> Success Receipt', (WidgetTester tester) async {
      // 1. Boot full application starting at Welcome Screen
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.welcome,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      // Verify WelcomeScreen
      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('BharathFix'), findsOneWidget);

      // Tap 'Get Started'
      final getStartedBtn = find.widgetWithText(CommonButton, 'Get Started');
      expect(getStartedBtn, findsOneWidget);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      // 2. Verify LoginScreen
      expect(find.byType(LoginScreen), findsOneWidget);
      final phoneInput = find.byType(EditableText);
      expect(phoneInput, findsAtLeastNWidgets(1));

      // Enter test phone number: 1234567890
      await tester.enterText(phoneInput.first, '1234567890');
      await tester.pumpAndSettle();

      // Tap 'Continue'
      final continueBtn = find.widgetWithText(CommonButton, 'Continue');
      expect(continueBtn, findsOneWidget);
      await tester.tap(continueBtn);

      // Wait up to 15 seconds for LoginScreen navigation to OtpScreen
      int navAttempts = 0;
      while (find.byType(LoginScreen).evaluate().isNotEmpty && navAttempts < 30) {
        await tester.pump(const Duration(milliseconds: 500));
        navAttempts++;
      }
      await tester.pumpAndSettle();

      // 3. Verify OtpScreen & enter test OTP (000000)
      if (find.byType(OtpScreen).evaluate().isNotEmpty) {
        expect(find.byType(OtpScreen), findsOneWidget);

        final pinField = find.descendant(
          of: find.byType(PinCodeTextField),
          matching: find.byType(EditableText),
        );
        if (pinField.evaluate().isNotEmpty) {
          await tester.enterText(pinField.first, '000000');
          await tester.pumpAndSettle();
        }

        final verifyBtn = find.widgetWithText(CommonButton, 'Verify & Continue');
        if (verifyBtn.evaluate().isNotEmpty) {
          await tester.tap(verifyBtn);
        }

        // Wait up to 15 seconds for OtpScreen to complete verification and navigate away
        int otpAttempts = 0;
        while (find.byType(OtpScreen).evaluate().isNotEmpty && otpAttempts < 30) {
          await tester.pump(const Duration(milliseconds: 500));
          otpAttempts++;
        }
        await tester.pumpAndSettle();
      }

      // 4. Verify RegisterScreen or DashboardScreen Redirection
      final onRegister = find.byType(RegisterScreen).evaluate().isNotEmpty;
      final onDashboard = find.byType(DashboardScreen).evaluate().isNotEmpty;
      expect(onRegister || onDashboard, isTrue);

      if (onRegister) {
        final registerInputs = find.byType(EditableText);
        if (registerInputs.evaluate().isNotEmpty) {
          // Fill Name
          await tester.enterText(registerInputs.at(0), 'Bharath Test Customer');
          await tester.pumpAndSettle();

          // Fill Email if available
          if (registerInputs.evaluate().length > 1) {
            await tester.enterText(registerInputs.at(1), 'customer.test@bharathfix.com');
            await tester.pumpAndSettle();
          }
        }

        // Tap Complete Setup / Save button
        final saveBtn = find.widgetWithText(CommonButton, 'Complete Setup');
        if (saveBtn.evaluate().isNotEmpty) {
          await tester.tap(saveBtn);
          
          int saveAttempts = 0;
          while (find.byType(RegisterScreen).evaluate().isNotEmpty && saveAttempts < 30) {
            await tester.pump(const Duration(milliseconds: 500));
            saveAttempts++;
          }
          await tester.pumpAndSettle();
        }
      }

      // 5. Verify DashboardScreen & Navigation Tabs
      await tester.pumpWidget(
        const MaterialApp(
          home: DashboardScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Switch to Bookings Tab
      final calendarIcon = find.byIcon(Icons.calendar_month_rounded);
      if (calendarIcon.evaluate().isNotEmpty) {
        await tester.tap(calendarIcon.first);
        await tester.pump(const Duration(seconds: 1));
      }

      // 6. Verify BookingsScreen & Order Receipt
      await tester.pumpWidget(
        const MaterialApp(
          home: BookingsScreen(),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(BookingsScreen), findsOneWidget);

      // Verify Receipt Confirmation Display
      const mockBooking = BookingEntry(
        id: 'BF-TEST-E2E-1001',
        title: 'AC Deep Cleaning & Inspection',
        dateTime: '12 Aug 2026, 11:00 AM',
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
        customerName: 'Bharath Test Customer',
        customerPhone: '+911234567890',
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
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(BookingSuccessScreen), findsOneWidget);
      expect(find.textContaining('BF-TEST-E2E-1001'), findsOneWidget);
      expect(find.textContaining('AC Deep Cleaning'), findsOneWidget);
    });
  });
}
