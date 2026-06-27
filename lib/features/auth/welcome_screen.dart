import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/theme/app_typography.dart';
import 'assets_provider.dart';
import 'auth_provider.dart';

enum _WelcomeAuthStep { mobileNumber, otp }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final _mobileNumberFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _isNavigating = false;
  bool _hasAuthenticated = false;
  bool _hasAttemptedValidation = false;
  bool _isMobileNumberFocused = false;
  bool _isOtpFocused = false;
  bool _isKeyboardDismissed = false;
  _WelcomeAuthStep _authStep = _WelcomeAuthStep.mobileNumber;
  String _otpValue = '';
  String _sentMobileNumber = '';

  static const _transitionDuration = Duration(milliseconds: 280);
  static const _transitionCurve = Curves.easeOutCubic;

  @override
  void initState() {
    super.initState();
    _mobileNumberFocusNode.addListener(_handleMobileNumberFocusChanged);
    _otpFocusNode.addListener(_handleOtpFocusChanged);
  }

  @override
  void dispose() {
    _mobileNumberFocusNode.removeListener(_handleMobileNumberFocusChanged);
    _otpFocusNode.removeListener(_handleOtpFocusChanged);
    _otpFocusNode.dispose();
    _mobileNumberFocusNode.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }

  void _handleMobileNumberFocusChanged() {
    if (_isMobileNumberFocused == _mobileNumberFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _isMobileNumberFocused = _mobileNumberFocusNode.hasFocus;
      if (_mobileNumberFocusNode.hasFocus) {
        _isKeyboardDismissed = false;
      }
    });
  }

  void _handleOtpFocusChanged() {
    if (_isOtpFocused == _otpFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _isOtpFocused = _otpFocusNode.hasFocus;
      if (_otpFocusNode.hasFocus) {
        _isKeyboardDismissed = false;
      }
    });
  }

  bool get _isMobileNumberValid => _mobileNumberController.text.length == 10;

  bool get _shouldShowMobileNumberError {
    final mobileNumber = _mobileNumberController.text;
    if (mobileNumber.isEmpty) {
      return _hasAttemptedValidation;
    }
    return mobileNumber.length != 10;
  }

  bool get _isOtpComplete => _otpValue.length == 6;

  Future<void> _continueWithMobileNumber() async {
    if (_isNavigating || _authStep != _WelcomeAuthStep.mobileNumber) {
      return;
    }

    setState(() => _hasAttemptedValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    await _sendOtpMock();
  }

  Future<void> _sendOtpMock() async {
    // TODO: Replace this placeholder with real OTP generation and delivery.
    setState(() {
      _sentMobileNumber = _mobileNumberController.text;
      _otpValue = '';
      _authStep = _WelcomeAuthStep.otp;
    });
    _mobileNumberFocusNode.unfocus();
    _otpFocusNode.requestFocus();
  }

  Future<void> _submitOtpMock() async {
    if (_isNavigating || _hasAuthenticated || !_isOtpComplete) {
      return;
    }

    setState(() => _isNavigating = true);
    try {
      // TODO: Replace anonymous authentication with real OTP verification.
      // AppSessionGate owns the transition to profile setup after auth changes.
      await ref.read(appAuthServiceProvider).ensureAnonymousSession();
      _hasAuthenticated = true;
    } catch (_) {
      _hasAuthenticated = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not start your session. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  void _appendKeyboardValue(String value) {
    if (_authStep == _WelcomeAuthStep.otp) {
      _appendOtpValue(value);
      return;
    }

    if (_mobileNumberController.text.length >= 10) {
      return;
    }

    final text = _mobileNumberController.text;
    _mobileNumberController.value = TextEditingValue(
      text: '$text$value',
      selection: TextSelection.collapsed(offset: text.length + value.length),
    );
    _handleMobileNumberChanged(_mobileNumberController.text);
  }

  void _appendOtpValue(String value) {
    if (_otpValue.length >= 6) {
      return;
    }

    setState(() {
      _otpValue = '$_otpValue$value';
    });
  }

  void _deleteKeyboardValue() {
    if (_authStep == _WelcomeAuthStep.otp) {
      _deleteOtpValue();
      return;
    }

    final text = _mobileNumberController.text;
    if (text.isEmpty) {
      return;
    }

    _mobileNumberController.value = TextEditingValue(
      text: text.substring(0, text.length - 1),
      selection: TextSelection.collapsed(offset: text.length - 1),
    );
    _handleMobileNumberChanged(_mobileNumberController.text);
  }

  void _deleteOtpValue() {
    if (_otpValue.isEmpty) {
      return;
    }

    setState(() {
      _otpValue = _otpValue.substring(0, _otpValue.length - 1);
    });
  }

  void _hideKeyboardView() {
    setState(() => _isKeyboardDismissed = true);
    FocusScope.of(context).unfocus();
  }

  void _showOtpKeyboard() {
    setState(() => _isKeyboardDismissed = false);
    _otpFocusNode.requestFocus();
  }

  void _handleMobileNumberChanged(String value) {
    setState(() {
      if (value.isEmpty && _hasAttemptedValidation) {
        _hasAttemptedValidation = false;
      }
    });
    _formKey.currentState?.validate();
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

  void _editMobileNumber() {
    setState(() {
      _authStep = _WelcomeAuthStep.mobileNumber;
      _otpValue = '';
      _hasAttemptedValidation = false;
      _isKeyboardDismissed = false;
    });
    _otpFocusNode.unfocus();
    _mobileNumberFocusNode.requestFocus();
  }

  Future<void> _handleKeyboardDone() async {
    if (_authStep == _WelcomeAuthStep.otp) {
      await _submitOtpMock();
    } else {
      await _continueWithMobileNumber();
    }
  }

  @override
  Widget build(BuildContext context) {
    final appAssets = ref.watch(appAssetsProvider);
    final backgroundUrl = appAssets['welcome_bg(1)'] ?? appAssets['welcome_bg'];
    final coverUrl = appAssets['welcome_cover'];
    final otpBackgroundUrl = appAssets['welcome_otp_bg'] ?? backgroundUrl;
    final otpCoverUrl = appAssets['welcome_otp_cover'] ?? coverUrl;
    final screenSize = MediaQuery.sizeOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    final shouldPreviewKeyboardView =
        !_isKeyboardDismissed &&
        (_isMobileNumberFocused ||
            _isOtpFocused ||
            _authStep == _WelcomeAuthStep.otp) &&
        screenSize.width <= 600;
    final isKeyboardView = keyboardInset > 0 || shouldPreviewKeyboardView;
    final activeBackgroundUrl = isKeyboardView
        ? otpBackgroundUrl
        : backgroundUrl;
    final activeCoverUrl = isKeyboardView ? otpCoverUrl : coverUrl;
    final showOtpStep = _authStep == _WelcomeAuthStep.otp;
    final otpContentTop = isKeyboardView ? 135.0 : 91.0;

    return PopScope(
      canPop: !isKeyboardView,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && isKeyboardView) {
          _hideKeyboardView();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5FAFF),
        resizeToAvoidBottomInset: false,
        body: Form(
          key: _formKey,
          child: Stack(
            children: [
              if (activeBackgroundUrl != null)
                AnimatedPositioned(
                  duration: _transitionDuration,
                  curve: _transitionCurve,
                  left: 0,
                  right: 0,
                  top: isKeyboardView ? -88 : 0,
                  height: screenSize.height,
                  child: _NetworkImageLayer(
                    imageUrl: activeBackgroundUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              _WelcomeBottomPanel(
                coverUrl: activeCoverUrl,
                isKeyboardView: isKeyboardView,
                duration: _transitionDuration,
                curve: _transitionCurve,
                child: Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    if (!isKeyboardView || showOtpStep)
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: showOtpStep
                            ? otpContentTop
                            : isKeyboardView
                            ? 135
                            : 91,
                        width: showOtpStep
                            ? 233
                            : isKeyboardView
                            ? 299
                            : null,
                        child: showOtpStep
                            ? const _OtpCopy()
                            : const _WelcomeCopy(),
                      ),
                    if (showOtpStep) ...[
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: otpContentTop + 35,
                        width: isKeyboardView ? 350 : 343,
                        child: _OtpSentLabel(
                          mobileNumber: _sentMobileNumber,
                          onEdit: _editMobileNumber,
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: otpContentTop + 99,
                        width: isKeyboardView ? 350 : 343,
                        child: GestureDetector(
                          key: const Key('otp-code-boxes-tap-target'),
                          onTap: _showOtpKeyboard,
                          behavior: HitTestBehavior.opaque,
                          child: Focus(
                            focusNode: _otpFocusNode,
                            child: Semantics(
                              textField: true,
                              label: 'OTP',
                              value: _otpValue,
                              onTap: _showOtpKeyboard,
                              child: _OtpCodeBoxes(value: _otpValue),
                            ),
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: otpContentTop + 175,
                        width: isKeyboardView ? 350 : 343,
                        child: Semantics(
                          button: true,
                          label: 'Submit',
                          child: _FigmaPrimaryButton(
                            key: const Key('otp-submit-button'),
                            label: 'Submit',
                            onTap:
                                _isOtpComplete &&
                                    !_isNavigating &&
                                    !_hasAuthenticated
                                ? _submitOtpMock
                                : null,
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: otpContentTop + 239,
                        width: isKeyboardView ? 350 : 343,
                        child: const _ResendOtpButton(),
                      ),
                    ] else if (isKeyboardView) ...[
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: 135,
                        width: 350,
                        child: _MobileKeyboardContent(
                          controller: _mobileNumberController,
                          focusNode: _mobileNumberFocusNode,
                          onChanged: _handleMobileNumberChanged,
                          onSubmitted: _continueWithMobileNumber,
                          validator: _validateMobileNumber,
                          showError: _shouldShowMobileNumberError,
                          isValid: _isMobileNumberValid,
                          isNavigating: _isNavigating,
                          onSendOtp: _continueWithMobileNumber,
                          onFieldTap: () {
                            if (_isKeyboardDismissed) {
                              setState(() => _isKeyboardDismissed = false);
                            }
                          },
                        ),
                      ),
                    ] else ...[
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: isKeyboardView ? 298 : 227,
                        width: isKeyboardView ? 350 : 343,
                        child: Semantics(
                          textField: true,
                          label: 'Mobile number',
                          child: _FigmaMobileNumberField(
                            controller: _mobileNumberController,
                            focusNode: _mobileNumberFocusNode,
                            onChanged: _handleMobileNumberChanged,
                            onSubmitted: _continueWithMobileNumber,
                            validator: _validateMobileNumber,
                            isKeyboardView: isKeyboardView,
                            showError: _shouldShowMobileNumberError,
                            onTap: () {
                              if (_isKeyboardDismissed) {
                                setState(() => _isKeyboardDismissed = false);
                              }
                            },
                          ),
                        ),
                      ),
                      AnimatedPositioned(
                        duration: _transitionDuration,
                        curve: _transitionCurve,
                        top: isKeyboardView ? 378 : 307,
                        width: isKeyboardView ? 350 : 343,
                        child: Semantics(
                          button: true,
                          label: 'Send Otp',
                          child: _FigmaPrimaryButton(
                            key: const Key('mobile-continue-button'),
                            label: isKeyboardView ? 'Send OTP' : 'Send Otp',
                            onTap: _isMobileNumberValid && !_isNavigating
                                ? _continueWithMobileNumber
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isKeyboardView)
                _FigmaNumericKeyboard(
                  onDigit: _appendKeyboardValue,
                  onBackspace: _deleteKeyboardValue,
                  onDone: _handleKeyboardDone,
                  onDismiss: _hideKeyboardView,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBottomPanel extends StatelessWidget {
  const _WelcomeBottomPanel({
    required this.coverUrl,
    required this.isKeyboardView,
    required this.duration,
    required this.curve,
    required this.child,
  });

  final String? coverUrl;
  final bool isKeyboardView;
  final Duration duration;
  final Curve curve;
  final Widget child;

  static const _panelHeight = 453.0;
  static const _coverLeft = -14.82;
  static const _coverWidth = 451.29;
  static const _coverHeight = 466.381;
  static const _keyboardPanelTop = 116.0;
  static const _keyboardPanelHeight = 728.0;
  static const _keyboardCoverLeft = -15.0;
  static const _keyboardCoverTop = 27.0;
  static const _keyboardCoverWidth = 451.0;
  static const _keyboardCoverHeight = 707.0;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final coverScale = screenSize.width / 390;
    final coverLeft =
        (isKeyboardView ? _keyboardCoverLeft : _coverLeft) * coverScale;
    final coverTop = (isKeyboardView ? _keyboardCoverTop : 0.0) * coverScale;
    final coverWidth =
        (isKeyboardView ? _keyboardCoverWidth : _coverWidth) * coverScale;
    final coverHeight =
        (isKeyboardView ? _keyboardCoverHeight : _coverHeight) * coverScale;
    final keyboardTop = _keyboardPanelTop * coverScale;
    final keyboardHeight = screenSize.height - keyboardTop;
    final targetHeight = isKeyboardView
        ? keyboardHeight.clamp(0, _keyboardPanelHeight * coverScale).toDouble()
        : (screenSize.height < _panelHeight ? screenSize.height : _panelHeight);

    return AnimatedPositioned(
      duration: duration,
      curve: curve,
      left: 0,
      right: 0,
      top: isKeyboardView ? keyboardTop : null,
      bottom: isKeyboardView ? null : 0,
      height: targetHeight.clamp(0, screenSize.height).toDouble(),
      child: ClipRect(
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (coverUrl != null)
              Positioned(
                left: coverLeft,
                top: coverTop,
                width: coverWidth,
                height: coverHeight,
                child: _NetworkImageLayer(
                  imageUrl: coverUrl!,
                  fit: BoxFit.fill,
                  width: coverWidth,
                  height: coverHeight,
                ),
              ),
            Align(alignment: Alignment.topCenter, child: child),
          ],
        ),
      ),
    );
  }
}

class _MobileNumberLabel extends StatelessWidget {
  const _MobileNumberLabel({required this.showError});

  final bool showError;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontFamily: AppTypography.fontFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w500,
      color: Color(0xFF667085),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 390,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Mobile number', style: labelStyle),
            if (showError)
              const Text(
                'Invalid Number',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 14,
                  height: 20 / 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF3B30),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCopy extends StatelessWidget {
  const _WelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Welcome to \nBedtime Stories',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 28,
            height: 32 / 28,
            letterSpacing: -0.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF29609B),
          ),
        ),
        SizedBox(height: 7),
        Text(
          'Safe, magical stories that kids love\n and parents trust.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            height: 20 / 14,
            fontWeight: FontWeight.w500,
            color: Color(0xFF667085),
          ),
        ),
      ],
    );
  }
}

class _MobileKeyboardContent extends StatelessWidget {
  const _MobileKeyboardContent({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.validator,
    required this.showError,
    required this.isValid,
    required this.isNavigating,
    required this.onSendOtp,
    required this.onFieldTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;
  final bool showError;
  final bool isValid;
  final bool isNavigating;
  final VoidCallback onSendOtp;
  final VoidCallback onFieldTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 350,
      height: 295,
      child: Stack(
        children: [
          const Positioned(
            left: 58.5,
            top: 0,
            width: 233,
            height: 111,
            child: _KeyboardWelcomeCopy(),
          ),
          Positioned(
            left: 0,
            top: 135,
            width: 350,
            height: 20,
            child: _MobileNumberLabel(showError: showError),
          ),
          Positioned(
            left: 0,
            top: 163,
            width: 350,
            height: 56,
            child: Semantics(
              textField: true,
              label: 'Mobile number',
              child: _FigmaMobileNumberField(
                controller: controller,
                focusNode: focusNode,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                validator: validator,
                isKeyboardView: true,
                showError: showError,
                onTap: onFieldTap,
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 243,
            width: 350,
            height: 52,
            child: Semantics(
              button: true,
              label: 'Send Otp',
              child: _FigmaPrimaryButton(
                key: const Key('mobile-continue-button'),
                label: 'Send OTP',
                onTap: isValid && !isNavigating ? onSendOtp : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KeyboardWelcomeCopy extends StatelessWidget {
  const _KeyboardWelcomeCopy();

  @override
  Widget build(BuildContext context) {
    return const Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 11,
          top: 0,
          width: 211,
          height: 64,
          child: Text(
            'Welcome to \nBedtime Stories',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 28,
              height: 32 / 28,
              letterSpacing: -0.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF29609B),
            ),
          ),
        ),
        Positioned(
          left: -33,
          top: 71,
          width: 299,
          height: 40,
          child: Text(
            'Safe, magical stories that kids love\n and parents trust.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
        ),
      ],
    );
  }
}

class _OtpCopy extends StatelessWidget {
  const _OtpCopy();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Enter your OTP',
      textAlign: TextAlign.center,
      maxLines: 1,
      softWrap: false,
      style: TextStyle(
        fontFamily: AppTypography.fontFamily,
        fontSize: 24,
        height: 28 / 24,
        fontWeight: FontWeight.w700,
        color: Color(0xFF29609B),
      ),
    );
  }
}

class _OtpSentLabel extends StatelessWidget {
  const _OtpSentLabel({required this.mobileNumber, required this.onEdit});

  final String mobileNumber;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'We have sent to',
            style: TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF667085),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            mobileNumber,
            style: const TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 14,
              height: 20 / 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF344054),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            key: const Key('otp-edit-mobile-button'),
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.edit, size: 16, color: Color(0xFF0BA5EC)),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpCodeBoxes extends StatelessWidget {
  const _OtpCodeBoxes({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 6; index++) ...[
          _OtpCodeBox(digit: index < value.length ? value[index] : null),
          if (index != 5) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _OtpCodeBox extends StatelessWidget {
  const _OtpCodeBox({required this.digit});

  final String? digit;

  @override
  Widget build(BuildContext context) {
    final hasDigit = digit != null;

    return Container(
      width: 48,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasDigit ? Colors.white : const Color(0xFFE4E7EC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasDigit ? const Color(0xFFD0D5DD) : const Color(0xFFD0D5DD),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        digit ?? '',
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 18,
          height: 24 / 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFF344054),
        ),
      ),
    );
  }
}

class _FigmaMobileNumberField extends StatelessWidget {
  const _FigmaMobileNumberField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.validator,
    required this.isKeyboardView,
    required this.showError,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onSubmitted;
  final FormFieldValidator<String> validator;
  final bool isKeyboardView;
  final bool showError;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = showError
        ? const Color(0xFFFF7765)
        : focusNode.hasFocus || controller.text.isNotEmpty
        ? const Color(0xFF0BA5EC)
        : const Color(0xFFD0D5DD);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAFF),
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 2,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        key: const Key('mobile-number-field'),
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.none,
        textInputAction: TextInputAction.done,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        onTap: () {
          onTap();
          focusNode.requestFocus();
        },
        onChanged: onChanged,
        autofillHints: const [AutofillHints.telephoneNumber],
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ],
        style: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFF667085),
        ),
        cursorColor: const Color(0xFF0BA5EC),
        decoration: InputDecoration(
          hintText: isKeyboardView ? 'Enter here' : 'Enter Your Mobile number',
          hintStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            height: 16 / 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF98A2B3),
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 72,
            minHeight: 56,
          ),
          prefixIcon: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 16),
              Icon(Icons.phone_outlined, color: Color(0xFF0BA5EC), size: 24),
              SizedBox(width: 16),
              SizedBox(
                width: 1,
                height: 32,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Color(0xFFE4E7EC)),
                ),
              ),
              SizedBox(width: 13),
            ],
          ),
          filled: false,
          isDense: true,
          contentPadding: const EdgeInsets.fromLTRB(0, 20, 16, 20),
          border: _fieldBorder(Colors.transparent),
          enabledBorder: _fieldBorder(Colors.transparent),
          focusedBorder: _fieldBorder(Colors.transparent),
          errorBorder: _fieldBorder(Colors.transparent),
          focusedErrorBorder: _fieldBorder(Colors.transparent),
          errorStyle: const TextStyle(height: 0, fontSize: 0),
          errorMaxLines: 1,
          errorText: showError ? '' : null,
        ),
        validator: validator,
        onFieldSubmitted: (_) => onSubmitted(),
      ),
    );
  }

  OutlineInputBorder _fieldBorder(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(color: color, width: width),
    );
  }
}

class _FigmaPrimaryButton extends StatelessWidget {
  const _FigmaPrimaryButton({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF13B5EA) : const Color(0xFF98A2B3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2E000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 16,
            height: 20 / 16,
            fontWeight: FontWeight.w700,
            color: isEnabled ? Colors.white : const Color(0xFFD0D5DD),
          ),
        ),
      ),
    );
  }
}

class _ResendOtpButton extends StatelessWidget {
  const _ResendOtpButton();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Resend OTP',
        style: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 16,
          height: 24 / 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF667085),
        ),
      ),
    );
  }
}

class _FigmaNumericKeyboard extends StatelessWidget {
  const _FigmaNumericKeyboard({
    required this.onDigit,
    required this.onBackspace,
    required this.onDone,
    required this.onDismiss,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onDone;
  final VoidCallback onDismiss;

  static const _figmaWidth = 390.0;
  static const _figmaHeight = 250.0;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final scale = screenWidth / _figmaWidth;
    final height = _figmaHeight * scale;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      height: height,
      child: SizedBox(
        width: screenWidth,
        child: FittedBox(
          fit: BoxFit.fill,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: _figmaWidth,
            height: _figmaHeight,
            child: ColoredBox(
              color: const Color(0xFFF2F0F4),
              child: Column(
                children: [
                  const SizedBox(height: 9),
                  _KeyboardRow(
                    children: [
                      _KeyboardKey(label: '1', onTap: () => onDigit('1')),
                      _KeyboardKey(label: '2', onTap: () => onDigit('2')),
                      _KeyboardKey(label: '3', onTap: () => onDigit('3')),
                      _KeyboardKey(
                        icon: Icons.remove,
                        color: const Color(0xFFD9E2F8),
                        onTap: () {},
                      ),
                    ],
                  ),
                  _KeyboardRow(
                    topPadding: 4,
                    children: [
                      _KeyboardKey(label: '4', onTap: () => onDigit('4')),
                      _KeyboardKey(label: '5', onTap: () => onDigit('5')),
                      _KeyboardKey(label: '6', onTap: () => onDigit('6')),
                      _KeyboardKey(
                        icon: Icons.keyboard_return,
                        color: const Color(0xFFD9E2F8),
                        onTap: () {},
                      ),
                    ],
                  ),
                  _KeyboardRow(
                    topPadding: 4,
                    children: [
                      _KeyboardKey(label: '7', onTap: () => onDigit('7')),
                      _KeyboardKey(label: '8', onTap: () => onDigit('8')),
                      _KeyboardKey(label: '9', onTap: () => onDigit('9')),
                      _KeyboardKey(
                        icon: Icons.backspace_outlined,
                        color: const Color(0xFFBDC6DC),
                        onTap: onBackspace,
                      ),
                    ],
                  ),
                  _KeyboardRow(
                    topPadding: 4,
                    children: [
                      _KeyboardKey(label: ',', onTap: () {}),
                      _KeyboardKey(label: '0', onTap: () => onDigit('0')),
                      _KeyboardKey(label: '.', onTap: () {}),
                      _KeyboardKey(
                        icon: Icons.keyboard_tab,
                        color: const Color(0xFFA6C8FF),
                        onTap: onDone,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 348,
                    height: 45,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 29,
                          child: Align(
                            alignment: const Alignment(-0.78, 1),
                            child: IconButton(
                              onPressed: onDismiss,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                size: 24,
                                color: Color(0xFF1B1B1D),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints.tightFor(
                                width: 24,
                                height: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 72,
                          height: 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Color(0xFF49494A),
                              borderRadius: BorderRadius.all(
                                Radius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({required this.children, this.topPadding = 0});

  final List<Widget> children;
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: topPadding),
      child: SizedBox(
        height: 42,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Expanded(child: children[index]),
              if (index != children.length - 1) const SizedBox(width: 5),
            ],
          ],
        ),
      ),
    );
  }
}

class _KeyboardKey extends StatelessWidget {
  const _KeyboardKey({
    required this.onTap,
    this.label,
    this.icon,
    this.color = Colors.white,
  });

  final String? label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(46),
        ),
        child: Center(
          child: icon == null
              ? Text(
                  label!,
                  style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 26,
                    height: 1,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF1B1B1D),
                  ),
                )
              : Icon(icon, size: 24, color: const Color(0xFF1B1B1D)),
        ),
      ),
    );
  }
}

class _NetworkImageLayer extends StatelessWidget {
  const _NetworkImageLayer({
    required this.imageUrl,
    required this.fit,
    required this.width,
    required this.height,
  });

  final String imageUrl;
  final BoxFit fit;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final mediaQuery = MediaQuery.of(context);
    final cacheWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: cacheWidth,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (context, url) => Container(color: colors.surface),
      errorWidget: (context, url, error) => Container(color: colors.surface),
    );
  }
}
