/// Establishes and holds the app's own session with the library backend.
///
/// Firebase Authentication is deliberately **not** behind this interface. It
/// stays the real identity provider in every configuration, so giving it a
/// mock implementation would be misleading — there is no "fake Firebase"
/// mode. What is swappable is the step immediately after: exchanging proof of
/// identity for an app session.
///
/// Today that is `KohaAuthService` against `POST /api/v1/auth/password`.
/// Later it becomes `POST /api/v1/juno/login`, which trades a Firebase ID
/// token for a Juno JWT.
///
/// Both establish methods are declared because those two backends
/// authenticate differently, and the asymmetry is real rather than something
/// to paper over: an implementation that cannot honour one of them should
/// throw [UnsupportedError] instead of pretending to succeed. Step 5 wires
/// the password path; the token path stays unimplemented until the backend
/// exists.
abstract interface class SessionRepository {
  /// Exchanges Koha credentials for a session, persists it, and returns the
  /// patron identifier it belongs to.
  Future<String> establishWithPassword({
    required String username,
    required String password,
  });

  /// Exchanges a Firebase ID token for a session, persists it, and returns
  /// the patron identifier it belongs to.
  Future<String> establishWithFirebaseToken(String idToken);

  /// Whether a session is currently stored.
  Future<bool> hasSession();

  /// Discards the stored session. Safe to call when none exists.
  Future<void> clear();
}
