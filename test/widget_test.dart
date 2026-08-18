import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:junaid_zaidi_library_app/main.dart';

void main() {
  testWidgets('Home screen renders with bottom tab bar', (WidgetTester tester) async {
    // Provide initialDarkMode: false for the test
    await tester.pumpWidget(const JunaidZaidiLibraryApp(initialDarkMode: false));
    await tester.pumpAndSettle();

    expect(find.text('Junaid Zaidi Library'), findsOneWidget);

    final bottomNavBar = find.byType(BottomNavigationBar);
    expect(bottomNavBar, findsOneWidget);
    for (final label in ['Home', 'Search', 'Services', 'Spaces', 'More']) {
      expect(
        find.descendant(of: bottomNavBar, matching: find.text(label)),
        findsOneWidget,
        reason: 'Expected bottom tab label "$label" to render exactly once',
      );
    }
  });
}
