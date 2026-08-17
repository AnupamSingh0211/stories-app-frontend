import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_shadows.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../../shared/widgets/pill_button.dart';
import 'companion_flow.dart';
import 'companion_model.dart';
import 'companions_provider.dart';
import 'confirm_companion_screen.dart';

class ChooseCompanionScreen extends ConsumerStatefulWidget {
  const ChooseCompanionScreen({super.key, this.onComplete});

  final CompanionFlowComplete? onComplete;

  @override
  ConsumerState<ChooseCompanionScreen> createState() =>
      _ChooseCompanionScreenState();
}

class _ChooseCompanionScreenState extends ConsumerState<ChooseCompanionScreen> {
  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'profile_selection_screen',
        properties: {'source': 'onboarding'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companions = ref.watch(companionsProvider);

    return Scaffold(
      body: RepaintBoundary(
        child: AppScreenBackground(
          child: SafeArea(
            child: companions.when(
              data: (items) =>
                  _CompanionList(
                    companions: items,
                    onComplete: widget.onComplete,
                  ),
              loading: () => const _LoadingState(),
              error: (error, stackTrace) => _ErrorState(error: error),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompanionList extends StatelessWidget {
  const _CompanionList({required this.companions, required this.onComplete});

  final List<CompanionModel> companions;
  final CompanionFlowComplete? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return ListView.builder(
      physics: const ClampingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
      itemCount: companions.length + 2,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Column(
            children: [
              _TopBar(onBack: () => Navigator.pop(context)),
              const SizedBox(height: 34),
              Text(
                'Pick Your Story\nCompanion',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: colors.onSurface,
                  fontSize: 30,
                  height: 1.06,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Choose a gentle guide to walk with your child through each story. Each companion brings a unique sense of peace.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.72),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 28),
            ],
          );
        }

        if (index == companions.length + 1) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            child: PillButton(
              onTap: () {
                unawaited(
                  PostHogAnalytics.instance.buttonClicked(
                    buttonName: 'skip_companion_selection',
                    screenName: 'profile_selection_screen',
                    properties: {'source': 'companion_selection'},
                  ),
                );
                final onComplete = this.onComplete;
                if (onComplete != null) {
                  onComplete(context);
                  return;
                }

                Navigator.pop(context);
              },
              height: 40,
              border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
              color: colors.surface.withValues(alpha: 0.18),
              child: Text(
                'Skip for now',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.68),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }

        final companionIndex = index - 1;

        return Padding(
          padding: EdgeInsets.only(
            bottom: companionIndex == companions.length - 1 ? 0 : 24,
          ),
          child: RepaintBoundary(
            child: _CompanionCard(
              companion: companions[companionIndex],
              onComplete: onComplete,
            ),
          ),
        );
      },
    );
  }
}

class _CompanionCard extends StatelessWidget {
  const _CompanionCard({required this.companion, required this.onComplete});

  final CompanionModel companion;
  final CompanionFlowComplete? onComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: colors.surface.withValues(alpha: 0.52),
        border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: colors.secondary.withValues(alpha: 0.12),
            blurRadius: 22,
            spreadRadius: -5,
          ),
          AppShadows.elevation2,
        ],
      ),
      child: Column(
        children: [
          RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cacheWidth = (constraints.maxWidth * devicePixelRatio)
                        .round();

                    return CachedNetworkImage(
                      imageUrl: companion.imageUrl,
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
                          size: 34,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            companion.displayName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            companion.shortDescription,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.76),
              fontSize: 11,
              height: 1.38,
            ),
          ),
          const SizedBox(height: 18),
          PillButton(
            onTap: () {
              unawaited(
                PostHogAnalytics.instance.buttonClicked(
                  buttonName: 'select_companion',
                  screenName: 'profile_selection_screen',
                  properties: {
                    'source': 'companion_card',
                    'target_type': 'companion',
                  },
                ),
              );
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ConfirmCompanionScreen(
                    companion: companion,
                    onComplete: onComplete,
                  ),
                ),
              );
            },
            height: 42,
            border: Border.all(color: colors.primary.withValues(alpha: 0.58)),
            color: colors.primary.withValues(alpha: 0.08),
            child: Text(
              'Select Companion',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
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
          dimension: 34,
          child: IconButton(
            onPressed: onBack,
            padding: EdgeInsets.zero,
            icon: Icon(
              Icons.arrow_back,
              color: colors.onSurface.withValues(alpha: 0.78),
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'Boopi',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off_rounded, color: colors.primary, size: 34),
          const SizedBox(height: 16),
          Text(
            'Could not load companions',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.62),
            ),
          ),
          const SizedBox(height: 20),
          PillButton(
            onTap: () => Navigator.pop(context),
            border: Border.all(color: colors.outline.withValues(alpha: 0.24)),
            color: colors.surface.withValues(alpha: 0.2),
            child: Text(
              'Go back',
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
