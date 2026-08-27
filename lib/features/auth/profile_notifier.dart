import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/backend_api_client.dart';
import 'auth_provider.dart';
import 'profile_repository.dart';

part 'profile_notifier.g.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    dataSource: BackendProfileDataSource(
      apiClient: ref.watch(backendApiClientProvider),
    ),
  );
});

class ChildProfilesState {
  const ChildProfilesState({this.children = const []});

  final List<ChildProfileModel> children;

  ChildProfileModel? get selectedChild => children.firstOrNull;

  ChildProfilesState copyWith({
    List<ChildProfileModel>? children,
  }) {
    return ChildProfilesState(
      children: children ?? this.children,
    );
  }
}

@Riverpod(keepAlive: true)
class ProfileNotifier extends _$ProfileNotifier {
  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  @override
  Future<ChildProfilesState> build() async {
    final userId = ref.watch(
      activeSessionProvider.select((session) => session?.userId),
    );
    if (userId == null) {
      if (kDebugMode) {
        debugPrint('ProfileNotifier: no authenticated session');
      }
      return const ChildProfilesState();
    }

    if (kDebugMode) {
      debugPrint('ProfileNotifier: loading profiles for authenticated user');
    }
    final List<ChildProfileModel> children;
    try {
      children = await _repository.fetchChildProfiles();
    } on BackendApiException catch (error) {
      if (error.isUnauthorized) {
        await ref.read(appAuthServiceProvider).signOut();
        ref.invalidate(authSessionProvider);
        return const ChildProfilesState();
      }
      rethrow;
    }
    return ChildProfilesState(children: _singleProfile(children));
  }

  Future<ChildProfileModel> addChild({
    required String name,
    required String gender,
    required int age,
    String locale = defaultProfileLocale,
  }) async {
    final previous = state.valueOrNull ?? const ChildProfilesState();
    if (previous.selectedChild != null) {
      throw const ChildProfileLimitException();
    }

    final result = await AsyncValue.guard(
      () => _repository.createChildProfile(
        name: name,
        gender: gender,
        age: age,
        locale: locale,
      ),
    );

    if (result.hasError) {
      state = AsyncData(previous);
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }

    final child = result.requireValue;
    if (kDebugMode) {
      debugPrint('ProfileNotifier: profile ${child.id} added to state');
    }
    state = AsyncData(
      ChildProfilesState(
        children: [child],
      ),
    );
    return child;
  }

  Future<ChildProfileModel> updateSelectedChildLocale(String locale) async {
    final previous = state.valueOrNull;
    final selectedChild = previous?.selectedChild;
    if (previous == null || selectedChild == null) {
      throw StateError('No child profile selected');
    }

    final updated = await _repository.updateChildLocale(
      child: selectedChild,
      locale: locale,
    );
    state = AsyncData(
      previous.copyWith(
        children: [updated],
      ),
    );
    return updated;
  }

  Future<ChildProfileModel> updateSelectedChildProfile({
    String? name,
    String? gender,
    int? age,
    String? locale,
  }) async {
    final previous = state.valueOrNull;
    final selectedChild = previous?.selectedChild;
    if (previous == null || selectedChild == null) {
      throw StateError('No child profile selected');
    }

    final updated = await _repository.updateChildProfile(
      child: selectedChild,
      name: name,
      gender: gender,
      age: age,
      locale: locale,
    );
    state = AsyncData(
      previous.copyWith(
        children: [updated],
      ),
    );
    return updated;
  }

  Future<void> refresh() async {
    final session = ref.read(activeSessionProvider);
    if (session == null) {
      state = const AsyncData(ChildProfilesState());
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final List<ChildProfileModel> children;
      try {
        children = await _repository.fetchChildProfiles();
      } on BackendApiException catch (error) {
        if (error.isUnauthorized) {
          await ref.read(appAuthServiceProvider).signOut();
          ref.invalidate(authSessionProvider);
          return const ChildProfilesState();
        }
        rethrow;
      }
      return ChildProfilesState(children: _singleProfile(children));
    });
  }

  List<ChildProfileModel> _singleProfile(List<ChildProfileModel> children) {
    final child = children.firstOrNull;
    return child == null ? const [] : [child];
  }
}
