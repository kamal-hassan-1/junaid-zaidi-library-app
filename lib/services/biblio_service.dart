import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/koha_service_account.dart';
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

  /// GET /api/v1/biblios/{biblio_id}. Best guess on the real endpoint
  /// shape — see deferred.md.
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

  /// GET /api/v1/biblios?q=<json> — server-side search, optionally
  /// narrowed to one [itemType], one [campus], and/or one [searchField].
  ///
  /// Koha's REST API does NOT accept plain `?title=foo&itemtype=BK`
  /// query-string filters — those are silently ignored or 500. It uses
  /// a JSON query language in the `q` param instead: `{"field": "value"}`
  /// for an exact match, `{"field": {"-like": "%value%"}}` for a partial
  /// match, and multiple top-level keys are AND'd together. This replaces
  /// the old query-string-param approach, which is why filtering
  /// previously did nothing against the real server.
  ///
  /// [searchField] reuses the real OPAC website's `idx=` short codes
  /// (`ti`/`au`/`su`/`nb`/`ns`) mapped to biblio-level columns below.
  /// [campus] reuses the real website's `homebranch:` facet codes
  /// (`isb`/`lhr`/`atd`/`atk`/`swl`/`veh`/`wah`).
  ///
  /// NOTE: `itemType` and `campus` (home library) are attributes of
  /// *items*, not of the biblio record itself, so filtering `/biblios`
  /// directly by them may not work even with the corrected JSON syntax
  /// below — Koha may require embedding items (`x-koha-embed: items`
  /// header) and querying `items.itype` / `items.home_branch` via dot
  /// notation instead. This hasn't been confirmed against a live server;
  /// if itemType/campus filters still don't narrow results after this
  /// fix, that's the next thing to check.
  @override
  Future<List<Biblio>> search(
      String query, {
        String? itemType,
        String? searchField,
        String? campus,
      }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty && itemType == null && campus == null) return fetchAll();

    final fieldColumn = switch (searchField) {
      'ti' => 'title',
      'au' => 'author',
      'su' => 'subject',
      'nb' => 'isbn',
      'ns' => 'issn',
      _ => null,
    };

    final Map<String, dynamic> conditions = {};

    if (trimmed.isNotEmpty) {
      if (fieldColumn != null) {
        conditions[fieldColumn] = {'-like': '%$trimmed%'};
      } else {
        // Keyword search: match title OR author (biblio-level columns).
        // Subject/ISBN/ISSN keyword matching may need items/biblioitems
        // embeds depending on schema — add here once confirmed.
        conditions['-or'] = [
          {'title': {'-like': '%$trimmed%'}},
          {'author': {'-like': '%$trimmed%'}},
        ];
      }
    }
    if (itemType != null) conditions['item_type'] = itemType;
    if (campus != null) conditions['items.home_branch'] = campus;

    final uri = Uri.parse('${ApiConstants.kohaBaseUrl}/api/v1/biblios')
        .replace(queryParameters: {
      if (conditions.isNotEmpty) 'q': jsonEncode(conditions),
    });
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