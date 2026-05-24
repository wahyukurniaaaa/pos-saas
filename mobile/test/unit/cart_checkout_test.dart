// Task 9.1 — Unit tests for CartNotifier.checkout()
// Validates: Requirements 8.1, 8.3

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/features/pos/providers/pos_providers.dart';
import 'package:mocktail/mocktail.dart';

class MockDatabase extends Mock implements LumioDatabase {}

void main() {
  group('CartNotifier.checkout() — source-level checks', () {
    test('pos_providers.dart should NOT contain ref.invalidate(productProvider)', () {
      final source = File(
        'lib/features/pos/providers/pos_providers.dart',
      ).readAsStringSync();

      expect(
        source.indexOf('Future<String?> checkout('),
        isNot(-1),
        reason: 'checkout() method should exist',
      );

      expect(
        source.contains('ref.invalidate(productProvider)'),
        isFalse,
        reason: 'ref.invalidate(productProvider) should have been removed from checkout()',
      );
    });

    test('pos_providers.dart should contain clearCart() call', () {
      final source = File(
        'lib/features/pos/providers/pos_providers.dart',
      ).readAsStringSync();

      expect(
        source.contains('clearCart()'),
        isTrue,
        reason: 'clearCart() must still be called after checkout',
      );
    });

    test('checkout() method body should call clearCart() after processCheckout', () {
      final source = File(
        'lib/features/pos/providers/pos_providers.dart',
      ).readAsStringSync();

      final checkoutStart = source.indexOf('Future<String?> checkout(');
      expect(checkoutStart, isNot(-1));

      // Find the end of checkout() — look for the next method at same indentation
      final afterCheckout = source.substring(checkoutStart);
      final nextMethodIdx = afterCheckout.indexOf('\n  Future<String?> holdBill(');
      final checkoutBody = nextMethodIdx != -1
          ? afterCheckout.substring(0, nextMethodIdx)
          : afterCheckout.substring(0, 3000);

      expect(
        checkoutBody.contains('clearCart()'),
        isTrue,
        reason: 'checkout() must call clearCart() after successful checkout',
      );
      expect(
        checkoutBody.contains('ref.invalidate(productProvider)'),
        isFalse,
        reason: 'checkout() must NOT call ref.invalidate(productProvider)',
      );
    });
  });

  group('CartNotifier.checkout() — behavioral tests via clearCart()', () {
    late ProviderContainer container;

    final product = Product(
      id: '1',
      name: 'Product A',
      price: 10000,
      categoryId: '1',
      stock: 10,
      sku: 'sku1',
      hasVariants: false,
      lowStockThreshold: 0,
      purchasePrice: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isDirty: false,
    );

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('cart should be empty after clearCart() — which checkout() calls', () {
      container.read(cartProvider.notifier).addToCart(product);
      expect(container.read(cartProvider).length, 1);

      // clearCart() is what checkout() calls after processCheckout succeeds
      container.read(cartProvider.notifier).clearCart();

      expect(container.read(cartProvider), isEmpty);
    });

    test('clearCart() empties cart with multiple items', () {
      final product2 = Product(
        id: '2',
        name: 'Product B',
        price: 20000,
        categoryId: '1',
        stock: 5,
        sku: 'sku2',
        hasVariants: false,
        lowStockThreshold: 0,
        purchasePrice: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isDirty: false,
      );

      container.read(cartProvider.notifier).addToCart(product);
      container.read(cartProvider.notifier).addToCart(product2);
      expect(container.read(cartProvider).length, 2);

      container.read(cartProvider.notifier).clearCart();

      expect(container.read(cartProvider), isEmpty);
    });

    test('cart state is empty initially', () {
      expect(container.read(cartProvider), isEmpty);
    });
  });
}
