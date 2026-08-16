/// A reservation the patron has placed on a title, from
/// `GET /api/v1/holds`. Koha holds are placed at the biblio (title)
/// level — a specific copy is only assigned once the hold is filled.
///
/// Field names/shape confirmed against real Postman testing (see
/// deferred.md) for most fields — `status`/`pickupLibraryId` are the
/// exception: the screenshot they were built from was cut off before
/// showing whether/how they appear on a real `GET` response, so treat
/// those two specifically as unconfirmed. [title]/[author] aren't part
/// of the real response at all — filled in separately by
/// [CirculationService] via a biblio lookup.
class Hold {
  final int holdId;
  final int biblioId;
  final int? itemId;
  final bool itemLevel;
  final DateTime? holdDate;
  final DateTime? expirationDate;
  final DateTime? cancellationDate;
  final String? cancellationReason;

  /// Unconfirmed — see class doc.
  final String? status;
  final String? pickupLibraryId;

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
    this.title,
    this.author,
  });

  bool get isCancelled => cancellationDate != null;
  bool get isWaiting => status == 'W' || status?.toLowerCase() == 'waiting';

  String get statusLabel {
    if (isCancelled) return 'Cancelled';
    if (isWaiting) return 'Ready for pickup';
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
    );
  }
}
