/// Which field a catalog search is scoped to — the mobile equivalent of
/// the index dropdown in Koha's OPAC masthead ("Library catalog", Title,
/// Author, Subject, ISBN, ISSN, Series, Call number).
///
/// Phase 1 ships the four that cover almost all student intent. Subject,
/// ISSN, Series and Call number are deliberately left out for now; adding
/// one later is a single enum case plus a branch in each CatalogRepository.
///
/// [apiValue] is the `index=` query parameter the backend will receive
/// once GET /api/v1/juno/search is live.
enum SearchIndex {
  keyword,
  title,
  author,
  isbn;

  String get label {
    switch (this) {
      case SearchIndex.keyword:
        return 'Keyword';
      case SearchIndex.title:
        return 'Title';
      case SearchIndex.author:
        return 'Author';
      case SearchIndex.isbn:
        return 'ISBN';
    }
  }

  /// Mirrors the web OPAC's per-index placeholder ("Search the catalog by
  /// ISBN"), which is a cheap way to make the active chip's effect
  /// obvious without a second line of explanatory text.
  String get placeholder {
    switch (this) {
      case SearchIndex.keyword:
        return 'Search the catalog...';
      case SearchIndex.title:
        return 'Search by title...';
      case SearchIndex.author:
        return 'Search by author...';
      case SearchIndex.isbn:
        return 'Search by ISBN...';
    }
  }

  String get apiValue => name;
}

/// Chip order for the search screen. `SearchIndex.values` already carries
/// the order, but going through a named list keeps the screen from
/// depending on enum declaration order for a presentational decision.
const List<SearchIndex> searchIndexes = SearchIndex.values;

const SearchIndex defaultSearchIndex = SearchIndex.keyword;
