import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../config/koha_service_account.dart';
import '../models/biblio.dart';

/// Fetches the full bibliographic catalog from the Koha REST API.
///
/// Uses the shared service-account credentials (see
/// [KohaServiceAccount]) rather than the logged-in student's own
/// credentials, since the `/biblios` endpoint is a public catalog
/// lookup that doesn't require patron-level auth.
class BiblioService {
  final http.Client _client;

  BiblioService({http.Client? client}) : _client = client ?? http.Client();

  /// GET /api/v1/biblios — returns every [Biblio] in the catalog.
  ///
  /// Throws on network errors or non-200 status codes.
  Future<List<Biblio>> fetchAll() async {
    final url = '${ApiConstants.kohaBaseUrl}/api/v1/biblios';
    final basicAuth = base64Encode(
      utf8.encode(
        '${KohaServiceAccount.validatorUserid}:${KohaServiceAccount.validatorPassword}',
      ),
    );

    debugPrint('[BiblioService] GET $url');
    debugPrint('[BiblioService] Auth: Basic ${KohaServiceAccount.validatorUserid}:****');
    developer.log('GET $url', name: 'BiblioService');

    final http.Response response;
    try {
      response = await _client
          .get(
            Uri.parse(url),
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

    final List<dynamic> jsonList = jsonDecode(response.body) as List<dynamic>;
    debugPrint('[BiblioService] ✅ Parsed ${jsonList.length} biblio records');
    return jsonList
        .map((item) => Biblio.fromJson(item as Map<String, dynamic>))
        .where((b) => !b.opacSuppressed) // hide suppressed records
        .toList();
  }

  /// Search [all] by [query] (client-side filter on title + author).
  ///
  /// A future version could use the Koha `?q=` query parameter for
  /// server-side search; for now this is simple and sufficient.
  Future<List<Biblio>> search(String query) async {
    final all = await fetchAll();
    if (query.trim().isEmpty) return all;

    final lowerQuery = query.toLowerCase();
    return all.where((b) {
      final title = b.title.toLowerCase();
      final author = (b.author ?? '').toLowerCase();
      final isbn = (b.isbn ?? '').toLowerCase();
      return title.contains(lowerQuery) ||
          author.contains(lowerQuery) ||
          isbn.contains(lowerQuery);
    }).toList();
  }
}
