import 'package:flutter/foundation.dart';

import '../../core/backend_api_client.dart';

const defaultProfileLocale = 'en-IN';
const supportedProfileLocales = ['en-IN', 'hi-IN'];

String normalizeProfileLocale(String? locale) {
  final value = locale?.trim();
  if (value == null || value.isEmpty) {
    return defaultProfileLocale;
  }

  return supportedProfileLocales.contains(value) ? value : defaultProfileLocale;
}

String profileLocaleLabel(String locale) {
  switch (normalizeProfileLocale(locale)) {
    case 'hi-IN':
      return 'Hindi';
    case 'en-IN':
    default:
      return 'English';
  }
}

abstract class ProfileDataSource {
  const ProfileDataSource();

  String? get currentUserId;

  Future<List<Map<String, dynamic>>> fetchChildProfiles();

  Future<Map<String, dynamic>> insertChildProfile(Map<String, dynamic> profile);

  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    Map<String, dynamic> profile,
  );
}

class BackendProfileDataSource extends ProfileDataSource {
  const BackendProfileDataSource({required BackendApiClient apiClient})
    : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  @override
  String? get currentUserId => null;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles() {
    return _apiClient.getList('/api/v1/profiles', authenticated: true);
  }

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) {
    return _apiClient.postObject(
      '/api/v1/profiles',
      authenticated: true,
      body: profile,
    );
  }

  @override
  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    Map<String, dynamic> profile,
  ) {
    return _apiClient.patchObject(
      '/api/v1/profiles/$childId',
      authenticated: true,
      body: profile,
    );
  }
}

class ChildProfileModel {
  const ChildProfileModel({
    required this.id,
    required this.parentId,
    required this.childName,
    required this.age,
    required this.gender,
    required this.createdAt,
    this.companionId,
    this.avatarUrl,
    this.locale = defaultProfileLocale,
  });

  factory ChildProfileModel.fromMap(Map<String, dynamic> row) {
    final ownerId = row['user_id']?.toString() ?? row['parent_id']?.toString();
    return ChildProfileModel(
      id: row['id'].toString(),
      parentId: ownerId ?? '',
      childName: row['child_name'] as String? ?? '',
      age: row['age'] as int? ?? 2,
      gender: row['gender'] as String? ?? 'boy',
      companionId: row['companion_id'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      locale: normalizeProfileLocale(row['locale'] as String?),
      createdAt:
          DateTime.tryParse(row['created_at']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  final String id;
  final String parentId;
  final String childName;
  final int age;
  final String gender;
  final String? companionId;
  final String? avatarUrl;
  final String locale;
  final DateTime createdAt;

  ChildProfileModel copyWith({
    String? id,
    String? parentId,
    String? childName,
    int? age,
    String? gender,
    String? companionId,
    String? avatarUrl,
    String? locale,
    DateTime? createdAt,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childName: childName ?? this.childName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      companionId: companionId ?? this.companionId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      locale: locale ?? this.locale,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class ProfileRepository {
  ProfileRepository({required ProfileDataSource dataSource})
    : _dataSource = dataSource;

  final ProfileDataSource _dataSource;

  Future<List<ChildProfileModel>> fetchChildProfiles() async {
    final rows = await _dataSource.fetchChildProfiles();

    return rows.map(ChildProfileModel.fromMap).toList(growable: false);
  }

  Future<ChildProfileModel> createChildProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String locale = defaultProfileLocale,
    String? avatarUrl,
  }) async {
    if (kDebugMode) {
      debugPrint('ProfileRepository: creating child profile via backend');
    }
    final row = await _dataSource.insertChildProfile({
      'child_name': name,
      'gender': gender,
      'age': age,
      'companion_id': companionId,
      'avatar_url': avatarUrl,
    });

    final child = ChildProfileModel.fromMap(row).copyWith(
      locale: normalizeProfileLocale(row['locale'] as String? ?? locale),
    );
    if (kDebugMode) {
      debugPrint('ProfileRepository: inserted child profile ${child.id}');
    }
    return child;
  }

  Future<ChildProfileModel> updateChildCompanion({
    required ChildProfileModel child,
    required String companionId,
  }) async {
    final row = await _dataSource.updateChildProfile(child.id, {
      'companion_id': companionId,
    });

    return ChildProfileModel.fromMap(row);
  }
}

const maxChildProfiles = 2;
const childProfileLimitMessage =
    'You can add up to two child profiles. To add another, please update or '
    'remove an existing profile.';

class ChildProfileLimitException implements Exception {
  const ChildProfileLimitException();

  @override
  String toString() => childProfileLimitMessage;
}

class MockProfileDataSource extends ProfileDataSource {
  const MockProfileDataSource();

  static final List<Map<String, dynamic>> _profiles = [];

  @override
  String? get currentUserId => '00000000-0000-0000-0000-000000000000';

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List.from(_profiles);
  }

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final newProfile = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': currentUserId,
      ...profile,
      'created_at': DateTime.now().toIso8601String(),
    };
    _profiles.add(newProfile);
    return newProfile;
  }

  @override
  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    Map<String, dynamic> profile,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));
    for (var i = 0; i < _profiles.length; i++) {
      if (_profiles[i]['id'] == childId) {
        _profiles[i] = {
          ..._profiles[i],
          ...profile,
        };
        return _profiles[i];
      }
    }
    throw StateError('Profile not found');
  }
}
