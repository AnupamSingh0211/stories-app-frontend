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
    expect(repository.fetchCalls, 1);

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
    expect(repository.fetchCalls, 0);
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

  test('updates selected child companion in state and repository', () async {
    final repository = _FakeProfileRepository(childCount: 1);
    final container = _authenticatedContainer(repository);
    addTearDown(container.dispose);
    await container.read(profileNotifierProvider.future);

    final updated = await container
        .read(profileNotifierProvider.notifier)
        .updateSelectedChildCompanion('krishna');

    final state = container.read(profileNotifierProvider).requireValue;
    expect(updated.companionId, 'krishna');
    expect(state.selectedChild?.companionId, 'krishna');
    expect(repository.updatedChildId, 'child-1');
    expect(repository.updatedCompanionId, 'krishna');
  });

  group('ProfileRepository authentication', () {
    test(
      'creates a child profile without sending parent_id or user_id',
      () async {
        final dataSource = _FakeProfileDataSource();
        final repository = ProfileRepository(dataSource: dataSource);

        final child = await repository.createChildProfile(
          name: 'Aarav',
          gender: 'boy',
          age: 2,
          companionId: null,
        );

        expect(dataSource.insertedProfile?['child_name'], 'Aarav');
        expect(dataSource.insertedProfile?.containsKey('parent_id'), isFalse);
        expect(dataSource.insertedProfile?.containsKey('user_id'), isFalse);
        expect(dataSource.insertedProfile?['locale'], defaultProfileLocale);
        expect(child.parentId, 'user-1');
        expect(child.locale, defaultProfileLocale);
      },
    );

    test(
      'preserves the supplied locale in the returned child when backend omits it',
      () async {
        final dataSource = _FakeProfileDataSource();
        final repository = ProfileRepository(dataSource: dataSource);

        final child = await repository.createChildProfile(
          name: 'Aarav',
          gender: 'boy',
          age: 2,
          companionId: null,
          locale: 'hi-IN',
        );

        expect(child.locale, 'hi-IN');
      },
    );

    test('updates child companion by child id only', () async {
      final dataSource = _FakeProfileDataSource();
      final repository = ProfileRepository(dataSource: dataSource);
      final child = ChildProfileModel(
        id: 'child-1',
        parentId: 'user-1',
        childName: 'Aarav',
        age: 2,
        gender: 'boy',
        createdAt: DateTime.utc(2026, 6, 9),
      );

      final updated = await repository.updateChildCompanion(
        child: child,
        companionId: 'krishna',
      );

      expect(dataSource.updatedChildId, 'child-1');
      expect(dataSource.updatedProfile?['companion_id'], 'krishna');
      expect(updated.companionId, 'krishna');
    });

    test('fetches children from the authenticated backend route', () async {
      final dataSource = _FakeProfileDataSource();
      final repository = ProfileRepository(dataSource: dataSource);

      await repository.fetchChildProfiles();

      expect(dataSource.fetchCalls, 1);
    });

    test('falls back to en-IN for missing or unsupported row locale', () {
      final missing = ChildProfileModel.fromMap({
        'id': 'child-1',
        'user_id': 'parent-1',
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
      ].take(childCount).toList(),
      super(dataSource: _FakeProfileDataSource());

  final List<ChildProfileModel> children;
  final Object? createError;
  String? updatedChildId;
  String? updatedCompanionId;
  int createCalls = 0;
  int fetchCalls = 0;

  @override
  Future<List<ChildProfileModel>> fetchChildProfiles() async {
    fetchCalls++;
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

  @override
  Future<ChildProfileModel> updateChildCompanion({
    required ChildProfileModel child,
    required String companionId,
  }) async {
    updatedChildId = child.id;
    updatedCompanionId = companionId;
    final updated = child.copyWith(companionId: companionId);
    final index = children.indexWhere((item) => item.id == child.id);
    if (index == -1) {
      children.insert(0, updated);
    } else {
      children[index] = updated;
    }
    return updated;
  }
}

class _FakeProfileDataSource extends ProfileDataSource {
  @override
  String? currentUserId;

  Map<String, dynamic>? insertedProfile;
  Map<String, dynamic>? updatedProfile;
  String? updatedChildId;
  int fetchCalls = 0;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles() async {
    fetchCalls++;
    return const [];
  }

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) async {
    insertedProfile = profile;
    return {
      'id': 'child-1',
      'user_id': 'user-1',
      ...profile,
      'created_at': '2026-06-09T00:00:00Z',
    };
  }

  @override
  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    Map<String, dynamic> profile,
  ) async {
    updatedChildId = childId;
    updatedProfile = profile;
    return {
      'id': childId,
      'user_id': 'user-1',
      'child_name': 'Aarav',
      'age': 2,
      'gender': 'boy',
      ...profile,
      'created_at': '2026-06-09T00:00:00Z',
    };
  }
}
