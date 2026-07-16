import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/custom_search_bar.dart';
import '../../shared/widgets/glassy_bottom_nav_bar.dart';
import '../../shared/widgets/play_circle_button.dart';
import '../../shared/widgets/story_card.dart';
import '../auth/profile_notifier.dart';
import '../profile/profile_screen.dart';
import '../storytime/models/story_model.dart';
import '../storytime/providers/story_player_provider.dart';

const String _supabaseAssetBase =
    'https://ozdvhjcumeujfxodiawc.supabase.co/storage/v1/object/public/app-assets/';
const double _figmaWidth = 390;

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, this.childName, this.childAge});

  final String? childName;
  final int? childAge;

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _bottomNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileNotifierProvider);
    final selectedChild = profileState.valueOrNull?.selectedChild;
    final childName = _firstNonEmpty([
      selectedChild?.childName,
      widget.childName,
      'Little One',
    ]);
    final contentState = ref.watch(storytimeContentProvider);

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.blue300, AppColors.blue500, AppColors.blue800],
              stops: [0, 0.48, 1],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: SafeArea(
                  bottom: false,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final scale = (constraints.maxWidth / _figmaWidth)
                          .clamp(0.88, 1.16)
                          .toDouble();
                      final horizontal = 16.0 * scale;
                      final banner = _resolveBanner(contentState.valueOrNull);

                      return SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          horizontal,
                          24 * scale,
                          horizontal,
                          118 * scale + MediaQuery.paddingOf(context).bottom,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _Header(name: childName, scale: scale),
                            SizedBox(height: 24 * scale),
                            const CustomSearchBar(),
                            SizedBox(height: 20 * scale),
                            _HeroBanner(banner: banner, scale: scale),
                            SizedBox(height: 22 * scale),
                            _SectionTitle('Top Picks for You', scale: scale),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: _topPickStories,
                            ),
                            SizedBox(height: 22 * scale),
                            _SectionTitle('Made for You', scale: scale),
                            SizedBox(height: 12 * scale),
                            _TwoColumnStoryGrid(
                              scale: scale,
                              stories: _madeForYouStories,
                            ),
                            if (contentState.hasError) ...[
                              SizedBox(height: 16 * scale),
                              Text(
                                'Stories could not be refreshed.',
                                style: AppTypography.bodySmallMedium.copyWith(
                                  color: Colors.white.withValues(alpha: 0.72),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: GlassyBottomNavBar(
                  currentIndex: _bottomNavIndex,
                  onTap: (index) {
                    if (index == 3) {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (context) => ProfileScreen(
                            fallbackChildName: childName,
                            fallbackChildAge:
                                selectedChild?.age ?? widget.childAge,
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() => _bottomNavIndex = index);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _HomeBannerData _resolveBanner(StorytimeContent? content) {
    final banner = content?.featuredBanners.firstOrNull;
    return _HomeBannerData(
      imageUrl:
          banner?.imageUrl ??
          '${_supabaseAssetBase}featured_banners/krishna ki sunheri subah.webp',
      title: 'Kanha Ki Sunheri Subah',
      subtitle: 'TONIGHT',
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name, required this.scale});

  final String name;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good Morning,',
                style: AppTypography.bodySmallRegular.copyWith(
                  color: Colors.white,
                  fontSize: 12 * scale,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodyLargeBold.copyWith(
                  color: Colors.white,
                  fontSize: 16 * scale,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 16 * scale),
        Row(
          children: [
            _GlassyActionButton(
              iconPath: 'assets/icons/new_boopi/State=Default, Icon=Heart.svg',
              size: 42 * scale,
              onTap: () {},
            ),
            SizedBox(width: 10 * scale),
            _GlassyActionButton(
              iconPath:
                  'assets/icons/new_boopi/State=Default, Icon=Notification.svg',
              size: 42 * scale,
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassyActionButton extends StatelessWidget {
  const _GlassyActionButton({
    required this.iconPath,
    required this.size,
    required this.onTap,
  });

  final String iconPath;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.2),
              border: Border.all(color: Colors.white.withValues(alpha: 0.38)),
            ),
            child: SvgPicture.asset(
              iconPath,
              width: size * 0.48,
              height: size * 0.48,
              colorFilter: const ColorFilter.mode(
                Colors.white,
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner({required this.banner, required this.scale});

  final _HomeBannerData banner;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 172 * scale,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            offset: const Offset(0, 8),
            blurRadius: 18,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16 * scale),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(color: AppColors.backgroundHero);
              },
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.08),
                    Colors.black.withValues(alpha: 0.72),
                  ],
                  stops: const [0.36, 0.66, 1],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16 * scale,
                16 * scale,
                16 * scale,
                14 * scale,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          banner.subtitle,
                          style: AppTypography.captionBold.copyWith(
                            color: Colors.white,
                            fontSize: 10 * scale,
                            letterSpacing: 1,
                          ),
                        ),
                        SizedBox(height: 4 * scale),
                        Text(
                          banner.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodyLargeBold.copyWith(
                            color: Colors.white,
                            fontSize: 16 * scale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 12 * scale),
                  PlayCircleButton(size: 42 * scale, onTap: () {}),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text, {required this.scale});

  final String text;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.bodyLargeBold.copyWith(
        color: Colors.white,
        fontSize: 16 * scale,
      ),
    );
  }
}

class _TwoColumnStoryGrid extends StatelessWidget {
  const _TwoColumnStoryGrid({required this.stories, required this.scale});

  final List<StoryModel> stories;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final count = stories.length;
    if (count == 0) {
      return const SizedBox.shrink();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = 16 * scale;
        final cardWidth = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: 16 * scale,
          children: [
            for (var index = 0; index < count; index += 1)
              SizedBox(
                width: cardWidth,
                height: 253 * scale,
                child: StoryCard(
                  title: stories[index].title,
                  imageUrl: stories[index].thumbnailUrl,
                  episodeCount: 'Ep 3 of 7',
                  imageHeight: 147 * scale,
                  onTap: () {},
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HomeBannerData {
  const _HomeBannerData({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });

  final String imageUrl;
  final String title;
  final String subtitle;
}

String _firstNonEmpty(List<String?> values) {
  for (final value in values) {
    final trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      return trimmed;
    }
  }

  return '';
}

String _storyThumbnailUrl(String fileName) {
  return Uri.encodeFull('${_supabaseAssetBase}story_thumbnails/$fileName');
}

final _topPickStories = [
  StoryModel(
    id: 'top-pick-shararati-krishna',
    title: 'Shararati Krishna ke karname',
    thumbnailUrl: _storyThumbnailUrl('Shararati krishna ke karname.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'top-pick-bal-ganesh',
    title: 'Bal Ganesh Aur Laddo',
    thumbnailUrl: _storyThumbnailUrl('Bal Ganesh aur laddu.webp'),
    category: 'Ganesh Stories',
    durationMinutes: 3,
  ),
];

final _madeForYouStories = [
  StoryModel(
    id: 'made-for-you-arjun',
    title: 'Veer Bal Arjun',
    thumbnailUrl: _storyThumbnailUrl('Veer Bal Arjun.webp'),
    category: 'Mahabharata',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-makhan',
    title: 'Krishna aur makhan',
    thumbnailUrl: _storyThumbnailUrl('krishna aur makhan.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-handi',
    title: 'Krishna aur handi',
    thumbnailUrl: _storyThumbnailUrl('krishna aur handi.webp'),
    category: 'Krishna Stories',
    durationMinutes: 3,
  ),
  StoryModel(
    id: 'made-for-you-ganesh-masti',
    title: 'Bal Ganesh ki Masti',
    thumbnailUrl: _storyThumbnailUrl('Bal Ganesh ki masti.webp'),
    category: 'Ganesh Stories',
    durationMinutes: 3,
  ),
];
