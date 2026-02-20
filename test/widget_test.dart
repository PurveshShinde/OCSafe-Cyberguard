import 'package:flutter_test/flutter_test.dart';
import 'package:ocsafe_cyberguard/main.dart';

void main() {
  testWidgets('App renders smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const OcSafeApp());
    expect(find.text('OcSafe'), findsOneWidget);
  });
}
