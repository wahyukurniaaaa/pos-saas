// Task 9.5 — Unit tests for DiscountNotifier
// Validates: Requirements 6.2, 7.2, 7.3

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DiscountNotifier — source-level checks', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/pos/providers/discount_provider.dart',
      ).readAsStringSync();
    });

    test('DiscountNotifier.build() should use ref.onDispose to cancel subscription', () {
      expect(
        source.contains('ref.onDispose(() => subscription.cancel())'),
        isTrue,
        reason: 'DiscountNotifier must cancel stream subscription on dispose to prevent memory leak',
      );
    });

    test('DiscountNotifier.build() should use sessionProvider.select for outletId', () {
      // Find DiscountNotifier class
      final classStart = source.indexOf('class DiscountNotifier');
      expect(classStart, isNot(-1), reason: 'DiscountNotifier class should exist');

      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      expect(
        classBody.contains('sessionProvider.select'),
        isTrue,
        reason: 'DiscountNotifier must use sessionProvider.select() to avoid unnecessary rebuilds',
      );
    });

    test('validTransactionDiscountsProvider should use sessionProvider.select', () {
      expect(
        source.contains('validTransactionDiscountsProvider'),
        isTrue,
        reason: 'validTransactionDiscountsProvider should exist',
      );

      // Find the provider definition
      final providerIdx = source.indexOf('validTransactionDiscountsProvider');
      final providerBody = source.substring(providerIdx, providerIdx + 500);

      expect(
        providerBody.contains('sessionProvider.select'),
        isTrue,
        reason: 'validTransactionDiscountsProvider must use sessionProvider.select()',
      );
    });

    test('validItemDiscountsProvider should use sessionProvider.select', () {
      expect(
        source.contains('validItemDiscountsProvider'),
        isTrue,
        reason: 'validItemDiscountsProvider should exist',
      );

      final providerIdx = source.indexOf('validItemDiscountsProvider');
      final providerBody = source.substring(providerIdx, providerIdx + 500);

      expect(
        providerBody.contains('sessionProvider.select'),
        isTrue,
        reason: 'validItemDiscountsProvider must use sessionProvider.select()',
      );
    });
  });
}
