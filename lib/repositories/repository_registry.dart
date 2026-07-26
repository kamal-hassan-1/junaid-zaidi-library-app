import '../config/api_constants.dart';
import '../config/data_source_config.dart';
import 'catalog_repository.dart';
import 'mock/mock_catalog_repository.dart';
import 'mock/mock_patron_repository.dart';
import 'mock/mock_session_repository.dart';
import 'patron_repository.dart';
import 'rest/rest_catalog_repository.dart';
import 'rest/rest_session_repository.dart';
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
  final PatronRepository? _patron;

  const RepositoryRegistry({
    required this.catalog,
    required this.searchHistory,
    SessionRepository? session,
    PatronRepository? patron,
  }) : _session = session,
       _patron = patron;

  /// Builds the registry from `DataSourceConfig`, with per-repository
  /// overrides for tests.
  factory RepositoryRegistry.fromConfig({
    DataSource catalog = DataSourceConfig.catalog,
    DataSource session = DataSourceConfig.session,
    DataSource patron = DataSourceConfig.patron,
  }) {
    return RepositoryRegistry(
      catalog: _buildCatalog(catalog),
      searchHistory: MockSearchHistoryRepository(),
      session: _buildSession(session),
      patron: _buildPatron(patron),
    );
  }

  /// The session repository.
  ///
  /// Optional on the constructor so that tests needing only a catalog can omit
  /// it; [fromConfig] always supplies one.
  SessionRepository get session {
    final session = _session;
    if (session == null) {
      throw StateError(
        'This RepositoryRegistry was built without a SessionRepository. Use '
        'RepositoryRegistry.fromConfig(), or pass one to the constructor.',
      );
    }
    return session;
  }

  /// The patron repository. Optional on the constructor for the same reason
  /// [session] is.
  PatronRepository get patron {
    final patron = _patron;
    if (patron == null) {
      throw StateError(
        'This RepositoryRegistry was built without a PatronRepository. Use '
        'RepositoryRegistry.fromConfig(), or pass one to the constructor.',
      );
    }
    return patron;
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

  /// Unlike the catalog, both session branches are real: the mock is not a
  /// stand-in for a missing backend but the dev-account login, which is the
  /// only way in while `ApiConstants.kohaBaseUrl` is still a placeholder.
  static SessionRepository _buildSession(DataSource source) => switch (source) {
    DataSource.mock => MockSessionRepository(),
    DataSource.rest => RestSessionRepository(),
  };

  /// Only the mock branch exists. Selecting [DataSource.rest] for the patron
  /// account fails at startup rather than at the first call — a deliberate
  /// difference from the catalog, because there is no `RestPatronRepository` to
  /// construct at all, and no endpoints for one to call.
  static PatronRepository _buildPatron(DataSource source) => switch (source) {
    DataSource.mock => MockPatronRepository(),
    DataSource.rest => throw UnimplementedError(
      'RestPatronRepository does not exist yet. Keep DataSourceConfig.patron '
      'on DataSource.mock until the patron endpoints are defined.',
    ),
  };

  // Search history takes no DataSource: it is device-local, so there is no
  // remote implementation to choose between.
}
