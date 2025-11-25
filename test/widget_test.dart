import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yakkkobak_flutter/main.dart';

void main() {
  testWidgets('Splash screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const YakKkobakApp());

    // Verify that our splash screen is present.
    expect(find.text('찰칵! 약알림'), findsOneWidget);
    expect(find.byIcon(Icons.medication), findsOneWidget);

    // Wait for the timer to finish and navigation to happen
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Verify that we are on the Home Screen
    expect(find.text('안녕하세요!\n오늘도 건강하세요.'), findsOneWidget);
  });
}
