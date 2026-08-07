import 'package:cloud_firestore/cloud_firestore.dart';

/// Status values used by the librarian-approval workflow (SDS Â§9.7).
class StudentRequestStatus {
  StudentRequestStatus._();
  static const String pending = 'Pending';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
}

/// Who this registration request is for. Mirrors the Student / Staff /
/// Teacher split already used as a display-only toggle on
/// email_login_screen.dart â€” this is what makes that toggle mean
/// something end-to-end. [student] fills in the full SignupFormScreen
/// (registration number, department, phone, CNIC, the works). [staff]
/// and [teacher] both go through the lighter StaffSignupFormScreen â€”
/// name, COMSATS email, campus, and password only â€” since neither has
/// a registration number or a CNIC-on-file requirement.
class RegistrationRole {
  RegistrationRole._();
  static const String student = 'Student';
  static const String staff = 'Staff';
  static const String teacher = 'Teacher';
}

/// Mirrors a single document in the `student_requests` Firestore
/// collection â€” despite the name, this now holds Student, Staff, and
/// Teacher registration requests alike, distinguished by [role]. Field
/// names here must stay in sync with firestore.rules â€” the rules check
/// `request.resource.data.email`, `.status`, and `.encryptedPassword`
/// by name.
///
/// [fullName], [registrationNumber], [department], [phone], and [cnic]
/// are Student-only fields. For a Staff/Teacher request they're left as
/// empty strings rather than omitted â€” the model always has the same
/// shape client-side, so callers never need to null-check based on
/// [role]; [toMap] is the only place that actually decides which keys
/// get written to Firestore for a given role.
///
/// [encryptedPassword] holds the account's password, RSA-OAEP encrypted
/// client-side with `CryptoConstants.passwordEncryptionPublicKeyPem`
/// (Updated Authentication Workflow, Phase 1 / Step 2). No Firebase
/// account and no Koha patron exist yet while this document is Pending â€”
/// see `functions/index.js` for what happens on approval. NOTE: as of
/// the Student/Staff/Teacher role split, `functions/index.js` still
/// needs to branch on `role` too â€” today it assumes every approved
/// document is a full student record. A Staff/Teacher approval should
/// still create a Firebase account, but likely wants a different (or no)
/// Koha patron category, since neither has a registration number.
///
/// This field is deleted by the Cloud Function the moment it finishes
/// creating the Firebase + Koha accounts (Phase 3 / Step 11 of the
/// workflow doc) â€” a document should never sit in `Approved` status
/// with `encryptedPassword` still populated for long. If you see one
/// that has, the Cloud Function failed partway through; check its logs
/// before manually approving anything else for that request.
class StudentRequest {
  final String? id; // Firestore document ID, null until saved
  final String role;
  final String campus;
  final String fullName;
  final String registrationNumber;
  final String department;
  final String email;
  final String phone;
  final String cnic;
  final String encryptedPassword;
  final String status;
  final DateTime? createdAt;

  const StudentRequest({
    this.id,
    this.role = RegistrationRole.student,
    required this.campus,
    required this.fullName,
    this.registrationNumber = '',
    this.department = '',
    required this.email,
    this.phone = '',
    this.cnic = '',
    required this.encryptedPassword,
    this.status = StudentRequestStatus.pending,
    this.createdAt,
  });

  /// Builds a Staff or Teacher request â€” just the fields the lighter
  /// signup form actually collects. [role] must be
  /// [RegistrationRole.staff] or [RegistrationRole.teacher].
  factory StudentRequest.forOtherRole({
    required String role,
    required String fullName,
    required String campus,
    required String email,
    required String encryptedPassword,
  }) {
    assert(role != RegistrationRole.student,
        'Use the default StudentRequest constructor for students.');
    return StudentRequest(
      role: role,
      campus: campus,
      fullName: fullName,
      email: email,
      encryptedPassword: encryptedPassword,
    );
  }

  bool get isStudent => role == RegistrationRole.student;

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'role': role,
      'campus': campus,
      'fullName': fullName,
      'email': email,
      'encryptedPassword': encryptedPassword,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
    // Student-only fields never get written for a Staff/Teacher
    // request â€” keeps those documents lean and matches what the form
    // actually asked for, rather than padding them with empty strings.
    if (isStudent) {
      map['registrationNumber'] = registrationNumber;
      map['department'] = department;
      map['phone'] = phone;
      map['cnic'] = cnic;
    }
    return map;
  }

  factory StudentRequest.fromMap(String id, Map<String, dynamic> map) {
    final ts = map['createdAt'];
    return StudentRequest(
      id: id,
      // Documents written before the role split don't have this field
      // at all â€” treat those as Student, since that was the only role
      // that could exist back then.
      role: map['role'] as String? ?? RegistrationRole.student,
      campus: map['campus'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      registrationNumber: map['registrationNumber'] as String? ?? '',
      department: map['department'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      cnic: map['cnic'] as String? ?? '',
      // Absent once the Cloud Function has processed approval and
      // deleted it â€” never assume this is non-empty for an Approved doc.
      encryptedPassword: map['encryptedPassword'] as String? ?? '',
      status: map['status'] as String? ?? StudentRequestStatus.pending,
      createdAt: ts is Timestamp ? ts.toDate() : null,
    );
  }

  StudentRequest copyWith({String? status, String? encryptedPassword}) {
    return StudentRequest(
      id: id,
      role: role,
      campus: campus,
      fullName: fullName,
      registrationNumber: registrationNumber,
      department: department,
      email: email,
      phone: phone,
      cnic: cnic,
      encryptedPassword: encryptedPassword ?? this.encryptedPassword,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
