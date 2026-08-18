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
  //
  // SECURITY GUARD (added after a repo audit found this app runs Basic
  // Auth over whatever scheme is set here, resent on every single Koha
  // request — there's no session/token, see kohaAuthValidationEndpoint's
  // comment below). Plain HTTP to anything other than a local/dev address
  // means real student credentials are sniffable in cleartext on any
  // shared network (campus WiFi being the obvious case). `_requireSafeUrl`
  // below throws immediately, in EVERY build mode including release (not
  // just `assert`, which release builds strip), if this is ever set to a
  // non-local http:// URL — so shipping that mistake fails loudly at
  // first Koha call instead of silently leaking credentials.
  static final String kohaBaseUrl = _requireSafeUrl('http://127.0.0.1:9090');

  static String _requireSafeUrl(String url) {
    final uri = Uri.parse(url);
    const localHosts = {'127.0.0.1', '10.0.2.2', 'localhost'};
    final isLocal = localHosts.contains(uri.host) ||
        uri.host.startsWith('192.168.') ||
        uri.host.startsWith('10.') ||
        uri.host.startsWith('172.');
    if (uri.scheme == 'http' && !isLocal) {
      throw StateError(
        'ApiConstants.kohaBaseUrl is "$url" — plain HTTP to a non-local '
        'host. Koha auth resends the real username/password on every '
        'request; over HTTP on a shared network that credential is '
        'trivially sniffable. Use https:// for the real deployment URL.',
      );
    }
    return url;
  }

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
  static final String kohaAuthValidationEndpoint =
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

  // ---- OPAC search, dev toggle ----
  //
  // No Koha instance is reachable from this dev machine yet (nothing
  // listening on kohaBaseUrl). Until a real URL is available, BiblioService
  // is backed by MockBiblioService instead (see opac.dart) so the search
  // bar UI/UX — debounce, loading state, server-shaped query params — can
  // be built and tested now. Flip this to false the moment a real Koha URL
  // is wired up; nothing else needs to change, since both implementations
  // share the same BiblioSource interface.
  static const bool useMockKohaBackend = true;

  // ---- Hold pickup location ----
  //
  // CONFIRMED against a real Koha instance: POST /api/v1/holds rejects
  // the request outright ("Missing property pickup_library_id") if this
  // field is omitted -- it is NOT optional, despite the Koha docs reading
  // that way. The app has no branch picker yet, so every hold placed
  // (single, from OPAC's detail sheet, and bulk, from the Book Bag) needs
  // a default. 'CPL' is a real, registered library code on the Koha
  // instance this was verified against -- confirm it's still correct (or
  // swap it) if pointed at a different Koha with different branch codes.
  static const String defaultPickupLibraryId = 'CPL';

  // ---- Circulation proxy (security fix) ----
  //
  // Checkouts/holds/fines used to be called directly against Koha using
  // KohaServiceAccount's staff-level credential embedded in this app —
  // a real vulnerability, since Koha can't scope that credential to
  // "only this one patron," and the credential had already leaked (this
  // repo is public). Those calls now go through a small Cloudflare
  // Worker (see /worker at the repo root) that verifies the caller's
  // real Firebase login, resolves THEIR OWN Koha patron_id server-side,
  // and holds the Koha credential itself instead — nothing the app sends
  // can make it act on someone else's record.
  //
  // Search/catalog browsing (BiblioService) still goes straight to Koha
  // — deliberately out of scope for the proxy, since catalog data is
  // public-equivalent (the real OPAC website shows the same data to
  // anyone), not the privacy-sensitive surface the proxy exists for.
  //
  // Not yet deployed — see worker/README.md. Empty until you deploy it
  // and fill in the real Worker URL (e.g.
  // 'https://jzl-koha-proxy.<your-subdomain>.workers.dev').
  static const String circulationProxyBaseUrl = '';
}