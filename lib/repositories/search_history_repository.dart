/// The student's recent catalog searches.
///
/// Deliberately separate from `CatalogRepository`: this is device-local state,
/// not catalog data. Were it a method on the catalog interface, every REST
/// implementation would have to re-implement local persistence, and switching
/// data source would wrongly change history behaviour.
///
/// So this interface has no remote variant — only a local one, which is why
/// `DataSourceConfig` has no entry for it. `MockSearchHistoryRepository` keeps
/// the list in memory; a later phase swaps the backing store for
/// `SecureStorageService` so history survives restarts, without either
/// method's signature changing.
abstract interface class SearchHistoryRepository {
  /// Most recent query first.
  Future<List<String>> recent();

  /// Records [query], moving it to the front if it is already present.
  /// Blank queries are ignored.
  Future<void> record(String query);
}
