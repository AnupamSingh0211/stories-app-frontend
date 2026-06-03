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
      childName: row['child_name'] as String,
      age: row['age'] as int,
      gender: row['gender'] as String,
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

    return ProfileModel(
      id: '',
      childName: name,
      age: age,
      gender: gender,
      companionId: companionId,
      avatarUrl: avatarUrl,
      userId: userId,
    );
  }
}
