import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_constants.dart';
import '../models/student_request.dart';
import 'firestore_service.dart';

/// Firebase Auth now serves three purposes:
///  1. Email verification for the legacy email/password signup path.
///  2. That same email/password account, now ALSO usable as a real,
///     persistent login IF the matching student_requests document's
///     status is Approved (see signInWithEmailAndPasswordApproved).
///  3. Microsoft OAuth (Azure AD) — domain-gated at sign-in, no
///     Firestore lookup needed to trust the session.
class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ---- Legacy email/password verification path ----

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

  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ---- Microsoft OAuth ----

  Future<User> signInWithMicrosoft() async {
    final provider = MicrosoftAuthProvider();
    provider.setCustomParameters({'tenant': ApiConstants.azureTenantId});

    final credential = await _auth.signInWithProvider(provider);
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'no-user',
        message: 'Microsoft sign-in did not return a user.',
      );
    }

    final email = user.email?.toLowerCase() ?? '';
    if (!email.endsWith(ApiConstants.studentEmailDomain)) {
      await _auth.signOut();
      throw StateError(
        'That Microsoft account isn\'t a COMSATS student account '
        '(must end with ${ApiConstants.studentEmailDomain}).',
      );
    }

    return user;
  }

  String extractRegistrationNumber(User user) {
    final fromEmail = RegExp(r'^([a-z]{2}\d{2}-[a-z]{3}-\d{3})', caseSensitive: false)
        .firstMatch(user.email ?? '')
        ?.group(1);
    if (fromEmail != null) return fromEmail.toUpperCase();

    final fromName = RegExp(r'\(([A-Z]{2}\d{2}-[A-Z]{3}-\d{3})\)')
        .firstMatch(user.displayName ?? '')
        ?.group(1);
    return fromName ?? '';
  }

  String extractFullName(User user) {
    final raw = user.displayName ?? '';
    return raw.replaceFirst(RegExp(r'^\([A-Z]{2}\d{2}-[A-Z]{3}-\d{3}\)\s*'), '').trim();
  }

  // ---- Email/password login gated on student_requests approval ----

  /// Signs in with email/password, then checks the matching
  /// student_requests document. Throws [StateError] with a user-facing
  /// message (and signs back out) if there's no request, the request
  /// isn't Approved, or the Firestore lookup itself fails — those three
  /// cases are kept distinct rather than collapsed into one message.
  Future<User> signInWithEmailAndPasswordApproved({
    required String email,
    required String password,
    required FirestoreService firestoreService,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Sign-in did not return a user.');
    }

    StudentRequest? request;
    try {
      request = await firestoreService.getLatestRequestForEmail(email);
    } catch (_) {
      // The query itself failed (e.g. missing Firestore index, offline) —
      // distinct from "queried fine, no request exists" below. Collapsing
      // these into one message would hide real problems behind a
      // misleading "no request found" for what's actually a backend issue.
      await _auth.signOut();
      throw StateError('Could not check your registration status. Try again in a moment.');
    }

    if (request == null) {
      await _auth.signOut();
      throw StateError('No registration request found for this email.');
    }

    switch (request.status) {
      case StudentRequestStatus.approved:
        return user;
      case StudentRequestStatus.rejected:
        await _auth.signOut();
        throw StateError('Your registration request was rejected.');
      default:
        await _auth.signOut();
        throw StateError('Your registration is still pending librarian approval.');
    }
  }

  /// Used by AuthGate on boot to decide whether an already-signed-in
  /// Firebase user still counts as a valid session. Microsoft accounts
  /// are valid by construction. Email/password accounts are re-checked
  /// against Firestore every time.
  Future<bool> hasApprovedRequestSession(FirestoreService firestoreService) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final isMicrosoft = user.providerData.any((p) => p.providerId == 'microsoft.com');
    if (isMicrosoft) return true;

    final email = user.email;
    if (email == null) {
      await _auth.signOut();
      return false;
    }

    // A Firestore failure here (missing index, offline, etc.) must never
    // propagate uncaught — AuthGate awaits this on every boot, and an
    // unhandled exception here previously left it stuck on the loading
    // spinner forever, since the setState() after it never ran. Fail
    // safe: treat any lookup failure as "not authenticated" rather than
    // hanging.
    try {
      final request = await firestoreService.getLatestRequestForEmail(email);
      if (request?.status == StudentRequestStatus.approved) {
        return true;
      }
      await _auth.signOut();
      return false;
    } catch (_) {
      await _auth.signOut();
      return false;
    }
  }

  Future<void> signOut() => _auth.signOut();
}