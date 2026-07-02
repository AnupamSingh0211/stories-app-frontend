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
      final client = BackendApiClient(
        baseUrl: 'http://localhost:5000',
        sessionReader: const _FakeSessionReader(null),
        transport: _FakeBackendTransport(
          response: const BackendTransportResponse(
            statusCode: 200,
            body: '{"success":true,"data":[]}',
            headers: {'content-type': 'application/json'},
          ),
        ),
      );

      await expectLater(
        client.getList('/api/v1/profiles', authenticated: true),
        throwsA(isA<MissingAuthenticatedSessionException>()),
      );
    });

    test('maps unauthorized backend responses to a safe auth error', () async {
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
    });

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
