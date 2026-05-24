import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumio/main.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/providers/supabase_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lumio/core/database/database.dart';

class MockDatabase extends Mock implements LumioDatabase {}

void main() {
  testWidgets('App renders LumioApp container', (WidgetTester tester) async {
    final mockDb = MockDatabase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
          // Override Supabase session to null (not logged in) so AppBootstrap
          // shows LoginScreen without needing a real Supabase instance.
          supabaseSessionProvider.overrideWithValue(null),
        ],
        child: const LumioApp(),
      ),
    );

    expect(find.byType(LumioApp), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
