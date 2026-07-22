/// Centralized API configuration (SDS §7.4). Every service reads from
/// here — never hardcode a URL anywhere else in the app.
class ApiConstants {
  const ApiConstants._();

  // TODO(Muaaz): replace with your actual Koha base URL, e.g.
  // "https://library.comsats.edu.pk" — no trailing slash.
  static const String kohaBaseUrl = 'http://192.168.1.5:8080';

  static const String kohaAuthEndpoint = '$kohaBaseUrl/api/v1/auth/password';

  static const String firestoreStudentRequestsCollection = 'student_requests';

  static const Duration requestTimeout = Duration(seconds: 15);
}
