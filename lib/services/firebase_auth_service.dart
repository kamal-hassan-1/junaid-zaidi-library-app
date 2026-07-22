import 'package:firebase_auth/firebase_auth.dart';

/// Firebase Auth's ONLY job in this app is proving a student controls the
/// email address they registered with (SDS §9.9). It never issues the
/// real app session — that's KohaAuthService's job. Don't add
/// sign-in-and-stay logic here; once verification succeeds, this account
/// has done its job.
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  /// Creates a temporary Firebase account for verification purposes only.
  /// Throws [FirebaseAuthException] on failure (e.g. email-already-in-use,
  /// weak-password) — callers should catch and show `e.message`.
  Future<User> createTempAccount({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Account creation did not return a user.',
      );
    }
    return user;
  }

  /// Sends the verification email to whichever account is currently
  /// signed in. Standard sendEmailVerification() — deliberately NOT the
  /// deprecated Dynamic-Links passwordless-sign-in flow.
  Future<void> sendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-current-user',
        message: 'No signed-in user to send a verification email to.',
      );
    }
    await user.sendEmailVerification();
  }

  /// Re-fetches the user's record so `emailVerified` reflects whether
  /// they've clicked the link yet. Call this when the student taps
  /// "I've verified" on verify_email_screen.dart.
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  /// Signs out of the temporary Firebase account. Call once the
  /// student_request document has been written — nothing after that
  /// point needs a live Firebase session.
  Future<void> signOut() => _auth.signOut();
}