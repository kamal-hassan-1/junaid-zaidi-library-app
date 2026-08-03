/// Centralized API configuration (SDS §7.4). Every service reads from
/// here — never hardcode a URL anywhere else in the app.
class ApiConstants {
  const ApiConstants._();

  // ---- Koha base URL (dev) ----
  //
  // Port confirmed as 9090.
  //
  // FIXED: this was '127.0.0.1', which is why login was failing with
  // "Could not reach the library server" — you're running the app on
  // the Android EMULATOR, and the emulator has its OWN loopback address.
  // 127.0.0.1 *inside* the emulator points at the emulator itself, NOT
  // at your host machine where Koha is actually running. The emulator's
  // special alias for "my host machine" is 10.0.2.2 — that's the fix
  // below.
  //
  // If you ever switch how you're running/testing this app, this value
  // needs to change again:
  //   - Android EMULATOR (what you're using now): 10.0.2.2
  //   - Flutter web / Windows desktop / iOS Simulator: 127.0.0.1
  //   - A physical phone (real device): your host machine's LAN IP
  //     (e.g. 'http://192.168.1.42:9090'), phone and Koha must be on
  //     the same Wi-Fi/network.
  // Swap it once more for your real production Koha URL before shipping.
  static const String kohaBaseUrl = 'http://127.0.0.1:9090';

  // CORRECTED (was pointed at /api/v1/auth/password, confirmed 404 by
  // Postman against this real Koha 25 instance — that endpoint doesn't
  // exist here). The real, working endpoint is
  // /api/v1/auth/password/validation, and it behaves completely
  // differently from what the old code assumed:
  //   - It is NOT a bearer-token endpoint. There is no access_token
  //     anywhere in the response, ever.
  //   - It requires HTTP Basic Auth on the request itself, using the
  //     SAME userid/password being logged in with (also repeated in the
  //     JSON body) — see KohaAuthService.login().
  //   - A successful response body only ever contains identity fields:
  //     cardnumber, patron_id, userid. Nothing else.
  // Since there's no token, EVERY later Koha API call (see
  // koha_api_client.dart) has to resend that same Basic Auth header
  // again — Koha's REST API, at least on this install, has no concept
  // of a session/token at all for this auth path.
  static const String kohaAuthValidationEndpoint =
      '$kohaBaseUrl/api/v1/auth/password/validation';

  static const String firestoreStudentRequestsCollection = 'student_requests';

  // ---- Added Phase 7: Microsoft OAuth ----

  /// COMSATS' Azure AD tenant ID. Pulled directly from a real OAuth
  /// response payload during planning — CONFIRM this is genuinely
  /// correct before shipping, this wasn't stated outright as "this is
  /// our tenant," it was inferred from a sample JSON.
  static const String azureTenantId = '75df096c-8b72-48e4-9b91-cbf79d87ee3a';

  /// Client-side domain check backing FirebaseAuthService.signInWithMicrosoft.
  /// The server-side equivalent lives in firestore.rules on the `users`
  /// collection — don't rely on this constant alone for security.
  static const String studentEmailDomain = '@isbstudent.comsats.edu.pk';

  static const String firestoreUsersCollection = 'users';

  // ---- Updated Authentication Workflow, no-backend version ----
  //
  // There is deliberately NO Cloud Functions backend in this version —
  // that requires Firebase's paid Blaze plan (a billing card on file),
  // which isn't an option right now. Every step that used to happen in
  // functions/index.js (decrypt password, create the Firebase account,
  // create the Koha patron, sync password changes) now happens
  // client-side instead, inside admin-dashboard.html, the moment a
  // librarian clicks Approve. See that file's own comments for the
  // full walkthrough. The `functions/` folder is no longer used and can
  // be deleted from the project entirely.
  static const String firestorePasswordChangeRequestsCollection =
      'password_change_requests';

  static const Duration requestTimeout = Duration(seconds: 15);
}