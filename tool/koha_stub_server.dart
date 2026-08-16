// Local stand-in for Koha's circulation REST API (checkouts, renewals,
// holds — see the "Opac Endpoint" PDF). Lets CirculationService be built
// and tested against real HTTP + JSON parsing without a reachable Koha
// instance. Swap ApiConstants.kohaBaseUrl to a real Koha URL once one
// exists and stop running this — nothing in the app needs to change.
//
// Run:  dart run tool/koha_stub_server.dart
//
// Response shapes below match real Postman testing against a live Koha
// instance (see deferred.md), not guesses: checkouts are per-item (no
// title/author/biblio_id on the object itself — CirculationService
// bridges item_id -> biblio_id via GET /api/v1/items/{id}, then to a
// title via the biblio source), and holds carry biblio_id directly but
// no title/author either.
//
// Single dev patron only (matches KohaAuthService's dev-only bypass
// account: testuser / test1234, patron_id 0000) — every request must
// send that Basic Auth, mirroring the real app's Basic-Auth-per-request
// pattern (see koha_api_client.dart). Note this is a stand-in for the
// per-request-Basic-Auth design specifically — real Koha testing since
// this stub was first written found Basic Auth disabled server-wide for
// general resource endpoints on the real production instance (see
// deferred.md); this stub still accepts it since CirculationService
// still sends it that way pending that decision.
//
// dart:io only, no pub packages — this repo's network has been too
// unreliable this session to depend on a package fetch succeeding.

import 'dart:convert';
import 'dart:io';

const _devUsername = 'testuser';
const _devPassword = 'test1234';

/// item_id -> biblio_id. biblio_id values match MockBiblioService's
/// catalog so a real title shows up once CirculationService enriches these.
final _items = <Map<String, dynamic>>[
  {'item_id': 101, 'biblio_id': 2}, // Database System Concepts
  {'item_id': 102, 'biblio_id': 9}, // Software Engineering: A Practitioner's Approach
];

final _checkouts = <Map<String, dynamic>>[
  {
    'checkout_id': 1001,
    'item_id': 101,
    'library_id': 'isb',
    'checkout_date': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
    'due_date': DateTime.now().add(const Duration(days: 4)).toIso8601String(),
    'last_renewed_date': null,
    'checkin_date': null,
    'auto_renew': false,
  },
  {
    'checkout_id': 1002,
    'item_id': 102,
    'library_id': 'isb',
    'checkout_date': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    'due_date': DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
    'last_renewed_date': null,
    'checkin_date': null,
    'auto_renew': false,
  },
];

/// Not part of the real response — the stub's own bookkeeping for which
/// checkout_ids reject a renewal, so the app's error-handling path (not
/// a client-known "renewable" flag, which doesn't exist on the real
/// endpoint) actually gets exercised.
final _nonRenewableCheckoutIds = <int>{1002};

final _holds = <Map<String, dynamic>>[
  {
    'hold_id': 501,
    'biblio_id': 6, // Artificial Intelligence: A Modern Approach
    'item_id': null,
    'item_level': false,
    'status': 'W', // "waiting" — unconfirmed field, see deferred.md
    'pickup_library_id': 'isb',
    'hold_date': DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
    'expiration_date': null,
    'cancellation_date': null,
    'cancellation_reason': null,
  },
];

var _nextHoldId = 502;

final _checkoutIdPath = RegExp(r'^/api/v1/checkouts/(\d+)/renewal$');
final _holdIdPath = RegExp(r'^/api/v1/holds/(\d+)$');
final _itemIdPath = RegExp(r'^/api/v1/items/(\d+)$');

void main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 9090);
  // ignore: avoid_print
  print('Koha circulation stub listening on http://127.0.0.1:9090 (patron 0000 / testuser)');

  await for (final request in server) {
    try {
      await _handle(request);
    } catch (e) {
      await _respond(request, 500, {'error': 'Stub server error: $e'});
    }
  }
}

Future<void> _handle(HttpRequest request) async {
  request.response.headers
    ..add('Access-Control-Allow-Origin', '*')
    ..add('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
    ..add('Access-Control-Allow-Headers', 'Authorization, Content-Type, Accept');

  if (request.method == 'OPTIONS') {
    request.response.statusCode = 204;
    await request.response.close();
    return;
  }

  if (!_isAuthorized(request)) {
    await _respond(request, 401, {'error': 'Authentication failed'});
    return;
  }

  final path = request.uri.path;
  final method = request.method;

  if (method == 'GET' && path == '/api/v1/checkouts') {
    await _respond(request, 200, _checkouts);
    return;
  }

  final itemMatch = _itemIdPath.firstMatch(path);
  if (method == 'GET' && itemMatch != null) {
    final id = int.parse(itemMatch.group(1)!);
    final item = _findById(_items, 'item_id', id);
    if (item == null) {
      await _respond(request, 404, {'error': 'Item not found'});
    } else {
      await _respond(request, 200, item);
    }
    return;
  }

  final renewalMatch = _checkoutIdPath.firstMatch(path);
  if (method == 'POST' && renewalMatch != null) {
    final id = int.parse(renewalMatch.group(1)!);
    final checkout = _findById(_checkouts, 'checkout_id', id);
    if (checkout == null) {
      await _respond(request, 404, {'error': 'Checkout not found'});
    } else if (_nonRenewableCheckoutIds.contains(id)) {
      await _respond(request, 403, {
        'error': 'This item cannot be renewed (on hold for another patron, or the renewal limit was reached)',
      });
    } else {
      checkout['due_date'] = DateTime.now().add(const Duration(days: 14)).toIso8601String();
      checkout['last_renewed_date'] = DateTime.now().toIso8601String();
      await _respond(request, 200, checkout);
    }
    return;
  }

  if (method == 'GET' && path == '/api/v1/holds') {
    await _respond(request, 200, _holds);
    return;
  }

  if (method == 'POST' && path == '/api/v1/holds') {
    final body = jsonDecode(await utf8.decoder.bind(request).join()) as Map<String, dynamic>;
    final newHold = {
      'hold_id': _nextHoldId++,
      'biblio_id': body['biblio_id'] as int,
      'item_id': null,
      'item_level': false,
      'status': 'pending',
      'pickup_library_id': body['pickup_library_id'] ?? 'isb',
      'hold_date': DateTime.now().toIso8601String(),
      'expiration_date': null,
      'cancellation_date': null,
      'cancellation_reason': null,
    };
    _holds.add(newHold);
    await _respond(request, 201, newHold);
    return;
  }

  final holdMatch = _holdIdPath.firstMatch(path);
  if (method == 'DELETE' && holdMatch != null) {
    final id = int.parse(holdMatch.group(1)!);
    _holds.removeWhere((h) => h['hold_id'] == id);
    request.response.statusCode = 204;
    await request.response.close();
    return;
  }

  await _respond(request, 404, {'error': 'Not found: $method $path'});
}

Map<String, dynamic>? _findById(List<Map<String, dynamic>> list, String key, int id) {
  for (final item in list) {
    if (item[key] == id) return item;
  }
  return null;
}

bool _isAuthorized(HttpRequest request) {
  final auth = request.headers.value('authorization');
  if (auth == null || !auth.startsWith('Basic ')) return false;
  try {
    final decoded = utf8.decode(base64.decode(auth.substring(6)));
    return decoded == '$_devUsername:$_devPassword';
  } catch (_) {
    return false;
  }
}

Future<void> _respond(HttpRequest request, int status, Object body) async {
  request.response
    ..statusCode = status
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(body));
  await request.response.close();
}
