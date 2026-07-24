import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wraps flutter_secure_storage for the Koha access token (SDS §9.9) and,
/// as of Phase 8, a simple guest-mode flag. Guest mode isn't sensitive
/// data, but reusing the same storage instance avoids adding a second
/// persistence mechanism (e.g. shared_preferences) for one boolean.
class SecureStorageService {
  static const _tokenKey = 'koha_access_token';
  static const _patronIdKey = 'koha_patron_id';
  static const _guestModeKey = 'guest_mode';

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

  // ---- Guest mode (Phase 8) ----

  Future<void> setGuestMode(bool value) async {
    if (value) {
      await _storage.write(key: _guestModeKey, value: 'true');
    } else {
      await _storage.delete(key: _guestModeKey);
    }
  }

  Future<bool> isGuestMode() async {
    final value = await _storage.read(key: _guestModeKey);
    return value == 'true';
  }
}