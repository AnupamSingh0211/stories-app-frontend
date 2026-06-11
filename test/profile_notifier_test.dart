import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_repository.dart';

void main() {
  test('loads, adds, and selects child profiles', () async {
    final repository = _FakeProfileRepository();
    final container = ProviderContainer(
      overrides: [profileRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final initial = await container.read(profileNotifierProvider.future);
    expect(initial.children.map((child) => child.childName), [
      'Aarav',
      'Meera',
    ]);
    expect(initial.selectedChild?.childName, 'Aarav');

    container
        .read(profileNotifierProvider.notifier)
        .selectChild(repository.children.last.id);
    expect(
      container
          .read(profileNotifierProvider)
          .valueOrNull
          ?.selectedChild
          ?.childName,
      'Meera',
    );

    final created = await container
        .read(profileNotifierProvider.notifier)
        .addChild(name: 'Kabir', gender: 'boy', age: 3, companionId: 'krishna');

    final state = container.read(profileNotifierProvider).requireValue;
    expect(created.childName, 'Kabir');
    expect(state.children.length, 3);
    expect(state.selectedChild?.id, created.id);
    expect(state.selectedChild?.companionId, 'krishna');
  });

  group('ProfileRepository authentication', () {
    test(
      'uses the existing authenticated user when creating a child',
      () async {
        final dataSource = _FakeProfileDataSource(currentUserId: 'user-1');
        final repository = ProfileRepository(dataSource: dataSource);

        final child = await repository.createChildProfile(
          name: 'Aarav',
          gender: 'boy',
          age: 2,
          companionId: null,
        );

        expect(dataSource.anonymousSignInCalls, 0);
        expect(dataSource.insertedProfile?['parent_id'], 'user-1');
        expect(child.parentId, 'user-1');
      },
    );

    test('signs in anonymously before creating a guest child', () async {
      final dataSource = _FakeProfileDataSource(anonymousUserId: 'anonymous-1');
      final repository = ProfileRepository(dataSource: dataSource);

      final child = await repository.createChildProfile(
        name: 'Meera',
        gender: 'girl',
        age: 3,
        companionId: 'krishna',
      );

      expect(dataSource.anonymousSignInCalls, 1);
      expect(dataSource.insertedProfile?['parent_id'], 'anonymous-1');
      expect(child.parentId, 'anonymous-1');
    });

    test('does not insert when anonymous sign-in fails', () async {
      final dataSource = _FakeProfileDataSource(
        signInError: Exception('Anonymous sign-ins are disabled'),
      );
      final repository = ProfileRepository(dataSource: dataSource);

      await expectLater(
        repository.createChildProfile(
          name: 'Kabir',
          gender: 'boy',
          age: 4,
          companionId: null,
        ),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            contains('Could not start a guest session'),
          ),
        ),
      );

      expect(dataSource.insertedProfile, isNull);
    });
  });
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository()
    : children = [
        ChildProfileModel(
          id: 'child-1',
          parentId: 'parent-1',
          childName: 'Aarav',
          age: 2,
          gender: 'boy',
          createdAt: DateTime.utc(2026, 6, 9),
        ),
        ChildProfileModel(
          id: 'child-2',
          parentId: 'parent-1',
          childName: 'Meera',
          age: 5,
          gender: 'girl',
          createdAt: DateTime.utc(2026, 6, 8),
        ),
      ];

  final List<ChildProfileModel> children;

  @override
  Future<List<ChildProfileModel>> fetchChildProfiles() async =>
      List.unmodifiable(children);

  @override
  Future<ChildProfileModel> createChildProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String? avatarUrl,
  }) async {
    final child = ChildProfileModel(
      id: 'child-${children.length + 1}',
      parentId: 'parent-1',
      childName: name,
      age: age,
      gender: gender,
      companionId: companionId,
      avatarUrl: avatarUrl,
      createdAt: DateTime.utc(2026, 6, 9, 1),
    );
    children.insert(0, child);
    return child;
  }
}

class _FakeProfileDataSource extends ProfileDataSource {
  _FakeProfileDataSource({
    this.currentUserId,
    this.anonymousUserId,
    this.signInError,
  });

  @override
  String? currentUserId;
  final String? anonymousUserId;
  final Object? signInError;
  int anonymousSignInCalls = 0;
  Map<String, dynamic>? insertedProfile;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles(
    String parentId,
  ) async => const [];

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) async {
    insertedProfile = profile;
    return {'id': 'child-1', ...profile, 'created_at': '2026-06-09T00:00:00Z'};
  }

  @override
  Future<String?> signInAnonymously() async {
    anonymousSignInCalls++;
    if (signInError case final error?) {
      throw error;
    }
    currentUserId = anonymousUserId;
    return anonymousUserId;
  }
}
