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
    expect(find.text('Subscribe Monthly'), findsOneWidget);
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
    expect(find.text('Subscribe Yearly'), findsOneWidget);
    expect(find.text('Subscribe Monthly'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('monthlyPlanCard')));
    await tester.pumpAndSettle();

    expect(_isSelected(tester, 'monthlyPlanCard'), isTrue);
    expect(_isSelected(tester, 'annualPlanCard'), isFalse);
    expect(find.text('Subscribe Monthly'), findsOneWidget);
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

  testWidgets('plans match the 390 by 868 Figma reference geometry', (
    tester,
  ) async {
    await _pumpPlans(tester, const Size(390, 868));

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

    expect(tester.getTopLeft(intro).dy, 98);
    expect(tester.getTopLeft(hero).dx, closeTo(136.693, 0.01));
    expect(tester.getTopLeft(hero).dy, 98);
    expect(tester.getSize(hero).width, closeTo(116.614, 0.001));
    expect(tester.getSize(hero).height, 152);
    expect(tester.getTopLeft(benefits).dy, 415);
    expect(tester.getTopLeft(monthly), const Offset(15, 597));
    expect(tester.getSize(monthly), const Size(171, 68));
    expect(tester.getTopLeft(annual), const Offset(198, 597));
    expect(tester.getSize(annual), const Size(171, 68));
    expect(tester.getTopLeft(promoText).dy, 692);
    expect(tester.getTopLeft(continueButton), const Offset(16, 751));
    expect(tester.getSize(continueButton), const Size(358, 52));
    expect(tester.getTopLeft(trust).dy, 823);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plans scale the Figma canvas on wider screens', (tester) async {
    await _pumpPlans(tester, const Size(500, 844));

    final monthly = find.byKey(const ValueKey('monthlyPlanCard'));
    final continueButton = find.byKey(
      const ValueKey('membershipPlansContinueButton'),
    );
    final hero = find.byKey(const ValueKey('membershipPlansHero'));

    expect(tester.getTopLeft(monthly).dx, closeTo(19.231, 0.01));
    expect(tester.getSize(monthly).width, 171);
    expect(tester.getTopLeft(continueButton).dx, closeTo(20.513, 0.01));
    expect(tester.getSize(continueButton).width, 358);
    expect(tester.getCenter(hero).dx, closeTo(250, 0.01));
    expect(tester.takeException(), isNull);
  });

  testWidgets('plans remain overflow-free on a compact viewport', (
    tester,
  ) async {
    await _pumpPlans(tester, const Size(320, 568));

    expect(find.text('Premium Membership'), findsOneWidget);
    expect(find.text('Subscribe Monthly'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('plans implementation uses Supabase mascot and bundled trust icons', () {
    final source = File(
      'lib/features/membership/membership_plans_screen.dart',
    ).readAsStringSync();

    expect(source, contains('membership_mascot_character.png'));
    expect(
      source,
      contains('assets/icons/new_boopi/State=Default, Icon=Shield Done.svg'),
    );
    expect(
      source,
      contains('assets/icons/new_boopi/State=Default, Icon=Close Square.svg'),
    );
    expect(
      source,
      contains('assets/icons/new_boopi/State=Default, Icon=3 User.svg'),
    );
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
