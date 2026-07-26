import '../data/search_indexes.dart';
import '../models/catalog_item.dart';
import '../models/catalog_search_result.dart';

/// Default page size for [CatalogRepository.search].
const int defaultCatalogPerPage = 20;

/// Thrown when a catalog request fails.
///
/// Callers show [message] directly — it is already written to be user-facing,
/// matching the convention `KohaAuthException` established.
class CatalogException implements Exception {
  final String message;

  const CatalogException(this.message);

  @override
  String toString() => message;
}

/// A catalog request completed successfully, but the requested record does
/// not exist.
///
/// Kept distinct from [CatalogException] so the detail screen can show a calm
/// not-found state rather than a network-error treatment.
class CatalogNotFoundException extends CatalogException {
  const CatalogNotFoundException(super.message);
}

/// Read access to the library catalog.
///
/// `MockCatalogRepository` answers from fixtures today. Every method is async
/// even though mock lookups are synchronous, so that swapping in the REST
/// implementation changes no call site and no `FutureBuilder`.
///
/// The eventual REST implementation maps onto:
///
///   search()    -> GET /api/v1/juno/search?q=&index=&page=&per_page=
///   getBiblio() -> GET /api/v1/juno/biblios/{id}
abstract interface class CatalogRepository {
  /// Searches the catalog, scoped to [index].
  ///
  /// [page] is 1-based, matching the backend contract. Throws
  /// [CatalogException] if the request fails.
  Future<CatalogSearchResult> search({
    required String query,
    SearchIndex index = defaultSearchIndex,
    int page = 1,
    int perPage = defaultCatalogPerPage,
  });

  /// Full record for the detail screen, including its holdings.
  ///
  /// Throws [CatalogNotFoundException] when no record has [id], and
  /// [CatalogException] if the request itself fails — the two are separate so
  /// the caller can tell "no such book" from "backend unreachable".
  Future<CatalogItem> getBiblio(String id);

  /// Shelf of records for the landing state, shown before anyone searches.
  Future<List<CatalogItem>> featured();
}
