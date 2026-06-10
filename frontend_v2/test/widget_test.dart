import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend_v2/main.dart';

void main() {
  testWidgets('App launch smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    // Verify that the splash screen text is rendered initially
    expect(find.text('YOUR PERSONAL HEALTH INSIGHTS'), findsOneWidget);

    // Allow splash timer to complete and trigger redirect
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });
}
