import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import 'secure_storage_service.dart';

/// Thrown when Koha rejects credentials or the request fails. Callers
/// show [message] directly — it's already meant to be user-facing.
class KohaAuthException implements Exception {
  final String message;
  const KohaAuthException(this.message);

  @override
  String toString() => message;
}

/// The REAL login for this app. Firebase's job ends at email
/// verification (SDS §9.9) — once a librarian has approved a student and
/// created their Koha patron record, every subsequent login goes through
/// Koha's own POST /api/v1/auth/password, not Firebase.
class KohaAuthService {
  final http.Client _client;
  final SecureStorageService _secureStorage;

  KohaAuthService({http.Client? client, SecureStorageService? secureStorage})
      : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  /// Logs a student in against Koha, stores the resulting token via
  /// [SecureStorageService], and returns the patron ID on success.
  /// Throws [KohaAuthException] with a user-facing message on failure.
  Future<String> login({required String username, required String password}) async {
    final uri = Uri.parse(ApiConstants.kohaAuthEndpoint);

    late final http.Response response;
    try {
      response = await _client
          .post(
        uri,
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'userid': username, 'password': password},
      )
          .timeout(ApiConstants.requestTimeout);
    } catch (_) {
      throw const KohaAuthException(
        'Could not reach the library server. Check your connection and try again.',
      );
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const KohaAuthException('Incorrect username or password.');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw KohaAuthException(
        'Login failed (server returned ${response.statusCode}). Please try again later.',
      );
    }

    Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const KohaAuthException('Unexpected response from the library server.');
    }

    // Koha's /api/v1/auth/password response shape can vary slightly by
    // version/config — adjust these keys once you see a real response body.
    final token = data['access_token'] as String? ?? data['token'] as String?;
    final patronId = (data['patron_id'] ?? data['borrowernumber'])?.toString();

    if (token == null || patronId == null) {
      throw const KohaAuthException('Unexpected response from the library server.');
    }

    await _secureStorage.saveSession(token: token, patronId: patronId);
    return patronId;
  }

  Future<void> logout() => _secureStorage.clearSession();

  Future<bool> isLoggedIn() => _secureStorage.hasSession();
}