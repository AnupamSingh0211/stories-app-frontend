import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/core/backend_api_client.dart';

void main() {
  group('BackendApiClient', () {
    test('attaches a bearer token to authenticated requests only', () async {
      final transport = _FakeBackendTransport(
        response: const BackendTransportResponse(
          statusCode: 200,
          body:
              '{"success":true,"data":{"userId":"0568b0f9-cbaa-4b72-a8b3-3a9233ae4261"}}',
          headers: {'content-type': 'application/json'},
        ),
      );
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: const _FakeSessionReader('access-token-123'),
        transport: transport,
      );

      await client.probeAuthenticatedIdentity();

      expect(transport.requests, hasLength(1));
      expect(
        transport.requests.single.headers['Authorization'],
        'Bearer access-token-123',
      );

      transport.requests.clear();
      transport.response = const BackendTransportResponse(
        statusCode: 200,
        body: '{"success":true,"data":[]}',
        headers: {'content-type': 'application/json'},
      );
      await client.getList('/api/v1/public-stories');
      expect(
        transport.requests.single.headers.containsKey('Authorization'),
        isFalse,
      );
    });

    test('throws safely when an authenticated session is missing', () async {
      var unauthorizedCalls = 0;
      final transport = _FakeBackendTransport(
        response: const BackendTransportResponse(
          statusCode: 200,
          body: '{"success":true,"data":[]}',
          headers: {'content-type': 'application/json'},
        ),
      );
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: const _FakeSessionReader(null),
        transport: transport,
        onUnauthorized: () {
          unauthorizedCalls++;
        },
      );

      await expectLater(
        client.getList('/api/v1/profiles', authenticated: true),
        throwsA(
          isA<MissingAuthenticatedSessionException>().having(
            (error) => error.isUnauthorized,
            'isUnauthorized',
            true,
          ),
        ),
      );
      expect(unauthorizedCalls, 1);
      expect(transport.requests, isEmpty);
    });

    test('maps unauthorized backend responses to a safe auth error', () async {
      var unauthorizedCalls = 0;
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: const _FakeSessionReader('expired-token'),
        transport: _FakeBackendTransport(
          response: const BackendTransportResponse(
            statusCode: 401,
            body: '{"success":false,"message":"Authentication required"}',
            headers: {'content-type': 'application/json'},
          ),
        ),
        onUnauthorized: () {
          unauthorizedCalls++;
        },
      );

      await expectLater(
        client.getList('/api/v1/profiles', authenticated: true),
        throwsA(
          isA<BackendApiException>()
              .having((error) => error.isUnauthorized, 'isUnauthorized', true)
              .having(
                (error) => error.message,
                'message',
                contains('Authentication required'),
              ),
        ),
      );
      expect(unauthorizedCalls, 1);
    });

    test(
      'central unauthorized handler signs out once for forbidden responses',
      () async {
        var signOutCalls = 0;
        final client = BackendApiClient(
          baseUrl: 'http://localhost:5000',
          sessionReader: const _FakeSessionReader('forbidden-token'),
          transport: _FakeBackendTransport(
            response: const BackendTransportResponse(
              statusCode: 403,
              body:
                  '{"success":false,"message":"Authenticated account required"}',
              headers: {'content-type': 'application/json'},
            ),
          ),
          onUnauthorized: () async {
            signOutCalls++;
          },
        );

        await expectLater(
          client.getObject('/api/v1/auth/me', authenticated: true),
          throwsA(
            isA<BackendApiException>()
                .having((error) => error.statusCode, 'statusCode', 403)
                .having(
                  (error) => error.isUnauthorized,
                  'isUnauthorized',
                  true,
                ),
          ),
        );

        expect(signOutCalls, 1);
      },
    );

    test(
      'unauthorized handler failures do not mask the backend auth error',
      () async {
        final client = BackendApiClient(
          baseUrl: 'http://localhost:5000',
          sessionReader: const _FakeSessionReader('expired-token'),
          transport: _FakeBackendTransport(
            response: const BackendTransportResponse(
              statusCode: 401,
              body:
                  '{"success":false,"message":"Invalid or expired access token"}',
              headers: {'content-type': 'application/json'},
            ),
          ),
          onUnauthorized: () {
            throw StateError('sign out failed');
          },
        );

        await expectLater(
          client.getObject('/api/v1/auth/me', authenticated: true),
          throwsA(
            isA<BackendApiException>().having(
              (error) => error.message,
              'message',
              'Invalid or expired access token',
            ),
          ),
        );
      },
    );

    test('successful authenticated probe returns safe identity data', () async {
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: const _FakeSessionReader('access-token-123'),
        transport: _FakeBackendTransport(
          response: const BackendTransportResponse(
            statusCode: 200,
            body:
                '{"success":true,"data":{"userId":"0568b0f9-cbaa-4b72-a8b3-3a9233ae4261"}}',
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      final identity = await client.probeAuthenticatedIdentity();

      expect(identity['userId'], '0568b0f9-cbaa-4b72-a8b3-3a9233ae4261');
    });

    test('signed-out state clears protected request access', () async {
      final sessionReader = _MutableSessionReader('access-token-123');
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: sessionReader,
        transport: _FakeBackendTransport(
          response: const BackendTransportResponse(
            statusCode: 200,
            body: '{"success":true,"data":[]}',
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await client.getList('/api/v1/profiles', authenticated: true);
      sessionReader.currentAccessToken = null;

      await expectLater(
        client.getList('/api/v1/profiles', authenticated: true),
        throwsA(isA<MissingAuthenticatedSessionException>()),
      );
    });

    test('removes client-controlled ownership keys from request bodies', () {
      expect(
        stripClientOwnershipFields({
          'user_id': 'attacker',
          'userId': 'attacker',
          'parent_id': 'attacker',
          'parentId': 'attacker',
          'profile_owner_id': 'attacker',
          'profileOwnerId': 'attacker',
          'child_name': 'Aarav',
        }),
        {'child_name': 'Aarav'},
      );
    });
  });
}

class _FakeSessionReader implements BackendSessionReader {
  const _FakeSessionReader(this.currentAccessToken);

  @override
  final String? currentAccessToken;
}

class _FakeBackendTransport implements BackendTransport {
  _FakeBackendTransport({required this.response});

  BackendTransportResponse response;
  final List<BackendTransportRequest> requests = [];

  @override
  Future<BackendTransportResponse> send(BackendTransportRequest request) async {
    requests.add(request);
    return response;
  }
}

class _MutableSessionReader implements BackendSessionReader {
  _MutableSessionReader(this.currentAccessToken);

  @override
  String? currentAccessToken;
}
