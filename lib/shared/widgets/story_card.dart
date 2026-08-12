import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class StoryCard extends StatelessWidget {
  final String title;
  final String episodeCount;
  final String? imageUrl;
  final double? width;
  final double imageHeight;
  final VoidCallback? onTap;
  final VoidCallback? onFavoriteTap;
  final bool isFavorite;

  const StoryCard({
    super.key,
    required this.title,
    required this.episodeCount,
    this.imageUrl,
    this.width,
    this.imageHeight = 184,
    this.onTap,
    this.onFavoriteTap,
    this.isFavorite = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              offset: const Offset(0, 4),
              blurRadius: 4,
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Container(
                    key: const ValueKey('story-card-thumbnail'),
                    height: imageHeight,
                    width: double.infinity,
                    color: Colors.white.withValues(alpha: 0.24),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const SizedBox.expand();
                            },
                          )
                        : null,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Semantics(
                    button: true,
                    label: isFavorite
                        ? 'Remove from favorites'
                        : 'Add to favorites',
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.36),
                              ),
                            ),
                            child: SvgPicture.asset(
                              isFavorite
                                  ? 'assets/icons/new_boopi/State=Bold, Icon=Heart.svg'
                                  : 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                              width: 16,
                              height: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          episodeCount,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 20 / 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ComingSoonStoryCard extends StatelessWidget {
  const ComingSoonStoryCard({
    super.key,
    required this.title,
    required this.imageUrl,
    this.width,
    this.scale = 1,
    this.isLiked = false,
    this.isDisliked = false,
    this.onLikeTap,
    this.onDislikeTap,
  });

  final String title;
  final String imageUrl;
  final double? width;
  final double scale;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback? onLikeTap;
  final VoidCallback? onDislikeTap;

  static const double designWidth = 172;
  static const double designHeight = 288;
  static const double thumbnailWidth = 147;
  static const double thumbnailHeight = 184;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? designWidth * scale;

    return Container(
      width: effectiveWidth,
      height: designHeight * scale,
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: AppColors.backgroundGlass,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: Offset(0, 4 * scale),
            blurRadius: 4 * scale,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: thumbnailWidth * scale,
            height: thumbnailHeight * scale,
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4 * scale),
                    child: Image.network(
                      imageUrl,
                      width: thumbnailWidth * scale,
                      height: thumbnailHeight * scale,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return ColoredBox(
                          color: Colors.white.withValues(alpha: 0.18),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: _WantThisBadge(scale: scale),
                ),
              ],
            ),
          ),
          SizedBox(height: 8 * scale),
          SizedBox(
            height: 40 * scale,
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.bodyMediumSemiBold.copyWith(
                color: AppColors.textOnPrimary,
                fontSize: 14 * scale,
                height: 20 / 14,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: thumbnailWidth * scale,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ThumbActionIcon(
                    assetPath: isLiked
                        ? 'assets/icons/new_boopi/fillThumbsUp_component.svg'
                        : 'assets/icons/new_boopi/State=Default, Icon=Like.svg',
                    semanticLabel: 'Vote yes',
                    scale: scale,
                    onTap: onLikeTap,
                  ),
                  _ThumbActionIcon(
                    assetPath: isDisliked
                        ? 'assets/icons/new_boopi/State=Bold, Icon=Dislike.svg'
                        : 'assets/icons/new_boopi/State=Default, Icon=Dislike.svg',
                    semanticLabel: 'Vote no',
                    scale: scale,
                    onTap: onDislikeTap,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WantThisBadge extends StatelessWidget {
  const _WantThisBadge({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [AppColors.interactivePrimaryPressed, Color(0xFF040F21)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3 * scale),
          bottomRight: Radius.circular(12 * scale),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
        child: Text(
          'Want This?',
          maxLines: 1,
          style: AppTypography.captionBold.copyWith(
            color: AppColors.textOnPrimary,
            fontSize: 10 * scale,
            height: 12 / 10,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _ThumbActionIcon extends StatelessWidget {
  const _ThumbActionIcon({
    required this.assetPath,
    required this.semanticLabel,
    required this.scale,
    this.onTap,
  });

  final String assetPath;
  final String semanticLabel;
  final double scale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox.square(
          dimension: 24 * scale,
          child: SvgPicture.asset(
            assetPath,
            colorFilter: const ColorFilter.mode(
              AppColors.textOnPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
