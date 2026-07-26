import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:junaid_zaidi_library_app/repositories/mock/mock_session_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/rest/rest_session_repository.dart';
import 'package:junaid_zaidi_library_app/repositories/session_repository.dart';
import 'package:junaid_zaidi_library_app/services/koha_auth_service.dart';
import 'package:junaid_zaidi_library_app/services/secure_storage_service.dart';

/// Replaces the platform channel with a map. Subclassing the service rather
/// than faking FlutterSecureStorage keeps the test away from plugin internals;
/// the super constructor's `const FlutterSecureStorage()` is never touched
/// because every method that would reach it is overridden.
class _InMemoryStorage extends SecureStorageService {
  final Map<String, String> values = {};

  @override
  Future<void> saveSession({
    required String token,
    required String patronId,
  }) async {
    values['token'] = token;
    values['patronId'] = patronId;
  }

  @override
  Future<String?> readToken() async => values['token'];

  @override
  Future<String?> readPatronId() async => values['patronId'];

  @override
  Future<bool> hasSession() async => (values['token'] ?? '').isNotEmpty;

  @override
  Future<void> clearSession() async {
    values.remove('token');
    values.remove('patronId');
  }
}

void main() {
  group('MockSessionRepository', () {
    late _InMemoryStorage storage;
    late MockSessionRepository repository;

    setUp(() {
      storage = _InMemoryStorage();
      repository = MockSessionRepository(secureStorage: storage);
    });

    test('accepts the dev account and returns its patron id', () async {
      final patronId = await repository.establishWithPassword(
        username: 'testuser',
        password: 'test1234',
      );

      expect(patronId, '0000');
    });

    test('persists a session the rest of the app can read', () async {
      await repository.establishWithPassword(
        username: 'testuser',
        password: 'test1234',
      );

      expect(await storage.hasSession(), isTrue);
      expect(await storage.readPatronId(), '0000');
      expect(await storage.readToken(), isNotEmpty);
    });

    test('rejects a wrong password', () async {
      expect(
        () => repository.establishWithPassword(
          username: 'testuser',
          password: 'wrong',
        ),
        throwsA(
          isA<SessionException>().having(
            (e) => e.message,
            'message',
            'Incorrect username or password.',
          ),
        ),
      );
    });

    test('rejects an unknown username', () async {
      expect(
        () => repository.establishWithPassword(
          username: 'someone-else',
          password: 'test1234',
        ),
        throwsA(isA<SessionException>()),
      );
    });

    test('persists nothing when credentials are rejected', () async {
      await expectLater(
        () => repository.establishWithPassword(
          username: 'testuser',
          password: 'wrong',
        ),
        throwsA(isA<SessionException>()),
      );

      expect(await repository.hasSession(), isFalse);
      expect(storage.values, isEmpty);
    });

    test('hasSession reflects the stored session', () async {
      expect(await repository.hasSession(), isFalse);

      await repository.establishWithPassword(
        username: 'testuser',
        password: 'test1234',
      );

      expect(await repository.hasSession(), isTrue);
    });

    test('clear discards the session', () async {
      await repository.establishWithPassword(
        username: 'testuser',
        password: 'test1234',
      );

      await repository.clear();

      expect(await repository.hasSession(), isFalse);
    });

    test('clear is safe when no session exists', () async {
      await expectLater(repository.clear(), completes);
      expect(await repository.hasSession(), isFalse);
    });
  });

  group('RestSessionRepository', () {
    late _InMemoryStorage storage;

    setUp(() => storage = _InMemoryStorage());

    RestSessionRepository build(MockClient client) => RestSessionRepository(
      kohaAuth: KohaAuthService(client: client, secureStorage: storage),
    );

    MockClient respondWith(
      int statusCode, {
      String body = '{}',
      void Function(http.Request)? onRequest,
    }) {
      return MockClient((request) async {
        onRequest?.call(request);
        return http.Response(body, statusCode);
      });
    }

    test('returns the patron id from a successful login', () async {
      final repository = build(
        respondWith(
          200,
          body: jsonEncode({'access_token': 'abc123', 'patron_id': 42}),
        ),
      );

      final patronId = await repository.establishWithPassword(
        username: 'student',
        password: 'secret',
      );

      expect(patronId, '42');
    });

    test('sends the credentials as a form-encoded body', () async {
      http.Request? captured;
      final repository = build(
        respondWith(
          200,
          body: jsonEncode({'access_token': 'abc123', 'patron_id': 42}),
          onRequest: (request) => captured = request,
        ),
      );

      await repository.establishWithPassword(
        username: 'student',
        password: 'secret',
      );

      expect(captured!.method, 'POST');
      expect(captured!.bodyFields, {'userid': 'student', 'password': 'secret'});
    });

    test('persists the token returned by Koha', () async {
      final repository = build(
        respondWith(
          200,
          body: jsonEncode({'access_token': 'abc123', 'patron_id': 42}),
        ),
      );

      await repository.establishWithPassword(
        username: 'student',
        password: 'secret',
      );

      expect(await storage.readToken(), 'abc123');
      expect(await storage.readPatronId(), '42');
    });

    test('translates a 401 into a credentials SessionException', () async {
      final repository = build(respondWith(401));

      expect(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'wrong',
        ),
        throwsA(
          isA<SessionException>().having(
            (e) => e.message,
            'message',
            'Incorrect username or password.',
          ),
        ),
      );
    });

    test('translates a 403 into a SessionException', () async {
      final repository = build(respondWith(403));

      expect(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'secret',
        ),
        throwsA(isA<SessionException>()),
      );
    });

    test('translates a server error into a SessionException', () async {
      final repository = build(respondWith(500));

      expect(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'secret',
        ),
        throwsA(
          isA<SessionException>().having(
            (e) => e.message,
            'message',
            contains('500'),
          ),
        ),
      );
    });

    test('translates an unreachable server into a SessionException', () async {
      final repository = build(
        MockClient((_) async => throw http.ClientException('offline')),
      );

      expect(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'secret',
        ),
        throwsA(
          isA<SessionException>().having(
            (e) => e.message,
            'message',
            contains('Could not reach the library server'),
          ),
        ),
      );
    });

    test('translates an unparseable body into a SessionException', () async {
      final repository = build(respondWith(200, body: 'not json'));

      expect(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'secret',
        ),
        throwsA(
          isA<SessionException>().having(
            (e) => e.message,
            'message',
            'Unexpected response from the library server.',
          ),
        ),
      );
    });

    test('never leaks KohaAuthException past the repository', () async {
      final repository = build(respondWith(401));

      await expectLater(
        () => repository.establishWithPassword(
          username: 'student',
          password: 'wrong',
        ),
        throwsA(isNot(isA<KohaAuthException>())),
      );
    });

    test('does not honour the dev account; it asks the server', () async {
      var requested = false;
      final repository = build(
        MockClient((_) async {
          requested = true;
          return http.Response('', 401);
        }),
      );

      await expectLater(
        () => repository.establishWithPassword(
          username: 'testuser',
          password: 'test1234',
        ),
        throwsA(isA<SessionException>()),
      );
      expect(
        requested,
        isTrue,
        reason: 'the dev bypass must live only in MockSessionRepository',
      );
    });

    test('hasSession and clear go through the stored session', () async {
      final repository = build(
        respondWith(
          200,
          body: jsonEncode({'access_token': 'abc123', 'patron_id': 42}),
        ),
      );

      expect(await repository.hasSession(), isFalse);

      await repository.establishWithPassword(
        username: 'student',
        password: 'secret',
      );
      expect(await repository.hasSession(), isTrue);

      await repository.clear();
      expect(await repository.hasSession(), isFalse);
    });
  });
}
