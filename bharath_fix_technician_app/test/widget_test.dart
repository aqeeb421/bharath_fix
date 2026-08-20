import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bharath_fix_technician_app/widgets/technician_state_widgets.dart';

void main() {
  testWidgets('TechEmptyStateWidget renders title, message and icon', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TechEmptyStateWidget(
            title: 'No Active Assigned Jobs',
            message: 'Check the Available Open Pool tab to claim new customer requests.',
            icon: Icons.assignment_turned_in_rounded,
          ),
        ),
      ),
    );

    expect(find.text('No Active Assigned Jobs'), findsOneWidget);
    expect(find.text('Check the Available Open Pool tab to claim new customer requests.'), findsOneWidget);
    expect(find.byIcon(Icons.assignment_turned_in_rounded), findsOneWidget);
  });

  testWidgets('TechLoadingStateWidget renders loading message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TechLoadingStateWidget(message: 'Loading assigned tasks...'),
        ),
      ),
    );

    expect(find.text('Loading assigned tasks...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
