import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/koha_service_account.dart';
import '../models/availability.dart';
import '../models/biblio.dart';

/// Common shape for anything the OPAC screen can pull books from —
/// implemented by [BiblioService] (real Koha) and MockBiblioService
/// (canned data, see mock_biblio_service.dart). Lets OpacScreen stay
/// unaware of which one it's using; see [ApiConstants.useMockKohaBackend].
abstract class BiblioSource {
  /// Every [Biblio] in the catalog, unfiltered.
  Future<List<Biblio>> fetchAll();

  /// A single record by id — GET /api/v1/biblios/{biblio_id}. Used to
  /// display title/author for a checkout or hold, which only carry an
  /// id, not the full record (see [CirculationService], deferred.md).
  /// Returns `null` if not found.
  Future<Biblio?> fetchOne(int biblioId);

  /// Server-side search by [query] against title/author/ISBN, optionally
  /// narrowed to a single [itemType] (Koha itemtype code — 'BK', 'EBK',
  /// 'THESIS', etc; see [Biblio.itemTypeLabel]), a single [campus] (home
  /// library code — 'isb', 'lhr', etc; see [Biblio.campusLabel]), and/or
  /// scoped to one [searchField] — mirrors the real OPAC website's `idx=`
  /// search-index parameter: `null`/`'kw'` = keyword (all fields), `'ti'`
  /// = title, `'au'` = author, `'su'` = subject, `'nb'` = ISBN, `'ns'` =
  /// ISSN.
  Future<List<Biblio>> search(
    String query, {
    String? itemType,
    String? searchField,
    String? campus,
  });

  /// Whether/when [biblioId] can be borrowed right now — see
  /// [Availability].
  Future<Availability> fetchAvailability(int biblioId);

  /// Multi-field search — every non-null/non-empty field is ANDed
  /// together (all substring matches), unlike [search]'s single free-text
  /// box. Field set mirrors what's actually on [Biblio] (confirmed real
  /// biblio columns, see deferred.md): title, author, isbn, issn,
  /// publisher, seriesTitle, publicationYear, plus the same [itemType]
  /// used elsewhere.
  Future<List<Biblio>> advancedSearch({
    String? title,
    String? author,
    String? isbn,
    String? issn,
    String? publisher,
    String? seriesTitle,
    String? publicationYear,
    String? itemType,
  });
}

/// Fetches the bibliographic catalog from the Koha REST API.
///
/// Uses the shared service-account credentials (see
/// [KohaServiceAccount]) rather than the logged-in student's own
/// credentials, since the `/biblios` endpoint is a public catalog
/// lookup that doesn't require patron-level auth.
class BiblioService implements BiblioSource {
  final http.Client _client;

  BiblioService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/v1/biblios — returns every [Biblio] in the catalog.
  ///
  /// Throws on network errors or non-200 status codes.
  @override
  Future<List<Biblio>> fetchAll() => _get(Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/biblios'));

  /// GET /api/v1/biblios/{biblio_id}. Shape confirmed against a real
  /// local Koha instance (2026-08-17, see deferred.md) — single JSON
  /// object, not wrapped in a list.
  @override
  Future<Biblio?> fetchOne(int biblioId) async {
    final uri = Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/biblios/$biblioId');
    try {
      final results = await _get(uri, expectList: false);
      return results.isEmpty ? null : results.first;
    } catch (_) {
      return null;
    }
  }

  /// GET /api/v1/biblios?q=`{...}` (JSON-encoded) — server-side search, optionally
  /// narrowed to one [itemType] and/or one [searchField].
  ///
  /// Confirmed live against a real Koha instance (2026-08-17, see
  /// deferred.md) that `/api/v1/biblios` does **not** take simple named
  /// query params (`title=`, `itemtype=`, etc. all 400) — the only
  /// filter mechanism is a single `q` param holding a JSON-encoded
  /// SQL::Abstract-style condition: a plain hash ANDs its keys
  /// (`{"item_type":"BK"}`), `{"field":{"-like":"%x%"}}` does a
  /// substring match, and a `-or` key holding an array ORs its entries
  /// together with the rest ANDed in — e.g.
  /// `{"item_type":"BK","-or":[{"title":{"-like":"%x%"}},{"author":...}]}`.
  /// All of this was verified with real requests, not inferred.
  ///
  /// [campus] has no effect here — confirmed `home_library_id` is an
  /// *item*-level field (see `/api/v1/items/{id}`), not a filterable
  /// attribute on the biblio search at all. Likewise [searchField]
  /// dropped `su` (subject) — no such field exists on the real biblio
  /// response. Kept as parameters for interface compatibility with
  /// [MockBiblioService], which still supports both against its own
  /// canned data.
  @override
  Future<List<Biblio>> search(
    String query, {
    String? itemType,
    String? searchField,
    String? campus,
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty && itemType == null) return fetchAll();

    final field = switch (searchField) {
      'ti' => 'title',
      'au' => 'author',
      'nb' => 'isbn',
      'ns' => 'issn',
      _ => null,
    };

    Map<String, dynamic>? textCondition;
    if (trimmed.isNotEmpty) {
      if (field != null) {
        textCondition = {field: {'-like': '%$trimmed%'}};
      } else {
        // Keyword: OR across every text field the real API exposes.
        textCondition = {
          '-or': [
            for (final f in ['title', 'author', 'isbn', 'issn'])
              {f: {'-like': '%$trimmed%'}},
          ],
        };
      }
    }

    final condition = <String, dynamic>{
      'item_type': ?itemType,
      ...?textCondition,
    };

    final uri = Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/biblios')
        .replace(queryParameters: {'q': jsonEncode(condition)});
    return _get(uri);
  }

  /// GET /api/v1/public/biblios/{biblio_id}/items. Confirmed live
  /// (2026-08-17, see deferred.md) to be genuinely public — no
  /// credentials needed, unlike almost every other Koha call this app
  /// makes. Deliberately does **not** send the service-account Basic
  /// Auth header other methods here use; availability is meant to be
  /// visible to anyone browsing the catalog, same as the real OPAC
  /// website.
  @override
  Future<Availability> fetchAvailability(int biblioId) async {
    final uri = Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/public/biblios/$biblioId/items');
    try {
      final response =
          await _client.get(uri, headers: {'Accept': 'application/json'}).timeout(ApiConstants.requestTimeout);
      if (response.statusCode != 200) return Availability.noItemsState;
      return Availability.fromItemsJson(jsonDecode(response.body) as List<dynamic>);
    } catch (_) {
      return Availability.noItemsState;
    }
  }

  /// GET /api/v1/biblios?q=`{...}` with every given field ANDed together
  /// as a `-like` substring match, plus [itemType] as an exact match —
  /// same JSON condition mechanism as [search], just with more than one
  /// field at once. Live-verified against a real Koha instance
  /// (2026-08-17): `{"title":{"-like":"%x%"},"author":{"-like":"%y%"}}`
  /// correctly ANDs and returns only records matching both, and
  /// `publication_year`/`publisher` are real, queryable columns (present
  /// in the OpenAPI schema and accepted without error), even though the
  /// seed data used for that test happened to have them empty. See
  /// deferred.md for the exact requests run.
  @override
  Future<List<Biblio>> advancedSearch({
    String? title,
    String? author,
    String? isbn,
    String? issn,
    String? publisher,
    String? seriesTitle,
    String? publicationYear,
    String? itemType,
  }) {
    Map<String, String>? like(String? value) {
      final trimmed = value?.trim();
      if (trimmed == null || trimmed.isEmpty) return null;
      return {'-like': '%$trimmed%'};
    }

    final condition = <String, dynamic>{
      'item_type': ?itemType,
      'title': ?like(title),
      'author': ?like(author),
      'isbn': ?like(isbn),
      'issn': ?like(issn),
      'publisher': ?like(publisher),
      'series_title': ?like(seriesTitle),
      'publication_year': ?like(publicationYear),
    };

    if (condition.isEmpty) return fetchAll();

    final uri = Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/biblios')
        .replace(queryParameters: {'q': jsonEncode(condition)});
    return _get(uri);
  }

  /// [expectList] false means the endpoint returns a single JSON object
  /// (e.g. GET .../{id}) rather than an array — wrapped in a one-element
  /// list for a uniform return type.
  Future<List<Biblio>> _get(Uri uri, {bool expectList = true}) async {
    final basicAuth = base64Encode(
      utf8.encode(
        '${KohaServiceAccount.validatorUserid}:${KohaServiceAccount.validatorPassword}',
      ),
    );

    debugPrint('[BiblioService] GET $uri');
    debugPrint('[BiblioService] Auth: Basic ${KohaServiceAccount.validatorUserid}:****');
    developer.log('GET $uri', name: 'BiblioService');

    final http.Response response;
    try {
      response = await _client
          .get(
            uri,
            headers: {
              'Authorization': 'Basic $basicAuth',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(ApiConstants.requestTimeout);
    } catch (e, stack) {
      debugPrint('[BiblioService] ❌ Network error: $e');
      developer.log('Network error', name: 'BiblioService', error: e, stackTrace: stack);
      rethrow;
    }

    debugPrint('[BiblioService] Response status: ${response.statusCode}');
    debugPrint('[BiblioService] Response headers: ${response.headers}');
    debugPrint('[BiblioService] Response body (first 1000 chars): ${response.body.length > 1000 ? response.body.substring(0, 1000) : response.body}');
    developer.log(
      'Status ${response.statusCode} — body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}',
      name: 'BiblioService',
    );

    if (response.statusCode != 200) {
      final msg = 'HTTP ${response.statusCode}: ${response.body}';
      debugPrint('[BiblioService] ❌ $msg');
      throw Exception(msg);
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> jsonList = expectList
        ? decoded as List<dynamic>
        : [decoded as Map<String, dynamic>];
    debugPrint('[BiblioService] ✅ Parsed ${jsonList.length} biblio records');
    return jsonList
        .map((item) => Biblio.fromJson(item as Map<String, dynamic>))
        .where((b) => !b.opacSuppressed) // hide suppressed records
        .toList();
  }
}
