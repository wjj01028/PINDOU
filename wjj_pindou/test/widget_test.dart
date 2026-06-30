// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:wjj_pindou/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const WjjPindouApp());

    // Verify that the app loads correctly
    expect(find.text('拼豆图纸生成器'), findsOneWidget);
  });
}
