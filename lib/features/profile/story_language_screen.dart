import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../auth/profile_notifier.dart';
import '../auth/profile_repository.dart';

const _figmaWidth = 390.0;
const _buttonShadowColor = Color(0x2E000000);

class StoryLanguageScreen extends ConsumerStatefulWidget {
  const StoryLanguageScreen({super.key});

  @override
  ConsumerState<StoryLanguageScreen> createState() =>
      _StoryLanguageScreenState();
}

class _StoryLanguageScreenState extends ConsumerState<StoryLanguageScreen> {
  String? _selectedLocale;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'story_language_screen',
        properties: {'source': 'profile_screen'},
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??=
        ref.read(profileNotifierProvider).valueOrNull?.selectedChild?.locale ??
        defaultProfileLocale;
  }

  Future<void> _continue() async {
    if (_isSaving) return;

    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'save_story_language',
        screenName: 'story_language_screen',
        properties: {'source': 'story_language_screen'},
      ),
    );
    final locale = normalizeProfileLocale(_selectedLocale);
    final hasProfile =
        ref.read(profileNotifierProvider).valueOrNull?.selectedChild != null;

    if (!hasProfile) {
      Navigator.of(context).maybePop();
      return;
    }

    setState(() => _isSaving = true);
    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .updateSelectedChildLocale(locale);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Could not update language.')),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final watchedLocale = ref
        .watch(profileNotifierProvider)
        .valueOrNull
        ?.selectedChild
        ?.locale;
    final selectedLocale = normalizeProfileLocale(
      _selectedLocale ?? watchedLocale,
    );
    final tokenStyles = _LanguageTokenStyles.fromRef(ref);

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        body: AppScreenBackground(
          child: SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.maxWidth / _figmaWidth)
                    .clamp(0.88, 1.18)
                    .toDouble();
                final horizontal = 16.0 * scale;

                return Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LanguageHeader(tokenStyles: tokenStyles),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            0,
                            horizontal,
                            0,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 12),
                              Text(
                                'Select Language',
                                style: tokenStyles.sectionLabel,
                              ),
                              const SizedBox(height: 16),
                              _LanguageCard(
                                tokenStyles: tokenStyles,
                                selectedLocale: selectedLocale,
                                onChanged: (locale) {
                                  setState(() => _selectedLocale = locale);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left: horizontal,
                      right: horizontal,
                      bottom: 38 * scale,
                      child: _ContinueButton(
                        tokenStyles: tokenStyles,
                        isSaving: _isSaving,
                        onTap: _continue,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageHeader extends StatelessWidget {
  const _LanguageHeader({required this.tokenStyles});

  final _LanguageTokenStyles tokenStyles;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox.square(
              dimension: 24,
              child: InkResponse(
                onTap: () => Navigator.of(context).maybePop(),
                radius: 24,
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: tokenStyles.contentColor,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text('Story Language', style: tokenStyles.title),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.tokenStyles,
    required this.selectedLocale,
    required this.onChanged,
  });

  final _LanguageTokenStyles tokenStyles;
  final String selectedLocale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokenStyles.cardBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tokenStyles.cardBorderColor),
        ),
        child: Column(
          children: [
            _LanguageOption(
              tokenStyles: tokenStyles,
              locale: 'en-IN',
              label: 'English',
              selected: selectedLocale == 'en-IN',
              iconText: 'En',
              onTap: onChanged,
            ),
            _LanguageOption(
              tokenStyles: tokenStyles,
              locale: 'hi-IN',
              label: '\u{0939}\u{093F}\u{0902}\u{0926}\u{0940}',
              selected: selectedLocale == 'hi-IN',
              iconText: '\u{0905}',
              onTap: onChanged,
              showDivider: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.tokenStyles,
    required this.locale,
    required this.label,
    required this.selected,
    required this.iconText,
    required this.onTap,
    this.showDivider = true,
  });

  final _LanguageTokenStyles tokenStyles;
  final String locale;
  final String label;
  final bool selected;
  final String iconText;
  final ValueChanged<String> onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: InkWell(
        onTap: () => onTap(locale),
        child: Container(
          height: 72,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 17),
          decoration: BoxDecoration(
            border: showDivider
                ? Border(bottom: BorderSide(color: tokenStyles.cardBorderColor))
                : null,
          ),
          child: Row(
            children: [
              _LanguageIcon(
                label: iconText,
                color: tokenStyles.contentColor,
                backgroundColor: tokenStyles.cardBackgroundColor,
                borderColor: tokenStyles.cardBorderColor,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tokenStyles.option,
                ),
              ),
              _RadioIcon(selected: selected, color: tokenStyles.contentColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageIcon extends StatelessWidget {
  const _LanguageIcon({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.borderColor,
  });

  final String label;
  final Color color;
  final Color backgroundColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39.993,
      height: 39.993,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      alignment: Alignment.center,
      child: SizedBox.square(
        dimension: 24,
        child: CustomPaint(painter: _LanguageGlyphPainter(label, color)),
      ),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  const _RadioIcon({required this.selected, required this.color});

  final bool selected;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(painter: _RadioPainter(selected, color)),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({
    required this.tokenStyles,
    required this.isSaving,
    required this.onTap,
  });

  final _LanguageTokenStyles tokenStyles;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isSaving ? null : onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokenStyles.cardBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: tokenStyles.cardBorderColor, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: _buttonShadowColor,
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: isSaving
            ? SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tokenStyles.contentColor,
                ),
              )
            : Text('Continue', style: tokenStyles.button),
      ),
    );
  }
}

class _LanguageGlyphPainter extends CustomPainter {
  const _LanguageGlyphPainter(this.label, this.color);

  final String label;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(5, 5, size.width - 10, size.height - 10),
      const Radius.circular(2),
    );
    canvas.drawRRect(rect, stroke);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: color,
          fontFamily: AppTypography.fontFamily,
          fontSize: label == 'En' ? 8.5 : 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _LanguageGlyphPainter oldDelegate) {
    return oldDelegate.label != label || oldDelegate.color != color;
  }
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter(this.selected, this.color);

  final bool selected;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8.5, stroke);

    if (!selected) return;

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.5, fill);
  }

  @override
  bool shouldRepaint(covariant _RadioPainter oldDelegate) {
    return oldDelegate.selected != selected || oldDelegate.color != color;
  }
}

class _LanguageTokenStyles {
  const _LanguageTokenStyles({
    required this.contentColor,
    required this.title,
    required this.sectionLabel,
    required this.option,
    required this.button,
    required this.cardBackgroundColor,
    required this.cardBorderColor,
  });

  factory _LanguageTokenStyles.fromRef(WidgetRef ref) {
    final tokenColors = AppTokenColors.of(ref);
    final tokenTextStyles = AppTokenTextStyles.of(ref);
    final contentColor = tokenColors.profileTextPrimary;
    return _LanguageTokenStyles(
      contentColor: contentColor,
      title: tokenTextStyles.profileHeaderTitle.copyWith(color: contentColor),
      sectionLabel: tokenTextStyles.profileSectionLabel.copyWith(
        color: contentColor,
      ),
      option: tokenTextStyles.profileRowTitle.copyWith(color: contentColor),
      button: tokenTextStyles.onboardingCtaLabel.copyWith(color: contentColor),
      cardBackgroundColor: tokenColors.profileCardBackground,
      cardBorderColor: tokenColors.profileCardBorder,
    );
  }

  final Color contentColor;
  final TextStyle title;
  final TextStyle sectionLabel;
  final TextStyle option;
  final TextStyle button;
  final Color cardBackgroundColor;
  final Color cardBorderColor;
}
