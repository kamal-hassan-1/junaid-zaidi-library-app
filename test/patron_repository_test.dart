import 'package:flutter_test/flutter_test.dart';
import 'package:junaid_zaidi_library_app/models/hold.dart';
import 'package:junaid_zaidi_library_app/models/loan.dart';
import 'package:junaid_zaidi_library_app/repositories/mock/mock_patron_repository.dart';

/// The patron models and the mock repository behind My Loans and My Holds.
///
/// The models carry real logic — loan urgency is derived from the due date
/// rather than stored — so most of this is about that derivation holding at its
/// boundaries.
void main() {
  /// Fixed so "today" cannot drift mid-test.
  final now = DateTime(2026, 7, 26, 14, 30);

  Loan loanDueOn(DateTime dueDate) => Loan(
    id: 'loan-x',
    biblioId: '1',
    title: 'Introduction to Algorithms',
    author: 'Thomas H. Cormen',
    dueDate: dueDate,
  );

  group('Loan status', () {
    test('is overdue once the due date has passed', () {
      final loan = loanDueOn(DateTime(2026, 7, 25));
      expect(loan.statusAsOf(now), LoanStatus.overdue);
    });

    test('is due soon on the due date itself', () {
      // Due at 09:00 on a day that is already 14:30 — still "today", not
      // overdue, because the comparison ignores the time.
      final loan = loanDueOn(DateTime(2026, 7, 26, 9));
      expect(loan.statusAsOf(now), LoanStatus.dueSoon);
    });

    test('is due soon at the edge of the window', () {
      final loan = loanDueOn(
        DateTime(2026, 7, 26 + Loan.dueSoonWindowDays),
      );
      expect(loan.statusAsOf(now), LoanStatus.dueSoon);
    });

    test('is active one day beyond the window', () {
      final loan = loanDueOn(
        DateTime(2026, 7, 26 + Loan.dueSoonWindowDays + 1),
      );
      expect(loan.statusAsOf(now), LoanStatus.active);
    });

    test('counts whole days regardless of the time of day', () {
      // 23:59 tomorrow is one day away, not two, and 00:01 tomorrow is one day
      // away, not zero.
      expect(loanDueOn(DateTime(2026, 7, 27, 23, 59)).daysUntilDueAsOf(now), 1);
      expect(loanDueOn(DateTime(2026, 7, 27, 0, 1)).daysUntilDueAsOf(now), 1);
    });

    test('goes negative once overdue', () {
      expect(loanDueOn(DateTime(2026, 7, 23)).daysUntilDueAsOf(now), -3);
    });
  });

  group('Loan labels', () {
    test('describe the near dates in words', () {
      expect(loanDueOn(DateTime(2026, 7, 26)).dueDescriptionAsOf(now), 'Due today');
      expect(
        loanDueOn(DateTime(2026, 7, 27)).dueDescriptionAsOf(now),
        'Due tomorrow',
      );
      expect(
        loanDueOn(DateTime(2026, 7, 31)).dueDescriptionAsOf(now),
        'Due in 5 days',
      );
    });

    test('singularise a single day late', () {
      expect(
        loanDueOn(DateTime(2026, 7, 25)).dueDescriptionAsOf(now),
        'Overdue by 1 day',
      );
      expect(
        loanDueOn(DateTime(2026, 7, 24)).dueDescriptionAsOf(now),
        'Overdue by 2 days',
      );
    });

    test('format the due date day-first with a named month', () {
      expect(loanDueOn(DateTime(2026, 8, 12)).dueDateLabel, '12 Aug 2026');
      expect(loanDueOn(DateTime(2026, 1, 5)).dueDateLabel, '5 Jan 2026');
      expect(loanDueOn(DateTime(2026, 12, 31)).dueDateLabel, '31 Dec 2026');
    });

    test('give each status its own badge intent', () {
      expect(LoanStatus.active.badgeIntent, 'success');
      expect(LoanStatus.dueSoon.badgeIntent, 'warning');
      expect(LoanStatus.overdue.badgeIntent, 'error');
      expect(
        {
          LoanStatus.active.label,
          LoanStatus.dueSoon.label,
          LoanStatus.overdue.label,
        },
        hasLength(3),
      );
    });
  });

  group('Hold', () {
    Hold holdAt(int? queuePosition, HoldStatus status) => Hold(
      id: 'hold-x',
      biblioId: '2',
      title: 'Clean Code',
      queuePosition: queuePosition,
      pickupLibrary: 'Circulation Desk - Floor 1',
      status: status,
    );

    test('describes a place in the queue', () {
      expect(
        holdAt(3, HoldStatus.waiting).queueLabel,
        'Position 3 in the queue',
      );
    });

    test('says there is no queue once ready for pickup', () {
      expect(
        holdAt(null, HoldStatus.readyForPickup).queueLabel,
        'No longer in the queue',
      );
    });

    test('only marks ready for pickup as actionable', () {
      expect(HoldStatus.readyForPickup.badgeIntent, 'success');
      expect(HoldStatus.waiting.badgeIntent, 'neutral');
      expect(HoldStatus.inTransit.badgeIntent, 'info');
    });
  });

  group('MockPatronRepository', () {
    final repository = MockPatronRepository(latency: Duration.zero);

    test('returns the patron behind the session', () async {
      final patron = await repository.getPatron();

      expect(patron.name, isNotEmpty);
      expect(patron.barcode, isNotEmpty);
      expect(patron.email, contains('@'));
      expect(patron.homeLibrary, isNotEmpty);
    });

    test('returns loans soonest due first', () async {
      final loans = await repository.getLoans();

      expect(loans, isNotEmpty);
      for (var i = 1; i < loans.length; i++) {
        expect(
          loans[i].dueDate.isBefore(loans[i - 1].dueDate),
          isFalse,
          reason: 'loan $i is due before the one listed above it',
        );
      }
    });

    test('covers every loan status', () async {
      final loans = await repository.getLoans();
      final statuses = loans.map((loan) => loan.status).toSet();

      expect(statuses, containsAll(LoanStatus.values));
    });

    test('covers every hold status', () async {
      final holds = await repository.getHolds();
      final statuses = holds.map((hold) => hold.status).toSet();

      expect(statuses, containsAll(HoldStatus.values));
    });

    test('gives every loan a catalog record to point at', () async {
      final loans = await repository.getLoans();

      expect(loans.every((loan) => loan.biblioId.isNotEmpty), isTrue);
      expect(loans.map((loan) => loan.id).toSet(), hasLength(loans.length));
    });

    test('hands out lists a screen cannot mutate', () async {
      final loans = await repository.getLoans();
      final holds = await repository.getHolds();

      expect(() => loans.clear(), throwsUnsupportedError);
      expect(() => holds.clear(), throwsUnsupportedError);
    });

    test('waits for the configured latency', () async {
      final slow = MockPatronRepository(
        latency: const Duration(milliseconds: 40),
      );
      final stopwatch = Stopwatch()..start();

      await slow.getLoans();

      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(30));
    });
  });
}
