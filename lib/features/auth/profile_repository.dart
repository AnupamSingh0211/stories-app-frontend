import '../../core/supabase_client.dart';

class ProfileRepository {
  const ProfileRepository();

  Future<void> saveProfile({
    required String name,
    required int age,
    required String character,
  }) async {
    final client = SupabaseClientProvider.client;
    final userId = client.auth.currentUser?.id;
    final profile = <String, dynamic>{
      'name': name,
      'age': age,
      'character': character,
    };

    if (userId == null) {
      await client.from('profiles').insert(profile);
      return;
    }

    await client.from('profiles').upsert({'id': userId, ...profile});
  }
}
