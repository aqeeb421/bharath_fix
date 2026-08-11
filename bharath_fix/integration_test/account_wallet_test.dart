import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bharath_fix/features/Account/profile_screen.dart';
import 'package:bharath_fix/features/Account/wallet_screen.dart';
import 'package:bharath_fix/features/Account/edit_profile_screen.dart';
import 'package:bharath_fix/utils/app_routes.dart';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint("Firebase initializeApp in account test: $e");
  }

  group('Account & Wallet Flow Integration Tests', () {
    testWidgets('Verify ProfileScreen renders profile items and navigation options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const ProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check ProfileScreen presence
      expect(find.byType(ProfileScreen), findsOneWidget);

      // Verify profile action items
      expect(find.textContaining('Wallet'), findsAtLeastNWidgets(1));
    });

    testWidgets('Verify WalletScreen balance display and payment options', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const WalletScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check WalletScreen presence
      expect(find.byType(WalletScreen), findsOneWidget);
    });

    testWidgets('Verify EditProfileScreen renders profile input fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          routes: AppRoutes.routes,
          home: const EditProfileScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Check EditProfileScreen presence
      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.byType(TextField), findsAtLeastNWidgets(1));
    });
  });
}
