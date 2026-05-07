import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/widgets/pill_button.dart';
import 'profile_notifier.dart';

const _companionOptions = [
  'Baby Krishna',
  'Baby Hanuman',
  'Baby Ganesha',
  'Baby Shiva',
];
const _ageOptions = [1, 2, 3, 4];
const _defaultCompanionLabel = 'Companion';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  int _selectedAge = 2;
  String _selectedCharacter = _defaultCompanionLabel;

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
      await ref.read(profileNotifierProvider.notifier).saveProfile(
        name: _nameController.text.trim(),
        age: _selectedAge,
        character: _selectedCharacter,
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
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _companionOptions.map((companion) {
                return ListTile(
                  title: Text(companion),
                  textColor: colors.onSurface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(16)),
                  ),
                  onTap: () {
                    setState(() => _selectedCharacter = companion);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  void _skipProfile() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final cacheWidth = MediaQuery.of(context).size.width.toInt();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          RepaintBoundary(
            child: Stack(
              children: [
                SizedBox.expand(
                  child: Image.asset(
                    'assets/images/profileSetup_bg.jpg',
                    fit: BoxFit.cover,
                    cacheWidth: cacheWidth,
                  ),
                ),
                Container(color: colors.surface.withValues(alpha: 0.44)),
                Container(
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
                ),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Form(
                key: _formKey,
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
                      text: 'How old are they?',
                      theme: theme,
                      colors: colors,
                    ),
                    const SizedBox(height: 12),
                    _AgeSelector(
                      selectedAge: _selectedAge,
                      onAgeChanged: (age) => setState(() => _selectedAge = age),
                    ),
                    const SizedBox(height: 40),
                    _CompanionButton(
                      label: _selectedCharacter == _defaultCompanionLabel
                          ? 'Choose Companion'
                          : _selectedCharacter,
                      onTap: _chooseCompanion,
                      colors: colors,
                      theme: theme,
                    ),
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

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({
    required this.selectedAge,
    required this.onAgeChanged,
  });

  final int selectedAge;
  final ValueChanged<int> onAgeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: _ageOptions.map((age) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _AgeButton(
            age: age,
            isSelected: age == selectedAge,
            onTap: () => onAgeChanged(age),
            colors: colors,
            theme: theme,
          ),
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
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colors.onSurface,
              fontWeight: FontWeight.w700,
              fontSize: 13,
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
