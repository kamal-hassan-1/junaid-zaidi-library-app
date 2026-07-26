import 'dart:math';

import '../data/mock_catalog_data.dart';
import '../data/search_indexes.dart';
import '../models/catalog_item.dart';
import '../models/catalog_search_result.dart';

/// Thrown when a catalog request fails. Callers show [message] directly —
/// it is already written to be user-facing, matching the convention
/// KohaAuthException established.
class OpacException implements Exception {
  final String message;
  const OpacException(this.message);

  @override
  String toString() => message;
}

/// A catalog request completed successfully, but the requested record no
/// longer exists. Kept distinct from [OpacException] so the detail screen
/// can show a calm not-found state instead of a network-error treatment.
class OpacNotFoundException extends OpacException {
  const OpacNotFoundException(super.message);
}

/// The catalog data source for the OPAC module.
///
/// Phase 1 answers every call from [mockCatalogItems] so the UI can be
/// built and reviewed before the backend exists. The method signatures
/// are already the ones the real implementation needs:
///
///   search()     -> GET /api/v1/juno/search?q=&index=&page=&per_page=
///   getBiblio()  -> GET /api/v1/juno/biblios/{id}
///
/// Every method is async and returns a Future even though mock lookups
/// are synchronous. That is deliberate: if these were synchronous now,
/// swapping in real HTTP calls later would change every call site and
/// every FutureBuilder in the module.
class OpacService {
  /// Simulated network delay, so loading states are actually visible
  /// while the UI is being reviewed. Tests can pass [Duration.zero].
  final Duration latency;

  OpacService({this.latency = const Duration(milliseconds: 700)});

  static const int defaultPerPage = 20;

  /// Typing this as the search term forces a failure, so the error state
  /// can be exercised on-device without unplugging anything.
  static const String _failureTrigger = 'error';

  static const int _maxRecentSearches = 6;

  /// Seeded so the landing state has something to show on a first run.
  /// In-memory and static, which is enough for Phase 1 — Phase 2 moves
  /// this behind SecureStorageService so it survives restarts, without
  /// changing either method's signature.
  static final List<String> _recentSearches = [
    'algorithms',
    'operating systems',
    'Kotler',
    '9780262033848',
  ];

  /// Records shown on the landing state before anyone has searched.
  /// Phase 2 replaces this with the student's recently viewed books.
  static const List<String> _featuredIds = ['1', '13', '17', '19', '25'];

  /// Searches the catalog, scoped to [index].
  ///
  /// [page] is 1-based, matching the backend contract.
  Future<CatalogSearchResult> search({
    required String query,
    SearchIndex index = defaultSearchIndex,
    int page = 1,
    int perPage = defaultPerPage,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const CatalogSearchResult.empty();

    await Future<void>.delayed(latency);

    if (trimmed.toLowerCase() == _failureTrigger) {
      throw const OpacException(
        'Could not reach the library catalog. Check your connection and try again.',
      );
    }

    final matches = _rank(
      mockCatalogItems.where((item) => _matches(item, trimmed, index)).toList(),
      trimmed,
    );

    final start = (page - 1) * perPage;
    if (start >= matches.length) {
      return CatalogSearchResult(
        items: const [],
        page: page,
        perPage: perPage,
        totalResults: matches.length,
        hasMore: false,
      );
    }

    final end = min(start + perPage, matches.length);
    final pageItems = matches.sublist(start, end);

    return CatalogSearchResult(
      items: pageItems,
      page: page,
      perPage: perPage,
      totalResults: matches.length,
      hasMore: end < matches.length,
    );
  }

  /// Full record for the detail screen, including its holdings.
  Future<CatalogItem> getBiblio(String id) async {
    await Future<void>.delayed(latency);

    // Mirrors search("error") so the detail screen's failure treatment can
    // be reviewed before the real endpoint exists.
    if (id.toLowerCase() == _failureTrigger) {
      throw const OpacException(
        'Could not load this catalog record. Check your connection and try again.',
      );
    }

    final index = mockCatalogItems.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw const OpacNotFoundException(
        'That record could not be found in the catalog.',
      );
    }
    final item = mockCatalogItems[index];

    // The real endpoint returns holdings inline; here they are stitched on
    // from the mock map so search results stay lightweight.
    return item.copyWith(holdings: mockCatalogHoldings[id] ?? const []);
  }

  /// Most recent queries first. Async for the same reason the rest of
  /// this class is: the Phase 2 implementation reads from storage.
  Future<List<String>> recentSearches() async =>
      List<String>.unmodifiable(_recentSearches);

  Future<void> recordSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _recentSearches
        .removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);

    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeRange(_maxRecentSearches, _recentSearches.length);
    }
  }

  /// Shelf of records for the landing state, spread across departments
  /// rather than taking the first N so the list doesn't look like an
  /// all-computer-science catalog.
  Future<List<CatalogItem>> featured() async {
    return _featuredIds
        .map((id) => mockCatalogItems.firstWhere((item) => item.id == id))
        .toList();
  }

  bool _matches(CatalogItem item, String query, SearchIndex index) {
    final q = query.toLowerCase();

    switch (index) {
      case SearchIndex.title:
        return item.title.toLowerCase().contains(q);

      case SearchIndex.author:
        return (item.author ?? '').toLowerCase().contains(q);

      case SearchIndex.isbn:
        // Compare digits only, so "978-0-262-03384-8" finds the same
        // record as "9780262033848".
        final needle = _digitsOnly(query);
        if (needle.isEmpty) return false;
        return _digitsOnly(item.isbn ?? '').contains(needle);

      case SearchIndex.keyword:
        // An approximation of Koha's "Library catalog" index, which is a
        // relevance-ranked full-text search across the whole MARC record.
        // The backend will do this properly; matching the fields students
        // actually search by is close enough to build the UI against.
        final haystack = [
          item.title,
          item.author ?? '',
          item.publisher ?? '',
          ...item.subjects,
        ].join(' ').toLowerCase();
        return haystack.contains(q);
    }
  }

  /// Crude stand-in for relevance ranking: exact title matches first, then
  /// titles starting with the query, then everything else alphabetically.
  /// Replaced wholesale by the backend's own ordering.
  List<CatalogItem> _rank(List<CatalogItem> items, String query) {
    final q = query.toLowerCase();

    int score(CatalogItem item) {
      final title = item.title.toLowerCase();
      if (title == q) return 0;
      if (title.startsWith(q)) return 1;
      return 2;
    }

    items.sort((a, b) {
      final byScore = score(a).compareTo(score(b));
      if (byScore != 0) return byScore;
      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });
    return items;
  }

  String _digitsOnly(String value) => value.replaceAll(RegExp(r'[^0-9]'), '');
}
