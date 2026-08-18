/// Whether/when a title can be borrowed, computed from its items.
///
/// Built from `GET /api/v1/public/biblios/{id}/items` — confirmed live
/// against a real Koha instance (2026-08-17, see deferred.md) to be a
/// genuinely public, unauthenticated endpoint (unlike almost everything
/// else in this app's Koha integration). An item counts as available
/// when `checked_out_date` is null and it isn't lost, withdrawn,
/// damaged, or flagged not-for-loan — those are the real fields Koha
/// returns, not guessed.
enum AvailabilityStatus {
  /// At least one item can be borrowed right now.
  available,

  /// Every item exists but is currently checked out.
  checkedOut,

  /// The biblio has no items in the system at all (catalog-only record,
  /// or a title this library doesn't hold a physical/loanable copy of).
  noItems,
}

class Availability {
  final AvailabilityStatus status;
  final int totalCopies;
  final int availableCopies;

  /// Earliest due date among checked-out copies — set only when
  /// [status] is [AvailabilityStatus.checkedOut].
  final DateTime? nextDueDate;

  const Availability({
    required this.status,
    required this.totalCopies,
    required this.availableCopies,
    this.nextDueDate,
  });

  static const noItemsState = Availability(
    status: AvailabilityStatus.noItems,
    totalCopies: 0,
    availableCopies: 0,
  );

  String get label {
    switch (status) {
      case AvailabilityStatus.available:
        return availableCopies == totalCopies
            ? 'Available'
            : 'Available ($availableCopies of $totalCopies)';
      case AvailabilityStatus.checkedOut:
        final due = nextDueDate;
        return due == null
            ? 'Checked out'
            : 'Due ${due.year}-${due.month.toString().padLeft(2, '0')}-${due.day.toString().padLeft(2, '0')}';
      case AvailabilityStatus.noItems:
        return 'No items';
    }
  }

  /// Builds availability from a raw items list (`GET
  /// /api/v1/public/biblios/{id}/items` response) — real Koha field
  /// names, not guessed.
  factory Availability.fromItemsJson(List<dynamic> items) {
    if (items.isEmpty) return noItemsState;

    var available = 0;
    DateTime? earliestDue;

    for (final raw in items) {
      final item = raw as Map<String, dynamic>;
      final lost = (item['lost_status'] as num?) != null && (item['lost_status'] as num) != 0;
      final withdrawn = (item['withdrawn'] as num?) != null && (item['withdrawn'] as num) != 0;
      final damaged = (item['damaged_status'] as num?) != null && (item['damaged_status'] as num) != 0;
      final notForLoan =
          (item['not_for_loan_status'] as num?) != null && (item['not_for_loan_status'] as num) != 0;
      final checkedOutDate = item['checked_out_date'] as String?;

      if (lost || withdrawn || damaged || notForLoan) continue; // not loanable at all
      if (checkedOutDate == null) {
        available++;
      } else {
        final due = DateTime.tryParse(checkedOutDate);
        if (due != null && (earliestDue == null || due.isBefore(earliestDue))) {
          earliestDue = due;
        }
      }
    }

    return Availability(
      status: available > 0 ? AvailabilityStatus.available : AvailabilityStatus.checkedOut,
      totalCopies: items.length,
      availableCopies: available,
      nextDueDate: available > 0 ? null : earliestDue,
    );
  }
}
