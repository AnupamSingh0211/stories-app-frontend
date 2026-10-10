import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boopi_app/features/auth/assets_provider.dart';
import 'package:boopi_app/features/auth/onboarding_store.dart';
import 'package:boopi_app/features/auth/auth_provider.dart';
import 'package:boopi_app/features/auth/profile_notifier.dart';
import 'package:boopi_app/features/auth/profile_setup_screen.dart';
import 'package:boopi_app/features/auth/welcome_screen.dart';
import 'package:boopi_app/main.dart';
import 'package:boopi_app/shared/theme/app_theme.dart';

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({
      OnboardingStore.completedKey: true,
    });
    dotenv.testLoad(
      fileInput: '''
DEV_AUTH_OTP_ENABLED=false
APP_ENV=test
''',
    );
  });

  testWidgets('renders Figma welcome mobile form', (tester) async {
    await _pumpWelcomeScreen(tester);

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Email'), findsNothing);
    expect(find.text('Boopi'), findsOneWidget);
    expect(
      find.text('Where every story ends in sweet dreams.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-number-field')), findsOneWidget);
    expect(find.text('Enter your mobile number'), findsOneWidget);
    expect(find.byKey(const Key('mobile-continue-button')), findsOneWidget);
    expect(find.text('Send OTP'), findsOneWidget);
  });

  testWidgets('login CTA labels stay vertically inside their buttons', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(tester, authService: authService);

    _expectTextInsideButton(
      tester,
      buttonKey: const Key('mobile-continue-button'),
      label: 'Send OTP',
    );

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    _expectTextInsideButton(
      tester,
      buttonKey: const Key('otp-submit-button'),
      label: 'Submit',
    );
  });

  testWidgets('send OTP button uses Material ink tap feedback', (tester) async {
    await _pumpWelcomeScreen(tester);

    final button = find.byKey(const Key('mobile-continue-button'));
    final inkWell = find.descendant(of: button, matching: find.byType(InkWell));

    expect(inkWell, findsOneWidget);
    expect(
      find.descendant(of: button, matching: find.byType(Material)),
      findsOneWidget,
    );
    expect(tester.widget<InkWell>(inkWell).onTap, isNull);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();

    expect(tester.widget<InkWell>(inkWell).onTap, isNotNull);
  });

  testWidgets('phone field exposes cross-platform phone autofill hints', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    final editableText = tester.widget<EditableText>(
      find.descendant(
        of: find.byKey(const Key('mobile-number-field')),
        matching: find.byType(EditableText),
      ),
    );
    expect(
      editableText.autofillHints,
      containsAll([
        AutofillHints.telephoneNumber,
        AutofillHints.telephoneNumberDevice,
      ]),
    );
  });

  testWidgets('does not render a separate phone number hint action', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    expect(find.byKey(const Key('mobile-number-hint-button')), findsNothing);
    expect(find.text('Use my number'), findsNothing);
  });

  testWidgets('phone field focus lifts the welcome layout for the keyboard', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    final titleFinder = find.text('Boopi');
    expect(tester.getTopLeft(titleFinder).dy, greaterThan(480));

    await tester.tap(find.byKey(const Key('mobile-number-field')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    addTearDown(() => tester.view.viewInsets = FakeViewPadding.zero);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(titleFinder).dy, lessThan(330));
  });

  testWidgets('welcome layout restores after keyboard closes', (tester) async {
    await _pumpWelcomeScreen(tester);

    final titleFinder = find.text('Boopi');
    final originalTitleTop = tester.getTopLeft(titleFinder).dy;

    await tester.tap(find.byKey(const Key('mobile-number-field')));
    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(titleFinder).dy, lessThan(originalTitleTop));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(titleFinder).dy, originalTitleTop);
  });

  testWidgets('OTP layout restores after keyboard closes', (tester) async {
    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(tester, authService: authService);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    final otpTitleFinder = find.text('Enter your OTP');
    final originalOtpTitleTop = tester.getTopLeft(otpTitleFinder).dy;

    tester.view.viewInsets = const FakeViewPadding(bottom: 320);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(otpTitleFinder).dy, lessThan(originalOtpTitleTop));

    tester.view.viewInsets = FakeViewPadding.zero;
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(otpTitleFinder).dy, originalOtpTitleTop);
  });

  testWidgets('invalid input shows inline error on submission', (tester) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(find.byKey(const Key('mobile-number-field')), '123');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Invalid Number'), findsOneWidget);

    final labelTopLeft = tester.getTopLeft(find.text('Mobile Number'));
    final errorTopLeft = tester.getTopLeft(find.text('Invalid Number'));
    final fieldTopLeft = tester.getTopLeft(
      find.byKey(const Key('mobile-number-field')),
    );

    expect(errorTopLeft.dx, greaterThan(labelTopLeft.dx));
    expect(errorTopLeft.dy, labelTopLeft.dy);
    expect(errorTopLeft.dy, lessThan(fieldTopLeft.dy));
  });

  testWidgets('input formatters allow only the first 10 digits', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '12345abc6789012',
    );
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('mobile-number-field')),
    );
    expect(field.controller!.text, '1234567890');
  });

  testWidgets('phone autofill removes Indian country code before limiting', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '+91 70606 58766',
    );
    await tester.pump();

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('mobile-number-field')),
    );
    expect(field.controller!.text, '7060658766');
  });

  testWidgets('exactly 10 digits requests OTP using E.164 and opens OTP step', (
    tester,
  ) async {
    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(tester, authService: authService);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Enter your OTP'), findsOneWidget);
    expect(find.text('Sent to'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(authService.requestedPhones, ['+911234567890']);
  });

  testWidgets('dev otp shows the fixed test code instead of Sent to', (
    tester,
  ) async {
    dotenv.testLoad(
      fileInput: '''
DEV_AUTH_OTP_ENABLED=true
APP_ENV=test
''',
    );
    addTearDown(() {
      dotenv.testLoad(
        fileInput: '''
DEV_AUTH_OTP_ENABLED=false
APP_ENV=test
''',
      );
    });

    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(tester, authService: authService);
    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    expect(find.text('Use 123456 for'), findsOneWidget);
    expect(find.text('Sent to'), findsNothing);
    expect(find.text('1234567890'), findsOneWidget);

    await tester.tap(find.byKey(const Key('otp-submit-button')));
    await tester.pumpAndSettle();

    expect(authService.verifyOtpCalls, 1);
    expect(authService.verifiedOtp, '123456');
    expect(authService.verifiedPhone, '+911234567890');
  });

  testWidgets('invalid input does not navigate', (tester) async {
    final observer = _CountingNavigatorObserver();
    await _pumpWelcomeScreen(tester, observer: observer);
    observer.pushCount = 0;

    await tester.enterText(find.byKey(const Key('mobile-number-field')), '123');
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-number-field')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();

    expect(observer.pushCount, 0);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
  });

  testWidgets('OTP submit verifies only once', (tester) async {
    final observer = _CountingNavigatorObserver();
    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(
      tester,
      observer: observer,
      authService: authService,
    );
    observer.pushCount = 0;

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).last, '987654');
    await tester.pump();

    await tester.tap(find.byKey(const Key('otp-submit-button')));
    await tester.tap(
      find.byKey(const Key('otp-submit-button')),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();

    expect(authService.verifyOtpCalls, 1);
    expect(authService.verifiedPhone, '+911234567890');
    expect(authService.verifiedOtp, '987654');
    expect(observer.pushCount, 0);
    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets(
    'authenticated OTP completion lets AppSessionGate show profile setup',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final authEvents = StreamController<AppSessionIdentity?>();
      addTearDown(authEvents.close);
      final authService = _FakeAuthService(
        onVerifyOtp: () {
          authEvents.add(
            const AppSessionIdentity(
              userId: 'phone-user-1',
              isAnonymous: false,
            ),
          );
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appAssetsProvider.overrideWithValue(_testAssets),
            appAuthServiceProvider.overrideWithValue(authService),
            authSessionProvider.overrideWith((ref) async* {
              yield null;
              yield* authEvents.stream;
            }),
            profileNotifierProvider.overrideWith(_EmptyProfileNotifier.new),
          ],
          child: const MyApp(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('mobile-number-field')),
        '1234567890',
      );
      await tester.pump();
      await tester.tap(find.byKey(const Key('mobile-continue-button')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).last, '987654');
      await tester.pump();
      await tester.tap(find.byKey(const Key('otp-submit-button')));
      await tester.pumpAndSettle();

      expect(authService.verifyOtpCalls, 1);
      expect(find.byType(ProfileSetupScreen), findsOneWidget);
      expect(find.byType(WelcomeScreen), findsNothing);
    },
  );

  testWidgets('auth identity updates do not reset the active profile form', (
    tester,
  ) async {
    final authEvents = StreamController<AppSessionIdentity?>();
    addTearDown(authEvents.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appAssetsProvider.overrideWithValue(_testAssets),
          authSessionProvider.overrideWith((ref) async* {
            yield const AppSessionIdentity(
              userId: 'phone-user-1',
              isAnonymous: false,
            );
            yield* authEvents.stream;
          }),
          profileNotifierProvider.overrideWith(_EmptyProfileNotifier.new),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final nameField = find.byType(TextFormField);
    await tester.enterText(nameField, 'Aarav');
    await tester.pump();

    authEvents.add(
      const AppSessionIdentity(userId: 'phone-user-1', isAnonymous: false),
    );
    await tester.pumpAndSettle();

    final field = tester.widget<TextFormField>(nameField);
    expect(field.controller?.text, 'Aarav');
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('keyboard Done moves a valid mobile number to OTP', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-number-field')));
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Enter your OTP'), findsOneWidget);
  });

  testWidgets('edit mobile returns from OTP to the mobile input state', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('otp-edit-mobile-button')));
    await tester.pumpAndSettle();

    expect(find.text('Boopi'), findsOneWidget);
    expect(find.byKey(const Key('mobile-number-field')), findsOneWidget);

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('mobile-number-field')),
    );
    expect(field.controller!.text, '1234567890');
  });

  testWidgets('OTP request failure stays on phone step and shows an error', (
    tester,
  ) async {
    final authService = _FakeAuthService(requestError: Exception('offline'));
    await _pumpWelcomeScreen(tester, authService: authService);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '9876543210',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    expect(authService.requestedPhones, ['+919876543210']);
    expect(find.text('We have sent to'), findsNothing);
    expect(find.text('Could not send OTP. Please try again.'), findsOneWidget);
  });

  testWidgets('pending OTP request blocks duplicate submission', (
    tester,
  ) async {
    final requestCompleter = Completer<void>();
    final authService = _FakeAuthService(requestCompleter: requestCompleter);
    await _pumpWelcomeScreen(tester, authService: authService);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '9876543210',
    );
    await tester.pump();
    final sendButton = find.byKey(const Key('mobile-continue-button'));
    await tester.tap(sendButton);
    await tester.tap(sendButton, warnIfMissed: false);
    await tester.pump();

    expect(authService.requestedPhones, ['+919876543210']);
    expect(find.text('Sending...'), findsOneWidget);

    requestCompleter.complete();
    await tester.pumpAndSettle();
    expect(find.text('Enter your OTP'), findsOneWidget);
  });

  testWidgets('incomplete OTP is not submitted', (tester) async {
    final authService = _FakeAuthService();
    await _pumpWelcomeScreen(tester, authService: authService);
    await _openOtpStep(tester);

    await tester.enterText(find.byType(TextFormField).last, '12345');
    await tester.pump();
    await tester.tap(
      find.byKey(const Key('otp-submit-button')),
      warnIfMissed: false,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(authService.verifyOtpCalls, 0);
    expect(authService.verifyOtpCalls, 0);
    expect(find.text('Submit'), findsOneWidget);
  });

  testWidgets('OTP verification failure keeps OTP step and shows an error', (
    tester,
  ) async {
    final authService = _FakeAuthService(verifyError: Exception('bad otp'));
    await _pumpWelcomeScreen(tester, authService: authService);
    await _openOtpStep(tester);
    await _enterOtp(tester, '123456');
    await tester.tap(find.byKey(const Key('otp-submit-button')));

    await tester.pumpAndSettle();

    expect(authService.verifyOtpCalls, 1);
    expect(find.text('Enter your OTP'), findsOneWidget);
    expect(find.text('Invalid OTP'), findsOneWidget);
  });

  testWidgets('pending OTP verification blocks duplicate submission', (
    tester,
  ) async {
    final verifyCompleter = Completer<AppSessionIdentity>();
    final authService = _FakeAuthService(verifyCompleter: verifyCompleter);
    await _pumpWelcomeScreen(tester, authService: authService);
    await _openOtpStep(tester);
    await _enterOtp(tester, '123456');

    final submitButton = find.byKey(const Key('otp-submit-button'));
    await tester.tap(submitButton);
    await tester.tap(submitButton, warnIfMissed: false);
    await tester.pump();

    expect(authService.verifyOtpCalls, 1);
    expect(find.text('Submit'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    verifyCompleter.complete(
      const AppSessionIdentity(userId: 'phone-user-1', isAnonymous: false),
    );
    await tester.pumpAndSettle();
  });

  testWidgets(
    'resend remains disabled for 60 seconds then requests a new OTP',
    (tester) async {
      final authService = _FakeAuthService();
      await _pumpWelcomeScreen(tester, authService: authService);
      await _openOtpStep(tester);

      expect(find.text('Resend in 1:00'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('otp-resend-button')),
        warnIfMissed: false,
      );
      expect(authService.requestedPhones, hasLength(1));

      await tester.pump(const Duration(seconds: 60));
      expect(find.text('Resend OTP'), findsOneWidget);

      await tester.tap(find.byKey(const Key('otp-resend-button')));
      await tester.pump();
      expect(authService.requestedPhones, hasLength(2));
      expect(authService.requestedPhones.last, '+911234567890');
    },
  );
}

Future<void> _openOtpStep(WidgetTester tester) async {
  await tester.enterText(
    find.byKey(const Key('mobile-number-field')),
    '1234567890',
  );
  await tester.pump();
  await tester.tap(find.byKey(const Key('mobile-continue-button')));
  await tester.pumpAndSettle();
}

Future<void> _enterOtp(WidgetTester tester, String otp) async {
  await tester.enterText(find.byType(TextFormField).last, otp);
  await tester.pump();
}

const _testAssets = {
  'welcome_bg(1)': 'https://example.com/welcome_bg.webp',
  'welcome_cover': 'https://example.com/welcome_cover.png',
  'welcome_otp_bg': 'https://example.com/welcome_otp_bg.webp',
  'welcome_otp_cover': 'https://example.com/welcome_otp_cover.png',
  'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
};

Future<void> _pumpWelcomeScreen(
  WidgetTester tester, {
  NavigatorObserver? observer,
  AppAuthService? authService,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appAssetsProvider.overrideWithValue(_testAssets),
        appAuthServiceProvider.overrideWithValue(
          authService ?? _FakeAuthService(),
        ),
      ],
      child: MaterialApp(
        themeMode: ThemeMode.dark,
        darkTheme: AppTheme.darkTheme,
        navigatorObservers: [?observer],
        home: const WelcomeScreen(),
      ),
    ),
  );
  await tester.pump();
}

void _expectTextInsideButton(
  WidgetTester tester, {
  required Key buttonKey,
  required String label,
}) {
  final buttonFinder = find.byKey(buttonKey);
  final buttonRect = tester.getRect(buttonFinder);
  final textRect = tester.getRect(
    find.descendant(of: buttonFinder, matching: find.text(label)),
  );

  expect(textRect.top, greaterThanOrEqualTo(buttonRect.top));
  expect(textRect.bottom, lessThanOrEqualTo(buttonRect.bottom));
}

class _FakeAuthService implements AppAuthService {
  _FakeAuthService({
    this.onVerifyOtp,
    this.requestError,
    this.verifyError,
    this.requestCompleter,
    this.verifyCompleter,
  });

  final VoidCallback? onVerifyOtp;
  final Object? requestError;
  final Object? verifyError;
  final Completer<void>? requestCompleter;
  final Completer<AppSessionIdentity>? verifyCompleter;
  final List<String> requestedPhones = [];
  int verifyOtpCalls = 0;
  int signOutCalls = 0;
  String? verifiedPhone;
  String? verifiedOtp;

  @override
  AppSessionIdentity? get currentIdentity => null;

  @override
  Future<void> requestOtp(String phoneNumber) async {
    requestedPhones.add(phoneNumber);
    if (requestCompleter != null) {
      await requestCompleter!.future;
    }
    if (requestError != null) {
      throw requestError!;
    }
  }

  @override
  Future<AppSessionIdentity> verifyOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    verifyOtpCalls++;
    verifiedPhone = phoneNumber;
    verifiedOtp = otp;
    if (verifyCompleter != null) {
      return verifyCompleter!.future;
    }
    if (verifyError != null) {
      throw verifyError!;
    }
    onVerifyOtp?.call();
    return const AppSessionIdentity(userId: 'phone-user-1', isAnonymous: false);
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
  }
}

class _EmptyProfileNotifier extends ProfileNotifier {
  @override
  Future<ChildProfilesState> build() async => const ChildProfilesState();
}

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}
