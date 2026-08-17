import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import 'secure_storage_service.dart';

/// Thrown when a Koha API call gets a 401/403 — the stored
/// username/password is missing or was rejected (e.g. the student
/// changed their password elsewhere since logging in here). Callers
/// should treat this as "the session is no longer valid" and trigger a
/// full logout (see AuthScope.of(context).onLogout in auth_scope.dart,
/// which clears both the Koha credentials and the Firebase session
/// together), not just retry the same call.
class KohaSessionExpiredException implements Exception {
  const KohaSessionExpiredException();
  @override
  String toString() => 'Koha session expired or was rejected.';
}

/// Updated Authentication Workflow, Step 16: "Koha Access Token gets
/// attached to all API calls." This is that attachment mechanism.
///
/// CORRECTED: the real Koha 25 instance's working login endpoint
/// (/api/v1/auth/password/validation, see KohaAuthService) never
/// issues a token — confirmed via Postman. So there is no bearer token
/// to attach here. Instead, EVERY call this client makes resends HTTP
/// Basic Auth built from the student's own username + password (saved
/// at login by SecureStorageService) — this Koha install is
/// Basic-Auth-per-request throughout, not session/token-based, and
/// koha_auth_service.dart and this file need to agree on that
/// consistently.
///
/// SCOPE NOTE: as of this phase, this app has no catalog / checkouts /
/// holds / renewals / fines screens or services yet — grepping lib/ for
/// any Koha HTTP call turns up nothing beyond koha_auth_service.dart's
/// own login request. Building those features out is a separate, much
/// larger effort outside the authentication workflow this class exists
/// to support. What's here is the INFRASTRUCTURE Step 16 specifies,
/// ready for whichever of those features gets built first, e.g.:
///
///   final client = KohaApiClient();
///   final response = await client.get('/api/v1/checkouts');
///   if (response.statusCode == 200) { ... }
///
/// A future feature should catch [KohaSessionExpiredException] and call
/// `AuthScope.of(context).onLogout()` rather than showing a raw error —
/// that's the one existing hook that already clears both sessions
/// together (see auth_gate.dart's _handleLogout).
class KohaApiClient {
  final http.Client _client;
  final SecureStorageService _secureStorage;

  KohaApiClient({http.Client? client, SecureStorageService? secureStorage})
      : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  Future<Map<String, String>> _authHeaders() async {
    final username = await _secureStorage.readUsername();
    final password = await _secureStorage.readPassword();
    if (username == null || username.isEmpty || password == null || password.isEmpty) {
      debugPrint('[KohaApiClient] ❌ No stored credentials — treating as session expired');
      throw const KohaSessionExpiredException();
    }
    final basicAuthValue = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $basicAuthValue',
      'Content-Type': 'application/json',
    };
  }

  Uri _resolve(String path) => Uri.parse('${ApiConstants.kohaBaseUrl}$path');

  Future<http.Response> _send(
      String method,
      String path,
      Future<http.Response> Function(Uri uri, Map<String, String> headers) request,
      ) async {
    final uri = _resolve(path);
    debugPrint('[KohaApiClient] $method $uri');
    final http.Response response;
    try {
      response = await request(uri, await _authHeaders()).timeout(ApiConstants.requestTimeout);
    } catch (e) {
      debugPrint('[KohaApiClient] ❌ $method $uri failed: $e');
      rethrow;
    }
    debugPrint('[KohaApiClient] $method $uri → ${response.statusCode}: '
        '${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
    _throwIfSessionExpired(response);
    return response;
  }

  Future<http.Response> get(String path) =>
      _send('GET', path, (uri, headers) => _client.get(uri, headers: headers));

  Future<http.Response> post(String path, {Object? body}) => _send(
    'POST',
    path,
        (uri, headers) => _client.post(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
  );

  Future<http.Response> put(String path, {Object? body}) => _send(
    'PUT',
    path,
        (uri, headers) => _client.put(uri, headers: headers, body: body == null ? null : jsonEncode(body)),
  );

  Future<http.Response> delete(String path) =>
      _send('DELETE', path, (uri, headers) => _client.delete(uri, headers: headers));

  void _throwIfSessionExpired(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      debugPrint('[KohaApiClient] ❌ ${response.statusCode} — session expired or rejected');
      throw const KohaSessionExpiredException();
    }
  }
}