import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'auth_provider.dart';
import 'profile_repository.dart';

part 'profile_notifier.g.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(dataSource: const LocalProfileDataSource());
});

class ChildProfilesState {
  const ChildProfilesState({this.children = const [], this.selectedChildId});

  final List<ChildProfileModel> children;
  final String? selectedChildId;

  ChildProfileModel? get selectedChild {
    if (children.isEmpty) return null;

    final selectedId = selectedChildId;
    if (selectedId != null) {
      for (final child in children) {
        if (child.id == selectedId) return child;
      }
    }

    return children.first;
  }

  ChildProfilesState copyWith({
    List<ChildProfileModel>? children,
    String? selectedChildId,
  }) {
    return ChildProfilesState(
      children: children ?? this.children,
      selectedChildId: selectedChildId ?? this.selectedChildId,
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
    final children = await _repository.fetchChildProfiles();
    return ChildProfilesState(
      children: children,
      selectedChildId: children.firstOrNull?.id,
    );
  }

  Future<ChildProfileModel> addChild({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String locale = defaultProfileLocale,
  }) async {
    final previous = state.valueOrNull ?? const ChildProfilesState();
    if (previous.children.length >= maxChildProfiles) {
      throw const ChildProfileLimitException();
    }

    final result = await AsyncValue.guard(
      () => _repository.createChildProfile(
        name: name,
        gender: gender,
        age: age,
        companionId: companionId,
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
        children: [
          child,
          ...previous.children.where((item) => item.id != child.id),
        ],
        selectedChildId: child.id,
      ),
    );
    return child;
  }

  void selectChild(String childId) {
    final current = state.valueOrNull;
    if (current == null ||
        !current.children.any((child) => child.id == childId)) {
      return;
    }

    state = AsyncData(current.copyWith(selectedChildId: childId));
  }

  Future<ChildProfileModel> updateSelectedChildCompanion(
    String companionId,
  ) async {
    final previous = state.valueOrNull;
    final selectedChild = previous?.selectedChild;
    if (previous == null || selectedChild == null) {
      throw StateError('No child profile selected');
    }

    final updated = await _repository.updateChildCompanion(
      child: selectedChild,
      companionId: companionId,
    );
    state = AsyncData(
      previous.copyWith(
        children: [
          updated,
          ...previous.children.where((child) => child.id != updated.id),
        ],
        selectedChildId: updated.id,
      ),
    );
    return updated;
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
        children: [
          updated,
          ...previous.children.where((child) => child.id != updated.id),
        ],
        selectedChildId: updated.id,
      ),
    );
    return updated;
  }

  Future<void> refresh() async {
    final selectedId = state.valueOrNull?.selectedChildId;
    final session = ref.read(activeSessionProvider);
    if (session == null) {
      state = const AsyncData(ChildProfilesState());
      return;
    }

    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final children = await _repository.fetchChildProfiles();
      final selectionExists = children.any((child) => child.id == selectedId);
      return ChildProfilesState(
        children: children,
        selectedChildId: selectionExists
            ? selectedId
            : children.firstOrNull?.id,
      );
    });
  }
}
