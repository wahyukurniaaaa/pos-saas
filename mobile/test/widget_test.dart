import 'package:flutter_test/flutter_test.dart';
import 'package:posify_app/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const PosifyApp());
    expect(find.text('POSify'), findsOneWidget);
  });
}
