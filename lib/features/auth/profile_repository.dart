import 'package:flutter/foundation.dart';

import '../../core/supabase_client.dart';

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

  Future<List<Map<String, dynamic>>> fetchChildProfiles(String parentId);

  Future<Map<String, dynamic>> insertChildProfile(Map<String, dynamic> profile);

  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    String parentId,
    Map<String, dynamic> profile,
  );
}

class SupabaseProfileDataSource extends ProfileDataSource {
  const SupabaseProfileDataSource();

  @override
  String? get currentUserId =>
      SupabaseClientProvider.client.auth.currentUser?.id;

  @override
  Future<List<Map<String, dynamic>>> fetchChildProfiles(String parentId) async {
    final rows = await SupabaseClientProvider.client
        .from('child_profiles')
        .select()
        .eq('parent_id', parentId)
        .order('created_at', ascending: false);

    return rows;
  }

  @override
  Future<Map<String, dynamic>> insertChildProfile(
    Map<String, dynamic> profile,
  ) {
    return SupabaseClientProvider.client
        .from('child_profiles')
        .insert(profile)
        .select()
        .single();
  }

  @override
  Future<Map<String, dynamic>> updateChildProfile(
    String childId,
    String parentId,
    Map<String, dynamic> profile,
  ) {
    return SupabaseClientProvider.client
        .from('child_profiles')
        .update(profile)
        .eq('id', childId)
        .eq('parent_id', parentId)
        .select()
        .single();
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
    return ChildProfileModel(
      id: row['id'].toString(),
      parentId: row['parent_id'].toString(),
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
  const ProfileRepository({
    ProfileDataSource dataSource = const SupabaseProfileDataSource(),
  }) : _dataSource = dataSource;

  final ProfileDataSource _dataSource;

  Future<List<ChildProfileModel>> fetchChildProfiles(String parentId) async {
    final rows = await _dataSource.fetchChildProfiles(parentId);

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
    final parentId = _requireUserId();

    if (kDebugMode) {
      debugPrint(
        'ProfileRepository: inserting child profile for user $parentId',
      );
    }
    final row = await _dataSource.insertChildProfile({
      'parent_id': parentId,
      'child_name': name,
      'gender': gender,
      'age': age,
      'companion_id': companionId,
      'avatar_url': avatarUrl,
      'locale': normalizeProfileLocale(locale),
    });

    final child = ChildProfileModel.fromMap(row);
    if (kDebugMode) {
      debugPrint('ProfileRepository: inserted child profile ${child.id}');
    }
    return child;
  }

  Future<ChildProfileModel> updateChildCompanion({
    required ChildProfileModel child,
    required String companionId,
  }) async {
    final parentId = _requireUserId();

    final row = await _dataSource.updateChildProfile(child.id, parentId, {
      'companion_id': companionId,
    });

    return ChildProfileModel.fromMap(row);
  }

  String _requireUserId() {
    final currentUserId = _dataSource.currentUserId;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    throw StateError(
      'An authenticated session is required before creating a child profile.',
    );
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
