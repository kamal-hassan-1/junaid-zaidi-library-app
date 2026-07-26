import '../config/api_constants.dart';
import '../config/data_source_config.dart';
import 'catalog_repository.dart';
import 'mock/mock_catalog_repository.dart';
import 'rest/rest_catalog_repository.dart';
import 'search_history_repository.dart';
import 'session_repository.dart';

/// The composed set of repositories the app runs on.
///
/// Immutable, and built once at startup — see `RepositoryScope`. Tests build
/// one directly from fakes; the app uses [RepositoryRegistry.fromConfig] so
/// that selection stays in `DataSourceConfig` alone.
class RepositoryRegistry {
  final CatalogRepository catalog;
  final SearchHistoryRepository searchHistory;

  final SessionRepository? _session;

  const RepositoryRegistry({
    required this.catalog,
    required this.searchHistory,
    SessionRepository? session,
  }) : _session = session;

  /// Builds the registry from `DataSourceConfig`, with per-repository
  /// overrides for tests.
  factory RepositoryRegistry.fromConfig({
    DataSource catalog = DataSourceConfig.catalog,
  }) {
    return RepositoryRegistry(
      catalog: _buildCatalog(catalog),
      searchHistory: MockSearchHistoryRepository(),
    );
  }

  /// The session repository.
  ///
  /// Throws until Step 5 implements one. [fromConfig] leaves it unset rather
  /// than building something that throws eagerly, because an eager throw would
  /// make the whole registry unconstructible and take `main.dart` down with
  /// it. Nothing reads this yet — the auth flow still uses `KohaAuthService`
  /// directly.
  SessionRepository get session {
    final session = _session;
    if (session == null) {
      throw UnimplementedError(
        'No SessionRepository implementation exists yet; it arrives in Step 5. '
        'The auth flow still calls KohaAuthService directly.',
      );
    }
    return session;
  }

  /// Both branches now construct something. Selecting [DataSource.rest] no
  /// longer fails at startup — it fails at the first catalog call instead,
  /// since RestCatalogRepository's methods are still unimplemented.
  static CatalogRepository _buildCatalog(DataSource source) => switch (source) {
    DataSource.mock => MockCatalogRepository(),
    DataSource.rest => RestCatalogRepository(
      baseUrl: ApiConstants.junoBaseUrl,
    ),
  };

  // Search history takes no DataSource: it is device-local, so there is no
  // remote implementation to choose between.
}
