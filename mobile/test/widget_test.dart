import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/main.dart';

void main() {
  testWidgets('App renders without crash', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: PosifyApp()));
    expect(find.byType(PosifyApp), findsOneWidget);
  });
}
