import 'dart:convert';

import 'package:flutter/foundation.dart' show kDebugMode;
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

/// Half of the real login for this app (Updated Authentication
/// Workflow, Phase 3) — the other half is FirebaseAuthService. See
/// EmailLoginScreen, which calls both with the same email + password
/// and requires both to succeed. This class only ever handles the Koha
/// side of that pair.
///
/// SECURITY FIX (2026-08-18, see deferred.md / worker/README.md): this
/// used to build a Basic Auth header from a staff "validator" account
/// (KohaServiceAccount) embedded directly in the app to call Koha's
/// /api/v1/auth/password/validation (staff-gated per Koha bug 36561 —
/// the Basic Auth account needs the `borrowers` permission, which a
/// regular student patron never has). That credential had leaked (this
/// repo is public) and, more importantly, never needed to be in the app
/// at all — the same Cloudflare Worker that now brokers circulation
/// calls does this validation instead, holding the staff credential
/// itself. This class now just POSTs the student's own email/password to
/// the Worker's `/login` and trusts its `patron_id` response, the same
/// way it used to trust Koha's own response directly.
class KohaAuthService {
  final http.Client _client;
  final SecureStorageService _secureStorage;

  KohaAuthService({http.Client? client, SecureStorageService? secureStorage})
      : _client = client ?? http.Client(),
        _secureStorage = secureStorage ?? SecureStorageService();

  // DEV-ONLY hardcoded account so the app is reachable without a real
  // Koha server running. Gated behind kDebugMode — this branch is
  // compiled out of release builds entirely (Dart's compiler strips
  // unreachable `if (kDebugMode)` branches in release mode), so it can
  // never work in anything you actually ship, not just "shouldn't"
  // work. Still search this file for "DEV-ONLY" before shipping, to
  // confirm.
  static const _devUsername = 'testuser';
  static const _devPassword = 'test1234';
  static const _devPatronId = '0000';

  /// Logs a student in against Koha, stores the student's own
  /// username+password (see SecureStorageService for why — there is no
  /// token to store instead) and returns the patron ID on success.
  /// Throws [KohaAuthException] with a user-facing message on failure.
  Future<String> login({required String username, required String password}) async {
    if (kDebugMode && username == _devUsername && password == _devPassword) {
      await _secureStorage.saveSession(
        username: _devUsername,
        password: _devPassword,
        patronId: _devPatronId,
      );
      return _devPatronId;
    }

    final uri = Uri.parse('${ApiConstants.circulationProxyBaseUrl}/login');

    late final http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'username': username, 'password': password}),
          )
          .timeout(ApiConstants.requestTimeout);
    } catch (_) {
      throw const KohaAuthException(
        'Could not reach the library server. Check your connection and try again.',
      );
    }

    // The Worker returns 502 if ITS OWN staff credential was rejected by
    // Koha (a Worker-side config problem) — distinct from 400, which
    // means the STUDENT's own email/password didn't validate.
    if (response.statusCode == 502) {
      throw const KohaAuthException(
        'Library server rejected the app\'s service account. Contact the library admin.',
      );
    }
    if (response.statusCode == 400) {
      throw const KohaAuthException('Incorrect email or password.');
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

    final patronId = data['patron_id']?.toString();
    if (patronId == null || patronId.isEmpty) {
      throw const KohaAuthException('Unexpected response from the library server.');
    }

    // From here on, every other Koha call uses the STUDENT's own
    // username/password — now confirmed correct — not the validator
    // account.
    await _secureStorage.saveSession(username: username, password: password, patronId: patronId);
    return patronId;
  }

  Future<void> logout() => _secureStorage.clearSession();

  Future<bool> isLoggedIn() => _secureStorage.hasSession();
}