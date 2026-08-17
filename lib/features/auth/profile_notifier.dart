import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class SelectedChildPreferences {
  const SelectedChildPreferences._();

  static String keyForUser(String userId) => 'user.$userId.selected_child_id';

  static Future<String?> read(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(keyForUser(userId));
  }

  static Future<void> save(String userId, String childId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(keyForUser(userId), childId);
  }

  static Future<void> clear(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(keyForUser(userId));
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
    final selectedChildId = await _resolveSelectedChildId(userId, children);
    return ChildProfilesState(
      children: children,
      selectedChildId: selectedChildId,
    );
  }

  Future<ChildProfileModel> addChild({
    required String name,
    required String gender,
    required int age,
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
    final userId = ref.read(activeSessionProvider)?.userId;
    if (userId != null) {
      unawaited(SelectedChildPreferences.save(userId, child.id));
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

    final userId = ref.read(activeSessionProvider)?.userId;
    if (userId != null) {
      unawaited(SelectedChildPreferences.save(userId, childId));
    }
    state = AsyncData(current.copyWith(selectedChildId: childId));
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
      final selectedId = await _resolveSelectedChildId(
        session.userId,
        children,
      );
      final selectionExists = children.any((child) => child.id == selectedId);
      return ChildProfilesState(
        children: children,
        selectedChildId: selectionExists
            ? selectedId
            : children.firstOrNull?.id,
      );
    });
  }

  Future<String?> _resolveSelectedChildId(
    String userId,
    List<ChildProfileModel> children,
  ) async {
    if (children.isEmpty) {
      await SelectedChildPreferences.clear(userId);
      return null;
    }

    final storedId = await SelectedChildPreferences.read(userId);
    if (storedId != null && children.any((child) => child.id == storedId)) {
      return storedId;
    }

    final fallbackId = children.first.id;
    await SelectedChildPreferences.save(userId, fallbackId);
    return fallbackId;
  }
}
