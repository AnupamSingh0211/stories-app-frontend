import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      body: _profileApiBody(profile),
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
      body: _profileApiBody(profile),
    );
  }

  Map<String, dynamic> _profileApiBody(Map<String, dynamic> profile) {
    final body = stripClientOwnershipFields(profile);
    body.remove('companion_id');
    body.remove('avatar_url');
    return body;
  }
}

class LocalProfileDataSource extends ProfileDataSource {
  const LocalProfileDataSource();

  static const _currentUserId = 'local-parent';
  static const _storageKey = 'user.$_currentUserId.local_child_profiles';

  @override
  String? get currentUserId => _currentUserId;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = prefs.getString(_storageKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }

    final decoded = jsonDecode(encoded);
    if (decoded is! List) {
      return const [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) async {
    final profiles = await fetchChildProfiles();
    final now = DateTime.now().toUtc();
    final newProfile = {
      'id': now.microsecondsSinceEpoch.toString(),
      'user_id': _currentUserId,
      ...profile,
      'created_at': now.toIso8601String(),
    };
    await _saveProfiles([newProfile, ...profiles]);
    return newProfile;
  }

  @override
  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    Map<String, dynamic> profile,
  ) async {
    final profiles = await fetchChildProfiles();
    for (var index = 0; index < profiles.length; index += 1) {
      if (profiles[index]['id'] == childId) {
        final updated = {...profiles[index], ...profile};
        profiles[index] = updated;
        await _saveProfiles(profiles);
        return updated;
      }
    }

    throw StateError('Profile not found');
  }

  Future<void> _saveProfiles(List<Map<String, dynamic>> profiles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(profiles));
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
  final String locale;
  final DateTime createdAt;

  ChildProfileModel copyWith({
    String? id,
    String? parentId,
    String? childName,
    int? age,
    String? gender,
    String? locale,
    DateTime? createdAt,
  }) {
    return ChildProfileModel(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childName: childName ?? this.childName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
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
    String locale = defaultProfileLocale,
  }) async {
    if (kDebugMode) {
      debugPrint('ProfileRepository: creating child profile via backend');
    }
    final row = await _dataSource.insertChildProfile({
      'child_name': name,
      'gender': gender,
      'age': age,
      'locale': normalizeProfileLocale(locale),
    });

    final child = ChildProfileModel.fromMap(row).copyWith(
      locale: normalizeProfileLocale(row['locale'] as String? ?? locale),
    );
    if (kDebugMode) {
      debugPrint('ProfileRepository: inserted child profile ${child.id}');
    }
    return child;
  }

  Future<ChildProfileModel> updateChildLocale({
    required ChildProfileModel child,
    required String locale,
  }) async {
    final row = await _dataSource.updateChildProfile(child.id, {
      'locale': normalizeProfileLocale(locale),
    });

    return ChildProfileModel.fromMap(row);
  }

  Future<ChildProfileModel> updateChildProfile({
    required ChildProfileModel child,
    String? name,
    String? gender,
    int? age,
    String? locale,
  }) async {
    final updates = <String, dynamic>{};
    if (name != null) updates['child_name'] = name;
    if (gender != null) updates['gender'] = gender;
    if (age != null) updates['age'] = age;
    if (locale != null) updates['locale'] = normalizeProfileLocale(locale);
    if (updates.isEmpty) {
      return child;
    }

    final row = await _dataSource.updateChildProfile(child.id, updates);

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
        _profiles[i] = {..._profiles[i], ...profile};
        return _profiles[i];
      }
    }
    throw StateError('Profile not found');
  }
}
