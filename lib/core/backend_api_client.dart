import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/auth_provider.dart';
import 'backend_config.dart';

class BackendTransportRequest {
  const BackendTransportRequest({
    required this.method,
    required this.uri,
    required this.headers,
    this.body,
  });

  final String method;
  final Uri uri;
  final Map<String, String> headers;
  final String? body;
}

class BackendTransportResponse {
  const BackendTransportResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract interface class BackendTransport {
  Future<BackendTransportResponse> send(BackendTransportRequest request);
}

class HttpBackendTransport implements BackendTransport {
  HttpBackendTransport({
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 15),
  }) : _client = client ?? http.Client(),
       _requestTimeout = requestTimeout;

  final http.Client _client;
  final Duration _requestTimeout;

  @override
  Future<BackendTransportResponse> send(BackendTransportRequest request) async {
    final response = await _client
        .send(
          http.Request(request.method, request.uri)
            ..headers.addAll(request.headers)
            ..body = request.body ?? '',
        )
        .timeout(_requestTimeout);

    return BackendTransportResponse(
      statusCode: response.statusCode,
      body: await response.stream.bytesToString().timeout(_requestTimeout),
      headers: response.headers,
    );
  }
}

abstract interface class BackendSessionReader {
  String? get currentAccessToken;
}

typedef BackendUnauthorizedHandler = FutureOr<void> Function();

class SupabaseBackendSessionReader implements BackendSessionReader {
  const SupabaseBackendSessionReader();

  @override
  String? get currentAccessToken {
    if (kUseAuthBypass) {
      return 'mock.dev.token';
    }
    if (DevOtpAuthConfig.enabled) {
      return DevOtpSessionStore.currentAccessToken;
    }
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }
}

class BackendApiException implements Exception {
  const BackendApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401 || statusCode == 403;

  @override
  String toString() => message;
}

class MissingAuthenticatedSessionException extends BackendApiException {
  const MissingAuthenticatedSessionException()
    : super(
        'An authenticated session is required before calling this backend endpoint.',
        statusCode: 401,
      );
}

const _clientOwnershipKeys = {
  'user_id',
  'userId',
  'parent_id',
  'parentId',
  'profile_owner_id',
  'profileOwnerId',
};

Map<String, dynamic> stripClientOwnershipFields(Map<String, dynamic> body) {
  final sanitized = Map<String, dynamic>.from(body);
  for (final key in _clientOwnershipKeys) {
    sanitized.remove(key);
  }
  return sanitized;
}

class BackendApiClient {
  BackendApiClient({
    required String baseUrl,
    required BackendSessionReader sessionReader,
    BackendTransport? transport,
    BackendUnauthorizedHandler? onUnauthorized,
  }) : _baseUrl = baseUrl,
       _sessionReader = sessionReader,
       _transport = transport ?? HttpBackendTransport(),
       _onUnauthorized = onUnauthorized;

  final String _baseUrl;
  final BackendSessionReader _sessionReader;
  final BackendTransport _transport;
  final BackendUnauthorizedHandler? _onUnauthorized;

  Future<Map<String, dynamic>> probeAuthenticatedIdentity() async {
    return getObject('/api/v1/auth/me', authenticated: true);
  }

  Future<List<Map<String, dynamic>>> getList(
    String path, {
    bool authenticated = false,
    Map<String, String>? queryParameters,
  }) async {
    final data = await _request(
      method: 'GET',
      path: path,
      authenticated: authenticated,
      queryParameters: queryParameters,
    );

    if (data is! List) {
      throw const BackendApiException('The backend response was not a list.');
    }

    return data.whereType<Map>().map(_stringKeyedMap).toList(growable: false);
  }

  Future<Map<String, dynamic>> getObject(
    String path, {
    bool authenticated = false,
    Map<String, String>? queryParameters,
  }) async {
    final data = await _request(
      method: 'GET',
      path: path,
      authenticated: authenticated,
      queryParameters: queryParameters,
    );

    return _stringKeyedMap(data);
  }

  Future<Map<String, dynamic>> postObject(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
  }) async {
    final data = await _request(
      method: 'POST',
      path: path,
      authenticated: authenticated,
      body: body,
    );

    return _stringKeyedMap(data);
  }

  Future<Map<String, dynamic>> patchObject(
    String path, {
    required Map<String, dynamic> body,
    bool authenticated = false,
  }) async {
    final data = await _request(
      method: 'PATCH',
      path: path,
      authenticated: authenticated,
      body: body,
    );

    return _stringKeyedMap(data);
  }

  Future<void> delete(
    String path, {
    bool authenticated = false,
    Map<String, String>? queryParameters,
  }) async {
    await _request(
      method: 'DELETE',
      path: path,
      authenticated: authenticated,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> _request({
    required String method,
    required String path,
    required bool authenticated,
    Map<String, dynamic>? body,
    Map<String, String>? queryParameters,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: queryParameters?.isEmpty ?? true
          ? null
          : queryParameters,
    );
    final headers = <String, String>{'Accept': 'application/json'};

    if (authenticated) {
      final accessToken = _sessionReader.currentAccessToken?.trim();
      if (accessToken == null || accessToken.isEmpty) {
        await _handleUnauthorized();
        throw const MissingAuthenticatedSessionException();
      }
      headers['Authorization'] = 'Bearer $accessToken';
    }

    String? encodedBody;
    if (body != null) {
      headers['Content-Type'] = 'application/json';
      encodedBody = jsonEncode(body);
    }

    final BackendTransportResponse response;
    try {
      response = await _transport.send(
        BackendTransportRequest(
          method: method,
          uri: uri,
          headers: headers,
          body: encodedBody,
        ),
      );
    } on TimeoutException {
      throw const BackendApiException(
        'The backend request timed out. Please check your connection and backend URL.',
      );
    } on http.ClientException catch (error) {
      throw BackendApiException(
        'Could not connect to the backend. ${error.message}',
      );
    }

    final decoded = _decodeResponseBody(response.body);
    if (response.statusCode == 401 || response.statusCode == 403) {
      await _handleUnauthorized();
      throw BackendApiException(
        _messageFromResponse(decoded) ??
            'Your session is no longer authorized for this request.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw BackendApiException(
        _messageFromResponse(decoded) ??
            'The backend request could not be completed.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }

    return decoded;
  }

  Future<void> _handleUnauthorized() async {
    try {
      await _onUnauthorized?.call();
    } catch (_) {
      // Preserve the original auth failure as the surfaced API error.
    }
  }

  dynamic _decodeResponseBody(String body) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return jsonDecode(trimmed);
  }

  String? _messageFromResponse(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final message = decoded['message'];
      if (message is String && message.trim().isNotEmpty) {
        return message;
      }
    }

    return null;
  }

  Map<String, dynamic> _stringKeyedMap(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }

    if (value is Map) {
      return value.map((key, entry) => MapEntry(key.toString(), entry));
    }

    throw const BackendApiException('The backend response was not an object.');
  }
}

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  return BackendApiClient(
    baseUrl: BackendConfig.baseUrl,
    sessionReader: const SupabaseBackendSessionReader(),
    onUnauthorized: () async {
      await ref.read(appAuthServiceProvider).signOut();
      ref.invalidate(authSessionProvider);
    },
  );
});
