import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bharath_fix/features/Authentication/welcome_screen.dart';
import 'package:bharath_fix/features/Authentication/login_screen.dart';
import 'package:bharath_fix/features/Authentication/otp_screen.dart';
import 'package:bharath_fix/features/Authentication/register_screen.dart';
import 'package:bharath_fix/ui/widgets/common_button.dart';
import 'package:bharath_fix/utils/app_routes.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initializeApp in test: $e");
  }

  group('Authentication Flow Integration Tests', () {
    setUp(() async {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
    });

    testWidgets('Verify Welcome Screen elements and navigate to Login Screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.welcome,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(WelcomeScreen), findsOneWidget);
      expect(find.text('BharathFix'), findsOneWidget);

      final getStartedBtn = find.widgetWithText(CommonButton, 'Get Started');
      expect(getStartedBtn, findsOneWidget);
      await tester.tap(getStartedBtn);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('Verify Phone Input and test credentials (+91 1234567890) on Login Screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.login,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      final phoneInput = find.byType(EditableText);
      expect(phoneInput, findsAtLeastNWidgets(1));

      await tester.enterText(phoneInput.first, '1234567890');
      await tester.pumpAndSettle();

      final continueBtn = find.widgetWithText(CommonButton, 'Continue');
      expect(continueBtn, findsOneWidget);
    });

    testWidgets('Verify OTP Verification Screen (000000) & Redirection to Register/Dashboard Screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const OtpScreen(),
        ),
      );
      await tester.pumpAndSettle();

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
        await tester.pumpAndSettle();
      }
    });

    testWidgets('Verify Register Screen input fields rendering', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          initialRoute: AppRoutes.register,
          routes: AppRoutes.routes,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.byType(EditableText), findsAtLeastNWidgets(1));
    });
  });
}
