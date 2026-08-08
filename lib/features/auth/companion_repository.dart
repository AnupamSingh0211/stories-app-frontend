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
    // Transitional: companion content still reads from Supabase until the
    // backend companion API is shaped for the Flutter onboarding UI.
    final client = SupabaseClientProvider.client;
    final storage = client.storage.from('app-assets');

    try {
      final rows = await client
          .from('companions')
          .select(
            'id, display_name, short_description, long_description, image_path',
          )
          .order('created_at');

      if (rows.isEmpty) {
        throw StateError('Empty companion list');
      }

      debugPrint(
        'CompanionRepository: loaded ${rows.length} companions from Supabase.',
      );
      return rows
          .asMap()
          .entries
          .map((entry) {
            final row = entry.value;
            final fallback = _fallbackFor(row, entry.key);
            final imagePath = _firstString(row, ['image_path']);

            return CompanionModel(
              id: _firstString(row, ['id']).ifEmpty(fallback.id),
              displayName: _firstString(row, [
                'display_name',
                'name',
                'title',
              ]).ifEmpty(fallback.displayName),
              shortDescription: _firstString(row, [
                'short_description',
                'description',
              ]).ifEmpty(fallback.shortDescription),
              longDescription: _firstString(row, [
                'long_description',
                'description',
              ]).ifEmpty(fallback.longDescription),
              imageUrl: _imageUrl(
                storage,
                imagePath.ifEmpty(fallback.imagePath),
              ),
            );
          })
          .toList(growable: false);
    } catch (error) {
      debugPrint(
        'CompanionRepository: Supabase query failed; using fallback storage companions. Error: $error',
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
  }

  String _imageUrl(StorageFileApi storage, String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }

    return storage.getPublicUrl(trimmed);
  }

  _CompanionSeed _fallbackFor(Map<String, dynamic> row, int index) {
    final id = _firstString(row, ['id']);
    for (final companion in _fallbackCompanions) {
      if (companion.id == id) {
        return companion;
      }
    }

    return _fallbackCompanions[index % _fallbackCompanions.length];
  }

  String _firstString(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }

      if (value != null && value is! String) {
        return value.toString();
      }
    }

    return '';
  }
}

extension _StringFallback on String {
  String ifEmpty(String fallback) {
    return isEmpty ? fallback : this;
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
