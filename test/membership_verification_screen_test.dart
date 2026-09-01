import 'package:dharma_app/features/membership/membership_plans_screen.dart';
import 'package:dharma_app/features/membership/membership_verification_screen.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('subscribe monthly opens the parent verification screen', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 868));
    await tester.pumpWidget(_membershipTestApp(const MembershipPlansScreen()));
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('membershipPlansContinueButton')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MembershipVerificationScreen), findsOneWidget);
    expect(find.text('For Parents Only'), findsOneWidget);
    expect(find.text('Please enter the year you were born.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('membershipVerificationDigit0')),
      findsOneWidget,
    );
  });

  testWidgets('verification screen matches the Figma panel geometry', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 868));
    await tester.pumpWidget(
      _membershipTestApp(const MembershipVerificationScreen()),
    );
    await tester.pump();

    final panel = find.byKey(const ValueKey('membershipVerificationPanel'));
    final hero = find.byKey(const ValueKey('membershipVerificationHero'));
    final digitOne = find.byKey(const ValueKey('membershipVerificationDigit1'));

    expect(tester.getTopLeft(hero).dy, 98);
    expect(tester.getSize(hero), const Size(116.614, 152));
    expect(tester.getTopLeft(panel), const Offset(0, 358));
    expect(tester.getSize(panel), const Size(390, 510));
    expect(tester.getSize(digitOne), const Size(44, 36));
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification header fills the status bar area', (tester) async {
    await _setViewport(tester, const Size(390, 868));
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(() => tester.view.padding = FakeViewPadding.zero);

    await tester.pumpWidget(
      _membershipTestApp(const MembershipVerificationScreen()),
    );
    await tester.pump();

    final headerRect = tester.getRect(
      find.byKey(const ValueKey('membershipVerificationHeader')),
    );
    final backRect = tester.getRect(
      find.byKey(const ValueKey('membershipVerificationBackButton')),
    );

    expect(headerRect.top, 0);
    expect(headerRect.height, 100);
    expect(backRect.top, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets('verification keypad fills four year boxes', (tester) async {
    await _setViewport(tester, const Size(390, 868));
    await tester.pumpWidget(
      _membershipTestApp(const MembershipVerificationScreen()),
    );
    await tester.pump();

    for (final digit in ['1', '9', '8', '0', '7']) {
      await tester.tap(
        find.byKey(ValueKey('membershipVerificationDigit$digit')),
      );
      await tester.pump();
    }

    expect(find.text('1'), findsWidgets);
    expect(find.text('9'), findsWidgets);
    expect(find.text('8'), findsWidgets);
    expect(find.text('0'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Widget _membershipTestApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.lightTheme, home: home),
  );
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}
