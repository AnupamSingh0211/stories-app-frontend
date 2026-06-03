import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase_client.dart';
import 'companion_model.dart';

const _fallbackCompanions = [
  _CompanionSeed(
    id: 'krishna',
    displayName: 'Baby Krishna',
    shortDescription:
        'Playful and loving, Krishna guides you through stories of joy and wonder.',
    longDescription:
        "A playful and divine presence that brings warmth and peace to your child's bedtime stories.",
    imagePath: 'companions/comp_krishna.webp',
  ),
  _CompanionSeed(
    id: 'hanuman',
    displayName: 'Baby Hanuman',
    shortDescription:
        'Strong yet gentle, Hanuman provides a sense of protection and courage.',
    longDescription:
        'A brave and loyal companion who fills every bedtime tale with courage, kindness, and a comforting sense of protection.',
    imagePath: 'companions/comp_hanuman.webp',
  ),
  _CompanionSeed(
    id: 'shiva',
    displayName: 'Baby Shiva',
    shortDescription:
        'Meditative and calm, Shiva helps clear the mind for a restful sleep.',
    longDescription:
        'A calm, moonlit guide who brings stillness, balance, and peaceful wonder to quiet nighttime adventures.',
    imagePath: 'companions/comp_shiva.webp',
  ),
  _CompanionSeed(
    id: 'ganesha',
    displayName: 'Baby Ganesha',
    shortDescription:
        'The remover of obstacles, Ganesha brings a comforting and sweet presence.',
    longDescription:
        'A wise and gentle friend who helps every story feel safe, joyful, and full of soft beginnings.',
    imagePath: 'companions/comp_ganesha.webp',
  ),
  _CompanionSeed(
    id: 'bheem',
    displayName: 'Baby Bheem',
    shortDescription:
        'Reliable and brave, Bheem offers steady and grounded story experience.',
    longDescription:
        'A strong and cheerful companion who brings confidence, loyalty, and a grounded sense of adventure to bedtime.',
    imagePath: 'companions/comp_bheem.webp',
  ),
  _CompanionSeed(
    id: 'arjun',
    displayName: 'Baby Arjun',
    shortDescription:
        'Focused and visionary, Arjun leads you through tales of purpose and light.',
    longDescription:
        'A focused and thoughtful friend who brings purpose, wonder, and gentle courage to every dream-bound story.',
    imagePath: 'companions/comp_arjun.webp',
  ),
];

class CompanionRepository {
  const CompanionRepository();

  Future<List<CompanionModel>> fetchCompanions() async {
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');
    final rows = await client
        .from('companions')
        .select(
          'id, display_name, short_description, long_description, image_path',
        )
        .order('created_at');

    if (rows.isEmpty) {
      debugPrint(
        'CompanionRepository: Supabase returned 0 rows; using fallback storage companions.',
      );
      return _fallbackCompanions
          .map(
            (companion) => CompanionModel(
              id: companion.id,
              displayName: companion.displayName,
              shortDescription: companion.shortDescription,
              longDescription: companion.longDescription,
              imageUrl: storage.getPublicUrl(companion.imagePath),
            ),
          )
          .toList(growable: false);
    }

    debugPrint(
      'CompanionRepository: loaded ${rows.length} companions from Supabase.',
    );
    return rows.map((row) {
      final imagePath = row['image_path'] as String;

      return CompanionModel(
        id: row['id'] as String,
        displayName: row['display_name'] as String,
        shortDescription: row['short_description'] as String,
        longDescription: row['long_description'] as String,
        imageUrl: _imageUrl(storage, imagePath),
      );
    }).toList();
  }

  String _imageUrl(StorageFileApi storage, String value) {
    final trimmed = value.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return storage.getPublicUrl(trimmed);
  }
}

class _CompanionSeed {
  const _CompanionSeed({
    required this.id,
    required this.displayName,
    required this.shortDescription,
    required this.longDescription,
    required this.imagePath,
  });

  final String id;
  final String displayName;
  final String shortDescription;
  final String longDescription;
  final String imagePath;
}
