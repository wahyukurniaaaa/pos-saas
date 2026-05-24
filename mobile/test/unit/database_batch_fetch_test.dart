// Task 9.2 — Unit tests for LumioDatabase batch-fetch methods
// Validates: Requirements 3.2, 3.3, 3.4, 9.3, 9.4, 9.5

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/database/database.dart';

void main() {
  late LumioDatabase db;

  setUp(() async {
    db = LumioDatabase.forTesting(NativeDatabase.memory());
    // Disable FK constraints for test isolation — we test query logic, not schema
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to insert a product
  Future<void> insertProduct(
    String id,
    String name,
    String sku,
    int price,
  ) async {
    final now = DateTime.now();
    await db.into(db.products).insert(
      ProductsCompanion.insert(
        id: Value(id),
        name: name,
        price: price,
        categoryId: 'cat-1',
        sku: sku,
        outletId: const Value('outlet-1'),
        hasVariants: const Value(false),
        stock: const Value(10),
        lowStockThreshold: const Value(0),
        purchasePrice: const Value(0),
        createdAt: Value(now),
        updatedAt: Value(now),
        isDirty: const Value(false),
      ),
    );
  }

  group('getProductsByIds()', () {
    test('returns empty list for empty input without querying', () async {
      final result = await db.getProductsByIds([]);
      expect(result, isEmpty);
    });

    test('returns only matching products, not all products', () async {
      await insertProduct('prod-1', 'Product One', 'SKU001', 10000);
      await insertProduct('prod-2', 'Product Two', 'SKU002', 20000);

      // Only fetch prod-1
      final result = await db.getProductsByIds(['prod-1']);
      expect(result.length, 1);
      expect(result.first.id, 'prod-1');
      expect(result.first.name, 'Product One');
    });

    test('returns multiple matching products', () async {
      for (int i = 1; i <= 3; i++) {
        await insertProduct('prod-$i', 'Product $i', 'SKU00$i', i * 10000);
      }

      final result = await db.getProductsByIds(['prod-1', 'prod-3']);
      expect(result.length, 2);
      final ids = result.map((p) => p.id).toSet();
      expect(ids, containsAll(['prod-1', 'prod-3']));
      expect(ids, isNot(contains('prod-2')));
    });

    test('returns empty list when no IDs match', () async {
      await insertProduct('prod-1', 'Product One', 'SKU001', 10000);

      final result = await db.getProductsByIds(['nonexistent-id']);
      expect(result, isEmpty);
    });
  });

  group('getVariantsByIds()', () {
    test('returns empty list for empty input', () async {
      final result = await db.getVariantsByIds([]);
      expect(result, isEmpty);
    });

    test('returns matching variants', () async {
      final now = DateTime.now();
      // Insert a product first (FK disabled, but insert for data integrity)
      await insertProduct('prod-1', 'Product One', 'SKU001', 10000);

      await db.into(db.productVariants).insert(
        ProductVariantsCompanion.insert(
          id: const Value('var-1'),
          productId: 'prod-1',
          name: 'Size',
          optionValue: 'L',
          stock: const Value(5),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(false),
        ),
      );
      await db.into(db.productVariants).insert(
        ProductVariantsCompanion.insert(
          id: const Value('var-2'),
          productId: 'prod-1',
          name: 'Size',
          optionValue: 'XL',
          stock: const Value(3),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(false),
        ),
      );

      final result = await db.getVariantsByIds(['var-1']);
      expect(result.length, 1);
      expect(result.first.id, 'var-1');
      expect(result.first.optionValue, 'L');
    });

    test('returns empty list when no IDs match', () async {
      final result = await db.getVariantsByIds(['nonexistent-var']);
      expect(result, isEmpty);
    });
  });

  group('getDiscountsByIds()', () {
    test('returns empty list for empty input', () async {
      final result = await db.getDiscountsByIds([]);
      expect(result, isEmpty);
    });

    test('returns matching discounts', () async {
      final now = DateTime.now();
      await db.into(db.discounts).insert(
        DiscountsCompanion.insert(
          id: const Value('disc-1'),
          name: 'Diskon 10%',
          value: 10.0,
          scope: const Value('transaction'),
          type: const Value('percentage'),
          outletId: const Value('outlet-1'),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(false),
        ),
      );

      final result = await db.getDiscountsByIds(['disc-1']);
      expect(result.length, 1);
      expect(result.first.id, 'disc-1');
      expect(result.first.name, 'Diskon 10%');
    });

    test('returns empty list when no IDs match', () async {
      final result = await db.getDiscountsByIds(['nonexistent-disc']);
      expect(result, isEmpty);
    });
  });

  group('getCustomerById()', () {
    test('returns Customer for valid ID', () async {
      final now = DateTime.now();
      await db.into(db.customers).insert(
        CustomersCompanion.insert(
          id: const Value('cust-1'),
          name: 'Budi Santoso',
          outletId: const Value('outlet-1'),
          isMember: const Value(true),
          points: const Value(100),
          createdAt: Value(now),
          updatedAt: Value(now),
          isDirty: const Value(false),
        ),
      );

      final result = await db.getCustomerById('cust-1');
      expect(result, isNotNull);
      expect(result!.id, 'cust-1');
      expect(result.name, 'Budi Santoso');
      expect(result.points, 100);
    });

    test('returns null for nonexistent ID', () async {
      final result = await db.getCustomerById('nonexistent-id');
      expect(result, isNull);
    });

    test('returns null when database is empty', () async {
      final result = await db.getCustomerById('any-id');
      expect(result, isNull);
    });
  });
}
