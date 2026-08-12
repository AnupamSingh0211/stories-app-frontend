import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import '../auth/profile_notifier.dart';
import '../auth/profile_repository.dart';

const _figmaWidth = 390.0;
const _glassColor = Color(0x2EFFFFFF);
const _borderColor = Color(0x59FFFFFF);
const _dividerColor = Color(0x59FFFFFF);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedLocale ??=
        ref.read(profileNotifierProvider).valueOrNull?.selectedChild?.locale ??
        defaultProfileLocale;
  }

  Future<void> _continue() async {
    if (_isSaving) return;

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
                        const _LanguageHeader(),
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
                              const Text(
                                'Select Language',
                                style: _LanguageTextStyles.sectionLabel,
                              ),
                              const SizedBox(height: 16),
                              _LanguageCard(
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
  const _LanguageHeader();

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
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: AppColors.textOnPrimary,
                  size: 24,
                  applyTextScaling: false,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('Story Language', style: _LanguageTextStyles.title),
          ],
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({required this.selectedLocale, required this.onChanged});

  final String selectedLocale;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _glassColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _borderColor),
        ),
        child: Column(
          children: [
            _LanguageOption(
              locale: 'en-IN',
              label: 'English',
              selected: selectedLocale == 'en-IN',
              iconText: 'En',
              onTap: onChanged,
            ),
            _LanguageOption(
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
    required this.locale,
    required this.label,
    required this.selected,
    required this.iconText,
    required this.onTap,
    this.showDivider = true,
  });

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
                ? const Border(bottom: BorderSide(color: _dividerColor))
                : null,
          ),
          child: Row(
            children: [
              _LanguageIcon(label: iconText),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _LanguageTextStyles.option,
                ),
              ),
              _RadioIcon(selected: selected),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageIcon extends StatelessWidget {
  const _LanguageIcon({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39.993,
      height: 39.993,
      decoration: BoxDecoration(
        color: AppColors.backgroundGlass,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      alignment: Alignment.center,
      child: SizedBox.square(
        dimension: 24,
        child: CustomPaint(painter: _LanguageGlyphPainter(label)),
      ),
    );
  }
}

class _RadioIcon extends StatelessWidget {
  const _RadioIcon({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(painter: _RadioPainter(selected)),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isSaving, required this.onTap});

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
          color: AppColors.backgroundGlass,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.borderLight, width: 0.8),
          boxShadow: const [
            BoxShadow(
              color: _buttonShadowColor,
              offset: Offset(0, 2),
              blurRadius: 8,
            ),
          ],
        ),
        child: isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.textOnPrimary,
                ),
              )
            : const Text('Continue', style: _LanguageTextStyles.button),
      ),
    );
  }
}

class _LanguageGlyphPainter extends CustomPainter {
  const _LanguageGlyphPainter(this.label);

  final String label;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = AppColors.textOnPrimary
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
          color: AppColors.textOnPrimary,
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
    return oldDelegate.label != label;
  }
}

class _RadioPainter extends CustomPainter {
  const _RadioPainter(this.selected);

  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = Paint()
      ..color = AppColors.textOnPrimary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, 8.5, stroke);

    if (!selected) return;

    final fill = Paint()
      ..color = AppColors.textOnPrimary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4.5, fill);
  }

  @override
  bool shouldRepaint(covariant _RadioPainter oldDelegate) {
    return oldDelegate.selected != selected;
  }
}

abstract final class _LanguageTextStyles {
  static const title = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 20,
    height: 24 / 20,
    letterSpacing: -0.25,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const sectionLabel = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const option = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
  );

  static const button = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );
}
