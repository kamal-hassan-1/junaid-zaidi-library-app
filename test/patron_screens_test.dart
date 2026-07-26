import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:junaid_zaidi_library_app/data/mock_patron_data.dart';
import 'package:junaid_zaidi_library_app/models/hold.dart';
import 'package:junaid_zaidi_library_app/models/loan.dart';
import 'package:junaid_zaidi_library_app/models/patron.dart';
import 'package:junaid_zaidi_library_app/repositories/mock/mock_patron_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/patron_repository.dart';
import 'package:junaid_zaidi_library_app/screens/patron/my_holds_screen.dart';
import 'package:junaid_zaidi_library_app/screens/patron/my_loans_screen.dart';
import 'package:junaid_zaidi_library_app/theme/theme.dart';
import 'package:junaid_zaidi_library_app/widgets/ui.dart';

/// The two patron screens, against the real fixtures where the point is what a
/// student sees, and against a stub where the point is a failure.
///
/// Both screens take their repository by constructor, so none of this needs a
/// RepositoryScope — or a Firebase app, since neither screen is mounted through
/// RootShell.
void main() {
  const failureMessage =
      'Could not reach your library account. Check your connection and try again.';

  /// The Scaffold stands in for the one the More tab's Navigator wraps these
  /// screens in.
  Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
    await tester.pumpWidget(
      AppThemeProvider(
        child: MaterialApp(home: Scaffold(body: screen)),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('My Loans', () {
    testWidgets('shows the skeleton while loading, then the loans', (
      tester,
    ) async {
      await tester.pumpWidget(
        AppThemeProvider(
          child: MaterialApp(
            home: Scaffold(
              body: MyLoansScreen(
                repository: MockPatronRepository(
                  latency: const Duration(milliseconds: 300),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(ListSkeleton), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.byType(ListSkeleton), findsNothing);
      expect(find.byType(AppCard), findsNWidgets(mockLoans.length));
    });

    testWidgets('renders every loan with its title and author', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      for (final loan in mockLoans) {
        expect(find.text(loan.title), findsOneWidget);
        expect(find.text('by ${loan.author!}'), findsOneWidget);
      }
    });

    testWidgets('shows each loan its due date and how long is left', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      for (final loan in mockLoans) {
        expect(find.text('Due ${loan.dueDateLabel}'), findsOneWidget);
      }
      expect(find.text('Due today'), findsOneWidget);
    });

    testWidgets('badges the overdue, nearly due and active loans', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      for (final status in LoanStatus.values) {
        final expected = mockLoans.where((l) => l.status == status).length;
        expect(
          find.text(status.label),
          findsNWidgets(expected),
          reason: 'wrong number of "${status.label}" badges',
        );
      }
    });

    testWidgets('offers a Renew button on every loan, disabled', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      final renewButtons = tester
          .widgetList<AppButton>(find.byType(AppButton))
          .where((button) => button.label == 'Renew')
          .toList();

      expect(renewButtons, hasLength(mockLoans.length));
      expect(
        renewButtons.every((button) => button.onPressed == null),
        isTrue,
        reason: 'renewals are not implemented, so the button must be inert',
      );
      expect(find.text('Coming soon'), findsNWidgets(mockLoans.length));
    });

    testWidgets('counts the items on loan', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      expect(find.text('${mockLoans.length} items on loan'), findsOneWidget);
    });

    testWidgets('uses the singular for a single loan', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: _StubPatron(loans: [mockLoans.first])),
      );

      expect(find.text('1 item on loan'), findsOneWidget);
    });

    testWidgets('treats an empty account as empty, not broken', (tester) async {
      await pumpScreen(tester, MyLoansScreen(repository: _StubPatron()));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('Nothing on loan'), findsOneWidget);
      expect(find.byType(ErrorState), findsNothing);
    });

    testWidgets('shows the error state when the request fails', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(
          repository: _StubPatron(
            loanErrors: [const PatronException(failureMessage)],
          ),
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Loans unavailable'), findsOneWidget);
      expect(find.text(failureMessage), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('generalises an unexpected exception', (tester) async {
      await pumpScreen(
        tester,
        MyLoansScreen(repository: _StubPatron(loanErrors: [StateError('boom')])),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(
        find.text('Something went wrong. Please try again.'),
        findsOneWidget,
      );
    });

    testWidgets('retry loads the loans that failed the first time', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MyLoansScreen(
          repository: _StubPatron(
            loans: mockLoans,
            loanErrors: [const PatronException(failureMessage)],
          ),
        ),
      );
      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text(mockLoans.first.title), findsOneWidget);
    });
  });

  group('My Holds', () {
    testWidgets('renders every hold with its title and status', (tester) async {
      await pumpScreen(
        tester,
        MyHoldsScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      for (final hold in mockHolds) {
        expect(find.text(hold.title), findsOneWidget);
      }
      for (final status in HoldStatus.values) {
        final expected = mockHolds.where((h) => h.status == status).length;
        expect(find.text(status.label), findsNWidgets(expected));
      }
    });

    testWidgets('shows the queue position and pickup library', (tester) async {
      await pumpScreen(
        tester,
        MyHoldsScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      for (final hold in mockHolds) {
        expect(find.text(hold.queueLabel), findsOneWidget);
        expect(find.text('Pickup at ${hold.pickupLibrary}'), findsWidgets);
      }
    });

    testWidgets('drops the queue position once ready for pickup', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MyHoldsScreen(repository: MockPatronRepository(latency: Duration.zero)),
      );

      expect(find.text('No longer in the queue'), findsOneWidget);
      expect(find.text('Position 0 in the queue'), findsNothing);
    });

    testWidgets('treats no holds as empty, not broken', (tester) async {
      await pumpScreen(tester, MyHoldsScreen(repository: _StubPatron()));

      expect(find.byType(EmptyState), findsOneWidget);
      expect(find.text('No holds placed'), findsOneWidget);
    });

    testWidgets('shows the error state when the request fails', (tester) async {
      await pumpScreen(
        tester,
        MyHoldsScreen(
          repository: _StubPatron(
            holdErrors: [const PatronException(failureMessage)],
          ),
        ),
      );

      expect(find.byType(ErrorState), findsOneWidget);
      expect(find.text('Holds unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('retry loads the holds that failed the first time', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        MyHoldsScreen(
          repository: _StubPatron(
            holds: mockHolds,
            holdErrors: [const PatronException(failureMessage)],
          ),
        ),
      );

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorState), findsNothing);
      expect(find.text(mockHolds.first.title), findsOneWidget);
    });
  });
}

/// A patron repository whose answers the test dictates.
///
/// Errors are consumed one per call, so a list of one error followed by real
/// data is how the retry paths get exercised.
class _StubPatron implements PatronRepository {
  final List<Loan> loans;
  final List<Hold> holds;
  final List<Object> loanErrors;
  final List<Object> holdErrors;

  _StubPatron({
    this.loans = const [],
    this.holds = const [],
    this.loanErrors = const [],
    this.holdErrors = const [],
  });

  int _loanCalls = 0;
  int _holdCalls = 0;

  @override
  Future<Patron> getPatron() async => mockPatron;

  @override
  Future<List<Loan>> getLoans() async {
    final call = _loanCalls++;
    if (call < loanErrors.length) throw loanErrors[call];
    return loans;
  }

  @override
  Future<List<Hold>> getHolds() async {
    final call = _holdCalls++;
    if (call < holdErrors.length) throw holdErrors[call];
    return holds;
  }
}
