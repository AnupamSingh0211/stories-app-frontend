import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_auth/smart_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/analytics_service.dart';
import '../../shared/theme/app_colors.dart';
import '../../shared/theme/app_tokens.dart';
import '../../shared/theme/app_typography.dart';
import '../../shared/widgets/app_screen_background.dart';
import 'assets_provider.dart';
import 'auth_provider.dart';
import 'indian_phone_number.dart';

enum _WelcomeAuthStep { mobileNumber, otp }

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  static const _figmaFrameWidth = 390.0;
  static const _figmaFrameHeight = 868.0;
  static const _contentWidth = 358.0;
  static const _contentTop = 522.0;
  static const _keyboardContentTop = 291.0;
  static const _otpContentTop = 291.0;
  static const _mascotTop = 133.0;
  static const _keyboardMascotTop = 56.0;
  static const _mascotWidth = 280.0;
  static const _mascotHeight = 421.0;
  static const _keyboardMascotWidth = 178.0;
  static const _keyboardMascotHeight = 267.0;
  static const _controlBorderRadius = 24.0;
  static const _glassShadow = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 4,
    offset: Offset(0, 2),
  );
  static const _buttonShadow = BoxShadow(
    color: Color(0x2D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static final TextInputFormatter _mobileNumberFormatter =
      TextInputFormatter.withFunction((oldValue, newValue) {
        final localNumber = IndianPhoneNumber.tryParseLocal(newValue.text);
        if (localNumber == null) {
          return newValue;
        }

        return TextEditingValue(
          text: localNumber,
          selection: TextSelection.collapsed(offset: localNumber.length),
        );
      });

  final _formKey = GlobalKey<FormState>();
  final _mobileNumberController = TextEditingController();
  final _mobileNumberFocusNode = FocusNode();
  final _otpFocusNode = FocusNode();

  bool _isRequestingOtp = false;
  bool _isVerifyingOtp = false;
  bool _hasAuthenticated = false;
  bool _hasAttemptedValidation = false;
  bool _isMobileNumberFocused = false;
  bool _isOtpFocused = false;
  bool _showInvalidOtp = false;
  bool _hasRequestedPhoneNumberHint = false;
  bool _isListeningForOtp = false;
  bool _didTrackOtpScreen = false;
  _WelcomeAuthStep _authStep = _WelcomeAuthStep.mobileNumber;
  String _otpValue = '';
  String _sentMobileNumber = '';
  String _sentE164MobileNumber = '';
  Timer? _resendTimer;
  int _resendSecondsRemaining = 0;
  static const _resendCooldown = Duration(seconds: 60);

  @override
  void initState() {
    super.initState();
    _mobileNumberFocusNode.addListener(_handleMobileNumberFocusChanged);
    _otpFocusNode.addListener(_handleOtpFocusChanged);
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'login_screen',
        properties: {'source': 'app_start'},
      ),
    );
  }

  @override
  void dispose() {
    _mobileNumberFocusNode.removeListener(_handleMobileNumberFocusChanged);
    _otpFocusNode.removeListener(_handleOtpFocusChanged);
    _otpFocusNode.dispose();
    _mobileNumberFocusNode.dispose();
    _mobileNumberController.dispose();
    _resendTimer?.cancel();
    unawaited(_stopListeningForOtpFromSms());
    super.dispose();
  }

  void _handleMobileNumberFocusChanged() {
    if (_isMobileNumberFocused == _mobileNumberFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _isMobileNumberFocused = _mobileNumberFocusNode.hasFocus;
    });
  }

  void _handleOtpFocusChanged() {
    if (_isOtpFocused == _otpFocusNode.hasFocus) {
      return;
    }

    setState(() {
      _isOtpFocused = _otpFocusNode.hasFocus;
    });
  }

  bool get _isMobileNumberValid =>
      IndianPhoneNumber.isValidLocal(_mobileNumberController.text);

  bool get _shouldShowPhoneNumberHint =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  bool get _canUsePhoneNumberHint => _shouldShowPhoneNumberHint && !_isBusy;

  bool get _shouldShowMobileNumberError {
    final mobileNumber = _mobileNumberController.text;
    if (mobileNumber.isEmpty) {
      return _hasAttemptedValidation;
    }
    return !IndianPhoneNumber.isValidLocal(mobileNumber);
  }

  bool get _isOtpComplete => _otpValue.length == 6;
  bool get _isBusy => _isRequestingOtp || _isVerifyingOtp;

  Future<void> _continueWithMobileNumber() async {
    if (_isBusy || _authStep != _WelcomeAuthStep.mobileNumber) {
      return;
    }

    setState(() => _hasAttemptedValidation = true);
    if (!_formKey.currentState!.validate()) {
      return;
    }

    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'request_otp',
        screenName: 'login_screen',
        properties: {'source': 'phone_auth'},
      ),
    );
    unawaited(
      PostHogAnalytics.instance.capture(
        'signup_started',
        properties: {
          'screen_name': 'login_screen',
          'auth_provider': 'phone_otp',
        },
      ),
    );
    final localNumber = _mobileNumberController.text.trim();
    await _requestOtp(
      localNumber: localNumber,
      e164Number: IndianPhoneNumber.toE164(localNumber),
      moveToOtpStep: true,
    );
  }

  Future<void> _pickPhoneNumberFromDevice() async {
    if (!_canUsePhoneNumberHint ||
        _authStep != _WelcomeAuthStep.mobileNumber ||
        _hasRequestedPhoneNumberHint ||
        _mobileNumberController.text.isNotEmpty) {
      return;
    }

    _hasRequestedPhoneNumberHint = true;
    try {
      final result = await SmartAuth.instance.requestPhoneNumberHint();
      if (!mounted || !result.hasData) {
        return;
      }

      final localNumber = IndianPhoneNumber.tryParseLocal(result.data ?? '');
      if (localNumber == null) {
        return;
      }

      setState(() {
        _mobileNumberController.text = localNumber;
        _hasAttemptedValidation = false;
      });
      _formKey.currentState?.validate();
    } catch (_) {
      // Optional Android helper only; manual entry remains the fallback.
    }
  }

  void _handleMobileNumberTap() {
    _focusAndShowKeyboard(_mobileNumberFocusNode);
    unawaited(_pickPhoneNumberFromDevice());
  }

  Future<void> _requestOtp({
    required String localNumber,
    required String e164Number,
    required bool moveToOtpStep,
  }) async {
    if (_isRequestingOtp || _isVerifyingOtp) {
      return;
    }

    _clearMessage();
    setState(() => _isRequestingOtp = true);
    try {
      await ref.read(appAuthServiceProvider).requestOtp(e164Number);
      if (!mounted) return;

      setState(() {
        _sentMobileNumber = localNumber;
        _sentE164MobileNumber = e164Number;
        _otpValue = '';
        _showInvalidOtp = false;
        if (moveToOtpStep) {
          _authStep = _WelcomeAuthStep.otp;
        }
      });
      if (moveToOtpStep) {
        _trackOtpScreenOpened();
      }
      unawaited(_listenForOtpFromSms());
      _startResendCooldown();
      _mobileNumberFocusNode.unfocus();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _focusAndShowKeyboard(_otpFocusNode);
        }
      });
    } catch (error) {
      if (!mounted) return;
      _showMessage(_otpRequestErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isRequestingOtp = false);
      }
    }
  }

  Future<void> _listenForOtpFromSms() async {
    if (kIsWeb ||
        defaultTargetPlatform != TargetPlatform.android ||
        _isListeningForOtp) {
      return;
    }

    _isListeningForOtp = true;
    try {
      final result = await SmartAuth.instance.getSmsWithUserConsentApi(
        matcher: r'\d{6}',
      );
      if (!mounted || !result.hasData) {
        return;
      }

      final code = result.data?.code;
      if (code == null || code.length != 6) {
        return;
      }

      setState(() {
        _otpValue = code;
        _showInvalidOtp = false;
      });
      _clearMessage();
    } catch (_) {
      // OTP can still be typed manually or filled through platform autofill.
    } finally {
      _isListeningForOtp = false;
    }
  }

  Future<void> _stopListeningForOtpFromSms() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    _isListeningForOtp = false;
    await SmartAuth.instance.removeUserConsentApiListener();
  }

  Future<void> _submitOtp() async {
    if (_isBusy || _hasAuthenticated) {
      return;
    }

    if (!_isOtpComplete) {
      _showMessage('Please enter the complete 6-digit OTP.');
      return;
    }

    _clearMessage();
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'submit_otp',
        screenName: 'otp_verification_screen',
        properties: {'source': 'phone_auth'},
      ),
    );
    setState(() {
      _isVerifyingOtp = true;
    });
    try {
      // AppSessionGate owns the transition to profile setup after auth changes.
      final identity = await ref
          .read(appAuthServiceProvider)
          .verifyOtp(phoneNumber: _sentE164MobileNumber, otp: _otpValue);
      if (identity.isAnonymous) {
        throw StateError('Phone OTP returned an anonymous identity.');
      }
      _hasAuthenticated = true;
      unawaited(
        PostHogAnalytics.instance.capture(
          'login_completed',
          properties: {
            'screen_name': 'otp_verification_screen',
            'auth_provider': 'phone_otp',
          },
        ),
      );
    } catch (_) {
      _hasAuthenticated = false;
      if (!mounted) return;
      setState(() => _showInvalidOtp = true);
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_authStep != _WelcomeAuthStep.otp ||
        _resendSecondsRemaining > 0 ||
        _isBusy ||
        _sentE164MobileNumber.isEmpty) {
      return;
    }

    unawaited(_stopListeningForOtpFromSms());
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'resend_otp',
        screenName: 'otp_verification_screen',
        properties: {'source': 'phone_auth'},
      ),
    );
    await _requestOtp(
      localNumber: _sentMobileNumber,
      e164Number: _sentE164MobileNumber,
      moveToOtpStep: false,
    );
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = _resendCooldown.inSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
        return;
      }

      setState(() => _resendSecondsRemaining--);
    });
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _clearMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }

  String _otpRequestErrorMessage(Object error) {
    if (error is AuthException && error.message.trim().isNotEmpty) {
      return error.message;
    }

    return 'Could not send OTP. Please try again.';
  }

  void _handleMobileNumberChanged(String value) {
    setState(() {
      if (value.isEmpty && _hasAttemptedValidation) {
        _hasAttemptedValidation = false;
      }
    });
    _formKey.currentState?.validate();
  }

  void _focusAndShowKeyboard(FocusNode focusNode) {
    focusNode.requestFocus();
    unawaited(SystemChannels.textInput.invokeMethod<void>('TextInput.show'));
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
    unawaited(
      PostHogAnalytics.instance.buttonClicked(
        buttonName: 'edit_phone_number',
        screenName: 'otp_verification_screen',
        properties: {'source': 'phone_auth'},
      ),
    );
    setState(() {
      _authStep = _WelcomeAuthStep.mobileNumber;
      _otpValue = '';
      _sentMobileNumber = '';
      _sentE164MobileNumber = '';
      _hasAttemptedValidation = false;
      _showInvalidOtp = false;
      _resendSecondsRemaining = 0;
    });
    _resendTimer?.cancel();
    unawaited(_stopListeningForOtpFromSms());
    _clearMessage();
    _otpFocusNode.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusAndShowKeyboard(_mobileNumberFocusNode);
      }
    });
  }

  void _trackOtpScreenOpened() {
    if (_didTrackOtpScreen) {
      return;
    }

    _didTrackOtpScreen = true;
    unawaited(
      PostHogAnalytics.instance.screenOpened(
        'otp_verification_screen',
        properties: {'source': 'phone_auth', 'auth_provider': 'phone_otp'},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appAssets = ref.watch(appAssetsProvider);
    final mascotUrl = appAssets['mascot_character'];
    final showOtpStep = _authStep == _WelcomeAuthStep.otp;
    final mediaQuery = MediaQuery.of(context);
    final contentColor = AppTokenColors.of(ref).homeCardTextPrimary;
    final safeScreenHeight =
        mediaQuery.size.height -
        mediaQuery.padding.top -
        mediaQuery.padding.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: AppScreenBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final scale = math.min(
                constraints.maxWidth / _figmaFrameWidth,
                safeScreenHeight / _figmaFrameHeight,
              );
              final frameWidth = _figmaFrameWidth * scale;
              final frameHeight = _figmaFrameHeight * scale;
              final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;
              final isMobileKeyboardOpen =
                  !showOtpStep && _isMobileNumberFocused && isKeyboardVisible;
              final isOtpKeyboardOpen =
                  showOtpStep && _isOtpFocused && isKeyboardVisible;
              final preferredContentTop = showOtpStep
                  ? isOtpKeyboardOpen
                        ? _otpContentTop
                        : _contentTop
                  : isMobileKeyboardOpen
                  ? _keyboardContentTop
                  : _contentTop;
              final isCompactLayout = isMobileKeyboardOpen || isOtpKeyboardOpen;
              final mascotTop = isCompactLayout
                  ? _keyboardMascotTop
                  : _mascotTop;
              final mascotWidth = isCompactLayout
                  ? _keyboardMascotWidth
                  : _mascotWidth;
              final mascotHeight = isCompactLayout
                  ? _keyboardMascotHeight
                  : _mascotHeight;

              return SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Center(
                    child: SizedBox(
                      width: frameWidth,
                      height: frameHeight,
                      child: Transform.scale(
                        scale: scale,
                        alignment: Alignment.topLeft,
                        child: SizedBox(
                          width: _figmaFrameWidth,
                          height: _figmaFrameHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              if (mascotUrl != null)
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 240),
                                  curve: Curves.easeOutCubic,
                                  left: (_figmaFrameWidth - mascotWidth) / 2,
                                  top: mascotTop,
                                  width: mascotWidth,
                                  height: mascotHeight,
                                  child: CachedNetworkImage(
                                    imageUrl: mascotUrl,
                                    fit: BoxFit.contain,
                                    fadeInDuration: Duration.zero,
                                    fadeOutDuration: Duration.zero,
                                    filterQuality: FilterQuality.medium,
                                    placeholder: (context, url) =>
                                        const SizedBox.expand(),
                                    errorWidget: (context, url, error) =>
                                        const SizedBox.shrink(),
                                  ),
                                ),
                              AnimatedPositioned(
                                duration: const Duration(milliseconds: 240),
                                curve: Curves.easeOutCubic,
                                left: (_figmaFrameWidth - _contentWidth) / 2,
                                top: preferredContentTop,
                                width: _contentWidth,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    showOtpStep
                                        ? _OtpTitleBlock(
                                            mobileNumber: _sentMobileNumber,
                                            onEdit: _editMobileNumber,
                                            showInvalidOtp: _showInvalidOtp,
                                            contentColor: contentColor,
                                          )
                                        : _WelcomeTitleBlock(
                                            compact: isMobileKeyboardOpen,
                                            contentColor: contentColor,
                                          ),
                                    const SizedBox(height: 36),
                                    Form(
                                      key: _formKey,
                                      child: showOtpStep
                                          ? _buildOtpStep()
                                          : _buildMobileNumberStep(),
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
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMobileNumberStep() {
    final contentColor = AppTokenColors.of(ref).homeCardTextPrimary;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Mobile Number',
                style: tokenTextStyles.onboardingFormLabel.copyWith(
                  color: contentColor,
                  fontFeatures: const [
                    FontFeature.disable('liga'),
                    FontFeature.disable('clig'),
                  ],
                ),
              ),
            ),
            if (_shouldShowMobileNumberError)
              const Text(
                'Invalid Number',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFFFF3B30),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleMobileNumberTap,
          child: _GlassControl(
            height: 56,
            borderRadius: _controlBorderRadius,
            shadow: _glassShadow,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            showErrorBorder: _shouldShowMobileNumberError,
            child: Row(
              children: [
                SvgPicture.asset(
                  'assets/icons/new_boopi/State=Default, Icon=Call.svg',
                  width: 24,
                  height: 24,
                ),
                const SizedBox(width: 8),
                Container(
                  width: 1,
                  height: 32,
                  color: AppColors.backgroundGlass,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    key: const Key('mobile-number-field'),
                    controller: _mobileNumberController,
                    focusNode: _mobileNumberFocusNode,
                    showCursor: true,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    onTap: _handleMobileNumberTap,
                    onChanged: _handleMobileNumberChanged,
                    autofillHints: const [
                      AutofillHints.telephoneNumber,
                      AutofillHints.telephoneNumberDevice,
                    ],
                    inputFormatters: [
                      _mobileNumberFormatter,
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    style: tokenTextStyles.onboardingFormInput.copyWith(
                      color: contentColor,
                    ),
                    cursorColor: contentColor,
                    decoration: InputDecoration(
                      hintText: 'Enter your mobile number',
                      hintStyle: tokenTextStyles.onboardingFormInput.copyWith(
                        color: AppColors.blue200,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      focusedErrorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      isDense: true,
                      filled: false,
                      fillColor: Colors.transparent,
                      contentPadding: EdgeInsets.zero,
                      errorStyle: const TextStyle(
                        height: 0,
                        color: Colors.transparent,
                      ),
                    ),
                    validator: _validateMobileNumber,
                    onFieldSubmitted: (_) => _continueWithMobileNumber(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _GlassControl(
          key: const Key('mobile-continue-button'),
          height: 52,
          borderRadius: _controlBorderRadius,
          shadow: _buttonShadow,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          onTap: _isMobileNumberValid && !_isBusy
              ? _continueWithMobileNumber
              : null,
          child: Text(
            _isRequestingOtp ? 'Sending...' : 'Send OTP',
            style: tokenTextStyles.onboardingCtaLabel.copyWith(
              color: _isMobileNumberValid
                  ? contentColor
                  : AppColors.textDisabled,
              fontFeatures: const [
                FontFeature.disable('liga'),
                FontFeature.disable('clig'),
              ],
            ),
            textHeightBehavior: const TextHeightBehavior(
              applyHeightToFirstAscent: false,
              applyHeightToLastDescent: false,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final canSubmitOtp =
        _isOtpComplete && !_showInvalidOtp && !_isBusy && !_hasAuthenticated;
    final contentColor = AppTokenColors.of(ref).homeCardTextPrimary;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          key: const Key('otp-code-boxes-tap-target'),
          onTap: () => _focusAndShowKeyboard(_otpFocusNode),
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            width: 342,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var index = 0; index < 6; index++) ...[
                  _buildOtpCodeBox(
                    index < _otpValue.length ? _otpValue[index] : null,
                  ),
                  if (index != 5) const SizedBox(width: 12),
                ],
              ],
            ),
          ),
        ),
        Opacity(
          opacity: 0,
          child: SizedBox(
            width: 1,
            height: 1,
            child: TextFormField(
              focusNode: _otpFocusNode,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              onChanged: (val) {
                setState(() {
                  _otpValue = val;
                  _showInvalidOtp = false;
                });
                _clearMessage();
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          key: const Key('otp-submit-button'),
          onTap: canSubmitOtp ? _submitOtp : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            height: 52,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.backgroundGlass,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.borderGlass),
              boxShadow: const [_buttonShadow],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Submit',
                  style: tokenTextStyles.onboardingCtaLabel.copyWith(
                    color: canSubmitOtp || _isVerifyingOtp
                        ? contentColor
                        : AppColors.textDisabled,
                  ),
                  textHeightBehavior: const TextHeightBehavior(
                    applyHeightToFirstAscent: false,
                    applyHeightToLastDescent: false,
                  ),
                ),
                if (_isVerifyingOtp) ...[
                  const SizedBox(width: 10),
                  SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(contentColor),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: Center(
            child: InkWell(
              key: const Key('otp-resend-button'),
              onTap: _resendSecondsRemaining == 0 && !_isBusy
                  ? _resendOtp
                  : null,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  _otpResendLabel,
                  style: tokenTextStyles.onboardingOtpCaption.copyWith(
                    color: _resendTextColor(contentColor),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpCodeBox(String? digit) {
    final contentColor = AppTokenColors.of(ref).homeCardTextPrimary;
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return GestureDetector(
      onTap: () => _focusAndShowKeyboard(_otpFocusNode),
      child: Container(
        width: 44,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(46),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withAlpha(51)),
          boxShadow: const [_glassShadow],
        ),
        child: Text(
          digit ?? '',
          style: tokenTextStyles.onboardingFormInput.copyWith(
            color: contentColor,
          ),
        ),
      ),
    );
  }

  String get _otpResendLabel {
    if (_isRequestingOtp) {
      return 'Sending...';
    }
    if (_otpValue.isEmpty && _resendSecondsRemaining > 0) {
      final minutes = _resendSecondsRemaining ~/ 60;
      final seconds = (_resendSecondsRemaining % 60).toString().padLeft(2, '0');
      return 'Resend in $minutes:$seconds';
    }
    return 'Resend OTP';
  }

  Color _resendTextColor(Color contentColor) {
    if (_otpValue.isEmpty && _resendSecondsRemaining > 0) {
      return AppColors.textDisabled;
    }
    return contentColor.withAlpha(217);
  }
}

class _GlassControl extends StatelessWidget {
  const _GlassControl({
    super.key,
    required this.height,
    required this.borderRadius,
    required this.shadow,
    required this.child,
    this.padding,
    this.showErrorBorder = false,
    this.onTap,
  });

  final double height;
  final double borderRadius;
  final BoxShadow shadow;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool showErrorBorder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: showErrorBorder
          ? const BorderSide(color: Color(0xFFFF7765))
          : const BorderSide(color: AppColors.borderLight, width: 1),
    );

    return Container(
      height: height,
      decoration: BoxDecoration(borderRadius: radius, boxShadow: [shadow]),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: ShapeDecoration(
            color: AppColors.backgroundGlass,
            shape: shape,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: radius,
            child: Padding(
              padding: padding ?? EdgeInsets.zero,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpTitleBlock extends ConsumerWidget {
  const _OtpTitleBlock({
    required this.mobileNumber,
    required this.onEdit,
    required this.showInvalidOtp,
    required this.contentColor,
  });

  final String mobileNumber;
  final VoidCallback onEdit;
  final bool showInvalidOtp;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Enter your OTP',
          textAlign: TextAlign.center,
          style: tokenTextStyles.onboardingOtpTitle.copyWith(
            color: contentColor,
          ),
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Sent to',
                style: tokenTextStyles.onboardingOtpCaption.copyWith(
                  color: contentColor.withAlpha(217),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                mobileNumber,
                style: tokenTextStyles.onboardingOtpCaption.copyWith(
                  color: contentColor.withAlpha(217),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                key: const Key('otp-edit-mobile-button'),
                onTap: onEdit,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 24,
          child: Center(
            child: showInvalidOtp
                ? const Text(
                    'Invalid OTP',
                    style: TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 14,
                      height: 20 / 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFFF3B30),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }
}

class _WelcomeTitleBlock extends ConsumerWidget {
  const _WelcomeTitleBlock({required this.compact, required this.contentColor});

  final bool compact;
  final Color contentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokenTextStyles = AppTokenTextStyles.of(ref);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Boopi',
          textAlign: TextAlign.center,
          style: tokenTextStyles.onboardingHeaderTitle.copyWith(
            fontSize: compact ? 24 : 28,
            height: compact ? 28 / 24 : 32 / 28,
            letterSpacing: compact ? -0.25 : -0.5,
            color: contentColor,
            fontFeatures: [
              FontFeature.disable('liga'),
              FontFeature.disable('clig'),
            ],
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: 299,
          child: Text(
            'Where every story ends in sweet dreams.',
            textAlign: TextAlign.center,
            style: tokenTextStyles.onboardingHeaderSubtitle.copyWith(
              color: const Color(0xD9FFFFFF),
              fontFeatures: const [
                FontFeature.disable('liga'),
                FontFeature.disable('clig'),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
