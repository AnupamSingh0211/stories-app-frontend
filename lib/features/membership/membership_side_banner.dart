import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';

class MembershipSideBanner extends StatelessWidget {
  const MembershipSideBanner({super.key});

  static const width = 318.676;
  static const height = 95.109;
  static const rotationRadians = -0.65;

  static const _tiles = [
    _SideBannerTileData(
      imagePath: 'side_banner_images/side_banner_Image_1.png',
      imageRotationRadians: 0.65,
    ),
    _SideBannerTileData(
      imagePath: 'side_banner_images/side_banner_Image_2.png',
      heightFactor: 1.3837,
      topFactor: -0.3223,
      imageRotationRadians: 0.65,
    ),
    _SideBannerTileData(
      imagePath: 'side_banner_images/side_banner_Image_3.png',
      heightFactor: 1.3837,
      leftFactor: 0.0066,
      topFactor: -0.1865,
      imageRotationRadians: 0.65,
    ),
    _SideBannerTileData(
      imagePath: 'side_banner_images/side_banner_Image_4.png',
      imageRotationRadians: 0.65,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final imageUrls = _sideBannerImageUrls();

    return Transform.rotate(
      angle: rotationRadians,
      alignment: Alignment.topLeft,
      child: SizedBox(
        key: const ValueKey('membershipSideBanner'),
        width: width,
        height: height,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var index = 0; index < _tiles.length; index += 1) ...[
              _PremiumStoryTile(
                data: _tiles[index],
                imageUrl: imageUrls?[index],
              ),
              if (index < _tiles.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }

  List<String>? _sideBannerImageUrls() {
    try {
      final storage = Supabase.instance.client.storage.from('app-assets');
      return [
        for (final tile in _tiles) storage.getPublicUrl(tile.imagePath),
      ];
    } catch (_) {
      return null;
    }
  }
}

class _SideBannerTileData {
  const _SideBannerTileData({
    required this.imagePath,
    this.heightFactor,
    this.leftFactor = 0,
    this.topFactor = 0,
    this.imageRotationRadians = 0,
  });

  final String imagePath;
  final double? heightFactor;
  final double leftFactor;
  final double topFactor;
  final double imageRotationRadians;
}

class _PremiumStoryTile extends StatelessWidget {
  const _PremiumStoryTile({required this.data, required this.imageUrl});

  final _SideBannerTileData data;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76.669,
      height: 95.109,
      decoration: BoxDecoration(
        color: _SideBannerColors.glass,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 4.15,
            top: 4.98,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: SizedBox(
                width: 68,
                height: 86,
                child: imageUrl == null
                    ? const SizedBox.shrink()
                    : _SideBannerImage(data: data, imageUrl: imageUrl!),
              ),
            ),
          ),
          const Positioned(
            left: 4.15,
            top: 74.98,
            child: _PremiumBadge(),
          ),
        ],
      ),
    );
  }
}

class _SideBannerImage extends StatelessWidget {
  const _SideBannerImage({required this.data, required this.imageUrl});

  final _SideBannerTileData data;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final heightFactor = data.heightFactor;

    if (heightFactor == null) {
      return Transform.rotate(
        angle: data.imageRotationRadians,
        child: OverflowBox(
          maxWidth: 112,
          maxHeight: 132,
          child: Image.network(
            imageUrl,
            width: 96,
            height: 116,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) =>
                const SizedBox.shrink(),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: 68 * data.leftFactor,
          top: 86 * data.topFactor,
          width: 68,
          height: 86 * heightFactor,
          child: Transform.rotate(
            angle: data.imageRotationRadians,
            child: OverflowBox(
              maxWidth: 112,
              maxHeight: 156,
              child: Image.network(
                imageUrl,
                width: 96,
                height: 136,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) =>
                    const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6.018, vertical: 3.009),
      decoration: const BoxDecoration(
        color: _SideBannerColors.glass,
        borderRadius: BorderRadius.only(topRight: Radius.circular(6.771)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'assets/icons/new_boopi/lucide_crown.svg',
            width: 9.027,
            height: 9.027,
            colorFilter: const ColorFilter.mode(
              _SideBannerColors.crown,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(width: 1.505),
          const Text(
            'Premium',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textOnPrimary,
              fontSize: 7.523,
              fontFamily: AppTypography.fontFamily,
              fontWeight: FontWeight.w600,
              height: 9.027 / 7.523,
            ),
          ),
        ],
      ),
    );
  }
}

abstract final class _SideBannerColors {
  static const glass = Color(0x2EFFFFFF);
  static const crown = Color(0xFFFFD104);
}
