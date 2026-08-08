import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_constants.dart';
import '../models/student_request.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  final FirebaseAuth? _authOverride;

  /// Does not touch [FirebaseAuth.instance] until first use, so AuthGate can
  /// be constructed before [Firebase.initializeApp] finishes.
  FirebaseAuthService({FirebaseAuth? auth}) : _authOverride = auth;

  FirebaseAuth get _auth => _authOverride ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Updated Authentication Workflow, Phase 3 (Steps 12-15): the real,
  /// day-to-day login. No separate "approved" check is needed here the
  /// way the old signInWithEmailAndPasswordApproved() did one — the
  /// Cloud Function (functions/index.js) only ever creates a Firebase
  /// account AFTER a librarian approves the student, so a Firebase
  /// account existing at all already implies approval. If sign-in fails
  /// with user-not-found, describeSignInFailure() below turns that into
  /// a friendlier "still pending" / "rejected" / "no such account"
  /// message by checking student_requests instead.
  Future<User> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Sign-in did not return a user.');
    }
    return user;
  }

  /// Turns a failed Firebase sign-in into a message that tells the
  /// student what's actually going on, using their student_requests
  /// history — e.g. "still pending" reads very differently from "wrong
  /// password" even though Firebase itself can't tell them apart (no
  /// account exists yet in both cases).
  Future<String> describeSignInFailure(String email, FirestoreService firestoreService) async {
    StudentRequest? request;
    try {
      request = await firestoreService.getLatestRequestForEmail(email.trim().toLowerCase());
    } catch (_) {
      return 'Incorrect email or password.';
    }

    if (request == null) return 'Incorrect email or password.';

    switch (request.status) {
      case StudentRequestStatus.pending:
        return 'Your registration is still pending librarian approval.';
      case StudentRequestStatus.rejected:
        return 'Your registration request was rejected.';
      case StudentRequestStatus.approved:
        // A request is Approved but sign-in still failed — most likely
        // a wrong password, or the Cloud Function is still processing
        // (student_requests.processingError would be set if it failed
        // outright — that's surfaced to admins on the dashboard, not
        // here, since there's nothing the student themselves can do
        // about a Koha API outage).
        return 'Incorrect email or password.';
      default:
        return 'Incorrect email or password.';
    }
  }

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

  /// Sends a Firebase password-reset email. Deliberately does not
  /// distinguish "no account for this email" from "email sent" at the
  /// call site (see EmailLoginScreen) — showing a different message for
  /// each would let this button be used to check which emails are
  /// registered students.
  ///
  /// Note: this resets the FIREBASE half of the student's password only.
  /// Under the dual-login model, that would leave Firebase and Koha out
  /// of sync — Updated Authentication Workflow Phase 7 exists precisely
  /// to avoid that by routing all password changes through an admin who
  /// updates both sides together. Consider hiding this button once
  /// Phase 5's request-password-change screen ships, so there's exactly
  /// one path for changing a password, not two that can drift apart.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> signOut() => _auth.signOut();
}