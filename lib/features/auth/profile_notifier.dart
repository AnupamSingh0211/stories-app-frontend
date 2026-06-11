import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'profile_repository.dart';

part 'profile_notifier.g.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return const ProfileRepository();
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
  }) async {
    final previous = state.valueOrNull ?? const ChildProfilesState();
    state = const AsyncLoading();

    final result = await AsyncValue.guard(
      () => _repository.createChildProfile(
        name: name,
        gender: gender,
        age: age,
        companionId: companionId,
      ),
    );

    if (result.hasError) {
      state = AsyncError(result.error!, result.stackTrace!);
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }

    final child = result.requireValue;
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

  Future<void> refresh() async {
    final selectedId = state.valueOrNull?.selectedChildId;
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
