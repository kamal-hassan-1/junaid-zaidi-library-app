/// A reservation the patron has placed on a title, from
/// `GET /api/v1/holds`. Koha holds are placed at the biblio (title)
/// level — a specific copy is only assigned once the hold is filled.
///
/// Field names/shape fully confirmed live (2026-08-18, see deferred.md):
/// placed a real test hold and inspected the response directly.
/// `status` is `null` until the hold is filled (not `'W'` until then, as
/// previously guessed) and `priority` (added this round) is a real
/// 1-indexed queue-position field — `1` means "next in line". [title]/
/// [author] aren't part of the real response at all — filled in
/// separately by [CirculationService] via a biblio lookup.
class Hold {
  final int holdId;
  final int biblioId;
  final int? itemId;
  final bool itemLevel;
  final DateTime? holdDate;
  final DateTime? expirationDate;
  final DateTime? cancellationDate;
  final String? cancellationReason;
  final String? status;
  final String? pickupLibraryId;

  /// 1-indexed queue position — `1` means next in line for this title.
  /// `null` once the hold is waiting/filled (Koha stops ranking it).
  final int? priority;

  final String? title;
  final String? author;

  const Hold({
    required this.holdId,
    required this.biblioId,
    this.itemId,
    this.itemLevel = false,
    this.holdDate,
    this.expirationDate,
    this.cancellationDate,
    this.cancellationReason,
    this.status,
    this.pickupLibraryId,
    this.priority,
    this.title,
    this.author,
  });

  bool get isCancelled => cancellationDate != null;
  bool get isWaiting => status == 'W' || status?.toLowerCase() == 'waiting';

  String get statusLabel {
    if (isCancelled) return 'Cancelled';
    if (isWaiting) return 'Ready for pickup';
    if (priority != null && priority! > 0) return 'Queue position #$priority';
    return 'Pending';
  }

  Hold withBiblioInfo({String? title, String? author}) => Hold(
        holdId: holdId,
        biblioId: biblioId,
        itemId: itemId,
        itemLevel: itemLevel,
        holdDate: holdDate,
        expirationDate: expirationDate,
        cancellationDate: cancellationDate,
        cancellationReason: cancellationReason,
        status: status,
        pickupLibraryId: pickupLibraryId,
        priority: priority,
        title: title,
        author: author,
      );

  factory Hold.fromJson(Map<String, dynamic> json) {
    return Hold(
      holdId: json['hold_id'] as int,
      biblioId: json['biblio_id'] as int,
      itemId: json['item_id'] as int?,
      itemLevel: json['item_level'] as bool? ?? false,
      holdDate: DateTime.tryParse((json['hold_date'] as String?) ?? ''),
      expirationDate: DateTime.tryParse((json['expiration_date'] as String?) ?? ''),
      cancellationDate: DateTime.tryParse((json['cancellation_date'] as String?) ?? ''),
      cancellationReason: json['cancellation_reason'] as String?,
      status: json['status'] as String?,
      pickupLibraryId: json['pickup_library_id'] as String?,
      priority: json['priority'] as int?,
    );
  }
}
