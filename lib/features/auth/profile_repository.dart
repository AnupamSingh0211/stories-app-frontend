import '../../core/supabase_client.dart';

class ProfileRepository {
  const ProfileRepository();

  Future<void> saveProfile({
    required String name,
    required String gender,
    required int age,
    required String? companionId,
  }) async {
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    final profile = <String, dynamic>{
      'name': name,
      'gender': gender,
      'age': age,
      'companion_id': companionId,
    };

    if (userId == null) {
      await client.from('profiles').insert(profile);
      return;
    }

    await client.from('profiles').upsert({'id': userId, ...profile});
  }
}
