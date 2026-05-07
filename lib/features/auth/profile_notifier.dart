import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'profile_repository.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  final ProfileRepository _repository = const ProfileRepository();

  @override
  Future<void> build() async {}

  Future<void> saveProfile({
    required String name,
    required int age,
    required String character,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => _repository.saveProfile(
        name: name,
        age: age,
        character: character,
      ),
    );
  }
}
