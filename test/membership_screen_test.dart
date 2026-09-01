import 'package:dharma_app/features/auth/companions_provider.dart';
import 'package:dharma_app/features/auth/profile_notifier.dart';
import 'package:dharma_app/features/membership/membership_screen.dart';
import 'package:dharma_app/features/profile/profile_screen.dart';
import 'package:dharma_app/shared/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
      authOptions: const FlutterAuthClientOptions(
        localStorage: EmptyLocalStorage(),
        pkceAsyncStorage: _EmptyAsyncStorage(),
      ),
    );
  });

  testWidgets('subscription opens membership and back returns to profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          profileNotifierProvider.overrideWith(_EmptyProfileNotifier.new),
          companionsProvider.overrideWith((ref) async => const []),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Subscription'));
    await tester.pumpAndSettle();

    expect(find.byType(MembershipScreen), findsOneWidget);
    expect(find.text('Premium Membership'), findsOneWidget);
    expect(find.text('₹1'), findsOneWidget);
    expect(find.text('Unlock for ₹1'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('membershipUnlockButton')))
          .width,
      358,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('membershipUnlockButton')))
          .dy,
      745,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('membershipBackButton')));
    await tester.pumpAndSettle();

    expect(find.byType(MembershipScreen), findsNothing);
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Subscription'), findsOneWidget);
  });

  testWidgets('membership remains overflow-free on a compact viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_membershipTestApp(const MembershipScreen()));
    await tester.pump();

    expect(find.text('Premium Membership'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership status bar remains transparent over app background', (
    tester,
  ) async {
    await tester.pumpWidget(_membershipTestApp(const MembershipScreen()));
    await tester.pump();

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final statusBarColors = tester
        .widgetList<AnnotatedRegion<SystemUiOverlayStyle>>(
          find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        )
        .map((overlay) => overlay.value.statusBarColor);

    expect(scaffold.backgroundColor, Colors.transparent);
    expect(statusBarColors, contains(Colors.transparent));
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership header stays pinned while content scrolls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_membershipTestApp(const MembershipScreen()));
    await tester.pump();

    final backButton = find.byKey(const ValueKey('membershipBackButton'));
    final initialHeaderTop = tester.getTopLeft(backButton).dy;
    final initialOfferTop = tester
        .getTopLeft(find.text('Premium Access for 5 Days'))
        .dy;

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -180),
    );
    await tester.pump();

    expect(tester.getTopLeft(backButton).dy, initialHeaderTop);
    expect(
      tester.getTopLeft(find.text('Premium Access for 5 Days')).dy,
      lessThan(initialOfferTop),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('membership uses available width and height on wider screens', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 817);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_membershipTestApp(const MembershipScreen()));
    await tester.pump();

    final cta = find.byKey(const ValueKey('membershipUnlockButton'));
    final back = find.byKey(const ValueKey('membershipBackButton'));
    final hero = find.byKey(const ValueKey('membershipHeroImage'));

    expect(tester.getSize(cta).width, 358);
    expect(tester.getTopLeft(cta).dy, closeTo(955.128, 0.01));
    expect(tester.getTopLeft(back).dx, 16);
    expect(tester.getCenter(hero).dx, closeTo(249.111, 0.01));
    expect(tester.takeException(), isNull);
  });
}

Widget _membershipTestApp(Widget home) {
  return ProviderScope(
    child: MaterialApp(theme: AppTheme.lightTheme, home: home),
  );
}

class _EmptyProfileNotifier extends ProfileNotifier {
  @override
  Future<ChildProfilesState> build() async => const ChildProfilesState();
}

class _EmptyAsyncStorage extends GotrueAsyncStorage {
  const _EmptyAsyncStorage();

  @override
  Future<String?> getItem({required String key}) async => null;

  @override
  Future<void> removeItem({required String key}) async {}

  @override
  Future<void> setItem({required String key, required String value}) async {}
}
