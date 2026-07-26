/// Availability of a single physical copy. Koha exposes a wider set of
/// item statuses (lost, damaged, in transit, withdrawn, ...); those all
/// collapse into [unavailable] here, since a student only needs to know
/// whether they can walk up and borrow the copy today.
enum ItemAvailability {
  available,
  checkedOut,
  reference,
  unavailable;

  /// Parses the backend's string form. Unknown values deliberately fall
  /// through to [unavailable] rather than throwing — a status this app
  /// doesn't recognize should never be presented as borrowable.
  static ItemAvailability fromApi(String? value) {
    switch (value) {
      case 'available':
        return ItemAvailability.available;
      case 'checked_out':
        return ItemAvailability.checkedOut;
      case 'reference':
        return ItemAvailability.reference;
      default:
        return ItemAvailability.unavailable;
    }
  }

  String get label {
    switch (this) {
      case ItemAvailability.available:
        return 'Available';
      case ItemAvailability.checkedOut:
        return 'Checked out';
      case ItemAvailability.reference:
        return 'Reference only';
      case ItemAvailability.unavailable:
        return 'Unavailable';
    }
  }

  /// Maps onto AppBadge's `intent` values. Lives here rather than in the
  /// screens so the results list and the detail screen can't drift apart
  /// on what colour a given status is.
  String get badgeIntent {
    switch (this) {
      case ItemAvailability.available:
        return 'success';
      case ItemAvailability.checkedOut:
        return 'warning';
      case ItemAvailability.reference:
        return 'info';
      case ItemAvailability.unavailable:
        return 'error';
    }
  }
}

/// One physical copy of a catalog record — what Koha calls an item, as
/// opposed to the bibliographic record ([CatalogItem]) it belongs to.
class CatalogHolding {
  final String itemId;
  final String library;
  final String callNumber;
  final ItemAvailability availability;

  /// Only set when [availability] is [ItemAvailability.checkedOut].
  final DateTime? dueDate;

  const CatalogHolding({
    required this.itemId,
    required this.library,
    required this.callNumber,
    required this.availability,
    this.dueDate,
  });

  factory CatalogHolding.fromJson(Map<String, dynamic> json) {
    final due = json['dueDate'] as String?;
    return CatalogHolding(
      itemId: json['itemId']?.toString() ?? '',
      library: json['library'] as String? ?? '',
      callNumber: json['callNumber'] as String? ?? '',
      availability: ItemAvailability.fromApi(json['availability'] as String?),
      dueDate: due == null ? null : DateTime.tryParse(due),
    );
  }
}
