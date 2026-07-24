import '../models/app_user.dart';
import '../models/profile_data.dart';
import '../models/student_request.dart';
import 'firebase_auth_service.dart';
import 'firestore_service.dart';
import 'koha_auth_service.dart';
import 'secure_storage_service.dart';

class ProfileLoader {
  final _firebaseAuth = FirebaseAuthService();
  final _firestoreService = FirestoreService();
  final _kohaAuth = KohaAuthService();
  final _secureStorage = SecureStorageService();

  Future<ProfileData?> load() async {
    final firebaseUser = _firebaseAuth.currentUser;

    if (firebaseUser != null) {
      final isMicrosoft = firebaseUser.providerData.any((p) => p.providerId == 'microsoft.com');

      if (isMicrosoft) {
        final appUser = await _firestoreService.getUserProfile(firebaseUser.uid);
        return _fromAppUser(appUser, firebaseUser.email);
      }

      final email = firebaseUser.email;
      if (email != null) {
        final request = await _firestoreService.getLatestRequestForEmail(email);
        return _fromStudentRequest(request, email);
      }
    }

    final hasKohaSession = await _kohaAuth.isLoggedIn();
    if (hasKohaSession) {
      final patronId = await _secureStorage.readPatronId();
      return ProfileData(
        fullName: 'Library Account',
        registrationNumber: 'Patron ID: ${patronId ?? 'unknown'}',
        isLimited: true,
      );
    }

    return null;
  }

  ProfileData _fromAppUser(AppUser? user, String? fallbackEmail) {
    if (user == null) {
      return ProfileData(
        fullName: 'Profile unavailable',
        registrationNumber: '',
        email: fallbackEmail,
        isLimited: true,
      );
    }
    return ProfileData(
      fullName: user.fullName,
      registrationNumber: user.registrationNumber,
      department: user.department,
      email: user.email,
      phone: user.phone,
      cnic: user.cnic,
    );
  }

  ProfileData _fromStudentRequest(StudentRequest? request, String fallbackEmail) {
    if (request == null) {
      return ProfileData(
        fullName: 'Profile unavailable',
        registrationNumber: '',
        email: fallbackEmail,
        isLimited: true,
      );
    }
    return ProfileData(
      fullName: request.fullName,
      registrationNumber: request.registrationNumber,
      department: request.department,
      email: request.email,
      phone: request.phone,
      cnic: request.cnic,
    );
  }
}