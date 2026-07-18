import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:junaid_zaidi_library_app/main.dart';

void main() {
  testWidgets('Home screen renders with bottom tab bar', (WidgetTester tester) async {
    await tester.pumpWidget(const JunaidZaidiLibraryApp());
    await tester.pumpAndSettle();

    expect(find.text('Junaid Zaidi Library'), findsOneWidget);

    // Bottom tab labels are checked as descendants of the bottom nav bar
    // specifically, since "Explore Spaces" also appears as a Home-screen
    // resource card title (matching the original app's data/design) and
    // would otherwise make find.text ambiguous.
    final bottomNavBar = find.byType(BottomNavigationBar);
    expect(bottomNavBar, findsOneWidget);
    for (final label in ['Home', 'Library Resources', 'Explore Spaces', 'More']) {
      expect(
        find.descendant(of: bottomNavBar, matching: find.text(label)),
        findsOneWidget,
        reason: 'Expected bottom tab label "$label" to render exactly once',
      );
    }
  });
}
