import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_constants.dart';
import '../../data/search_indexes.dart';
import '../../models/catalog_item.dart';
import '../../models/catalog_search_result.dart';
import '../catalog_repository.dart';

/// Supplies the bearer token for authenticated Juno endpoints, or null when no
/// session exists.
///
/// A callback rather than a stored token, because the token outlives neither
/// the session nor this object: Firebase ID tokens expire hourly, so the value
/// has to be fetched per request. Wiring it to a real source is a later step —
/// this class only calls the hook it is given.
typedef AuthTokenProvider = Future<String?> Function();

/// The Juno-backed catalog.
///
/// Nothing constructs this in the running app yet: `DataSourceConfig.catalog`
/// still selects the mock, and [ApiConstants.junoBaseUrl] is still a
/// placeholder host. The HTTP code is written and unit-tested against
/// `MockClient` so that going live is a configuration change rather than a
/// development one.
///
/// ## API contract
///
/// All paths are relative to `{baseUrl}/api/v1/juno`. Every request sends
/// `Accept: application/json`, plus `Authorization: Bearer <token>` when
/// [tokenProvider] yields one.
///
/// ### GET /search?q=&index=&page=&per_page=
///
/// `index` takes a [SearchIndex.apiValue]: `keyword`, `title`, `author` or
/// `isbn`. `page` is 1-based. Response is decoded by
/// [CatalogSearchResult.fromJson], which expects:
///
/// ```json
/// {
///   "results": [ /* item objects, see below */ ],
///   "page": 1,
///   "perPage": 20,
///   "totalResults": 137,
///   "hasMore": true
/// }
/// ```
///
/// Search results omit `holdings` — [CatalogItem.holdings] is null for them by
/// design, and the counts below are what the results list renders instead.
///
/// ### GET /biblios/{id}
///
/// Returns one item object with `holdings` present inline. Decoded by
/// [CatalogItem.fromJson], which expects:
///
/// ```json
/// {
///   "id": "42",
///   "title": "…",
///   "author": "…",
///   "publisher": "…",
///   "year": 2009,
///   "isbn": "9780262033848",
///   "itemType": "…",
///   "summary": "…",
///   "language": "…",
///   "subjects": ["…"],
///   "availableCount": 2,
///   "totalCount": 5,
///   "holdings": [
///     {
///       "itemId": "…",
///       "library": "…",
///       "callNumber": "…",
///       "availability": "available",
///       "dueDate": "2026-08-01T00:00:00Z"
///     }
///   ]
/// }
/// ```
///
/// `availability` is one of `available`, `checked_out` or `reference`; any
/// other value is read as unavailable rather than rejected, so the backend can
/// pass Koha's wider status set through untranslated. `dueDate` is ISO-8601
/// and only meaningful for checked-out copies.
///
/// Every field except `id` and `title` tolerates being absent — the model
/// factories default them — so the backend may omit what Koha doesn't hold.
///
/// ## Still TBD
///
/// These are genuinely undecided, not omitted for brevity:
///
/// - **The [featured] endpoint does not exist.** Its path and response shape
///   below are placeholders; see the TODO on `_featuredPath`.
/// - **Query vs. response casing.** The query string above is snake_case
///   (`per_page`) while the response body is camelCase (`perPage`). That is
///   what the existing model and endpoint sketch each say; confirm which the
///   backend actually uses before relying on either.
/// - **Error bodies.** How a failure explains itself is unspecified, so the
///   messages below are written from the status code alone and ignore the
///   response body. If Juno returns structured errors, [_failureFor] is the
///   one place that needs to change.
/// - **Whether Koha ids are stable.** [CatalogItem.id] is a string here; Koha
///   biblionumbers are integers. Confirm the proxy passes them through rather
///   than minting its own.
class RestCatalogRepository implements CatalogRepository {
  /// Origin of the Juno backend, without a trailing slash. Injected rather
  /// than read from [ApiConstants] here, so tests and future flavors can point
  /// this at a different host without touching the class.
  final String baseUrl;

  /// Injectable so tests can substitute a `MockClient` instead of reaching the
  /// network.
  final http.Client client;

  /// Null when there is no session to authenticate with, in which case
  /// requests go out unauthenticated.
  final AuthTokenProvider? tokenProvider;

  /// Per-request deadline. Defaults to the app-wide
  /// [ApiConstants.requestTimeout]; overridable mainly so tests can exercise
  /// the timeout path without waiting fifteen seconds.
  final Duration timeout;

  RestCatalogRepository({
    required String baseUrl,
    http.Client? client,
    this.tokenProvider,
    Duration? timeout,
  }) : baseUrl = baseUrl.endsWith('/')
           ? baseUrl.substring(0, baseUrl.length - 1)
           : baseUrl,
       client = client ?? http.Client(),
       timeout = timeout ?? ApiConstants.requestTimeout;

  static const String _basePath = '/api/v1/juno';
  static const String _searchPath = '$_basePath/search';
  static const String _bibliosPath = '$_basePath/biblios';

  // TODO(backend): no endpoint has been agreed for the landing shelf. This
  // path and the bare-array response [featured] expects are both placeholders
  // — confirm or replace them before switching DataSourceConfig to REST. The
  // shelf may not be a request at all: it was always meant to become
  // "recently viewed", which could be device-local state.
  static const String _featuredPath = '$_basePath/featured';

  @override
  Future<CatalogSearchResult> search({
    required String query,
    SearchIndex index = defaultSearchIndex,
    int page = 1,
    int perPage = defaultCatalogPerPage,
  }) async {
    final trimmed = query.trim();
    // Matches the mock, which also answers an empty query without work. Saves
    // a request that could only return everything or nothing.
    if (trimmed.isEmpty) return const CatalogSearchResult.empty();

    final json = await _getObject(
      _uri(_searchPath, {
        'q': trimmed,
        'index': index.apiValue,
        'page': '$page',
        'per_page': '$perPage',
      }),
    );

    return CatalogSearchResult.fromJson(json);
  }

  @override
  Future<CatalogItem> getBiblio(String id) async {
    final json = await _getObject(
      _uri('$_bibliosPath/${Uri.encodeComponent(id)}'),
      // The only endpoint where 404 carries meaning: it is the backend saying
      // this biblio is gone, which the detail screen shows as its own calm
      // not-found state rather than an error.
      missingMeansNotFound: true,
    );

    return CatalogItem.fromJson(json);
  }

  @override
  Future<List<CatalogItem>> featured() async {
    final json = await _getArray(_uri(_featuredPath));

    return json
        .map((item) => CatalogItem.fromJson(_asObject(item)))
        .toList(growable: false);
  }

  /// Absolute URL for [path], with [query] appended when non-empty.
  Uri _uri(String path, [Map<String, String>? query]) {
    return Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: (query?.isEmpty ?? true) ? null : query);
  }

  /// Request headers, including the bearer token when one is available.
  ///
  /// A null or empty token is treated as "no session" rather than an error, so
  /// the endpoints still work if they turn out to be public.
  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{'Accept': 'application/json'};

    final provider = tokenProvider;
    if (provider == null) return headers;

    final String? token;
    try {
      token = await provider();
    } catch (_) {
      // Refreshing an expired Firebase token needs the network too, so this
      // is a plausible failure rather than a defensive flourish.
      throw const CatalogException(
        'Could not verify your session. Please sign in again.',
      );
    }

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  /// GETs [uri] and returns the decoded JSON body.
  ///
  /// Throws [CatalogException] for anything that goes wrong, or
  /// [CatalogNotFoundException] on a 404 when [missingMeansNotFound] is set.
  Future<Object?> _getJson(Uri uri, {bool missingMeansNotFound = false}) async {
    // Deliberately outside the try below, so a token failure surfaces as
    // itself instead of being reported as a connection problem.
    final headers = await _headers();

    final http.Response response;
    try {
      response = await client.get(uri, headers: headers).timeout(timeout);
    } on TimeoutException {
      throw const CatalogException(
        'The library catalog took too long to respond. Please try again.',
      );
    } catch (_) {
      // http throws ClientException for a dropped connection and
      // SocketException for DNS or routing failures; neither is worth
      // distinguishing for the student reading the message.
      throw const CatalogException(
        'Could not reach the library catalog. Check your connection and try again.',
      );
    }

    if (response.statusCode == 404 && missingMeansNotFound) {
      throw const CatalogNotFoundException(
        'That record could not be found in the catalog.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _failureFor(response);
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const CatalogException(
        'Unexpected response from the library catalog.',
      );
    }
  }

  /// Maps a non-success status onto a user-facing message.
  ///
  /// Reads the status code only — see "Still TBD" above on error bodies.
  CatalogException _failureFor(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return const CatalogException(
        'Your session has expired. Please sign in again.',
      );
    }

    return CatalogException(
      'The library catalog is unavailable right now '
      '(server returned ${response.statusCode}). Please try again later.',
    );
  }

  Future<Map<String, dynamic>> _getObject(
    Uri uri, {
    bool missingMeansNotFound = false,
  }) async {
    return _asObject(
      await _getJson(uri, missingMeansNotFound: missingMeansNotFound),
    );
  }

  Future<List<dynamic>> _getArray(Uri uri) async {
    final decoded = await _getJson(uri);
    if (decoded is! List) {
      throw const CatalogException(
        'Unexpected response from the library catalog.',
      );
    }
    return decoded;
  }

  /// Guards the cast the model factories require. Valid JSON of the wrong
  /// shape is still a broken response, and it must not reach the screens as an
  /// unhandled TypeError.
  Map<String, dynamic> _asObject(Object? decoded) {
    if (decoded is! Map<String, dynamic>) {
      throw const CatalogException(
        'Unexpected response from the library catalog.',
      );
    }
    return decoded;
  }
}
