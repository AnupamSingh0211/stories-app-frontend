import 'package:flutter_riverpod/flutter_riverpod.dart';
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

const bool kUseAuthBypass = true;

final mockSessionStateProvider = StateProvider<AppSessionIdentity?>((ref) => null);

class SupabaseAppAuthService implements AppAuthService {
  const SupabaseAppAuthService(this.ref);

  final Ref ref;

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

    await _auth.signInWithOtp(phone: phoneNumber);
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
  Future<void> signOut() async {
    if (kUseAuthBypass) {
      ref.read(mockSessionStateProvider.notifier).state = null;
      return;
    }
    await _auth.signOut();
  }
}

final appAuthServiceProvider = Provider<AppAuthService>(
  (ref) => SupabaseAppAuthService(ref),
);

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
