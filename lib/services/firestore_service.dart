import 'package:cloud_firestore/cloud_firestore.dart';

import '../config/api_constants.dart';
import '../models/app_user.dart';
import '../models/student_request.dart';

class FirestoreService {
  final FirebaseFirestore _db;

  FirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _requestsCollection =>
      _db.collection(ApiConstants.firestoreStudentRequestsCollection);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _db.collection(ApiConstants.firestoreUsersCollection);

  Future<void> submitStudentRequest(StudentRequest request) async {
    await _requestsCollection.add(request.toMap());
  }

  Stream<List<StudentRequest>> watchRequestsForEmail(String email) {
    final normalized = email.trim().toLowerCase();
    return _requestsCollection
        .where('email', isEqualTo: normalized)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentRequest.fromMap(doc.id, doc.data()))
            .toList());
  }

  Future<StudentRequest?> getLatestRequestForEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final snapshot = await _requestsCollection
        .where('email', isEqualTo: normalized)
        .orderBy('createdAt', descending: true)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return StudentRequest.fromMap(doc.id, doc.data());
  }

  Future<void> saveUserProfile(AppUser user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
  }

  Future<AppUser?> getUserProfile(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.id, doc.data()!);
  }

  Future<bool> hasCompletedOnboarding(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    return doc.exists;
  }
}