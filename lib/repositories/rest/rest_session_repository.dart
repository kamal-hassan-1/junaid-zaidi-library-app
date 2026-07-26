import '../../services/koha_auth_service.dart';
import '../session_repository.dart';

/// The real session: Koha's own `POST /api/v1/auth/password`.
///
/// A thin adapter rather than a reimplementation. `KohaAuthService` already
/// builds that request, reads the token and patron id out of the response, and
/// persists them, so this wraps it instead of duplicating it — the HTTP code
/// and its quirks stay in one place.
///
/// Its one real job is translating [KohaAuthException] into
/// [SessionException], which is what keeps `services/` out of the screens'
/// imports.
class RestSessionRepository implements SessionRepository {
  final KohaAuthService _kohaAuth;

  RestSessionRepository({KohaAuthService? kohaAuth})
    : _kohaAuth = kohaAuth ?? KohaAuthService();

  @override
  Future<String> establishWithPassword({
    required String username,
    required String password,
  }) async {
    try {
      return await _kohaAuth.login(username: username, password: password);
    } on KohaAuthException catch (error) {
      // Already user-facing, so it is carried across verbatim.
      throw SessionException(error.message);
    }
  }

  @override
  Future<bool> hasSession() => _kohaAuth.isLoggedIn();

  @override
  Future<void> clear() => _kohaAuth.logout();
}
