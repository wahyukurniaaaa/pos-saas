import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/main.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posify_app/core/database/database.dart';

class MockDatabase extends Mock implements PosifyDatabase {}

void main() {
  testWidgets('App renders LumioApp container', (WidgetTester tester) async {
    final mockDb = MockDatabase();
    
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
        child: const LumioApp(),
      ),
    );

    expect(find.byType(LumioApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
