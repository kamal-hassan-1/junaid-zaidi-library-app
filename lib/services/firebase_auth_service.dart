import 'package:firebase_auth/firebase_auth.dart';

import '../config/api_constants.dart';
import '../models/student_request.dart';
import 'firestore_service.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth;

  FirebaseAuthService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

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

  /// Signs in with email/password, then checks the matching
  /// student_requests document. Both the sign-in call and the Firestore
  /// query use the SAME normalized (trimmed, lowercased) email — a real
  /// bug existed here where the raw, as-typed casing was used for the
  /// Firestore query while Firebase's own account email was already
  /// normalized, causing "no registration request found" for accounts
  /// that genuinely existed, just typed with different capitalization.
  Future<User> signInWithEmailAndPasswordApproved({
    required String email,
    required String password,
    required FirestoreService firestoreService,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(code: 'no-user', message: 'Sign-in did not return a user.');
    }

    StudentRequest? request;
    try {
      request = await firestoreService.getLatestRequestForEmail(normalizedEmail);
    } catch (_) {
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

  /// Sends a Firebase password-reset email. Deliberately does not
  /// distinguish "no account for this email" from "email sent" at the
  /// call site (see EmailLoginScreen) — showing a different message for
  /// each would let this button be used to check which emails are
  /// registered students.
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<bool> hasApprovedRequestSession(FirestoreService firestoreService) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    final isMicrosoft = user.providerData.any((p) => p.providerId == 'microsoft.com');
    if (isMicrosoft) return true;

    final email = user.email?.trim().toLowerCase();
    if (email == null) {
      await _auth.signOut();
      return false;
    }

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