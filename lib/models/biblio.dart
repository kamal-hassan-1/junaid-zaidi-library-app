/// Data model for a single bibliographic record returned by
/// `GET /api/v1/biblios`.
class Biblio {
  final int biblioId;
  final String title;
  final String? subtitle;
  final String? author;
  final String? isbn;
  final String? issn;
  final String? publisher;
  final String? publicationYear;
  final String? publicationPlace;
  final String? editionStatement;
  final String? pages;
  final String? materialSize;
  final String? medium;
  final String? illustrations;
  final String? itemType;
  final String? abstract_;
  final String? notes;
  final String? url;
  final String? ean;
  final String? volume;
  final String? volumeDescription;
  final String? volumeDate;
  final String? seriesTitle;
  final String? collectionTitle;
  final String? collectionVolume;
  final String? collectionIssn;
  final int? copyrightDate;
  final String? creationDate;
  final String? timestamp;
  final bool serial;
  final bool opacSuppressed;

  const Biblio({
    required this.biblioId,
    required this.title,
    this.subtitle,
    this.author,
    this.isbn,
    this.issn,
    this.publisher,
    this.publicationYear,
    this.publicationPlace,
    this.editionStatement,
    this.pages,
    this.materialSize,
    this.medium,
    this.illustrations,
    this.itemType,
    this.abstract_,
    this.notes,
    this.url,
    this.ean,
    this.volume,
    this.volumeDescription,
    this.volumeDate,
    this.seriesTitle,
    this.collectionTitle,
    this.collectionVolume,
    this.collectionIssn,
    this.copyrightDate,
    this.creationDate,
    this.timestamp,
    this.serial = false,
    this.opacSuppressed = false,
  });

  factory Biblio.fromJson(Map<String, dynamic> json) {
    return Biblio(
      biblioId: json['biblio_id'] as int,
      title: (json['title'] as String?) ?? 'Untitled',
      subtitle: json['subtitle'] as String?,
      author: json['author'] as String?,
      isbn: json['isbn'] as String?,
      issn: json['issn'] as String?,
      publisher: json['publisher'] as String?,
      publicationYear: json['publication_year']?.toString(),
      publicationPlace: json['publication_place'] as String?,
      editionStatement: json['edition_statement'] as String?,
      pages: json['pages'] as String?,
      materialSize: json['material_size'] as String?,
      medium: json['medium'] as String?,
      illustrations: json['illustrations'] as String?,
      itemType: json['item_type'] as String?,
      abstract_: json['abstract'] as String?,
      notes: json['notes'] as String?,
      url: json['url'] as String?,
      ean: json['ean'] as String?,
      volume: json['volume'] as String?,
      volumeDescription: json['volume_description'] as String?,
      volumeDate: json['volume_date'] as String?,
      seriesTitle: json['series_title'] as String?,
      collectionTitle: json['collection_title'] as String?,
      collectionVolume: json['collection_volume'] as String?,
      collectionIssn: json['collection_issn'] as String?,
      copyrightDate: json['copyright_date'] is int
          ? json['copyright_date'] as int
          : null,
      creationDate: json['creation_date'] as String?,
      timestamp: json['timestamp'] as String?,
      serial: json['serial'] as bool? ?? false,
      opacSuppressed: json['opac_suppressed'] as bool? ?? false,
    );
  }

  /// Human-friendly item-type label.
  String get itemTypeLabel {
    switch (itemType) {
      case 'BK':
        return 'Book';
      case 'CF':
        return 'Computer File';
      case 'CR':
        return 'Continuing Resource';
      case 'MP':
        return 'Map';
      case 'MU':
        return 'Music';
      case 'MX':
        return 'Mixed Materials';
      case 'RE':
        return 'Reference';
      case 'VM':
        return 'Visual Material';
      default:
        return itemType ?? 'Unknown';
    }
  }

  /// The best available year string for display.
  String? get displayYear =>
      publicationYear ?? (copyrightDate != null ? '$copyrightDate' : null);
}
