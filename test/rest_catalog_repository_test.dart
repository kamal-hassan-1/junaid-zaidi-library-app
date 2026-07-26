import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:junaid_zaidi_library_app/data/search_indexes.dart';
import 'package:junaid_zaidi_library_app/models/catalog_holding.dart';
import 'package:junaid_zaidi_library_app/repositories/catalog_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/rest/rest_catalog_repository.dart';

/// Covers RestCatalogRepository's HTTP layer: the requests it builds, the
/// headers it attaches, and how each kind of failure is translated for the
/// screens. No server is involved — every response comes from MockClient.
void main() {
  const baseUrl = 'https://juno.test';

  /// The last request the repository sent, for asserting on URLs and headers.
  http.Request? sent;

  setUp(() => sent = null);

  RestCatalogRepository build(
    Future<http.Response> Function(http.Request request) handler, {
    String url = baseUrl,
    AuthTokenProvider? tokenProvider,
    Duration? timeout,
  }) {
    return RestCatalogRepository(
      baseUrl: url,
      tokenProvider: tokenProvider,
      timeout: timeout,
      client: MockClient((request) {
        sent = request;
        return handler(request);
      }),
    );
  }

  /// Answers every request with [body] as JSON.
  RestCatalogRepository serving(
    Object body, {
    int status = 200,
    String url = baseUrl,
    AuthTokenProvider? tokenProvider,
  }) {
    return build(
      (_) async => http.Response(
        jsonEncode(body),
        status,
        headers: {'content-type': 'application/json'},
      ),
      url: url,
      tokenProvider: tokenProvider,
    );
  }

  final searchBody = {
    'results': [
      {
        'id': '1',
        'title': 'Introduction to Algorithms',
        'author': 'Cormen',
        'availableCount': 2,
        'totalCount': 5,
      },
    ],
    'page': 2,
    'perPage': 10,
    'totalResults': 37,
    'hasMore': true,
  };

  group('request construction', () {
    test('search targets /api/v1/juno/search with the expected query', () async {
      await serving(searchBody).search(query: '  algorithms  ');

      expect(sent!.method, 'GET');
      expect(sent!.url.origin, baseUrl);
      expect(sent!.url.path, '/api/v1/juno/search');
      expect(sent!.url.queryParameters, {
        // Trimmed, matching what the mock searches on.
        'q': 'algorithms',
        'index': 'keyword',
        'page': '1',
        'per_page': '20',
      });
    });

    test('search passes the selected index and pagination through', () async {
      await serving(searchBody).search(
        query: '9780262033848',
        index: SearchIndex.isbn,
        page: 3,
        perPage: 5,
      );

      expect(sent!.url.queryParameters, {
        'q': '9780262033848',
        'index': 'isbn',
        'page': '3',
        'per_page': '5',
      });
    });

    test('a blank query is answered without any request', () async {
      final result = await serving(searchBody).search(query: '   ');

      expect(sent, isNull, reason: 'nothing worth asking the backend');
      expect(result.isEmpty, isTrue);
      expect(result.totalResults, 0);
    });

    test('getBiblio targets /biblios/{id}', () async {
      await serving({'id': '42', 'title': 'Clean Code'}).getBiblio('42');

      expect(sent!.url.path, '/api/v1/juno/biblios/42');
    });

    test('an awkward id stays inside one path segment', () async {
      await serving({'id': 'a b/c', 'title': 'x'}).getBiblio('a b/c');

      // Decoded back, the whole id is the final segment — so the slash was
      // encoded rather than splitting the path.
      expect(sent!.url.pathSegments.last, 'a b/c');
    });

    test('featured targets the placeholder shelf endpoint', () async {
      await serving(const []).featured();

      expect(sent!.url.path, '/api/v1/juno/featured');
      expect(sent!.url.queryParameters, isEmpty);
    });

    test('a trailing slash on baseUrl does not double up', () async {
      await serving(
        {'id': '1', 'title': 'x'},
        url: '$baseUrl/',
      ).getBiblio('1');

      expect(sent!.url.toString(), '$baseUrl/api/v1/juno/biblios/1');
    });
  });

  group('authorization', () {
    test('no token provider means an unauthenticated request', () async {
      await serving(searchBody).search(query: 'x');

      expect(sent!.headers, isNot(contains('Authorization')));
      expect(sent!.headers['Accept'], 'application/json');
    });

    test('a token is attached as a bearer credential', () async {
      await serving(
        searchBody,
        tokenProvider: () async => 'jwt-123',
      ).search(query: 'x');

      expect(sent!.headers['Authorization'], 'Bearer jwt-123');
    });

    test('a provider with no session leaves the request unauthenticated', () async {
      await serving(searchBody, tokenProvider: () async => null).search(query: 'x');

      expect(sent!.headers, isNot(contains('Authorization')));
    });

    test('an empty token is treated as no session', () async {
      await serving(searchBody, tokenProvider: () async => '').search(query: 'x');

      expect(sent!.headers, isNot(contains('Authorization')));
    });

    test('a failing token refresh is reported as a session problem', () async {
      final repository = serving(
        searchBody,
        tokenProvider: () async => throw Exception('refresh failed'),
      );

      await expectLater(
        repository.search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('sign in again'),
          ),
        ),
      );
      expect(sent, isNull, reason: 'no point sending a request we cannot authorize');
    });
  });

  group('parsing', () {
    test('search is decoded by CatalogSearchResult.fromJson', () async {
      final result = await serving(searchBody).search(query: 'algorithms');

      expect(result.items, hasLength(1));
      expect(result.items.single.title, 'Introduction to Algorithms');
      expect(result.items.single.author, 'Cormen');
      expect(result.items.single.availableCount, 2);
      expect(result.page, 2);
      expect(result.perPage, 10);
      expect(result.totalResults, 37);
      expect(result.hasMore, isTrue);
    });

    test('getBiblio is decoded with its holdings inline', () async {
      final book = await serving({
        'id': '42',
        'title': 'Clean Code',
        'year': 2008,
        'availableCount': 0,
        'totalCount': 1,
        'holdings': [
          {
            'itemId': 'i1',
            'library': 'Main Library',
            'callNumber': 'QA76.76',
            'availability': 'checked_out',
            'dueDate': '2026-08-01T00:00:00Z',
          },
        ],
      }).getBiblio('42');

      expect(book.title, 'Clean Code');
      expect(book.year, 2008);
      expect(book.holdings, hasLength(1));

      final holding = book.holdings!.single;
      expect(holding.library, 'Main Library');
      expect(holding.availability, ItemAvailability.checkedOut);
      expect(holding.dueDate, DateTime.utc(2026, 8, 1));
    });

    test('an unrecognized availability is read as unavailable', () async {
      final book = await serving({
        'id': '1',
        'title': 'x',
        'holdings': [
          {'itemId': 'i1', 'availability': 'in_transit'},
        ],
      }).getBiblio('1');

      expect(book.holdings!.single.availability, ItemAvailability.unavailable);
    });

    test('featured is decoded into items', () async {
      final items = await serving([
        {'id': '1', 'title': 'First'},
        {'id': '2', 'title': 'Second'},
      ]).featured();

      expect(items.map((item) => item.title), ['First', 'Second']);
    });
  });

  group('failures', () {
    test('404 on a biblio is a not-found, not an error', () async {
      await expectLater(
        serving({'error': 'nope'}, status: 404).getBiblio('999'),
        throwsA(isA<CatalogNotFoundException>()),
      );
    });

    test('404 on search is an ordinary failure', () async {
      // A missing search endpoint is a deployment problem, not a student
      // searching for something that does not exist.
      await expectLater(
        serving({'error': 'nope'}, status: 404).search(query: 'x'),
        throwsA(
          allOf(
            isA<CatalogException>(),
            isNot(isA<CatalogNotFoundException>()),
          ),
        ),
      );
    });

    test('a rejected session is called out as such', () async {
      await expectLater(
        serving({}, status: 401).search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('session has expired'),
          ),
        ),
      );
    });

    test('a server error names the status code', () async {
      await expectLater(
        serving({}, status: 503).search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('503'),
          ),
        ),
      );
    });

    test('a body that is not JSON is a catalog failure', () async {
      final repository = build(
        (_) async => http.Response('<html>gateway</html>', 200),
      );

      await expectLater(
        repository.search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('Unexpected response'),
          ),
        ),
      );
    });

    test('valid JSON of the wrong shape is a catalog failure', () async {
      // An array where an object belongs would otherwise reach the model
      // factory and blow up as a TypeError.
      await expectLater(
        serving(const []).getBiblio('1'),
        throwsA(isA<CatalogException>()),
      );
    });

    test('featured given an object instead of a list fails cleanly', () async {
      await expectLater(
        serving({'results': []}).featured(),
        throwsA(isA<CatalogException>()),
      );
    });

    test('a dropped connection becomes a connection message', () async {
      final repository = build(
        (_) async => throw http.ClientException('connection closed'),
      );

      await expectLater(
        repository.search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('Check your connection'),
          ),
        ),
      );
    });

    test('a slow backend times out rather than hanging', () async {
      final repository = build((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        return http.Response('{}', 200);
      }, timeout: const Duration(milliseconds: 20));

      await expectLater(
        repository.search(query: 'x'),
        throwsA(
          isA<CatalogException>().having(
            (e) => e.message,
            'message',
            contains('too long'),
          ),
        ),
      );
    });
  });
}
