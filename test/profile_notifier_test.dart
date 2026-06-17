import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/auth_provider.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_repository.dart';

void main() {
  test('returning parent loads and selects only their children', () async {
    final repository = _FakeProfileRepository(childCount: 2);
    final container = ProviderContainer(
      overrides: [
        activeSessionProvider.overrideWithValue(
          const AppSessionIdentity(userId: 'parent-1', isAnonymous: false),
        ),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final initial = await container.read(profileNotifierProvider.future);
    expect(initial.children.map((child) => child.childName), [
      'Aarav',
      'Meera',
    ]);
    expect(initial.selectedChild?.childName, 'Aarav');
    expect(repository.fetchedParentId, 'parent-1');

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

    final state = container.read(profileNotifierProvider).requireValue;
    expect(state.children.length, 2);
    expect(state.selectedChild?.childName, 'Meera');
  });

  test('signed-out session resets stale repository children', () async {
    final repository = _FakeProfileRepository(childCount: 2);
    final container = ProviderContainer(
      overrides: [
        activeSessionProvider.overrideWithValue(null),
        profileRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final state = await container.read(profileNotifierProvider.future);

    expect(state.children, isEmpty);
    expect(state.selectedChild, isNull);
    expect(repository.fetchedParentId, isNull);
  });

  for (final initialCount in [0, 1]) {
    test(
      'allows adding a child when parent has $initialCount children',
      () async {
        final repository = _FakeProfileRepository(childCount: initialCount);
        final container = _authenticatedContainer(repository);
        addTearDown(container.dispose);
        await container.read(profileNotifierProvider.future);

        final created = await container
            .read(profileNotifierProvider.notifier)
            .addChild(
              name: 'Kabir',
              gender: 'boy',
              age: 3,
              companionId: 'krishna',
            );

        final state = container.read(profileNotifierProvider).requireValue;
        expect(state.children.length, initialCount + 1);
        expect(state.selectedChild?.id, created.id);
      },
    );
  }

  test('rejects adding a third child without calling the repository', () async {
    final repository = _FakeProfileRepository(childCount: 2);
    final container = _authenticatedContainer(repository);
    addTearDown(container.dispose);
    await container.read(profileNotifierProvider.future);

    await expectLater(
      container
          .read(profileNotifierProvider.notifier)
          .addChild(name: 'Kabir', gender: 'boy', age: 3, companionId: null),
      throwsA(isA<ChildProfileLimitException>()),
    );

    expect(repository.createCalls, 0);
    expect(
      container.read(profileNotifierProvider).requireValue.children.length,
      2,
    );
  });

  test('restores the previous state when creating a child fails', () async {
    final repository = _FakeProfileRepository(
      childCount: 0,
      createError: StateError('locale column is missing'),
    );
    final container = _authenticatedContainer(repository);
    addTearDown(container.dispose);
    await container.read(profileNotifierProvider.future);

    await expectLater(
      container
          .read(profileNotifierProvider.notifier)
          .addChild(name: 'Kabir', gender: 'boy', age: 3, companionId: null),
      throwsA(isA<StateError>()),
    );

    final state = container.read(profileNotifierProvider);
    expect(state.hasError, isFalse);
    expect(state.requireValue.children, isEmpty);
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
        expect(dataSource.insertedProfile?['locale'], defaultProfileLocale);
        expect(child.parentId, 'user-1');
      },
    );

    test('stores the supplied locale when creating a child', () async {
      final dataSource = _FakeProfileDataSource(currentUserId: 'user-1');
      final repository = ProfileRepository(dataSource: dataSource);

      final child = await repository.createChildProfile(
        name: 'Aarav',
        gender: 'boy',
        age: 2,
        companionId: null,
        locale: 'hi-IN',
      );

      expect(dataSource.insertedProfile?['locale'], 'hi-IN');
      expect(child.locale, 'hi-IN');
    });

    test('fetches children only for the supplied parent identifier', () async {
      final dataSource = _FakeProfileDataSource(currentUserId: 'user-1');
      final repository = ProfileRepository(dataSource: dataSource);

      await repository.fetchChildProfiles('user-2');

      expect(dataSource.fetchedParentId, 'user-2');
    });

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

    test('falls back to en-IN for missing or unsupported row locale', () {
      final missing = ChildProfileModel.fromMap({
        'id': 'child-1',
        'parent_id': 'parent-1',
        'child_name': 'Aarav',
        'age': 2,
        'gender': 'boy',
        'created_at': '2026-06-09T00:00:00Z',
      });
      final unsupported = ChildProfileModel.fromMap({
        'id': 'child-2',
        'parent_id': 'parent-1',
        'child_name': 'Meera',
        'age': 3,
        'gender': 'girl',
        'locale': 'fr-FR',
        'created_at': '2026-06-09T00:00:00Z',
      });

      expect(missing.locale, defaultProfileLocale);
      expect(unsupported.locale, defaultProfileLocale);
    });
  });
}

ProviderContainer _authenticatedContainer(ProfileRepository repository) {
  return ProviderContainer(
    overrides: [
      activeSessionProvider.overrideWithValue(
        const AppSessionIdentity(userId: 'parent-1', isAnonymous: false),
      ),
      profileRepositoryProvider.overrideWithValue(repository),
    ],
  );
}

class _FakeProfileRepository extends ProfileRepository {
  _FakeProfileRepository({required int childCount, this.createError})
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
      ].take(childCount).toList();

  final List<ChildProfileModel> children;
  final Object? createError;
  String? fetchedParentId;
  int createCalls = 0;

  @override
  Future<List<ChildProfileModel>> fetchChildProfiles(String parentId) async {
    fetchedParentId = parentId;
    return List.unmodifiable(children);
  }

  @override
  Future<ChildProfileModel> createChildProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String locale = defaultProfileLocale,
    String? avatarUrl,
  }) async {
    createCalls++;
    if (createError case final error?) {
      throw error;
    }

    final child = ChildProfileModel(
      id: 'child-${children.length + 1}',
      parentId: 'parent-1',
      childName: name,
      age: age,
      gender: gender,
      companionId: companionId,
      avatarUrl: avatarUrl,
      locale: locale,
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
  String? fetchedParentId;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles(String parentId) async {
    fetchedParentId = parentId;
    return const [];
  }

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
