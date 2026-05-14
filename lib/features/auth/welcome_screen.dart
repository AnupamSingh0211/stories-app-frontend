import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'assets_provider.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appAssets = ref.watch(appAssetsProvider);

    return Scaffold(
      body: Stack(
        children: [
          RepaintBoundary(
            child: Stack(
              children: [
                _BackgroundImage(imageUrl: appAssets['welcome_bg']!),
                Container(color: colors.surface.withValues(alpha: 0.6)),
              ],
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 100),
                            Text(
                              "Welcome to\nBedtime Stories",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 36,
                                color: colors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Step into a world of gentle tales \nand quiet nights. Your journey to restful \nsleep starts here.",
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                            const Spacer(),
                            _AuthButton(
                              text: "Continue with Apple",
                              iconPath: appAssets['ios_icon']!,
                              iconHeight: 20,
                              iconGap: 4,
                              textColor: colors.surface,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileSetupScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _AuthButton(
                              text: "Continue with Google",
                              iconPath: appAssets['google_icon']!,
                              iconHeight: 20,
                              iconGap: 10,
                              textColor: colors.onSurface,
                              border: Border.all(
                                color: colors.outline.withValues(alpha: 0.3),
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileSetupScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _AuthButton(
                              text: "Continue with Email",
                              iconPath: appAssets['email_icon']!,
                              iconHeight: 24,
                              iconGap: 10,
                              textColor: colors.onPrimary,
                              fontWeight: FontWeight.w600,
                              gradient: LinearGradient(
                                colors: [colors.primary, colors.secondary],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileSetupScreen(),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ProfileSetupScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                "Browse as a Guest ->",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundImage extends StatelessWidget {
  const _BackgroundImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();

    return SizedBox.expand(
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: cacheWidth,
        fadeInDuration: const Duration(milliseconds: 120),
        placeholder: (context, url) => Container(color: colors.surface),
        errorWidget: (context, url, error) => Container(color: colors.surface),
      ),
    );
  }
}

class _AuthButton extends StatelessWidget {
  const _AuthButton({
    required this.text,
    required this.iconPath,
    required this.iconHeight,
    required this.iconGap,
    required this.textColor,
    required this.onTap,
    this.fontWeight,
    this.color,
    this.gradient,
    this.border,
  });

  final String text;
  final String iconPath;
  final double iconHeight;
  final double iconGap;
  final Color textColor;
  final VoidCallback onTap;
  final FontWeight? fontWeight;
  final Color? color;
  final Gradient? gradient;
  final Border? border;

  @override
  Widget build(BuildContext context) {
    final cacheHeight = (iconHeight * MediaQuery.of(context).devicePixelRatio)
        .round();

    return PillButton(
      onTap: onTap,
      height: 56,
      color: color,
      gradient: gradient,
      border: border,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CachedNetworkImage(
            imageUrl: iconPath,
            height: iconHeight,
            memCacheHeight: cacheHeight,
            fadeInDuration: const Duration(milliseconds: 80),
            placeholder: (context, url) =>
                SizedBox.square(dimension: iconHeight),
            errorWidget: (context, url, error) =>
                SizedBox.square(dimension: iconHeight),
          ),
          SizedBox(width: iconGap),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: textColor, fontWeight: fontWeight),
            ),
          ),
        ],
      ),
    );
  }
}
