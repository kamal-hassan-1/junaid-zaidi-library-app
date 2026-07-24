import 'package:cloud_firestore/cloud_firestore.dart';

/// Mirrors a document in Firestore's `users` collection — profiles for
/// students who signed in via Microsoft OAuth. Unlike StudentRequest,
/// there is no `status`/approval concept here: per the updated spec,
/// a successful Microsoft sign-in against COMSATS' tenant IS the
/// approval. The document ID is always the Firebase Auth uid.
class AppUser {
  final String uid;
  final String fullName;
  final String registrationNumber;
  final String email;
  final String department;
  final String phone;
  final String cnic;
  final DateTime? createdAt;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.registrationNumber,
    required this.email,
    required this.department,
    required this.phone,
    required this.cnic,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'registrationNumber': registrationNumber,
      'email': email,
      'department': department,
      'phone': phone,
      'cnic': cnic,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return AppUser(
      uid: uid,
      fullName: map['fullName'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      department: map['department'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cnic: map['cnic'] as String? ?? '',
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }
}