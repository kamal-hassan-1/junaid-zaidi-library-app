import 'catalog_holding.dart';

/// A bibliographic record — one title in the catalog, independent of how
/// many physical copies exist. Koha calls this a biblio.
///
/// Search results and the detail screen share this one model. The
/// difference is [holdings]: null means "copies not loaded yet" (search
/// results never carry them), while an empty list means "loaded, and the
/// library holds no copies". Availability *counts* are present in both
/// cases, so the results list can show a badge without a second request
/// per row.
class CatalogItem {
  final String id;
  final String title;
  final String? author;
  final String? publisher;
  final int? year;
  final String? isbn;

  /// Koha item type, e.g. "Books", "Reference", "Visual Materials".
  final String? itemType;

  final String? summary;
  final String? language;
  final List<String> subjects;

  final int availableCount;
  final int totalCount;

  final List<CatalogHolding>? holdings;

  const CatalogItem({
    required this.id,
    required this.title,
    this.author,
    this.publisher,
    this.year,
    this.isbn,
    this.itemType,
    this.summary,
    this.language,
    this.subjects = const [],
    this.availableCount = 0,
    this.totalCount = 0,
    this.holdings,
  });

  bool get isAvailable => availableCount > 0;

  /// Summary badge for the results list. Deliberately derived from the
  /// counts rather than stored as its own field — two sources for the
  /// same fact is how they end up disagreeing.
  String get availabilityLabel {
    if (totalCount == 0) return 'No copies';
    if (isAvailable) return 'Available';
    return 'All copies out';
  }

  String get availabilityBadgeIntent {
    if (totalCount == 0) return 'neutral';
    return isAvailable ? 'success' : 'warning';
  }

  /// "Author, 2019" style line for the results list, skipping whichever
  /// part is missing rather than rendering a stray comma.
  String get subtitleLine {
    final parts = <String>[
      if (author != null && author!.isNotEmpty) author!,
      if (year != null) year.toString(),
    ];
    return parts.join(' · ');
  }

  factory CatalogItem.fromJson(Map<String, dynamic> json) {
    final rawHoldings = json['holdings'] as List<dynamic>?;
    return CatalogItem(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String?,
      publisher: json['publisher'] as String?,
      year: json['year'] as int?,
      isbn: json['isbn'] as String?,
      itemType: json['itemType'] as String?,
      summary: json['summary'] as String?,
      language: json['language'] as String?,
      subjects: (json['subjects'] as List<dynamic>?)?.cast<String>() ?? const [],
      availableCount: json['availableCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      holdings: rawHoldings
          ?.map((e) => CatalogHolding.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Narrow by design, matching StudentRequest.copyWith — the only thing
  /// that ever needs replacing is the lazily-loaded holdings list.
  CatalogItem copyWith({List<CatalogHolding>? holdings}) {
    return CatalogItem(
      id: id,
      title: title,
      author: author,
      publisher: publisher,
      year: year,
      isbn: isbn,
      itemType: itemType,
      summary: summary,
      language: language,
      subjects: subjects,
      availableCount: availableCount,
      totalCount: totalCount,
      holdings: holdings ?? this.holdings,
    );
  }
}
