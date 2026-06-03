import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'profile_repository.dart';

part 'profile_notifier.g.dart';

@riverpod
class ProfileNotifier extends _$ProfileNotifier {
  final ProfileRepository _repository = const ProfileRepository();

  @override
  Future<ProfileModel?> build() async => null;

  Future<ProfileModel> saveProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
  }) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => _repository.saveProfile(
        name: name,
        gender: gender,
        age: age,
        companionId: companionId,
      ),
    );
    state = result.whenData<ProfileModel?>((profile) => profile);

    if (result.hasError) {
      Error.throwWithStackTrace(result.error!, result.stackTrace!);
    }

    return result.requireValue;
  }
}
