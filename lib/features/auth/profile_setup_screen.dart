import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'assets_provider.dart';
import 'companion_flow.dart';
import 'companion_notifier.dart';
import 'onboarding_progress_header.dart';
import 'profile_notifier.dart';
import 'profile_repository.dart';

const _ageOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9];
const _genderOptions = [
  _ChoiceOption(label: 'Boy', value: 'boy', icon: _ChildIconType.boy),
  _ChoiceOption(label: 'Girl', value: 'girl', icon: _ChildIconType.girl),
];
const _localeOptions = [
  _ChoiceOption(label: 'English', value: 'en-IN', icon: _ChildIconType.boy),
  _ChoiceOption(label: 'Hindi', value: 'hi-IN', icon: _ChildIconType.girl),
];

const _backgroundColor = Color(0xFFF5FAFF);
const _titleColor = Color(0xFF29609B);
const _bodyColor = Color(0xFF667085);
const _choiceTextColor = Color(0xFF475467);
const _fieldHintColor = Color(0xFF98A2B3);
const _fieldBorderColor = Color(0xFFE4E7EC);
const _ageBorderColor = Color(0xFFD0D5DD);
const _activeBorderColor = Color(0xFF99E1FA);
const _iconBlue = Color(0xFF00AEEF);
const _buttonBorderColor = Color(0xFF009DD7);
const _buttonShadowColor = Color(0xFF0082B2);
const _activeGlowColor = Color(0xFFC2EEFC);
const _figmaFrameWidth = 390.0;
const _figmaHorizontalInset = 20.0;

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key, this.popOnSave = false});

  final bool popOnSave;

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nameFocusNode = FocusNode();

  int? _selectedAge;
  String? _selectedGender;
  String? _selectedLocale;
  bool _isSubmitting = false;
  bool _submissionLocked = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refreshNameState);
    _nameFocusNode.addListener(_refreshNameState);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refreshNameState)
      ..dispose();
    _nameFocusNode
      ..removeListener(_refreshNameState)
      ..dispose();
    super.dispose();
  }

  void _refreshNameState() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (_submissionLocked ||
        _isSubmitting ||
        !_formKey.currentState!.validate()) {
      return;
    }

    _submissionLocked = true;
    setState(() => _isSubmitting = true);
    if (!widget.popOnSave) {
      ref.read(companionSelectionPendingProvider.notifier).state = true;
    }

    try {
      final child = await ref
          .read(profileNotifierProvider.notifier)
          .addChild(
            name: _nameController.text.trim(),
            gender: _selectedGender ?? 'boy',
            age: _selectedAge ?? 2,
            companionId: ref.read(companionNotifierProvider)?.id,
            locale: _selectedLocale ?? defaultProfileLocale,
          );

      if (widget.popOnSave) {
        if (!mounted) return;
        Navigator.pop(context, child);
        return;
      }
    } catch (error) {
      _submissionLocked = false;
      if (!mounted) return;

      if (!widget.popOnSave) {
        ref.read(companionSelectionPendingProvider.notifier).state = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not save profile. Please check your connection and try again.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _skipProfile() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        _isSubmitting ||
        ref.watch(profileNotifierProvider.select((state) => state.isLoading));
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = 18.0 + bottomInset;
            final horizontalPadding =
                constraints.maxWidth *
                (_figmaHorizontalInset / _figmaFrameWidth);
            final minHeight = (constraints.maxHeight - bottomPadding)
                .clamp(0.0, double.infinity)
                .toDouble();

            return Form(
              key: _formKey,
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: EdgeInsets.only(bottom: bottomPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Column(
                    children: [
                      OnboardingProgressHeader(
                        activeStep: 0,
                        onBack: () => Navigator.pop(context),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroSection(),
                            const SizedBox(height: 32),
                            _ProfileForm(
                              nameController: _nameController,
                              nameFocusNode: _nameFocusNode,
                              isNameActive:
                                  _nameFocusNode.hasFocus ||
                                  _nameController.text.trim().isNotEmpty,
                              selectedGender: _selectedGender,
                              selectedAge: _selectedAge,
                              selectedLocale: _selectedLocale,
                              onGenderChanged: (gender) =>
                                  setState(() => _selectedGender = gender),
                              onAgeChanged: (age) =>
                                  setState(() => _selectedAge = age),
                              onLocaleChanged: (locale) =>
                                  setState(() => _selectedLocale = locale),
                            ),
                            const SizedBox(height: 32),
                            _FooterActions(
                              isSaving: isSaving,
                              onContinue: isSaving ? null : _saveProfile,
                              onSkip: _skipProfile,
                            ),
                          ],
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
    );
  }
}

class _ChoiceOption {
  const _ChoiceOption({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final _ChildIconType icon;
}

enum _ChildIconType { boy, girl }

class _HeroSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          width: 108,
          height: 108,
          child: ClipOval(
            child: Image(
              image: AssetImage(profileSetupIconAsset),
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Add child Profile',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: _titleColor,
            fontSize: 28,
            height: 32 / 28,
            fontWeight: FontWeight.w700,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'We use this to personalise experience',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _bodyColor,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }
}

class _ProfileForm extends StatelessWidget {
  const _ProfileForm({
    required this.nameController,
    required this.nameFocusNode,
    required this.isNameActive,
    required this.selectedGender,
    required this.selectedAge,
    required this.selectedLocale,
    required this.onGenderChanged,
    required this.onAgeChanged,
    required this.onLocaleChanged,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final bool isNameActive;
  final String? selectedGender;
  final int? selectedAge;
  final String? selectedLocale;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _FormGroup(
          label: 'Child’s name',
          child: _NameField(
            controller: nameController,
            focusNode: nameFocusNode,
            isActive: isNameActive,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'Child’s gender',
          child: _ChoiceRow(
            options: _genderOptions,
            selectedValue: selectedGender,
            onChanged: onGenderChanged,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'How old are they?',
          child: _AgeSelector(
            selectedAge: selectedAge,
            onAgeChanged: onAgeChanged,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'Preferred story language',
          child: _ChoiceRow(
            options: _localeOptions,
            selectedValue: selectedLocale,
            onChanged: onLocaleChanged,
          ),
        ),
      ],
    );
  }
}

class _FormGroup extends StatelessWidget {
  const _FormGroup({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: _bodyColor,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            letterSpacing: 0,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.focusNode,
    required this.isActive,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _ActiveSurface(
      isActive: isActive,
      child: TextFormField(
        key: const ValueKey('childNameField'),
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        cursorColor: _iconBlue,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: _choiceTextColor,
          fontSize: 14,
          height: 20 / 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
        ),
        decoration: InputDecoration(
          hintText: 'Enter here',
          hintStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: _fieldHintColor,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          filled: false,
          errorStyle: const TextStyle(height: 0.01, fontSize: 0),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Enter here';
          }

          return null;
        },
      ),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.options,
    required this.selectedValue,
    required this.onChanged,
  });

  final List<_ChoiceOption> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var index = 0; index < options.length; index++) ...[
          Expanded(
            child: _ChoiceButton(
              option: options[index],
              isSelected: options[index].value == selectedValue,
              onTap: () => onChanged(options[index].value),
            ),
          ),
          if (index != options.length - 1) const SizedBox(width: 24),
        ],
      ],
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _ChoiceOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: GestureDetector(
        key: ValueKey(
          'choice${option.value}${isSelected ? 'Selected' : 'Unselected'}',
        ),
        onTap: onTap,
        child: _ActiveSurface(
          isActive: isSelected,
          horizontalPadding: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ChildFaceIcon(type: option.icon),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: _choiceTextColor,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AgeSelector extends StatelessWidget {
  const _AgeSelector({required this.selectedAge, required this.onAgeChanged});

  final int? selectedAge;
  final ValueChanged<int> onAgeChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        itemCount: _ageOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final age = _ageOptions[index];
          return _AgeChip(
            age: age,
            isSelected: age == selectedAge,
            onTap: () => onAgeChanged(age),
          );
        },
      ),
    );
  }
}

class _AgeChip extends StatelessWidget {
  const _AgeChip({
    required this.age,
    required this.isSelected,
    required this.onTap,
  });

  final int age;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$age',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          key: ValueKey('ageChip$age${isSelected ? 'Selected' : ''}'),
          duration: const Duration(milliseconds: 160),
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: _surfaceDecoration(
            isActive: isSelected,
            borderColor: isSelected ? _activeBorderColor : _ageBorderColor,
            radius: 32,
          ),
          child: Text(
            '$age',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: _choiceTextColor,
              fontSize: 16,
              height: 20 / 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}

class _ActiveSurface extends StatelessWidget {
  const _ActiveSurface({
    required this.isActive,
    required this.child,
    this.horizontalPadding = 20,
  });

  final bool isActive;
  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      key: ValueKey('activeSurface$isActive'),
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      height: 52,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      alignment: Alignment.center,
      decoration: _surfaceDecoration(
        isActive: isActive,
        borderColor: isActive ? _activeBorderColor : _fieldBorderColor,
        radius: 24,
      ),
      child: child,
    );
  }
}

BoxDecoration _surfaceDecoration({
  required bool isActive,
  required Color borderColor,
  required double radius,
}) {
  return BoxDecoration(
    color: _backgroundColor,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: borderColor),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        offset: const Offset(0, 2),
        blurRadius: 4,
      ),
      if (isActive)
        const BoxShadow(
          color: _activeGlowColor,
          offset: Offset.zero,
          blurRadius: 12,
          spreadRadius: 2,
        ),
    ],
  );
}

class _ChildFaceIcon extends StatelessWidget {
  const _ChildFaceIcon({required this.type});

  final _ChildIconType type;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(painter: _ChildFacePainter(type)),
    );
  }
}

class _ChildFacePainter extends CustomPainter {
  const _ChildFacePainter(this.type);

  final _ChildIconType type;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = _iconBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()
      ..color = _iconBlue
      ..style = PaintingStyle.fill;

    final rect = Rect.fromLTWH(3, 3, size.width - 6, size.height - 6);
    canvas.drawOval(rect, stroke);
    canvas.drawCircle(const Offset(8.5, 10), 1.1, fill);
    canvas.drawCircle(const Offset(15.5, 10), 1.1, fill);
    canvas.drawLine(const Offset(9, 16), const Offset(15, 16), stroke);

    if (type == _ChildIconType.girl) {
      final hair = Path()
        ..moveTo(6.2, 7.5)
        ..quadraticBezierTo(12, 1.5, 17.8, 7.5);
      canvas.drawPath(hair, stroke);
      canvas.drawLine(const Offset(5.5, 6), const Offset(3.8, 10), stroke);
      canvas.drawLine(const Offset(18.5, 6), const Offset(20.2, 10), stroke);
    } else {
      canvas.drawArc(Rect.fromLTWH(6, 4, 12, 7), 3.45, 2.55, false, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ChildFacePainter oldDelegate) {
    return oldDelegate.type != type;
  }
}

class _FooterActions extends StatelessWidget {
  const _FooterActions({
    required this.isSaving,
    required this.onContinue,
    required this.onSkip,
  });

  final bool isSaving;
  final VoidCallback? onContinue;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ContinueButton(isSaving: isSaving, onTap: onContinue),
        const SizedBox(height: 8),
        _SkipButton(onTap: onSkip),
      ],
    );
  }
}

class _ContinueButton extends StatelessWidget {
  const _ContinueButton({required this.isSaving, required this.onTap});

  final bool isSaving;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _iconBlue,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _buttonBorderColor),
          boxShadow: const [
            BoxShadow(
              color: _buttonShadowColor,
              offset: Offset(0, 2),
              blurRadius: 4,
            ),
          ],
        ),
        child: isSaving
            ? const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                'Continue',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Colors.white,
                  fontSize: 16,
                  height: 20 / 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
      ),
    );
  }
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Center(
          child: Text(
            'Skip for now',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: _bodyColor,
              fontSize: 16,
              height: 20 / 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0,
            ),
          ),
        ),
      ),
    );
  }
}
