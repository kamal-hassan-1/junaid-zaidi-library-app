/// A borrowed item currently checked out to the logged-in patron, from
/// `GET /api/v1/checkouts`.
///
/// Field names/shape confirmed against real Postman testing (see
/// deferred.md) — notably, Koha checkouts are per-*item*, not per-title:
/// there is no `biblio_id`/`title`/`author` on the raw response, only
/// `item_id`. [title]/[author] are filled in separately by
/// [CirculationService] via an item → biblio lookup, not parsed from this
/// endpoint.
class Checkout {
  final int checkoutId;
  final int itemId;
  final String? libraryId;
  final DateTime? checkoutDate;
  final DateTime? dueDate;
  final DateTime? lastRenewedDate;
  final DateTime? checkinDate;
  final bool autoRenew;

  final String? title;
  final String? author;

  const Checkout({
    required this.checkoutId,
    required this.itemId,
    this.libraryId,
    this.checkoutDate,
    this.dueDate,
    this.lastRenewedDate,
    this.checkinDate,
    this.autoRenew = false,
    this.title,
    this.author,
  });

  /// Koha doesn't expose a "renewable" flag on this endpoint (confirmed —
  /// not present in the real response) — the only way to know is to
  /// attempt the renewal and handle a rejection, so the UI always offers
  /// the action rather than trying to predict it.
  bool get isOverdue =>
      checkinDate == null && dueDate != null && dueDate!.isBefore(DateTime.now());

  Checkout withBiblioInfo({String? title, String? author}) => Checkout(
        checkoutId: checkoutId,
        itemId: itemId,
        libraryId: libraryId,
        checkoutDate: checkoutDate,
        dueDate: dueDate,
        lastRenewedDate: lastRenewedDate,
        checkinDate: checkinDate,
        autoRenew: autoRenew,
        title: title,
        author: author,
      );

  factory Checkout.fromJson(Map<String, dynamic> json) {
    return Checkout(
      checkoutId: json['checkout_id'] as int,
      itemId: json['item_id'] as int,
      libraryId: json['library_id'] as String?,
      checkoutDate: DateTime.tryParse((json['checkout_date'] as String?) ?? ''),
      dueDate: DateTime.tryParse((json['due_date'] as String?) ?? ''),
      lastRenewedDate: DateTime.tryParse((json['last_renewed_date'] as String?) ?? ''),
      checkinDate: DateTime.tryParse((json['checkin_date'] as String?) ?? ''),
      autoRenew: json['auto_renew'] as bool? ?? false,
    );
  }
}
