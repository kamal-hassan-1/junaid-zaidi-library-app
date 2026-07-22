import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for the one thing that must never sit in
/// plain SharedPreferences: the Koha access token (SDS §9.9). Firebase
/// state is disposable — this is the actual app session.
class SecureStorageService {
  static const _tokenKey = 'koha_access_token';
  static const _patronIdKey = 'koha_patron_id';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveSession({required String token, required String patronId}) async {
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _patronIdKey, value: patronId);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<String?> readPatronId() => _storage.read(key: _patronIdKey);

  Future<bool> hasSession() async {
    final token = await readToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _patronIdKey);
  }
}