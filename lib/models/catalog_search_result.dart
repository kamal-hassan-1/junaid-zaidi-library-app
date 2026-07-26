import 'catalog_item.dart';

/// One page of search results plus the paging metadata the results screen
/// needs to decide whether to keep loading as the student scrolls.
///
/// [totalResults] is the size of the whole result set, not of [items] —
/// the results header shows it ("143 results"), so it has to survive
/// pagination.
class CatalogSearchResult {
  final List<CatalogItem> items;
  final int page;
  final int perPage;
  final int totalResults;
  final bool hasMore;

  const CatalogSearchResult({
    required this.items,
    required this.page,
    required this.perPage,
    required this.totalResults,
    required this.hasMore,
  });

  const CatalogSearchResult.empty()
      : items = const [],
        page = 1,
        perPage = 0,
        totalResults = 0,
        hasMore = false;

  bool get isEmpty => items.isEmpty;

  factory CatalogSearchResult.fromJson(Map<String, dynamic> json) {
    final rawItems = json['results'] as List<dynamic>? ?? const [];
    return CatalogSearchResult(
      items: rawItems
          .map((e) => CatalogItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: json['page'] as int? ?? 1,
      perPage: json['perPage'] as int? ?? rawItems.length,
      totalResults: json['totalResults'] as int? ?? rawItems.length,
      hasMore: json['hasMore'] as bool? ?? false,
    );
  }
}
