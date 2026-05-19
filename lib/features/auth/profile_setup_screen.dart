import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'assets_provider.dart';
import 'choose_companion_screen.dart';
import 'companion_notifier.dart';
import 'profile_notifier.dart';

const _ageOptions = [1, 2, 3, 4];
const _genderOptions = [
  _GenderOption(label: 'Boy', value: 'boy', icon: Icons.face_rounded),
  _GenderOption(label: 'Girl', value: 'girl', icon: Icons.face_3_rounded),
];

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _selectedAge = 2;
  String _selectedGender = 'boy';

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    try {
      await ref
          .read(profileNotifierProvider.notifier)
          .saveProfile(
            name: _nameController.text.trim(),
            gender: _selectedGender,
            age: _selectedAge,
            companionId: ref.read(companionNotifierProvider)?.id,
          );

      if (!mounted) return;

      final profileState = ref.read(profileNotifierProvider);
      if (profileState.hasError) {
        throw profileState.error!;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    }
  }

  void _chooseCompanion() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChooseCompanionScreen()),
    );
  }

  void _skipProfile() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final appAssets = ref.watch(appAssetsProvider);
    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();

    return Scaffold(
      body: Stack(
        children: [
          _ProfileBackground(
            imageUrl: appAssets['profile_setup_bg']!,
            colors: colors,
            cacheWidth: cacheWidth,
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.of(context).viewInsets.bottom;
                const horizontalPadding = 18.0;
                const topPadding = 10.0;
                final bottomPadding = 24.0 + bottomInset;
                final minContentHeight =
                    (constraints.maxHeight - topPadding - bottomPadding)
                        .clamp(0.0, double.infinity)
                        .toDouble();

                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      topPadding,
                      horizontalPadding,
                      bottomPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minContentHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TopBar(
                              colors: colors,
                              onBack: () => Navigator.pop(context),
                            ),
                            const SizedBox(height: 42),
                            _BookBadge(colors: colors),
                            const SizedBox(height: 22),
                            _TitleText(theme: theme, colors: colors),
                            const SizedBox(height: 12),
                            const _SubtitleText(),
                            const SizedBox(height: 32),
                            _FieldLabel(
                              text: "Child's name",
                              theme: theme,
                              colors: colors,
                            ),
                            const SizedBox(height: 8),
                            _NameField(
                              controller: _nameController,
                              colors: colors,
                              theme: theme,
                            ),
                            const SizedBox(height: 28),
                            _FieldLabel(
                              text: "Child's gender",
                              theme: theme,
                              colors: colors,
                            ),
                            const SizedBox(height: 12),
                            _GenderSelector(
                              selectedGender: _selectedGender,
                              onGenderChanged: (gender) =>
                                  setState(() => _selectedGender = gender),
                            ),
                            const SizedBox(height: 28),
                            _FieldLabel(
                              text: 'How old are they?',
                              theme: theme,
                              colors: colors,
                            ),
                            const SizedBox(height: 12),
                            _AgeSelector(
                              selectedAge: _selectedAge,
                              onAgeChanged: (age) =>
                                  setState(() => _selectedAge = age),
                            ),
                            const SizedBox(height: 40),
                            Consumer(
                              builder: (context, ref, child) {
                                final companionName = ref.watch(
                                  companionNotifierProvider.select(
                                    (companion) => companion?.displayName,
                                  ),
                                );

                                return _CompanionButton(
                                  label: companionName ?? 'Choose Companion',
                                  onTap: _chooseCompanion,
                                  colors: colors,
                                  theme: theme,
                                );
                              },
                            ),
                            const SizedBox(height: 28),
                            const Spacer(),
                            Consumer(
                              builder: (context, ref, child) {
                                final isSaving = ref.watch(
                                  profileNotifierProvider.select(
                                    (state) => state.isLoading,
                                  ),
                                );

                                return _CreateProfileButton(
                                  isSaving: isSaving,
                                  onTap: isSaving ? null : _saveProfile,
                                  colors: colors,
                                  theme: theme,
                                );
                              },
                            ),
                            const SizedBox(height: 16),
                            _SkipButton(
                              onTap: _skipProfile,
                              colors: colors,
                              theme: theme,
                            ),
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

class _GenderOption {
  const _GenderOption({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _ProfileBackground extends StatelessWidget {
  const _ProfileBackground({
    required this.imageUrl,
    required this.colors,
    required this.cacheWidth,
  });

  final String imageUrl;
  final ColorScheme colors;
  final int cacheWidth;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          RepaintBoundary(
            child: SizedBox.expand(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: cacheWidth,
                fadeInDuration: const Duration(milliseconds: 120),
                placeholder: (context, url) => Container(color: colors.surface),
                errorWidget: (context, url, error) =>
                    Container(color: colors.surface),
              ),
            ),
          ),
          Container(color: colors.surface.withValues(alpha: 0.44)),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.22, 0.42, 0.56, 1],
                colors: [
                  colors.surface.withValues(alpha: 0.08),
                  colors.surface.withValues(alpha: 0.08),
                  colors.surface.withValues(alpha: 0.58),
                  colors.surface.withValues(alpha: 0.92),
                  colors.surface.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.colors, required this.onBack});

  final ColorScheme colors;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = this.colors;

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
          'Bedtime Stories',
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

class _BookBadge extends StatelessWidget {
  const _BookBadge({required this.colors});

  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final colors = this.colors;

    return Center(
      child: Container(
        height: 52,
        width: 52,
        decoration: BoxDecoration(
          color: colors.primary.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: colors.secondary.withValues(alpha: 0.22),
              blurRadius: 18,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(Icons.menu_book_rounded, color: colors.primary, size: 27),
      ),
    );
  }
}

class _TitleText extends StatelessWidget {
  const _TitleText({required this.theme, required this.colors});

  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return Text(
      'Who are we telling\nstories to today?',
      textAlign: TextAlign.center,
      style: theme.textTheme.headlineMedium?.copyWith(
        color: colors.onSurface,
        fontSize: 28,
        height: 1.12,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _SubtitleText extends StatelessWidget {
  const _SubtitleText();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text(
      'Create a profile to tailor bedtime adventures\nand gentle dreamscapes.',
      textAlign: TextAlign.center,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface.withValues(alpha: 0.68),
        fontSize: 13,
        height: 1.45,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({
    required this.text,
    required this.theme,
    required this.colors,
  });

  final String text;
  final ThemeData theme;
  final ColorScheme colors;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: colors.onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.colors,
    required this.theme,
  });

  final TextEditingController controller;
  final ColorScheme colors;
  final ThemeData theme;

  static final OutlineInputBorder _emptyBorder = OutlineInputBorder(
    borderRadius: const BorderRadius.all(Radius.circular(16)),
    borderSide: BorderSide.none,
  );

  static OutlineInputBorder _fieldBorder(Color color) {
    return OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      borderSide: BorderSide(color: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return TextFormField(
      controller: controller,
      textInputAction: TextInputAction.done,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colors.onSurface,
        fontSize: 13,
      ),
      cursorColor: colors.primary,
      decoration: InputDecoration(
        hintText: 'Enter name',
        hintStyle: theme.textTheme.bodyMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.42),
          fontSize: 13,
        ),
        suffixIcon: Icon(
          Icons.face_5_rounded,
          color: colors.onSurface.withValues(alpha: 0.52),
          size: 18,
        ),
        filled: true,
        fillColor: colors.surface.withValues(alpha: 0.92),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        border: _emptyBorder,
        enabledBorder: _emptyBorder,
        focusedBorder: _fieldBorder(colors.primary),
        errorBorder: _fieldBorder(colors.error),
        focusedErrorBorder: _fieldBorder(colors.error),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Enter name';
        }

        return null;
      },
    );
  }
}

class _GenderSelector extends StatelessWidget {
  const _GenderSelector({
    required this.selectedGender,
    required this.onGenderChanged,
  });

  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: _genderOptions.map((gender) {
        final isSelected = gender.value == selectedGender;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: gender == _genderOptions.first ? 12 : 0,
              left: gender == _genderOptions.last ? 12 : 0,
            ),
            child: _GenderButton(
              option: gender,
              isSelected: isSelected,
              onTap: () => onGenderChanged(gender.value),
              colors: colors,
              theme: theme,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _GenderButton extends StatelessWidget {
  const _GenderButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final _GenderOption option;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? colors.secondaryContainer
              : colors.surface.withValues(alpha: 0.88),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.16),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.secondary.withValues(alpha: 0.32),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              option.icon,
              color: isSelected
                  ? colors.onSecondaryContainer
                  : colors.onSurface.withValues(alpha: 0.64),
              size: 18,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colors.onSecondaryContainer
                      : colors.onSurface.withValues(alpha: 0.64),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({required this.selectedAge, required this.onAgeChanged});

  final int selectedAge;
  final ValueChanged<int> onAgeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: _ageOptions.map((age) {
        return _AgeButton(
          age: age,
          isSelected: age == selectedAge,
          onTap: () => onAgeChanged(age),
          colors: colors,
          theme: theme,
        );
      }).toList(),
    );
  }
}

class _AgeButton extends StatelessWidget {
  const _AgeButton({
    required this.age,
    required this.isSelected,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final int age;
  final bool isSelected;
  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 50,
        width: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected
              ? colors.secondaryContainer
              : colors.surface.withValues(alpha: 0.88),
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? colors.primary
                : colors.outline.withValues(alpha: 0.16),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colors.secondary.withValues(alpha: 0.32),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Text(
          '$age',
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? colors.onSecondaryContainer
                : colors.onSurface.withValues(alpha: 0.64),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _CompanionButton extends StatelessWidget {
  const _CompanionButton({
    required this.label,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final String label;
  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return PillButton(
      onTap: onTap,
      gradient: LinearGradient(
        colors: [
          colors.secondaryContainer.withValues(alpha: 0.58),
          colors.tertiary.withValues(alpha: 0.28),
        ],
      ),
      border: Border.all(color: colors.primary.withValues(alpha: 0.28)),
      boxShadow: [
        BoxShadow(
          color: colors.secondary.withValues(alpha: 0.18),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.diversity_1_rounded,
            color: colors.onSurface.withValues(alpha: 0.9),
            size: 18,
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateProfileButton extends StatelessWidget {
  const _CreateProfileButton({
    required this.isSaving,
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final bool isSaving;
  final VoidCallback? onTap;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return PillButton(
      onTap: onTap,
      gradient: isSaving
          ? null
          : LinearGradient(colors: [colors.primary, colors.secondary]),
      color: isSaving ? colors.surface.withValues(alpha: 0.78) : null,
      child: isSaving
          ? SizedBox.square(
              dimension: 19,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.onSurface,
              ),
            )
          : Text(
              'Create Profile',
              style: theme.textTheme.labelLarge?.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({
    required this.onTap,
    required this.colors,
    required this.theme,
  });

  final VoidCallback onTap;
  final ColorScheme colors;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final theme = this.theme;
    final colors = this.colors;

    return PillButton(
      onTap: onTap,
      height: 42,
      border: Border.all(color: colors.outline.withValues(alpha: 0.18)),
      color: colors.surface.withValues(alpha: 0.12),
      child: Text(
        'Skip for now',
        style: theme.textTheme.labelMedium?.copyWith(
          color: colors.onSurface.withValues(alpha: 0.6),
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
