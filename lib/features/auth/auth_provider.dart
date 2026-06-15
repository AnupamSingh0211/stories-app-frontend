import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'auth_provider.g.dart';

class AppSessionIdentity {
  const AppSessionIdentity({required this.userId, required this.isAnonymous});

  final String userId;
  final bool isAnonymous;
}

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
