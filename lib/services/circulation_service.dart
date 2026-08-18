import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

import '../config/api_constants.dart';
import '../models/checkout.dart';
import '../models/hold.dart';
import '../models/patron_account.dart';
import 'biblio_service.dart';
import 'mock_biblio_service.dart';

/// Thrown when a circulation request fails for a reason the UI should show
/// directly (renewal blocked, hold rejected, etc).
class CirculationException implements Exception {
  final String message;
  const CirculationException(this.message);
  @override
  String toString() => message;
}

/// Checkouts, renewals, and holds for the logged-in student.
///
/// SECURITY FIX (2026-08-18, see deferred.md / worker/README.md): this
/// used to call Koha directly with a shared staff-level service account
/// embedded in the app, with `patron_id` scoping enforced only
/// client-side — meaning anyone who extracted that credential could
/// read/act on ANY patron's data, not just the logged-in one. Every
/// method here now goes through a small Cloudflare Worker instead
/// ([ApiConstants.circulationProxyBaseUrl]), authenticated with the
/// student's real Firebase ID token. The Worker verifies that token,
/// resolves the caller's OWN Koha patron_id itself server-side, and
/// holds the actual Koha credential — this app never sees it and can't
/// send a patron_id the Worker would trust anyway.
///
/// Koha checkouts only carry an `item_id` and holds only carry a
/// `biblio_id` — neither includes title/author (confirmed against real
/// Koha, see deferred.md). [fetchCheckouts]/[fetchHolds] do a follow-up
/// lookup (item → biblio for checkouts, biblio directly for holds) so
/// the UI still gets a title to show, using the same [BiblioSource]
/// OPAC search uses — real or mock, whichever
/// [ApiConstants.useMockKohaBackend] currently selects. That lookup
/// still talks to Koha directly (not through the Worker) — catalog data
/// is public-equivalent, not the privacy-sensitive surface the Worker
/// exists for; see [ApiConstants.circulationProxyBaseUrl]'s doc comment.
class CirculationService {
  final http.Client _client;
  final BiblioSource _biblioSource;
  final FirebaseAuth _auth;

  CirculationService({
    http.Client? client,
    BiblioSource? biblioSource,
    FirebaseAuth? auth,
  })  : _client = client ?? http.Client(),
        _biblioSource = biblioSource ??
            (ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService()),
        _auth = auth ?? FirebaseAuth.instance;

  Future<List<Checkout>> fetchCheckouts() async {
    final response = await _get('/checkouts');
    if (response.statusCode != 200) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Could not load your checkouts (HTTP ${response.statusCode}).',
      );
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    final checkouts = list.map((e) => Checkout.fromJson(e as Map<String, dynamic>)).toList();
    return Future.wait(checkouts.map(_withCheckoutBiblioInfo));
  }

  Future<Checkout> renewCheckout(int checkoutId) async {
    final response = await _post('/checkouts/$checkoutId/renewal');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Renewal failed (HTTP ${response.statusCode}).',
      );
    }
    final renewed = Checkout.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    return _withCheckoutBiblioInfo(renewed);
  }

  Future<List<Hold>> fetchHolds() async {
    final response = await _get('/holds');
    if (response.statusCode != 200) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Could not load your holds (HTTP ${response.statusCode}).',
      );
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    final holds = list.map((e) => Hold.fromJson(e as Map<String, dynamic>)).toList();
    return Future.wait(holds.map(_withHoldBiblioInfo));
  }

  /// Places a hold (reservation) on [biblioId] for the logged-in student.
  /// Which patron this hold is placed for is decided by the Worker from
  /// the caller's Firebase token, not by anything sent here — there is
  /// deliberately no `patron_id` in this request at all anymore.
  ///
  /// CONFIRMED live against a real Koha instance: `pickup_library_id` is
  /// REQUIRED — Koha 400s with "Missing property pickup_library_id" if
  /// it's left out, even though the docs read as if it were optional.
  /// The app has no branch picker yet, so [pickupLibraryId] falls back to
  /// [ApiConstants.defaultPickupLibraryId] when the caller doesn't pass
  /// one, instead of omitting the field.
  Future<Hold> placeHold({required int biblioId, String? pickupLibraryId}) async {
    final response = await _post('/holds', body: {
      'biblio_id': biblioId,
      'pickup_library_id': pickupLibraryId ?? ApiConstants.defaultPickupLibraryId,
    });
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Could not place hold (HTTP ${response.statusCode}).',
      );
    }
    final hold = Hold.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    return _withHoldBiblioInfo(hold);
  }

  /// Confirmed live (2026-08-18, see deferred.md): posted a real test
  /// debit and inspected the response, not just the docs.
  Future<PatronAccount> fetchAccount() async {
    final response = await _get('/account');
    if (response.statusCode != 200) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Could not load your account (HTTP ${response.statusCode}).',
      );
    }
    return PatronAccount.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// The signed-in patron's checkout limit — how many items their patron
  /// category (undergrad/grad/PhD/etc, whatever the library's Koha admin
  /// has configured) is allowed to have out at once. See the Worker's
  /// `handleCheckoutLimit` for the same real-Koha-confirmed
  /// `circulation_rules` lookup this used to do directly.
  Future<int?> fetchCheckoutLimit() async {
    final response = await _get('/checkout-limit');
    if (response.statusCode != 200) return null;
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['max_issue_qty'] as int?;
  }

  Future<void> cancelHold(int holdId) async {
    final response = await _delete('/holds/$holdId');
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Could not cancel hold (HTTP ${response.statusCode}).',
      );
    }
  }

  Future<Checkout> _withCheckoutBiblioInfo(Checkout checkout) async {
    final biblioId = await _biblioIdForItem(checkout.itemId);
    if (biblioId == null) return checkout;
    final biblio = await _biblioSource.fetchOne(biblioId);
    return checkout.withBiblioInfo(title: biblio?.title, author: biblio?.author);
  }

  Future<Hold> _withHoldBiblioInfo(Hold hold) async {
    final biblio = await _biblioSource.fetchOne(hold.biblioId);
    return hold.withBiblioInfo(title: biblio?.title, author: biblio?.author);
  }

  /// Bridge from a checkout (item-level) to a biblio (title) — via the
  /// Worker's `/items/{id}` (proxied straight through to Koha's
  /// `GET /api/v1/items/{item_id}`, confirmed live 2026-08-17), not
  /// called directly, so the app never needs Koha credentials for any
  /// part of the circulation flow.
  Future<int?> _biblioIdForItem(int itemId) async {
    try {
      final response = await _get('/items/$itemId');
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['biblio_id'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, String>> _authHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const CirculationException('Not signed in.');
    }
    final idToken = await user.getIdToken();
    return {
      'Authorization': 'Bearer $idToken',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Uri _resolve(String path) => Uri.parse('${ApiConstants.circulationProxyBaseUrl}$path');

  Future<http.Response> _get(String path) async =>
      _client.get(_resolve(path), headers: await _authHeaders()).timeout(ApiConstants.requestTimeout);

  Future<http.Response> _post(String path, {Object? body}) async => _client
      .post(_resolve(path), headers: await _authHeaders(), body: body == null ? null : jsonEncode(body))
      .timeout(ApiConstants.requestTimeout);

  Future<http.Response> _delete(String path) async =>
      _client.delete(_resolve(path), headers: await _authHeaders()).timeout(ApiConstants.requestTimeout);

  String? _errorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return (decoded['error'] ?? decoded['message'])?.toString();
      }
    } catch (_) {
      // Non-JSON error body — fall through to the generic HTTP-status message.
    }
    return null;
  }
}
