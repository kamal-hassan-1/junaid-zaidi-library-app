import 'dart:convert';

import '../config/api_constants.dart';
import '../models/checkout.dart';
import '../models/hold.dart';
import 'biblio_service.dart';
import 'koha_api_client.dart';
import 'mock_biblio_service.dart';
import 'secure_storage_service.dart';

/// Thrown when a circulation request fails for a reason the UI should show
/// directly (renewal blocked, hold rejected, etc). Distinct from
/// [KohaSessionExpiredException], which callers should treat as "log the
/// student out," not display as a normal error.
class CirculationException implements Exception {
  final String message;
  const CirculationException(this.message);
  @override
  String toString() => message;
}

/// Checkouts, renewals, and holds for the logged-in student — see the
/// "Opac Endpoint" PDF for the endpoints this wraps.
///
/// Every method sources `patron_id` from [SecureStorageService] itself
/// rather than accepting one as a parameter, so a circulation request can
/// never be pointed at another patron's records by a caller mistake — the
/// PDF is explicit that this must never happen.
///
/// Koha checkouts only carry an `item_id` and holds only carry a
/// `biblio_id` — neither includes title/author (confirmed against real
/// Postman testing, see deferred.md). [fetchCheckouts]/[fetchHolds] do a
/// follow-up lookup (item → biblio for checkouts, biblio directly for
/// holds) so the UI still gets a title to show, using the same
/// [BiblioSource] OPAC search uses — real or mock, whichever
/// [ApiConstants.useMockKohaBackend] currently selects.
class CirculationService {
  final KohaApiClient _client;
  final SecureStorageService _secureStorage;
  final BiblioSource _biblioSource;

  CirculationService({
    KohaApiClient? client,
    SecureStorageService? secureStorage,
    BiblioSource? biblioSource,
  })  : _client = client ?? KohaApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService(),
        _biblioSource = biblioSource ??
            (ApiConstants.useMockKohaBackend ? MockBiblioService() : BiblioService());

  Future<String> _requirePatronId() async {
    final patronId = await _secureStorage.readPatronId();
    if (patronId == null || patronId.isEmpty) {
      throw const CirculationException('Not signed in.');
    }
    return patronId;
  }

  Future<List<Checkout>> fetchCheckouts() async {
    final patronId = await _requirePatronId();
    final response = await _client.get('/api/v1/checkouts?patron_id=$patronId');
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
    final response = await _client.post('/api/v1/checkouts/$checkoutId/renewal');
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw CirculationException(
        _errorMessage(response.body) ?? 'Renewal failed (HTTP ${response.statusCode}).',
      );
    }
    final renewed = Checkout.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
    return _withCheckoutBiblioInfo(renewed);
  }

  Future<List<Hold>> fetchHolds() async {
    final patronId = await _requirePatronId();
    final response = await _client.get('/api/v1/holds?patron_id=$patronId');
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
  /// [pickupLibraryId] defaults to the main branch when omitted — the app
  /// doesn't have a branch picker yet.
  ///
  /// CONFIRMED against Opac_Endpoint.doc's real Postman testing: this is
  /// the correct, real endpoint — POST /api/v1/holds with
  /// {patron_id, biblio_id, pickup_library_id}. (An earlier attempt to
  /// guess a `/api/v1/public/...` self-service route was wrong — no such
  /// route is documented and it 404'd; reverted.)
  ///
  /// OPEN ISSUE, flagged in the source doc itself, not a code bug: that
  /// doc's own testing was done with a staff account (apiuser), which has
  /// full access. A real student's own patron account will likely lack
  /// the `reserveforothers` permission this endpoint requires, causing a
  /// 403 even for a hold on themselves — Koha's REST API doesn't appear
  /// to have a separate unprivileged patron-holds route. Per the doc:
  /// "Confirm with whoever manages Koha whether student sessions get
  /// their own more restricted token/permission" — this needs a Koha
  /// admin to grant the student patron category the permission needed to
  /// place holds via this endpoint (check Administration → Patron
  /// categories → permissions, or however this Koha version exposes
  /// patron-level API permissions). No app-side fix exists for this.
  ///
  /// CONFIRMED (real 400 response): `pickup_library_id` is REQUIRED by
  /// this Koha instance, not optional as first assumed — Koha rejects
  /// the request outright without it ("Missing property... pickup_
  /// library_id"). Since the app has no branch picker yet, default to
  /// [ApiConstants.defaultPickupLibraryId] when the caller doesn't pass
  /// one, instead of omitting the field.
  Future<Hold> placeHold({required int biblioId, String? pickupLibraryId}) async {
    final patronId = await _requirePatronId();
    final response = await _client.post('/api/v1/holds', body: {
      'patron_id': patronId,
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

  Future<void> cancelHold(int holdId) async {
    final response = await _client.delete('/api/v1/holds/$holdId');
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

  /// GET /api/v1/items/{item_id} — items carry their own biblio_id, so
  /// this is the bridge from a checkout (item-level) to a biblio (title).
  Future<int?> _biblioIdForItem(int itemId) async {
    try {
      final response = await _client.get('/api/v1/items/$itemId');
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return json['biblio_id'] as int?;
    } catch (_) {
      return null;
    }
  }

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