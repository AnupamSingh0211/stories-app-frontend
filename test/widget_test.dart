import 'package:flutter_test/flutter_test.dart';

import 'package:dharma_app/main.dart';

void main() {
  testWidgets('shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Welcome to\nBedtime Stories'), findsOneWidget);
    expect(find.text('Browse as a Guest ->'), findsOneWidget);
  });
}
