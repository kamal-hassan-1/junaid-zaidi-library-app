import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/api_constants.dart';
import '../models/app_user.dart';
import '../models/student_request.dart';

/// Handles both Firestore collections used by auth:
///  - `student_requests` — the legacy librarian-approval path.
///  - `users` — the new self-onboarded Microsoft OAuth path, added here
///    in Phase 7. No approval step; a document existing at all means the
///    student completed onboarding.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _db.collection(ApiConstants.firestoreStudentRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection(ApiConstants.firestoreUsersCollection);

  // ---- Legacy student_requests path (kept, see FirebaseAuthService) ----

  Future<void> submitStudentRequest(StudentRequest request) async {
    await _requestsCollection.add(request.toMap());
  }

  Stream<List<StudentRequest>> watchRequestsForEmail(String email) {
    return _requestsCollection
        .where('email', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<StudentRequest?> getLatestRequestForEmail(String email) async {
    final snapshot = await _requestsCollection
        .where('email', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return StudentRequest.fromMap(doc.id, doc.data());
  }

  // ---- Microsoft OAuth users path (Phase 7) ----

  /// Writes (or overwrites) the onboarding profile for [user]. Document
  /// ID is always the Firebase uid — one profile per account, no
  /// approval gating.
  Future<void> saveUserProfile(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  /// A document existing at all means onboarding is done — used by
  /// AuthGate (Phase 8) to decide whether a returning Microsoft sign-in
  /// goes straight to RootShell or back through onboarding.
  Future<bool> hasCompletedOnboarding(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.exists;
  }
}