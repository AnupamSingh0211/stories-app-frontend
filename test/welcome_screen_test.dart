import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/auth_provider.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/auth/profile_setup_screen.dart';
import 'package:dharma_app/features/auth/welcome_screen.dart';
import 'package:dharma_app/main.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';

void main() {
  testWidgets('renders Figma welcome mobile form', (tester) async {
    await _pumpWelcomeScreen(tester);

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Email'), findsNothing);
    expect(find.text('Welcome to \nBedtime Stories'), findsOneWidget);
    expect(
      find.text('Safe, magical stories that kids love\n and parents trust.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('mobile-number-field')), findsOneWidget);
    expect(find.text('Enter Your Mobile number'), findsOneWidget);
    expect(find.byKey(const Key('mobile-continue-button')), findsOneWidget);
    expect(find.text('Send Otp'), findsOneWidget);
  });

  testWidgets('empty input shows the required mobile-number error', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.tap(find.byKey(const Key('mobile-number-field')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_tab));
    await tester.pump();

    expect(find.text('Invalid Number'), findsOneWidget);
  });

  testWidgets('fewer than 10 digits shows the invalid-number error', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.tap(find.byKey(const Key('mobile-number-field')));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '123456789',
    );
    await tester.pump();

    expect(find.text('Invalid Number'), findsOneWidget);
  });

  testWidgets('validation error clears when input becomes 10 digits', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    final field = find.byKey(const Key('mobile-number-field'));
    await tester.tap(field);
    await tester.pump();
    await tester.enterText(field, '123');
    await tester.pump();

    expect(find.text('Invalid Number'), findsOneWidget);

    await tester.enterText(field, '1234567890');
    await tester.pump();

    expect(find.text('Invalid Number'), findsNothing);
  });

  testWidgets(
    'clearing input hides validation until Continue is pressed again',
    (tester) async {
      await _pumpWelcomeScreen(tester);

      final field = find.byKey(const Key('mobile-number-field'));

      await tester.tap(field);
      await tester.pump();
      await tester.enterText(field, '123');
      await tester.pump();
      expect(find.text('Invalid Number'), findsOneWidget);

      await tester.enterText(field, '');
      await tester.pump();
      expect(find.text('Invalid Number'), findsNothing);

      await tester.enterText(field, '456');
      await tester.pump();
      expect(find.text('Invalid Number'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.keyboard_tab));
      await tester.pump();
      expect(find.text('Invalid Number'), findsOneWidget);
    },
  );

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
    expect(find.text('We have sent to'), findsOneWidget);
    expect(find.text('1234567890'), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
    expect(authService.requestedPhones, ['+911234567890']);

    final title = tester.widget<Text>(find.text('Enter your OTP'));
    expect(title.maxLines, 1);
    expect(title.softWrap, isFalse);
  });

  testWidgets('invalid input does not navigate', (tester) async {
    final observer = _CountingNavigatorObserver();
    await _pumpWelcomeScreen(tester, observer: observer);
    observer.pushCount = 0;

    await tester.enterText(find.byKey(const Key('mobile-number-field')), '123');
    await tester.pump();
    await tester.tap(find.byKey(const Key('mobile-number-field')));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.keyboard_tab));
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

    for (final digit in ['9', '8', '7', '6', '5', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }

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

      for (final digit in ['9', '8', '7', '6', '5', '4']) {
        await tester.tap(find.text(digit));
        await tester.pump();
      }

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
    await tester.tap(find.byIcon(Icons.keyboard_tab));
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

    expect(find.text('Welcome to \nBedtime Stories'), findsOneWidget);
    expect(find.byKey(const Key('mobile-number-field')), findsOneWidget);

    final field = tester.widget<TextFormField>(
      find.byKey(const Key('mobile-number-field')),
    );
    expect(field.controller!.text, '1234567890');
  });

  testWidgets('tapping OTP boxes reopens the numeric keyboard after dismiss', (
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

    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsNothing);

    await tester.tap(find.byKey(const Key('otp-code-boxes-tap-target')));
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
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
    expect(find.text('Enter your OTP'), findsNothing);
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

    for (final digit in ['1', '2', '3', '4', '5']) {
      await tester.tap(find.text(digit));
    }
    await tester.tap(find.byIcon(Icons.keyboard_tab));
    await tester.pump();

    expect(authService.verifyOtpCalls, 0);
    expect(find.text('Please enter the complete 6-digit OTP.'), findsOneWidget);
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
    expect(
      find.text('Invalid or expired OTP. Please try again.'),
      findsOneWidget,
    );
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
    expect(find.text('Verifying...'), findsOneWidget);

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

      expect(find.text('Resend OTP in 60s'), findsOneWidget);
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
  for (final digit in otp.split('')) {
    await tester.tap(find.text(digit));
    await tester.pump();
  }
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
