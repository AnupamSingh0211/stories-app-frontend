import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import 'companion_model.dart';

class CompanionRepository {
  const CompanionRepository();

  String _optimizedCompanionPath(String path) {
    return path.replaceFirst(
      RegExp(r'\.(png|jpe?g)$', caseSensitive: false),
      '.webp',
    );
  }

  Future<List<CompanionModel>> fetchCompanions() async {
    final client = SupabaseClientProvider.client;
    final storage = Supabase.instance.client.storage.from('app-assets');
    final rows = await client
        .from('companions')
        .select(
          'id, display_name, short_description, long_description, image_path',
        )
        .order('created_at');

    return rows.map((row) {
      final imagePath = _optimizedCompanionPath(row['image_path'] as String);

      return CompanionModel(
        id: row['id'] as String,
        displayName: row['display_name'] as String,
        shortDescription: row['short_description'] as String,
        longDescription: row['long_description'] as String,
        imageUrl: storage.getPublicUrl(imagePath),
      );
    }).toList();
  }
}
