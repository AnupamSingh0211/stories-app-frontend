import '../../core/supabase_client.dart';

class ProfileModel {
  const ProfileModel({
    required this.id,
    required this.childName,
    required this.age,
    required this.gender,
    this.companionId,
    this.avatarUrl,
    this.userId,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> row) {
    return ProfileModel(
      id: row['id'].toString(),
      childName: row['child_name'] as String? ?? '',
      age: row['age'] as int? ?? 0,
      gender: row['gender'] as String? ?? '',
      companionId: row['companion_id'] as String?,
      avatarUrl: row['avatar_url'] as String?,
      userId: row['user_id'] as String?,
    );
  }

  final String id;
  final String childName;
  final int age;
  final String gender;
  final String? companionId;
  final String? avatarUrl;
  final String? userId;
}

class ProfileRepository {
  const ProfileRepository();

  static ProfileModel? _cachedProfile;

  Future<ProfileModel?> fetchProfile() async {
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;

    try {
      var query = client.from('profiles').select();
      if (userId != null) {
        query = query.eq('user_id', userId);
      }

      final rows = await query.order('created_at', ascending: false).limit(1);

      if (rows.isEmpty) {
        return _cachedProfile;
      }

      _cachedProfile = ProfileModel.fromMap(rows.first);
      return _cachedProfile;
    } catch (_) {
      return _cachedProfile;
    }
  }

  Future<ProfileModel> saveProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
    String? avatarUrl,
  }) async {
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    final profile = <String, dynamic>{
      'child_name': name,
      'gender': gender,
      'age': age,
      'companion_id': companionId,
      'avatar_url': avatarUrl,
      'user_id': userId,
    };

    await client.from('profiles').insert(profile);

    final savedProfile = ProfileModel(
      id: '',
      childName: name,
      age: age,
      gender: gender,
      companionId: companionId,
      avatarUrl: avatarUrl,
      userId: userId,
    );
    _cachedProfile = savedProfile;

    return savedProfile;
  }
}
