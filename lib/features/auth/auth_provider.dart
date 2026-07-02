import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

class AppSessionIdentity {
  const AppSessionIdentity({required this.userId, required this.isAnonymous});

  final String userId;
  final bool isAnonymous;

  @override
  bool operator ==(Object other) {
    return other is AppSessionIdentity &&
        other.userId == userId &&
        other.isAnonymous == isAnonymous;
  }

  @override
  int get hashCode => Object.hash(userId, isAnonymous);
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

class SupabaseAppAuthService implements AppAuthService {
  const SupabaseAppAuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  AppSessionIdentity? get currentIdentity => _identityFor(_auth.currentSession);

  @override
  Future<void> requestOtp(String phoneNumber) async {
    if (_auth.currentUser?.isAnonymous ?? false) {
      await _auth.signOut();
    }

    await _auth.signInWithOtp(phone: phoneNumber);
  }

  @override
  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await _auth.verifyOTP(
      type: OtpType.sms,
      phone: phoneNumber,
      token: otp,
    );
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
  Future<void> signOut() => _auth.signOut();
}

final appAuthServiceProvider = Provider<AppAuthService>(
  (ref) => const SupabaseAppAuthService(),
);

final activeSessionProvider = Provider<AppSessionIdentity?>((ref) {
  return ref.watch(authSessionProvider).valueOrNull;
});

@riverpod
Stream<AppSessionIdentity?> authSession(AuthSessionRef ref) async* {
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
