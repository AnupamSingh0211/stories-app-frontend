import 'package:flutter/foundation.dart';
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

  Future<AppSessionIdentity> ensureAnonymousSession();
}

class SupabaseAppAuthService implements AppAuthService {
  const SupabaseAppAuthService();

  GoTrueClient get _auth => Supabase.instance.client.auth;

  @override
  AppSessionIdentity? get currentIdentity => _identityFor(_auth.currentSession);

  @override
  Future<AppSessionIdentity> ensureAnonymousSession() async {
    final existing = currentIdentity;
    if (existing != null) {
      return existing;
    }

    if (kDebugMode) {
      debugPrint('AppAuthService: starting anonymous authentication');
    }
    final response = await _auth.signInAnonymously();
    final user = response.user ?? _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'Anonymous authentication did not return a user.',
      );
    }

    if (kDebugMode) {
      debugPrint('AppAuthService: authenticated user ${user.id}');
    }
    return AppSessionIdentity(userId: user.id, isAnonymous: user.isAnonymous);
  }
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
  if (user == null) {
    return null;
  }

  return AppSessionIdentity(userId: user.id, isAnonymous: user.isAnonymous);
}
