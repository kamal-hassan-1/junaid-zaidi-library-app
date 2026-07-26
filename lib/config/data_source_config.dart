/// Which implementation backs a repository.
enum DataSource {
  /// In-memory fixtures — see `lib/data/mock_catalog_data.dart`.
  mock,

  /// The Koha-proxying REST backend. No implementation exists yet.
  rest,
}

/// The single place data-source selection changes.
///
/// Per-repository constants rather than one global flag, because the
/// migration is incremental — the catalog can move to REST while sessions
/// stay on mock. Both derive from [defaultSource], so moving everything at
/// once stays a one-line edit.
///
/// Shaped like `ApiConstants` (static constants, private constructor): the
/// app reads configuration, it never mutates it.
class DataSourceConfig {
  const DataSourceConfig._();

  /// Change this to switch every repository at once.
  static const DataSource defaultSource = DataSource.mock;

  static const DataSource catalog = defaultSource;

  static const DataSource session = defaultSource;

  /// Cannot be [DataSource.rest] yet — no REST implementation exists, so the
  /// registry throws on that branch rather than pretending otherwise. Left
  /// deriving from [defaultSource] so it moves with everything else once one
  /// does.
  static const DataSource patron = defaultSource;

  // Search history is deliberately absent. It is device-local state with no
  // remote equivalent, so there is nothing to switch — see
  // SearchHistoryRepository.
}
