import 'package:flutter/material.dart';

import '../../shared/widgets/pill_button.dart';
import 'profile_repository.dart';

const _companionOptions = ['Luna', 'Nova', 'Milo', 'Stella'];
const _ageOptions = [1, 2, 3, 4];
const _defaultCompanionLabel = 'Companion';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _repository = const ProfileRepository();

  int _selectedAge = 2;
  String _selectedCharacter = _defaultCompanionLabel;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      await _repository.saveProfile(
        name: _nameController.text.trim(),
        age: _selectedAge,
        character: _selectedCharacter,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved')));
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save profile: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          SizedBox.expand(
            child: Image.asset(
              'assets/images/profileSetup_bg.jpg',
              fit: BoxFit.cover,
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopBar(context),
                    const SizedBox(height: 42),
                    _buildBookBadge(context),
                    const SizedBox(height: 22),
                    _buildTitle(context),
                    const SizedBox(height: 12),
                    _buildSubtitle(context),
                    const SizedBox(height: 32),
                    _buildFieldLabel(context, "Child's name"),
                    const SizedBox(height: 8),
                    _buildNameField(context),
                    const SizedBox(height: 28),
                    _buildFieldLabel(context, 'How old are they?'),
                    const SizedBox(height: 12),
                    _buildAgeSelector(context),
                    const SizedBox(height: 40),
                    _buildCompanionButton(context),
                    const Spacer(),
                    _buildCreateProfileButton(context),
                    const SizedBox(height: 16),
                    _buildSkipButton(context),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Row(
      children: [
        SizedBox.square(
          dimension: 34,
          child: IconButton(
            onPressed: () => Navigator.pop(context),
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

  Widget _buildBookBadge(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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

  Widget _buildSubtitle(BuildContext context) {
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

  Widget _buildFieldLabel(BuildContext context, String text) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: colors.onSurface.withValues(alpha: 0.72),
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );
  }

  Widget _buildNameField(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final emptyBorder = _fieldBorder();

    return TextFormField(
      controller: _nameController,
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
        border: emptyBorder,
        enabledBorder: emptyBorder,
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

  OutlineInputBorder _fieldBorder([Color? color]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: color == null ? BorderSide.none : BorderSide(color: color),
    );
  }

  Widget _buildAgeSelector(BuildContext context) {
    return Row(
      children: _ageOptions.map((age) {
        return Padding(
          padding: const EdgeInsets.only(right: 16),
          child: _buildAgeButton(context, age),
        );
      }).toList(),
    );
  }

  Widget _buildAgeButton(BuildContext context, int age) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isSelected = age == _selectedAge;

    return GestureDetector(
      onTap: () => setState(() => _selectedAge = age),
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

  Widget _buildCompanionButton(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final label = _selectedCharacter == _defaultCompanionLabel
        ? 'Choose Companion'
        : _selectedCharacter;

    return PillButton(
      onTap: _chooseCompanion,
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

  Widget _buildCreateProfileButton(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PillButton(
      onTap: _isSaving ? null : _saveProfile,
      gradient: _isSaving
          ? null
          : LinearGradient(colors: [colors.primary, colors.secondary]),
      color: _isSaving ? colors.surface.withValues(alpha: 0.78) : null,
      child: _isSaving
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

  Widget _buildSkipButton(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return PillButton(
      onTap: _skipProfile,
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
