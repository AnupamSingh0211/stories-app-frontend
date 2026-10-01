import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/backend_config.dart';
import '../../services/otp_api_service.dart';

part 'auth_provider.g.dart';

class AppSessionIdentity {
  const AppSessionIdentity({
    required this.userId,
    required this.isAnonymous,
    this.accessToken,
  });

  final String userId;
  final bool isAnonymous;
  final String? accessToken;

  @override
  bool operator ==(Object other) {
    return other is AppSessionIdentity &&
        other.userId == userId &&
        other.isAnonymous == isAnonymous &&
        other.accessToken == accessToken;
  }

  @override
  int get hashCode => Object.hash(userId, isAnonymous, accessToken);
}

abstract interface class AppAuthService {
  AppSessionIdentity? get currentIdentity;

  Future<void> requestOtp(String phoneNumber);

  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  });

  Future<void> signOut();
}

const bool kUseAuthBypass = false;

final mockSessionStateProvider = StateProvider<AppSessionIdentity?>(
  (ref) => null,
);

final devAuthSessionStateProvider = StateProvider<AppSessionIdentity?>(
  (ref) => null,
);

class DevOtpAuthConfig {
  const DevOtpAuthConfig._();

  /// Local/dev auth path used when Supabase phone SMS is not configured.
  /// Enabled by backend hardcoded OTP mode and/or Twilio otp-api.
  static bool get enabled =>
      !_isProductionBuild &&
      (dotenv.env['DEV_AUTH_OTP_ENABLED'] == 'true' ||
          OtpApiService.isConfigured());

  static bool get usesOtpApi =>
      !_isProductionBuild && OtpApiService.isConfigured();

  static bool get _isProductionBuild {
    final appEnvironment = dotenv.env['APP_ENV']?.trim().toLowerCase();
    return appEnvironment == 'production';
  }
}

class DevOtpSessionStore {
  const DevOtpSessionStore._();

  static const _sessionKey = 'dev_auth_session';
  static AppSessionIdentity? _memorySession;

  static String? get currentAccessToken => _memorySession?.accessToken;

  static Future<AppSessionIdentity?> restore() async {
    if (_memorySession != null) {
      return _memorySession;
    }

    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_sessionKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        return null;
      }

      final userId = decoded['userId'];
      final accessToken = decoded['accessToken'];
      if (userId is! String ||
          userId.isEmpty ||
          accessToken is! String ||
          accessToken.isEmpty) {
        return null;
      }

      _memorySession = AppSessionIdentity(
        userId: userId,
        isAnonymous: false,
        accessToken: accessToken,
      );
      return _memorySession;
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> save(AppSessionIdentity identity) async {
    _memorySession = identity;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'userId': identity.userId,
        'accessToken': identity.accessToken,
      }),
    );
  }

  static Future<void> clear() async {
    _memorySession = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}

class SupabaseAppAuthService implements AppAuthService {
  const SupabaseAppAuthService(this.ref);

  final Ref ref;
  static const _authTimeout = Duration(seconds: 20);

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  AppSessionIdentity? get currentIdentity {
    if (kUseAuthBypass) {
      return ref.read(mockSessionStateProvider);
    }
    return _identityFor(_auth.currentSession);
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    if (kUseAuthBypass) {
      return;
    }

    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.signOut();
    }

    await _auth.signInWithOtp(phone: phoneNumber).timeout(_authTimeout);
  }

  @override
  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    if (kUseAuthBypass) {
      const identity = AppSessionIdentity(
        userId: '00000000-0000-0000-0000-000000000000',
        isAnonymous: false,
      );
      ref.read(mockSessionStateProvider.notifier).state = identity;
      return identity;
    }

    final response = await _auth
        .verifyOTP(type: OtpType.sms, phone: phoneNumber, token: otp)
        .timeout(_authTimeout);
    final identity = _identityFor(response.session);
    if (identity == null) {
      throw const AuthException(
        'OTP verification did not return an authenticated session.',
      );
    }

    if (identity.isAnonymous) {
      throw const AuthException(
        'OTP verification returned an anonymous session.',
      );
    }

    return identity;
  }

  @override
  Future<void> signOut() async {
    if (kUseAuthBypass) {
      ref.read(mockSessionStateProvider.notifier).state = null;
      return;
    }
    await _auth.signOut();
  }
}

class DevBackendOtpAuthService implements AppAuthService {
  DevBackendOtpAuthService(
    this.ref, {
    http.Client? client,
    Duration requestTimeout = const Duration(seconds: 12),
  }) : _requestTimeout = requestTimeout,
       _client = client ?? http.Client();

  final Ref ref;
  final http.Client _client;
  final Duration _requestTimeout;

  Uri _uri(String path) => Uri.parse('${BackendConfig.baseUrl}$path');

  @override
  AppSessionIdentity? get currentIdentity {
    return ref.read(devAuthSessionStateProvider) ??
        DevOtpSessionStore._memorySession;
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }
  }

  @override
  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            _uri('/api/v1/auth/dev/verify-otp'),
            headers: const {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
          )
          .timeout(_requestTimeout);
    } on TimeoutException {
      throw const AuthException(
        'Authentication backend timed out. Check BACKEND_BASE_URL and that the backend is reachable from this device.',
      );
    } catch (_) {
      throw const AuthException(
        'Could not connect to authentication backend. Please check the dev API URL.',
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(_authErrorMessage(response.body));
    }

    final decoded = jsonDecode(response.body);
    final data = decoded is Map ? decoded['data'] : null;
    if (data is! Map ||
        data['userId'] is! String ||
        data['accessToken'] is! String) {
      throw const AuthException('OTP verification did not return a session.');
    }

    final identity = AppSessionIdentity(
      userId: data['userId'] as String,
      isAnonymous: false,
      accessToken: data['accessToken'] as String,
    );
    await DevOtpSessionStore.save(identity);
    ref.read(devAuthSessionStateProvider.notifier).state = identity;
    return identity;
  }

  @override
  Future<void> signOut() async {
    await DevOtpSessionStore.clear();
    ref.read(devAuthSessionStateProvider.notifier).state = null;
  }

  String _authErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map && decoded['message'] is String) {
        return decoded['message'] as String;
      }
    } catch (_) {
      // Fall back to a stable client error below.
    }

    return 'Authentication failed. Please try again.';
  }
}

/// Twilio otp-api auth: send/verify SMS via local OTP API, then create a
/// local app session so [AppSessionGate] can leave the welcome screen.
class OtpApiAppAuthService implements AppAuthService {
  OtpApiAppAuthService(this.ref, {OtpApiService? otpApi})
      : _otpApi = otpApi ?? OtpApiService();

  final Ref ref;
  final OtpApiService _otpApi;

  @override
  AppSessionIdentity? get currentIdentity {
    return ref.read(devAuthSessionStateProvider) ??
        DevOtpSessionStore._memorySession;
  }

  @override
  Future<void> requestOtp(String phoneNumber) async {
    if (phoneNumber.trim().isEmpty) {
      throw const AuthException('Phone number is required.');
    }

    try {
      await _otpApi.sendOtp(phone: phoneNumber);
    } on OtpApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException(
        'Could not send OTP. Is otp-api running on OTP_API_BASE_URL?',
      );
    }
  }

  @override
  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final result = await _otpApi.verifyOtp(phone: phoneNumber, code: otp);
      if (!OtpApiService.isVerifySuccess(result)) {
        throw AuthException(
          result['message']?.toString() ?? 'Invalid or expired OTP',
        );
      }
    } on AuthException {
      rethrow;
    } on OtpApiException catch (error) {
      throw AuthException(error.message);
    } catch (_) {
      throw const AuthException(
        'Could not verify OTP. Is otp-api running on OTP_API_BASE_URL?',
      );
    }

    final identity = AppSessionIdentity(
      userId: _userIdForPhone(phoneNumber),
      isAnonymous: false,
      // Accepted by stories-app-backend in development NODE_ENV.
      accessToken: 'mock.dev.token',
    );
    await DevOtpSessionStore.save(identity);
    ref.read(devAuthSessionStateProvider.notifier).state = identity;
    return identity;
  }

  @override
  Future<void> signOut() async {
    await DevOtpSessionStore.clear();
    ref.read(devAuthSessionStateProvider.notifier).state = null;
  }

  /// Stable UUID-shaped id matching stories-app-backend `userIdForPhone`.
  static String _userIdForPhone(String phoneNumber) {
    final hash = sha256
        .convert(utf8.encode('stories-app-dev-phone:$phoneNumber'))
        .toString();
    return [
      hash.substring(0, 8),
      hash.substring(8, 12),
      '4${hash.substring(13, 16)}',
      '8${hash.substring(17, 20)}',
      hash.substring(20, 32),
    ].join('-');
  }
}

final appAuthServiceProvider = Provider<AppAuthService>((ref) {
  if (!DevOtpAuthConfig.enabled) {
    return SupabaseAppAuthService(ref);
  }
  if (DevOtpAuthConfig.usesOtpApi) {
    return OtpApiAppAuthService(ref);
  }
  return DevBackendOtpAuthService(ref);
});

final activeSessionProvider = Provider<AppSessionIdentity?>((ref) {
  return ref.watch(authSessionProvider).valueOrNull;
});

@riverpod
Stream<AppSessionIdentity?> authSession(AuthSessionRef ref) async* {
  if (kUseAuthBypass) {
    final mockSession = ref.watch(mockSessionStateProvider);
    yield mockSession;
    return;
  }

  if (DevOtpAuthConfig.enabled) {
    final currentSession = ref.watch(devAuthSessionStateProvider);
    if (currentSession != null) {
      yield currentSession;
      return;
    }

    yield await DevOtpSessionStore.restore();
    return;
  }

  final auth = Supabase.instance.client.auth;
  yield _identityFor(auth.currentSession);

  await for (final state in auth.onAuthStateChange) {
    yield _identityFor(state.session);
  }
}

AppSessionIdentity? _identityFor(Session? session) {
  final user = session?.user;
  if (user == null || user.isAnonymous) {
    return null;
  }

  return AppSessionIdentity(userId: user.id, isAnonymous: false);
}
