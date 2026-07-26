import 'dart:math';

import '../../data/mock_catalog_data.dart';
import '../../data/search_indexes.dart';
import '../../models/catalog_item.dart';
import '../../models/catalog_search_result.dart';
import '../catalog_repository.dart';
import '../search_history_repository.dart';

/// Answers every catalog call from [mockCatalogItems], so the OPAC UI can be
/// built and reviewed before the backend exists.
///
/// This is `OpacService` moved behind [CatalogRepository] unchanged — same
/// latency, same ranking, same failure triggers. Nothing about the module's
/// behaviour differs; only who hands the screens their data.
///
/// Every method is async even though mock lookups are synchronous. That was
/// deliberate from the start, and it is what let this become a move rather
/// than a rewrite.
class MockCatalogRepository implements CatalogRepository {
  /// Simulated network delay, so loading states are actually visible while
  /// the UI is being reviewed. Tests can pass [Duration.zero].
  final Duration latency;

  MockCatalogRepository({this.latency = const Duration(milliseconds: 700)});

  /// Typing this as the search term forces a failure, so the error state can
  /// be exercised on-device without unplugging anything.
  static const String _failureTrigger = 'error';

  /// Records shown on the landing state before anyone has searched.
  /// Phase 2 replaces this with the student's recently viewed books.
  static const List<String> _featuredIds = ['1', '13', '17', '19', '25'];

  @override
  Future<CatalogSearchResult> search({
    required String query,
    SearchIndex index = defaultSearchIndex,
    int page = 1,
    int perPage = defaultCatalogPerPage,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const CatalogSearchResult.empty();

    await Future<void>.delayed(latency);

    if (trimmed.toLowerCase() == _failureTrigger) {
      throw const CatalogException(
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

  @override
  Future<CatalogItem> getBiblio(String id) async {
    await Future<void>.delayed(latency);

    // Mirrors search("error") so the detail screen's failure treatment can
    // be reviewed before the real endpoint exists.
    if (id.toLowerCase() == _failureTrigger) {
      throw const CatalogException(
        'Could not load this catalog record. Check your connection and try again.',
      );
    }

    final index = mockCatalogItems.indexWhere((i) => i.id == id);
    if (index == -1) {
      throw const CatalogNotFoundException(
        'That record could not be found in the catalog.',
      );
    }
    final item = mockCatalogItems[index];

    // The real endpoint returns holdings inline; here they are stitched on
    // from the mock map so search results stay lightweight.
    return item.copyWith(holdings: mockCatalogHoldings[id] ?? const []);
  }

  /// Shelf of records for the landing state, spread across departments
  /// rather than taking the first N so the list doesn't look like an
  /// all-computer-science catalog.
  @override
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

/// Recent searches, held in memory for the life of the process.
///
/// This is the other half of `OpacService`, carried over verbatim: the same
/// seeded list, the same de-duplicating insert, the same cap. It lives in this
/// file rather than its own because it is a dozen lines of transitional code —
/// a later phase moves it behind `SecureStorageService` so history survives
/// restarts, at which point it earns a file of its own.
///
/// The backing list stays `static` deliberately. It was static on OpacService,
/// which each screen constructed for itself, so recorded searches were already
/// shared process-wide. Keeping it static preserves that exactly.
class MockSearchHistoryRepository implements SearchHistoryRepository {
  static const int _maxRecentSearches = 6;

  /// Seeded so the landing state has something to show on a first run.
  static final List<String> _recentSearches = [
    'algorithms',
    'operating systems',
    'Kotler',
    '9780262033848',
  ];

  /// Most recent queries first. Async for the same reason the rest of the
  /// layer is: the storage-backed implementation will need to be.
  @override
  Future<List<String>> recent() async =>
      List<String>.unmodifiable(_recentSearches);

  @override
  Future<void> record(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _recentSearches.removeWhere((q) => q.toLowerCase() == trimmed.toLowerCase());
    _recentSearches.insert(0, trimmed);

    if (_recentSearches.length > _maxRecentSearches) {
      _recentSearches.removeRange(_maxRecentSearches, _recentSearches.length);
    }
  }
}
