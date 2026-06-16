import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_border_radius.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_shadows.dart';
import '../../shared/widgets/pill_button.dart';
import 'assets_provider.dart';
import 'profile_setup_screen.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();

  bool _isNavigating = false;
  bool _hasAttemptedValidation = false;

  @override
  void dispose() {
    _mobileNumberController.dispose();
    super.dispose();
  }

  Future<void> _openProfileSetup() async {
    if (_isNavigating) {
      return;
    }

    _isNavigating = true;
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfileSetupScreen()),
      );
    } finally {
      _isNavigating = false;
    }
  }

  Future<void> _continueWithMobileNumber() async {
    if (_isNavigating) {
      return;
    }

    setState(() => _hasAttemptedValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _openProfileSetup();
  }

  void _handleMobileNumberChanged(String value) {
    if (value.isEmpty && _hasAttemptedValidation) {
      setState(() => _hasAttemptedValidation = false);
      _formKey.currentState?.validate();
    }
  }

  String? _validateMobileNumber(String? value) {
    if (!_hasAttemptedValidation) {
      return null;
    }

    final mobileNumber = value?.trim() ?? '';
    if (mobileNumber.isEmpty) {
      return 'Please enter your mobile number.';
    }
    if (mobileNumber.length != 10) {
      return 'Please enter a valid 10-digit mobile number.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
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
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0, 0.45, 0.72, 1],
                      colors: [
                        Color(0x80101646),
                        Color(0x66131D54),
                        Color(0xB30B1238),
                        Color(0xE6080D25),
                      ],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
              ],
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                final bottomPadding = 30.0 + bottomInset;
                final minContentHeight = (constraints.maxHeight - bottomPadding)
                    .clamp(0.0, double.infinity)
                    .toDouble();
                final formWidth = (MediaQuery.sizeOf(context).width * 0.8)
                    .clamp(0.0, 420.0)
                    .toDouble();

                return Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(24, 0, 24, bottomPadding),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: minContentHeight),
                      child: IntrinsicHeight(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                "Welcome to\nBedtime Stories",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 36,
                                  height: 1.12,
                                  letterSpacing: -0.7,
                                  color: colors.onSurface,
                                  shadows: [
                                    Shadow(
                                      color: colors.primary.withValues(
                                        alpha: 0.24,
                                      ),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                "Step into a world of gentle tales \nand quiet nights. Your journey to restful \nsleep starts here.",
                                textAlign: TextAlign.center,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onSurface.withValues(
                                    alpha: 0.7,
                                  ),
                                  height: 1.55,
                                ),
                              ),
                              const SizedBox(height: 120),
                              SizedBox(
                                width: formWidth,
                                child: Semantics(
                                  textField: true,
                                  label: 'Mobile number',
                                  child: _GlassMobileNumberField(
                                    controller: _mobileNumberController,
                                    onChanged: _handleMobileNumberChanged,
                                    onSubmitted: _continueWithMobileNumber,
                                    validator: _validateMobileNumber,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              SizedBox(
                                width: formWidth,
                                child: Semantics(
                                  button: true,
                                  label: 'Continue with mobile number',
                                  child: PillButton(
                                    key: const Key('mobile-continue-button'),
                                    onTap: _isNavigating
                                        ? null
                                        : _continueWithMobileNumber,
                                    height: 58,
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.accentPrimarySoft,
                                        AppColors.accentSecondary,
                                      ],
                                    ),
                                    boxShadow: [
                                      ...AppShadows.glow(
                                        AppColors.accentPrimaryLight,
                                        opacity: 0.38,
                                        blurRadius: 28,
                                        spreadRadius: 1,
                                      ),
                                      BoxShadow(
                                        color: colors.shadow.withValues(
                                          alpha: 0.28,
                                        ),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                    child: Text(
                                      'Continue',
                                      style: theme.textTheme.labelLarge
                                          ?.copyWith(
                                            color: AppColors.textOnAccent,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.1,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 50),
                              GestureDetector(
                                onTap: _openProfileSetup,
                                behavior: HitTestBehavior.opaque,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                  child: Text(
                                    "Browse as Guest →",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: colors.onSurface.withValues(
                                        alpha: 0.75,
                                      ),
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.15,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _GlassMobileNumberField extends StatelessWidget {
  const _GlassMobileNumberField({
    required this.controller,
    required this.onChanged,
    required this.onSubmitted,
    required this.validator,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 62,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppBorderRadius.radiusButton),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentPrimaryLight.withValues(alpha: 0.12),
                  blurRadius: 18,
                  spreadRadius: -2,
                ),
                const BoxShadow(
                  color: AppColors.surfaceWhite05,
                  blurRadius: 8,
                  spreadRadius: -3,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppBorderRadius.radiusButton),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCardDeep.withValues(alpha: 0.56),
                    borderRadius: BorderRadius.circular(
                      AppBorderRadius.radiusButton,
                    ),
                    border: Border.all(color: AppColors.surfaceWhite18),
                  ),
                ),
              ),
            ),
          ),
        ),
        TextFormField(
          key: const Key('mobile-number-field'),
          controller: controller,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onChanged: onChanged,
          autofillHints: const [AutofillHints.telephoneNumber],
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(10),
          ],
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colors.onSurface,
            fontSize: 15,
            letterSpacing: 0.2,
          ),
          cursorColor: AppColors.accentPrimaryLight,
          decoration: InputDecoration(
            hintText: 'Enter your mobile number',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurface.withValues(alpha: 0.62),
              fontSize: 14,
              letterSpacing: 0.05,
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 78,
              minHeight: 62,
            ),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: 22),
                const Icon(
                  Icons.phone_outlined,
                  color: AppColors.accentPrimaryLight,
                  size: 23,
                ),
                const SizedBox(width: 18),
                Container(
                  width: 1,
                  height: 30,
                  color: AppColors.surfaceWhite18,
                ),
                const SizedBox(width: 17),
              ],
            ),
            filled: false,
            contentPadding: const EdgeInsets.fromLTRB(0, 19, 18, 19),
            border: _fieldBorder(AppColors.transparent),
            enabledBorder: _fieldBorder(AppColors.transparent),
            focusedBorder: _fieldBorder(
              AppColors.accentPrimaryLight.withValues(alpha: 0.82),
              width: 1.4,
            ),
            errorBorder: _fieldBorder(colors.error),
            focusedErrorBorder: _fieldBorder(colors.error, width: 1.4),
            errorStyle: theme.textTheme.bodySmall?.copyWith(
              color: colors.error,
              fontSize: 12,
              height: 1.35,
            ),
            errorMaxLines: 2,
            errorText: null,
          ),
          validator: validator,
          onFieldSubmitted: (_) => onSubmitted(),
        ),
      ],
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppBorderRadius.radiusButton),
      borderSide: BorderSide(color: color, width: width),
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
