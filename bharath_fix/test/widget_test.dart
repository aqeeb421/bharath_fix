import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix/ui/widgets/common_button.dart';
import 'package:bharath_fix/ui/widgets/app_state_widgets.dart';

void main() {
  testWidgets('CommonButton renders label and triggers callback', (WidgetTester tester) async {
    bool tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CommonButton(
            label: 'Book Service Now',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Book Service Now'), findsOneWidget);
    await tester.tap(find.text('Book Service Now'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('EmptyStateWidget renders title, message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: EmptyStateWidget(
            title: 'No Orders Placed Yet',
            message: 'Your store orders will appear here.',
            icon: Icons.local_shipping_outlined,
          ),
        ),
      ),
    );

    expect(find.text('No Orders Placed Yet'), findsOneWidget);
    expect(find.text('Your store orders will appear here.'), findsOneWidget);
    expect(find.byIcon(Icons.local_shipping_outlined), findsOneWidget);
  });
}
