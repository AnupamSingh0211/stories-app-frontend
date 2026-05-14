import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'companion_model.dart';
import 'companion_notifier.dart';

class ConfirmCompanionScreen extends ConsumerWidget {
  const ConfirmCompanionScreen({required this.companion, super.key});

  final CompanionModel companion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: RepaintBoundary(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF151333),
                colors.surface,
                const Color(0xFF090E1A),
              ],
            ),
          ),
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBar(onBack: () => Navigator.pop(context)),
                          const SizedBox(height: 46),
                          _CompanionPortrait(companion: companion),
                          const SizedBox(height: 48),
                          Text(
                            'Your Eternal Friend',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: colors.onSurface,
                              fontSize: 34,
                              height: 1.05,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            companion.longDescription,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.onSurface.withValues(alpha: 0.68),
                              fontSize: 19,
                              height: 1.62,
                            ),
                          ),
                          const SizedBox(height: 34),
                          const RepaintBoundary(child: _PolicyCard()),
                          const SizedBox(height: 54),
                          PillButton(
                            onTap: () {
                              ref
                                  .read(companionNotifierProvider.notifier)
                                  .selectCompanion(companion);
                              Navigator.pop(context);
                              Navigator.pop(context);
                            },
                            height: 62,
                            gradient: LinearGradient(
                              colors: [colors.primary, colors.secondary],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors.secondary.withValues(alpha: 0.3),
                                blurRadius: 22,
                                offset: const Offset(0, 9),
                              ),
                            ],
                            child: Text(
                              'Confirm & Start',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 19,
                              ),
                            ),
                          ),
                          const SizedBox(height: 22),
                          TextButton.icon(
                            onPressed: () => Navigator.pop(context),
                            icon: Icon(
                              Icons.swap_horiz_rounded,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            label: Text(
                              'Choose a different character',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.72),
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionPortrait extends StatelessWidget {
  const _CompanionPortrait({required this.companion});

  final CompanionModel companion;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
          final portraitSize = (constraints.maxWidth * 0.82)
              .clamp(230.0, 278.0)
              .toDouble();
          final cacheWidth = (portraitSize * devicePixelRatio).round();

          return Center(
            child: Container(
              width: portraitSize,
              height: portraitSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.secondary.withValues(alpha: 0.2),
                    blurRadius: 38,
                    spreadRadius: 7,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: companion.imageUrl,
                      width: portraitSize,
                      height: portraitSize,
                      fit: BoxFit.cover,
                      memCacheWidth: cacheWidth,
                      memCacheHeight: cacheWidth,
                      fadeInDuration: const Duration(milliseconds: 120),
                      placeholder: (context, url) => Container(
                        color: colors.surface.withValues(alpha: 0.72),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: colors.surface.withValues(alpha: 0.72),
                        child: Icon(
                          Icons.auto_stories_rounded,
                          color: colors.primary,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.68),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: colors.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'BABY',
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.72),
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            companion.displayName.replaceFirst('Baby ', ''),
                            style: TextStyle(
                              color: colors.onSurface,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PolicyCard extends StatelessWidget {
  const _PolicyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        color: colors.surface.withValues(alpha: 0.62),
        border: Border.all(color: colors.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF332B2C).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: Color(0xFFFFD65B),
              size: 25,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Free Choice Policy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFFFFEB80),
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Free users can only choose one character permanently. Premium members can switch characters anytime.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.64),
                    height: 1.52,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        SizedBox.square(
          dimension: 42,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back,
              color: colors.onSurface.withValues(alpha: 0.9),
              size: 29,
            ),
          ),
        ),
        Expanded(
          child: Text(
            'Confirm Companion',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 21,
            ),
          ),
        ),
        SizedBox.square(
          dimension: 42,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.onSurface.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: colors.onSurface.withValues(alpha: 0.12),
              ),
            ),
            child: Icon(
              Icons.dark_mode_rounded,
              color: colors.onSurface.withValues(alpha: 0.86),
              size: 24,
            ),
          ),
        ),
      ],
    );
  }
}
