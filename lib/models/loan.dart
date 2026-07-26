/// How urgent a loan is. Derived from the due date rather than stored — see
/// [Loan.statusAsOf].
///
/// No `fromApi` counterpart to `ItemAvailability.fromApi`, because nothing
/// parses this: the backend sends a date, and urgency is this app's reading of
/// it. That also keeps "due soon" consistent with whatever the UI says, since
/// there is only one definition of it.
enum LoanStatus {
  active,
  dueSoon,
  overdue;

  String get label => switch (this) {
    LoanStatus.active => 'On loan',
    LoanStatus.dueSoon => 'Due soon',
    LoanStatus.overdue => 'Overdue',
  };

  /// Maps onto AppBadge's `intent` values, for the same reason
  /// `ItemAvailability.badgeIntent` does: so two screens can't disagree about
  /// what colour "overdue" is.
  String get badgeIntent => switch (this) {
    LoanStatus.active => 'success',
    LoanStatus.dueSoon => 'warning',
    LoanStatus.overdue => 'error',
  };
}

/// One item the student currently has out. Koha calls this a checkout or issue.
///
/// [biblioId] is the catalog record it came from, so a loan can later link
/// through to `BookDetailScreen` without a second lookup.
///
/// Status is deliberately absent as a field. It is a pure function of
/// [dueDate], and storing it too is how the badge ends up saying "On loan" on
/// a book that went overdue while the screen was open.
class Loan {
  final String id;
  final String biblioId;
  final String title;
  final String? author;
  final DateTime dueDate;

  const Loan({
    required this.id,
    required this.biblioId,
    required this.title,
    this.author,
    required this.dueDate,
  });

  /// How close to the due date counts as "nearly due". A library setting
  /// really, so it will move to the backend eventually; until then one
  /// constant beats the same 3 sprinkled through the UI.
  static const int dueSoonWindowDays = 3;

  /// Takes [now] so tests can pin it. The no-argument [status] is what screens
  /// use.
  LoanStatus statusAsOf(DateTime now) {
    final days = daysUntilDueAsOf(now);
    if (days < 0) return LoanStatus.overdue;
    if (days <= dueSoonWindowDays) return LoanStatus.dueSoon;
    return LoanStatus.active;
  }

  LoanStatus get status => statusAsOf(DateTime.now());

  /// Whole days from [now] until the due date; negative once overdue.
  ///
  /// Compared date-to-date, not instant-to-instant, so a book due later today
  /// reads as "due today" rather than "due in 0.4 days" — and so the answer
  /// doesn't change as the afternoon wears on.
  int daysUntilDueAsOf(DateTime now) => _wholeDaysBetween(now, dueDate);

  int get daysUntilDue => daysUntilDueAsOf(DateTime.now());

  /// The date itself, e.g. "12 Aug 2026".
  String get dueDateLabel => _formatDate(dueDate);

  /// The date in words, e.g. "Due tomorrow" or "Overdue by 3 days" — the part
  /// a student actually acts on.
  String dueDescriptionAsOf(DateTime now) {
    final days = daysUntilDueAsOf(now);
    if (days < 0) {
      final late = -days;
      return 'Overdue by $late ${_dayNoun(late)}';
    }
    return switch (days) {
      0 => 'Due today',
      1 => 'Due tomorrow',
      _ => 'Due in $days days',
    };
  }

  String get dueDescription => dueDescriptionAsOf(DateTime.now());
}

String _dayNoun(int days) => days == 1 ? 'day' : 'days';

/// Calendar days between two instants, ignoring the time of day.
///
/// Rounded from hours rather than read off `Duration.inDays` so a daylight
/// saving shift — 23 or 25 hours between midnights — can't drop or add a day.
int _wholeDaysBetween(DateTime from, DateTime to) {
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(to.year, to.month, to.day);
  return (end.difference(start).inHours / 24).round();
}

const List<String> _monthAbbreviations = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Hand-rolled because the project has no `intl` dependency, and one date
/// format is not worth adding it for. Day-first and with a named month, so it
/// can't be misread as month-first the way a numeric date can.
String _formatDate(DateTime date) {
  final month = _monthAbbreviations[date.month - 1];
  return '${date.day} $month ${date.year}';
}
