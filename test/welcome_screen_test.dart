import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/features/auth/profile_setup_screen.dart';
import 'package:dharma_app/features/auth/welcome_screen.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';
import 'package:dharma_app/shared/widgets/pill_button.dart';

void main() {
  testWidgets('replaces social continuation buttons with mobile form', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    expect(find.text('Continue with Apple'), findsNothing);
    expect(find.text('Continue with Google'), findsNothing);
    expect(find.text('Continue with Email'), findsNothing);
    expect(find.byKey(const Key('mobile-number-field')), findsOneWidget);
    expect(find.text('Enter your mobile number'), findsOneWidget);
    expect(find.byKey(const Key('mobile-continue-button')), findsOneWidget);
    expect(find.text('Browse as Guest →'), findsOneWidget);
  });

  testWidgets('empty input shows the required mobile-number error', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pump();

    expect(find.text('Please enter your mobile number.'), findsOneWidget);
  });

  testWidgets('fewer than 10 digits shows the invalid-number error', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '123456789',
    );
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pump();

    expect(
      find.text('Please enter a valid 10-digit mobile number.'),
      findsOneWidget,
    );
  });

  testWidgets('validation error clears when input becomes 10 digits', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    final field = find.byKey(const Key('mobile-number-field'));
    await tester.enterText(field, '123');
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pump();

    expect(
      find.text('Please enter a valid 10-digit mobile number.'),
      findsOneWidget,
    );

    await tester.enterText(field, '1234567890');
    await tester.pump();

    expect(
      find.text('Please enter a valid 10-digit mobile number.'),
      findsNothing,
    );
  });

  testWidgets(
    'clearing input hides validation until Continue is pressed again',
    (tester) async {
      await _pumpWelcomeScreen(tester);

      final field = find.byKey(const Key('mobile-number-field'));
      final continueButton = find.byKey(const Key('mobile-continue-button'));

      await tester.enterText(field, '123');
      await tester.tap(continueButton);
      await tester.pump();
      expect(
        find.text('Please enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );

      await tester.enterText(field, '');
      await tester.pump();
      expect(find.text('Please enter your mobile number.'), findsNothing);
      expect(
        find.text('Please enter a valid 10-digit mobile number.'),
        findsNothing,
      );

      await tester.enterText(field, '456');
      await tester.pump();
      expect(
        find.text('Please enter a valid 10-digit mobile number.'),
        findsNothing,
      );

      await tester.tap(continueButton);
      await tester.pump();
      expect(
        find.text('Please enter a valid 10-digit mobile number.'),
        findsOneWidget,
      );
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

  testWidgets('exactly 10 digits navigates to profile setup', (tester) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('invalid input does not navigate', (tester) async {
    final observer = _CountingNavigatorObserver();
    await _pumpWelcomeScreen(tester, observer: observer);
    observer.pushCount = 0;

    await tester.enterText(find.byKey(const Key('mobile-number-field')), '123');
    await tester.tap(find.byKey(const Key('mobile-continue-button')));
    await tester.pump();

    expect(observer.pushCount, 0);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(find.byType(ProfileSetupScreen), findsNothing);
  });

  testWidgets('repeated Continue taps push profile setup only once', (
    tester,
  ) async {
    final observer = _CountingNavigatorObserver();
    await _pumpWelcomeScreen(tester, observer: observer);
    observer.pushCount = 0;

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    final button = tester.widget<PillButton>(
      find.byKey(const Key('mobile-continue-button')),
    );
    button.onTap!();
    button.onTap!();
    await tester.pumpAndSettle();

    expect(observer.pushCount, 1);
    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('keyboard Done validates and continues', (tester) async {
    await _pumpWelcomeScreen(tester);

    await tester.enterText(
      find.byKey(const Key('mobile-number-field')),
      '1234567890',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });

  testWidgets('Browse as Guest keeps the existing profile setup flow', (
    tester,
  ) async {
    await _pumpWelcomeScreen(tester);

    await tester.tap(find.text('Browse as Guest →'));
    await tester.pumpAndSettle();

    expect(find.byType(ProfileSetupScreen), findsOneWidget);
  });
}

const _testAssets = {
  'welcome_bg': 'https://example.com/welcome_bg.webp',
  'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
};

Future<void> _pumpWelcomeScreen(
  WidgetTester tester, {
  NavigatorObserver? observer,
}) async {
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
