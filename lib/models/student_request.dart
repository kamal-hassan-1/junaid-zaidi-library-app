import 'package:cloud_firestore/cloud_firestore.dart';

/// Status values used by the librarian-approval workflow (SDS §9.7).
class StudentRequestStatus {
  StudentRequestStatus._();
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
}

/// Mirrors a single document in the `student_requests` Firestore
/// collection. Field names here must stay in sync with firestore.rules —
/// the rules check `request.resource.data.email` and `.status` by name.
class StudentRequest {
  final String? id; // Firestore document ID, null until saved
  final String fullName;
  final String registrationNumber;
  final String department;
  final String email;
  final String phone;
  final String cnic;
  final String status;
  final DateTime? createdAt;

  const StudentRequest({
    this.id,
    required this.fullName,
    required this.registrationNumber,
    required this.department,
    required this.email,
    required this.phone,
    required this.cnic,
    this.status = StudentRequestStatus.pending,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'registrationNumber': registrationNumber,
      'department': department,
      'email': email,
      'phone': phone,
      'cnic': cnic,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory StudentRequest.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return StudentRequest(
      id: id,
      fullName: map['fullName'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      department: map['department'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cnic: map['cnic'] as String? ?? '',
      status: map['status'] as String? ?? StudentRequestStatus.pending,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  StudentRequest copyWith({String? status}) {
    return StudentRequest(
      id: id,
      fullName: fullName,
      registrationNumber: registrationNumber,
      department: department,
      email: email,
      phone: phone,
      cnic: cnic,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}