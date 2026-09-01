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
  final Color contentColor;
  final Color backgroundColor;
  final Color shadowColor;
  final Color imagePlaceholderColor;
  final Color favoriteBackgroundColor;
  final Color favoriteBorderColor;
  final Color badgeBackgroundColor;
  final Color badgeBorderColor;
  final TextStyle? titleStyle;
  final TextStyle? metaStyle;

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
    this.contentColor = AppColors.textOnPrimary,
    this.backgroundColor = AppColors.backgroundGlass,
    this.shadowColor = const Color(0x1A000000),
    this.imagePlaceholderColor = const Color(0x3DFFFFFF),
    this.favoriteBackgroundColor = const Color(0x38FFFFFF),
    this.favoriteBorderColor = const Color(0x5CFFFFFF),
    this.badgeBackgroundColor = const Color(0x66000000),
    this.badgeBorderColor = const Color(0x33FFFFFF),
    this.titleStyle,
    this.metaStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
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
                    color: imagePlaceholderColor,
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
                              color: favoriteBackgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: favoriteBorderColor),
                            ),
                            child: SvgPicture.asset(
                              isFavorite
                                  ? 'assets/icons/new_boopi/State=Bold, Icon=Heart.svg'
                                  : 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
                              colorFilter: ColorFilter.mode(
                                contentColor,
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
                          color: badgeBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: badgeBorderColor),
                        ),
                        child: Text(
                          episodeCount,
                          style: (metaStyle ?? AppTypography.bodySmallSemiBold)
                              .copyWith(color: contentColor),
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
              style: (titleStyle ?? AppTypography.bodyMediumSemiBold).copyWith(
                color: contentColor,
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
    this.contentColor = AppColors.textOnPrimary,
    this.backgroundColor = AppColors.backgroundGlass,
    this.borderColor = const Color(0x3DFFFFFF),
    this.shadowColor = const Color(0x1A000000),
    this.imagePlaceholderColor = const Color(0x2EFFFFFF),
    this.badgeBackgroundStart = AppColors.interactivePrimaryPressed,
    this.badgeBackgroundEnd = const Color(0xFF040F21),
    this.badgeTextColor,
    this.voteIconDefaultColor,
    this.voteIconSelectedColor,
    this.voteIconDisabledColor,
    this.titleStyle,
    this.badgeStyle,
    this.isLiked = false,
    this.isDisliked = false,
    this.onLikeTap,
    this.onDislikeTap,
  });

  final String title;
  final String imageUrl;
  final double? width;
  final double scale;
  final Color contentColor;
  final Color backgroundColor;
  final Color borderColor;
  final Color shadowColor;
  final Color imagePlaceholderColor;
  final Color badgeBackgroundStart;
  final Color badgeBackgroundEnd;
  final Color? badgeTextColor;
  final Color? voteIconDefaultColor;
  final Color? voteIconSelectedColor;
  final Color? voteIconDisabledColor;
  final TextStyle? titleStyle;
  final TextStyle? badgeStyle;
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
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
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
                        return ColoredBox(color: imagePlaceholderColor);
                      },
                    ),
                  ),
                ),
                Positioned(
                  left: 0,
                  top: 0,
                  child: _WantThisBadge(
                    scale: scale,
                    contentColor: badgeTextColor ?? contentColor,
                    textStyle: badgeStyle,
                    backgroundStart: badgeBackgroundStart,
                    backgroundEnd: badgeBackgroundEnd,
                  ),
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
              style: (titleStyle ?? AppTypography.bodyMediumSemiBold).copyWith(
                color: contentColor,
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
                    contentColor: onLikeTap == null
                        ? voteIconDisabledColor ?? contentColor
                        : isLiked
                        ? voteIconSelectedColor ?? contentColor
                        : voteIconDefaultColor ?? contentColor,
                    onTap: onLikeTap,
                  ),
                  _ThumbActionIcon(
                    assetPath: isDisliked
                        ? 'assets/icons/new_boopi/State=Bold, Icon=Dislike.svg'
                        : 'assets/icons/new_boopi/State=Default, Icon=Dislike.svg',
                    semanticLabel: 'Vote no',
                    scale: scale,
                    contentColor: onDislikeTap == null
                        ? voteIconDisabledColor ?? contentColor
                        : isDisliked
                        ? voteIconSelectedColor ?? contentColor
                        : voteIconDefaultColor ?? contentColor,
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
  const _WantThisBadge({
    required this.scale,
    required this.contentColor,
    this.textStyle,
    required this.backgroundStart,
    required this.backgroundEnd,
  });

  final double scale;
  final Color contentColor;
  final TextStyle? textStyle;
  final Color backgroundStart;
  final Color backgroundEnd;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [backgroundStart, backgroundEnd],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(3 * scale),
          bottomRight: Radius.circular(12 * scale),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 8 * scale,
          vertical: 4 * scale,
        ),
        child: Text(
          'Want This?',
          maxLines: 1,
          style: (textStyle ?? AppTypography.captionBold).copyWith(
            color: contentColor,
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
    required this.contentColor,
    this.onTap,
  });

  final String assetPath;
  final String semanticLabel;
  final double scale;
  final Color contentColor;
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
            colorFilter: ColorFilter.mode(contentColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}
