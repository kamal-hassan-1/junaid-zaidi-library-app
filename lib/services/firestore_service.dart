import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/api_constants.dart';
import '../models/student_request.dart';

/// Handles the `student_requests` collection. Every write here must
/// satisfy firestore.rules exactly — if a create fails with
/// permission-denied, check that the signed-in user's email/verification
/// state matches what the document claims before assuming this code is
/// wrong.
class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _db.collection(ApiConstants.firestoreStudentRequestsCollection);

  /// Submits a new registration request. Requires the caller to already
  /// be signed in with a verified Firebase account whose email matches
  /// [request.email] — enforced both here and by firestore.rules.
  Future<void> submitStudentRequest(StudentRequest request) async {
    await _collection.add(request.toMap());
  }

  /// Watches the current student's own request(s) so status screens can
  /// react live to librarian approval. Rules restrict reads to the
  /// requester's own email, so this query is always self-scoped.
  Stream<List<StudentRequest>> watchRequestsForEmail(String email) {
    return _collection
        .where('email', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => StudentRequest.fromMap(doc.id, doc.data()))
        .toList());
  }

  /// One-shot fetch of the most recent request for this email. Returns
  /// null if no request exists yet.
  Future<StudentRequest?> getLatestRequestForEmail(String email) async {
    final snapshot = await _collection
        .where('email', isEqualTo: email)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return StudentRequest.fromMap(doc.id, doc.data());
  }
}