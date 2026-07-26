/// Where a reservation has got to.
///
/// Koha tracks more than this — suspended holds, holds whose pickup window has
/// expired — but those collapse into [waiting] here, the same way
/// `ItemAvailability` collapses Koha's longer item-status list. A student only
/// needs to know whether to walk over and collect the book.
enum HoldStatus {
  /// In the queue; no copy allocated yet.
  waiting,

  /// A copy is on its way to the pickup branch.
  inTransit,

  /// On the hold shelf, waiting to be collected.
  readyForPickup;

  String get label => switch (this) {
    HoldStatus.waiting => 'Waiting',
    HoldStatus.inTransit => 'In transit',
    HoldStatus.readyForPickup => 'Ready for pickup',
  };

  /// Maps onto AppBadge's `intent` values. Only [readyForPickup] is 'success',
  /// since it is the only one that means the student can do something.
  String get badgeIntent => switch (this) {
    HoldStatus.waiting => 'neutral',
    HoldStatus.inTransit => 'info',
    HoldStatus.readyForPickup => 'success',
  };
}

/// A reservation the student has placed. Koha calls this a hold or a reserve.
class Hold {
  final String id;
  final String biblioId;
  final String title;
  final String? author;

  /// Place in the queue, 1-based, or null once the hold is
  /// [HoldStatus.readyForPickup] and there is no queue left to be in. Koha
  /// zeroes its `priority` at that point; null says the same thing without
  /// inviting "position 0" to reach the screen.
  final int? queuePosition;

  /// Branch the copy is being held at, which is not necessarily the patron's
  /// home library.
  final String pickupLibrary;

  final HoldStatus status;

  const Hold({
    required this.id,
    required this.biblioId,
    required this.title,
    this.author,
    this.queuePosition,
    required this.pickupLibrary,
    required this.status,
  });

  /// Queue position in words, so the screen doesn't have to special-case the
  /// null.
  String get queueLabel {
    final position = queuePosition;
    if (position == null) return 'No longer in the queue';
    return 'Position $position in the queue';
  }
}
