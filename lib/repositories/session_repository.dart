/// Thrown when a session cannot be established or checked.
///
/// Callers show [message] directly — it is already written to be user-facing,
/// matching `CatalogException` and the `KohaAuthException` convention it came
/// from. Implementations translate their own transport errors into this, so
/// screens never import from `services/`.
class SessionException implements Exception {
  final String message;

  const SessionException(this.message);

  @override
  String toString() => message;
}

/// Establishes and holds the app's own session with the library backend.
///
/// Firebase Authentication is deliberately **not** behind this interface. It
/// stays the real identity provider in every configuration, so giving it a
/// mock implementation would be misleading — there is no "fake Firebase" mode.
/// What is swappable is the step immediately after: exchanging proof of
/// identity for a session the app can hold onto.
///
/// Two implementations exist, selected by `DataSourceConfig.session`:
/// `MockSessionRepository` accepts the dev account with no server at all, and
/// `RestSessionRepository` performs the real `POST /api/v1/auth/password`
/// against Koha.
///
/// The method is named for the credential it takes rather than just
/// `establish`, because a second mechanism is already planned: once
/// `POST /api/v1/juno/login` exists it will trade a Firebase ID token for a
/// Juno JWT, and that arrives as `establishWithFirebaseToken` alongside this
/// one. It is deliberately absent until the endpoint is real, so that no
/// implementation has to declare a method it can only throw from.
abstract interface class SessionRepository {
  /// Exchanges Koha credentials for a session, persists it, and returns the
  /// patron identifier it belongs to.
  ///
  /// Throws [SessionException] if the credentials are rejected or the backend
  /// cannot be reached.
  Future<String> establishWithPassword({
    required String username,
    required String password,
  });

  /// Whether a session is currently stored.
  Future<bool> hasSession();

  /// Discards the stored session. Safe to call when none exists.
  Future<void> clear();
}
