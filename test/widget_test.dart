import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/features/auth/assets_provider.dart';
import 'package:dharma_app/main.dart';

void main() {
  testWidgets('shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appAssetsProvider.overrideWithValue({
            'welcome_bg': 'https://example.com/welcome_bg.webp',
            'profile_setup_bg': 'https://example.com/profile_setup_bg.webp',
            'ios_icon': 'https://example.com/ios_icon.png',
            'google_icon': 'https://example.com/google_icon.png',
            'email_icon': 'https://example.com/email_icon.png',
          }),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Welcome to\nBedtime Stories'), findsOneWidget);
    expect(find.text('Browse as a Guest ->'), findsOneWidget);
  });
}
