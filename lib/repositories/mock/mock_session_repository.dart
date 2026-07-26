import '../../services/secure_storage_service.dart';
import '../session_repository.dart';

/// Signs in the dev account without a server.
///
/// This is the hardcoded bypass that used to sit at the top of
/// `KohaAuthService.login`, marked `TEMP —` and checked before any network
/// call. Moving it here turns a permanent branch in production code into a
/// configuration choice: `DataSourceConfig.session = mock` means "the dev
/// account works with nothing running", and `rest` means real Koha only.
///
/// The session it writes is indistinguishable from a real one — same keys via
/// [SecureStorageService] — so `AuthGate`, `ProfileLoader` and anything else
/// reading session state behave exactly as they would after a genuine login.
class MockSessionRepository implements SessionRepository {
  final SecureStorageService _secureStorage;

  MockSessionRepository({SecureStorageService? secureStorage})
    : _secureStorage = secureStorage ?? SecureStorageService();

  static const String _devUsername = 'testuser';
  static const String _devPassword = 'test1234';
  static const String _devPatronId = '0000';
  static const String _devToken = 'dev-hardcoded-token';

  @override
  Future<String> establishWithPassword({
    required String username,
    required String password,
  }) async {
    if (username != _devUsername || password != _devPassword) {
      // The same wording Koha's 401 produces. There is no server to ask, so
      // "wrong credentials" is the only honest answer for anything else.
      throw const SessionException('Incorrect username or password.');
    }

    await _secureStorage.saveSession(token: _devToken, patronId: _devPatronId);
    return _devPatronId;
  }

  @override
  Future<bool> hasSession() => _secureStorage.hasSession();

  @override
  Future<void> clear() => _secureStorage.clearSession();
}
