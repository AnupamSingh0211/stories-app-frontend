import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boopi_app/features/auth/onboarding_screen.dart';
import 'package:boopi_app/features/auth/onboarding_store.dart';

void main() {
  testWidgets('onboarding walks through stories, companion, and notifications', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var finished = false;
    var permissionRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onFinished: () => finished = true,
          requestNotifications: () async => permissionRequests++,
        ),
      ),
    );

    expect(find.text('Stories that end\nin sweet dreams'), findsOneWidget);
    expect(find.text('Allow notifications'), findsNothing);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('A companion for\nevery night'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    expect(find.text('May Boopi send\nnotifications?'), findsOneWidget);
    expect(find.text('Allow notifications'), findsOneWidget);
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.byKey(const Key('onboarding-skip')));
    await tester.pumpAndSettle();

    expect(finished, isTrue);
    expect(permissionRequests, 0);
    expect(await OnboardingStore.isCompleted(), isTrue);
    expect(await OnboardingStore.notificationsAllowed(), isFalse);
  });

  testWidgets('allow notifications asks the system and remembers the choice', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var permissionRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: OnboardingScreen(
          onFinished: () {},
          requestNotifications: () async => permissionRequests++,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('onboarding-allow')));
    await tester.pumpAndSettle();

    expect(permissionRequests, 1);
    expect(await OnboardingStore.notificationsAllowed(), isTrue);
  });
}
