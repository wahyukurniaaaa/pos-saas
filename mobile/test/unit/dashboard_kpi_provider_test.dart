// Task 9.6 — Unit tests for dashboardKpiProvider
// Validates: Requirements 10.2, 10.8, 15.3, 15.4

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('dashboardKpiProvider — source-level checks', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/dashboard/providers/dashboard_kpi_provider.dart',
      ).readAsStringSync();
    });

    test('_fetchKpiData() should use Future.wait([]) for parallel queries', () {
      expect(
        source.contains('Future.wait(['),
        isTrue,
        reason: 'dashboardKpiProvider must run all 8 KPI queries in parallel via Future.wait()',
      );
    });

    test('build() should register ref.onDispose()', () {
      expect(
        source.contains('ref.onDispose('),
        isTrue,
        reason: 'DashboardKpiNotifier must cancel timer and subscription on dispose',
      );
    });

    test('ref.onDispose() should cancel _debounceTimer', () {
      expect(
        source.contains('_debounceTimer?.cancel()'),
        isTrue,
        reason: '_debounceTimer must be cancelled in onDispose to prevent queries after dispose',
      );
    });

    test('ref.onDispose() should cancel _txnSubscription', () {
      expect(
        source.contains('_txnSubscription?.cancel()'),
        isTrue,
        reason: '_txnSubscription must be cancelled in onDispose to prevent memory leak',
      );
    });

    test('refresh() should call ref.invalidateSelf() without debounce', () {
      // Find the refresh() method
      final refreshIdx = source.indexOf('Future<void> refresh()');
      expect(refreshIdx, isNot(-1), reason: 'refresh() method should exist');

      final refreshBody = source.substring(refreshIdx, refreshIdx + 200);

      expect(
        refreshBody.contains('ref.invalidateSelf()'),
        isTrue,
        reason: 'refresh() must call invalidateSelf() immediately (no debounce)',
      );

      // Verify refresh() does NOT start a new timer (no debounce)
      expect(
        refreshBody.contains('Timer('),
        isFalse,
        reason: 'refresh() must NOT use a debounce timer — it should be immediate',
      );
    });

    test('DashboardKpiNotifier should use sessionProvider.select for outletId', () {
      expect(
        source.contains('sessionProvider.select'),
        isTrue,
        reason: 'DashboardKpiNotifier must use sessionProvider.select() to avoid unnecessary rebuilds',
      );
    });

    test('dashboardKpiProvider should be registered as AsyncNotifierProvider', () {
      expect(
        source.contains('AsyncNotifierProvider<DashboardKpiNotifier, DashboardKpiData>'),
        isTrue,
        reason: 'dashboardKpiProvider must be an AsyncNotifierProvider',
      );
    });
  });
}
