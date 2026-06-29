import 'dart:io';

import 'package:dharma_app/features/membership/membership_plans_screen.dart';
import 'package:dharma_app/features/membership/membership_screen.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('See All Plans opens the monthly Figma state and back returns', (
    tester,
  ) async {
    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MembershipScreen()),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('membershipSeeAllPlansButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MembershipPlansScreen), findsOneWidget);
    expect(find.text('Continue with Monthly'), findsOneWidget);
    expect(_isSelected(tester, 'monthlyPlanCard'), isTrue);
    expect(_isSelected(tester, 'annualPlanCard'), isFalse);

    await tester.tap(find.byKey(const ValueKey('membershipPlansBackButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MembershipPlansScreen), findsNothing);
    expect(find.byType(MembershipScreen), findsOneWidget);
  });

  testWidgets('plan cards switch between exact monthly and annual states', (
    tester,
  ) async {
    await _pumpPlans(tester, const Size(390, 844));

    await tester.tap(find.byKey(const ValueKey('annualPlanCard')));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'monthlyPlanCard'), isFalse);
    expect(_isSelected(tester, 'annualPlanCard'), isTrue);
    expect(find.text('Continue with Annually'), findsOneWidget);
    expect(find.text('Continue with Monthly'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('monthlyPlanCard')));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'monthlyPlanCard'), isTrue);
    expect(_isSelected(tester, 'annualPlanCard'), isFalse);
    expect(find.text('Continue with Monthly'), findsOneWidget);
  });

  testWidgets('continue and promo callbacks remain isolated for integration', (
    tester,
  ) async {
    MembershipPlan? continuedPlan;
    var promoTaps = 0;

    await _setViewport(tester, const Size(390, 844));
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: MembershipPlansScreen(
          onContinue: (plan) => continuedPlan = plan,
          onPromoCode: () => promoTaps++,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('annualPlanCard')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('membershipPlansContinueButton')),
    );
    await tester.tap(find.byKey(const ValueKey('membershipPromoCodeButton')));

    expect(continuedPlan, MembershipPlan.annual);
    expect(promoTaps, 1);
  });

  testWidgets('plans match the 390 by 844 Figma reference geometry', (
    tester,
  ) async {
    await _pumpPlans(tester, const Size(390, 844));

    final intro = find.byKey(const ValueKey('membershipPlansIntro'));
    final hero = find.byKey(const ValueKey('membershipPlansHero'));
    final benefits = find.byKey(const ValueKey('membershipPlansBenefits'));
    final monthly = find.byKey(const ValueKey('monthlyPlanCard'));
    final annual = find.byKey(const ValueKey('annualPlanCard'));
    final promoText = find.byKey(const ValueKey('membershipPromoCodeText'));
    final continueButton = find.byKey(
      const ValueKey('membershipPlansContinueButton'),
    );
    final trust = find.byKey(const ValueKey('membershipTrustIndicators'));

    expect(tester.getTopLeft(intro).dy, 63);
    expect(tester.getTopLeft(hero), const Offset(92, 135));
    expect(tester.getSize(hero).width, closeTo(209.567, 0.001));
    expect(tester.getSize(hero).height, 176);
    expect(tester.getTopLeft(benefits).dy, 327);
    expect(tester.getTopLeft(monthly), const Offset(22, 485));
    expect(tester.getSize(monthly), const Size(350, 70));
    expect(tester.getTopLeft(annual), const Offset(22, 571));
    expect(tester.getSize(annual), const Size(350, 70));
    expect(tester.getTopLeft(promoText).dy, 663);
    expect(tester.getTopLeft(continueButton), const Offset(20, 730));
    expect(tester.getSize(continueButton), const Size(350, 52));
    expect(tester.getTopLeft(trust).dy, 801);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plans use available width on wider screens', (tester) async {
    await _pumpPlans(tester, const Size(500, 844));

    final monthly = find.byKey(const ValueKey('monthlyPlanCard'));
    final continueButton = find.byKey(
      const ValueKey('membershipPlansContinueButton'),
    );
    final hero = find.byKey(const ValueKey('membershipPlansHero'));

    expect(tester.getTopLeft(monthly).dx, 22);
    expect(tester.getSize(monthly).width, 460);
    expect(tester.getTopLeft(continueButton).dx, 20);
    expect(tester.getSize(continueButton).width, 460);
    expect(tester.getCenter(hero).dx, closeTo(251.7835, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plans remain overflow-free on a compact viewport', (
    tester,
  ) async {
    await _pumpPlans(tester, const Size(320, 568));

    expect(find.text('Premium Membership'), findsOneWidget);
    expect(find.text('Continue with Monthly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('plans implementation has no network image dependency', () {
    final source = File(
      'lib/features/membership/membership_plans_screen.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('http://')));
    expect(source, isNot(contains('https://')));
    expect(source, isNot(contains('Image.network')));
    expect(source, isNot(contains('CachedNetworkImage')));
  });
}

Future<void> _pumpPlans(WidgetTester tester, Size size) async {
  await _setViewport(tester, size);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.lightTheme,
      home: const MembershipPlansScreen(),
    ),
  );
  await tester.pump();
}

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

bool _isSelected(WidgetTester tester, String key) {
  return tester
          .widget<Semantics>(find.byKey(ValueKey(key)))
          .properties
          .selected ??
      false;
}
