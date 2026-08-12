import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import 'profile_notifier.dart';

const _ageOptions = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
const _genderOptions = [
  _ChoiceOption(label: 'Boy', value: 'boy', icon: _ProfileIconType.boy),
  _ChoiceOption(label: 'Girl', value: 'girl', icon: _ProfileIconType.girl),
];
const _localeOptions = [
  _ChoiceOption(label: 'English', value: 'en-IN', icon: _ProfileIconType.en),
  _ChoiceOption(label: 'Hindi', value: 'hi-IN', icon: _ProfileIconType.hi),
];

const _glassColor = Color(0x2EFFFFFF);
const _selectedColor = Color(0xFFA8D8FB);
const _selectedTextColor = Color(0xFF16202C);
const _disabledTextColor = Color(0xFFA9BED6);
const _secondaryTextColor = Color(0xD9FFFFFF);
const _lightBorderColor = Color(0x8CFFFFFF);
const _buttonShadowColor = Color(0x2E000000);
const _surfaceShadowColor = Color(0x26000000);
const _glowColor = Color(0x40FFFFFF);
const _figmaWidth = 390.0;
const _ageChipSize = 52.0;
const _ageChipMinGap = 12.0;
const _childNameMinLength = 2;
const _childNameMaxLength = 50;

final _childNameRegex = RegExp(
  // Unicode letters with optional combining marks, separated by single
  // spaces, hyphens, straight apostrophes, or curly apostrophes.
  r"^(?:\p{L}\p{M}*)+(?:[ '\-’](?:\p{L}\p{M}*)+)*$",
  unicode: true,
);

String? _validateChildName(String? value) {
  final name = value?.trim() ?? '';

  if (name.isEmpty) {
    return 'Please enter your child\'s name';
  }

  if (name.length < _childNameMinLength || name.length > _childNameMaxLength) {
    return 'Name must be between 2 and 50 characters';
  }

  if (!_childNameRegex.hasMatch(name)) {
    return 'Please enter a valid name';
  }

  return null;
}

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

  bool get _isComplete =>
      _nameController.text.trim().isNotEmpty &&
      _selectedGender != null &&
      _selectedAge != null &&
      _selectedLocale != null;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController
      ..removeListener(_refresh)
      ..dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    if (_submissionLocked ||
        _isSubmitting ||
        !_isComplete ||
        !_formKey.currentState!.validate()) {
      return;
    }

    _submissionLocked = true;
    setState(() => _isSubmitting = true);

    try {
      final child = await ref
          .read(profileNotifierProvider.notifier)
          .addChild(
            name: _nameController.text.trim(),
            gender: _selectedGender!,
            age: _selectedAge!,
            locale: _selectedLocale!,
          );

      if (!mounted) return;
      if (widget.popOnSave) {
        Navigator.pop(context, child);
      }
    } catch (_) {
      _submissionLocked = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        _isSubmitting ||
        ref.watch(profileNotifierProvider.select((state) => state.isLoading));
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return MediaQuery.withNoTextScaling(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SizedBox.expand(
          child: AppScreenBackground(
            child: SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final scale = (constraints.maxWidth / _figmaWidth)
                      .clamp(0.88, 1.18)
                      .toDouble();
                  final horizontal = 19.0 * scale;

                  return Form(
                    key: _formKey,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(painter: _GlowPainter()),
                        ),
                        SingleChildScrollView(
                          physics: const ClampingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            38 * scale,
                            horizontal,
                            118 * scale + bottomInset,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _HeaderCopy(),
                              SizedBox(height: 32 * scale),
                              _ProfileForm(
                                nameController: _nameController,
                                nameFocusNode: _nameFocusNode,
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
                            ],
                          ),
                        ),
                        Positioned(
                          left: 16 * scale,
                          right: 16 * scale,
                          bottom: 38 * scale,
                          child: _StartButton(
                            enabled: _isComplete && !isSaving,
                            isSaving: isSaving,
                            onTap: _saveProfile,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderCopy extends StatelessWidget {
  const _HeaderCopy();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Tell us about your little one',
            maxLines: 1,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 24,
              height: 28 / 24,
              letterSpacing: -0.25,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 4),
        Text(
          'We personalise every story to fit.',
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: _secondaryTextColor,
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
    required this.selectedGender,
    required this.selectedAge,
    required this.selectedLocale,
    required this.onGenderChanged,
    required this.onAgeChanged,
    required this.onLocaleChanged,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final String? selectedGender;
  final int? selectedAge;
  final String? selectedLocale;
  final ValueChanged<String> onGenderChanged;
  final ValueChanged<int> onAgeChanged;
  final ValueChanged<String> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FormGroup(
          label: 'Child\'s Name',
          child: _NameField(
            controller: nameController,
            focusNode: nameFocusNode,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'Child\'s Gender',
          child: _ChoiceRow(
            options: _genderOptions,
            selectedValue: selectedGender,
            onChanged: onGenderChanged,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'Child\'s Age',
          child: _AgeSelector(
            selectedAge: selectedAge,
            onAgeChanged: onAgeChanged,
          ),
        ),
        const SizedBox(height: 24),
        _FormGroup(
          label: 'Story Language',
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
        Text(label, style: _ProfileSetupTextStyles.label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({required this.controller, required this.focusNode});

  final TextEditingController controller;
  final FocusNode focusNode;

  @override
  Widget build(BuildContext context) {
    return _GlassSurface(
      height: 52,
      child: TextFormField(
        key: const ValueKey('childNameField'),
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.done,
        cursorColor: Colors.white,
        style: _ProfileSetupTextStyles.input,
        decoration: const InputDecoration(
          hintText: 'Enter here',
          hintStyle: _ProfileSetupTextStyles.hint,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          filled: false,
          fillColor: Colors.transparent,
          focusColor: Colors.transparent,
          hoverColor: Colors.transparent,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          errorStyle: TextStyle(height: 0.01, fontSize: 0),
        ),
        validator: _validateChildName,
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
  final _ProfileIconType icon;
}

enum _ProfileIconType { boy, girl, en, hi }

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
        for (var index = 0; index < options.length; index += 1) ...[
          Expanded(
            child: _ChoiceButton(
              option: options[index],
              isSelected: options[index].value == selectedValue,
              onTap: () => onChanged(options[index].value),
            ),
          ),
          if (index != options.length - 1) const SizedBox(width: 33),
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
    final color = isSelected ? _selectedTextColor : Colors.white;

    return Semantics(
      button: true,
      selected: isSelected,
      label: option.label,
      child: GestureDetector(
        key: ValueKey(
          'choice${option.value}${isSelected ? 'Selected' : 'Unselected'}',
        ),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: _GlassSurface(
          height: 52,
          selected: isSelected,
          horizontalPadding: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              _ProfileOptionIcon(type: option.icon, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  option.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _ProfileSetupTextStyles.choice.copyWith(color: color),
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
      height: 60,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fullVisibleChipCount =
              ((constraints.maxWidth - _ageChipSize / 2 + _ageChipMinGap) /
                      (_ageChipSize + _ageChipMinGap))
                  .floor()
                  .clamp(1, _ageOptions.length - 1);
          final gap =
              ((constraints.maxWidth -
                          _ageChipSize / 2 -
                          fullVisibleChipCount * _ageChipSize) /
                      fullVisibleChipCount)
                  .clamp(_ageChipMinGap, double.infinity)
                  .toDouble();

          return ListView.separated(
            clipBehavior: Clip.hardEdge,
            scrollDirection: Axis.horizontal,
            physics: const ClampingScrollPhysics(),
            itemCount: _ageOptions.length,
            separatorBuilder: (context, index) => SizedBox(width: gap),
            itemBuilder: (context, index) {
              final age = _ageOptions[index];
              return Center(
                child: _AgeChip(
                  age: age,
                  isSelected: age == selectedAge,
                  onTap: () => onAgeChanged(age),
                ),
              );
            },
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
          width: _ageChipSize,
          height: _ageChipSize,
          padding: const EdgeInsets.all(12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? _selectedColor : _glassColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: _lightBorderColor,
              width: isSelected ? 1 : 0.8,
            ),
            boxShadow: [
              const BoxShadow(
                color: _surfaceShadowColor,
                offset: Offset(0, 2),
                blurRadius: 4,
              ),
              if (isSelected)
                const BoxShadow(
                  color: _glowColor,
                  blurRadius: 4,
                  spreadRadius: 2,
                ),
            ],
          ),
          child: Text(
            '$age',
            style: _ProfileSetupTextStyles.age.copyWith(
              color: isSelected ? _selectedTextColor : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassSurface extends StatelessWidget {
  const _GlassSurface({
    required this.child,
    required this.height,
    this.selected = false,
    this.horizontalPadding = 20,
  });

  final Widget child;
  final double height;
  final bool selected;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: double.infinity,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 12,
      ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: selected ? _selectedColor : _glassColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: selected ? _lightBorderColor : _lightBorderColor,
          width: selected ? 1 : 0.8,
        ),
        boxShadow: [
          const BoxShadow(
            color: _surfaceShadowColor,
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
          if (selected)
            const BoxShadow(color: _glowColor, blurRadius: 4, spreadRadius: 2),
        ],
      ),
      child: child,
    );
  }
}

class _StartButton extends StatelessWidget {
  const _StartButton({
    required this.enabled,
    required this.isSaving,
    required this.onTap,
  });

  final bool enabled;
  final bool isSaving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled ? onTap : null,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _glassColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _lightBorderColor, width: 0.8),
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
                  color: Colors.white,
                ),
              )
            : Text(
                'Start Storytime',
                style: _ProfileSetupTextStyles.button.copyWith(
                  color: enabled ? Colors.white : _disabledTextColor,
                ),
              ),
      ),
    );
  }
}

class _ProfileOptionIcon extends StatelessWidget {
  const _ProfileOptionIcon({required this.type, required this.color});

  final _ProfileIconType type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 24,
      child: CustomPaint(painter: _ProfileIconPainter(type, color)),
    );
  }
}

class _ProfileIconPainter extends CustomPainter {
  const _ProfileIconPainter(this.type, this.color);

  final _ProfileIconType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (type == _ProfileIconType.en || type == _ProfileIconType.hi) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(4, 4, size.width - 8, size.height - 8),
        const Radius.circular(2),
      );
      canvas.drawRRect(rect, stroke);
      final textPainter = TextPainter(
        text: TextSpan(
          text: type == _ProfileIconType.en ? 'En' : 'अ',
          style: TextStyle(
            color: color,
            fontFamily: AppTypography.fontFamily,
            fontSize: type == _ProfileIconType.en ? 9 : 13,
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
      return;
    }

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final rect = Rect.fromLTWH(4, 4, size.width - 8, size.height - 8);
    canvas.drawOval(rect, stroke);
    canvas.drawCircle(const Offset(9, 11), 1.1, fill);
    canvas.drawCircle(const Offset(15, 11), 1.1, fill);
    canvas.drawArc(Rect.fromLTWH(9, 13, 6, 4), 0.1, 2.95, false, stroke);

    if (type == _ProfileIconType.girl) {
      final hair = Path()
        ..moveTo(6.5, 8)
        ..quadraticBezierTo(12, 3, 17.5, 8);
      canvas.drawPath(hair, stroke);
    } else {
      final hair = Path()
        ..moveTo(6.5, 8)
        ..quadraticBezierTo(10, 4.5, 14, 5)
        ..quadraticBezierTo(16.5, 5.4, 18, 8);
      canvas.drawPath(hair, stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _ProfileIconPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}

class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.18),
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: Offset(size.width * 0.05, size.height * 0.12),
              radius: size.width * 0.85,
            ),
          );
    canvas.drawCircle(
      Offset(size.width * 0.05, size.height * 0.12),
      size.width * 0.85,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

abstract final class _ProfileSetupTextStyles {
  static const label = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: Colors.white,
  );

  static const hint = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    color: _secondaryTextColor,
  );

  static const input = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w700,
    color: _secondaryTextColor,
  );

  static const choice = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
  );

  static const age = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w600,
  );

  static const button = TextStyle(
    fontFamily: AppTypography.fontFamily,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
  );
}
