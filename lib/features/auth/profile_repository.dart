import '../../core/supabase_client.dart';

abstract class ProfileDataSource {
  const ProfileDataSource();

  String? get currentUserId;

  Future<String?> signInAnonymously();

  Future<List<Map<String, dynamic>>> fetchChildProfiles(String parentId);

  Future<Map<String, dynamic>> insertChildProfile(Map<String, dynamic> profile);
}

class SupabaseProfileDataSource extends ProfileDataSource {
  const SupabaseProfileDataSource();

  @override
  String? get currentUserId =>
      SupabaseClientProvider.client.auth.currentUser?.id;

  @override
  Future<String?> signInAnonymously() async {
    final response = await SupabaseClientProvider.client.auth
        .signInAnonymously();
    return response.user?.id ??
        SupabaseClientProvider.client.auth.currentUser?.id;
  }

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
  final DateTime createdAt;
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
    String? avatarUrl,
  }) async {
    final parentId = await _requireUserId();

    final row = await _dataSource.insertChildProfile({
      'parent_id': parentId,
      'child_name': name,
      'gender': gender,
      'age': age,
      'companion_id': companionId,
      'avatar_url': avatarUrl,
    });

    return ChildProfileModel.fromMap(row);
  }

  Future<String> _requireUserId() async {
    final currentUserId = _dataSource.currentUserId;
    if (currentUserId != null && currentUserId.isNotEmpty) {
      return currentUserId;
    }

    try {
      final anonymousUserId = await _dataSource.signInAnonymously();
      if (anonymousUserId != null && anonymousUserId.isNotEmpty) {
        return anonymousUserId;
      }
    } catch (error) {
      throw StateError('Could not start a guest session: $error');
    }

    throw StateError(
      'Could not start a guest session. '
      'Confirm anonymous sign-ins are enabled in Supabase.',
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
