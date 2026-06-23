import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/profile_setup_screen.dart';
import 'package:dharma_app/features/auth/welcome_screen.dart';
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

  testWidgets('exactly 10 digits opens the mock OTP step', (tester) async {
    await _pumpWelcomeScreen(tester);

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

  testWidgets('mock OTP submit pushes profile setup only once', (tester) async {
    final observer = _CountingNavigatorObserver();
    await _pumpWelcomeScreen(tester, observer: observer);
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

    expect(observer.pushCount, 1);
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
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [appAssetsProvider.overrideWithValue(_testAssets)],
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

class _CountingNavigatorObserver extends NavigatorObserver {
  int pushCount = 0;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushCount++;
    super.didPush(route, previousRoute);
  }
}
