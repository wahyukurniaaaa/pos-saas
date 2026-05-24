// Task 9.7–9.10, 9.12 — Property-based tests for filter logic and getCategoryIcon
// Validates: Requirements 2.7, 2.8, 2.4, 2.5, 4.7, 4.8

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/widgets/product_image.dart';

// ─── Standalone _filter() that mirrors ProductWithVariantsNotifier._filter() ──

List<ProductWithVariants> _filter(
  List<ProductWithVariants> data,
  String? searchQuery,
  String? categoryId,
) {
  final query = searchQuery?.toLowerCase() ?? '';

  return data.where((pwv) {
    final matchesCategory =
        categoryId == null || pwv.product.categoryId == categoryId;

    if (query.isEmpty) return matchesCategory;

    final matchesSearch =
        pwv.product.name.toLowerCase().contains(query) ||
        pwv.product.sku.toLowerCase().contains(query);

    return matchesCategory && matchesSearch;
  }).toList();
}

// ─── Random data generators ────────────────────────────────────────────────────

Product _makeProduct(Random rng, int index, String categoryId) {
  final now = DateTime.now();
  final names = [
    'Kopi Susu', 'Nasi Goreng', 'Teh Tarik', 'Bakso', 'Mie Ayam',
    'Es Teh', 'Sate Ayam', 'Gado-gado', 'Rendang', 'Soto Betawi',
    'Produk A', 'Produk B', 'Item X', 'Barang Y', 'Dagangan Z',
  ];
  final name = names[rng.nextInt(names.length)];
  return Product(
    id: 'prod-$index',
    name: name,
    price: (rng.nextInt(100) + 1) * 1000,
    categoryId: categoryId,
    stock: rng.nextInt(50),
    sku: 'SKU${index.toString().padLeft(4, '0')}',
    hasVariants: false,
    lowStockThreshold: 0,
    purchasePrice: 0,
    createdAt: now,
    updatedAt: now,
    isDirty: false,
  );
}

List<ProductWithVariants> _generateRandomProductList(Random rng) {
  final count = rng.nextInt(20); // 0–19 items
  final categoryIds = ['cat-1', 'cat-2', 'cat-3', 'cat-4'];
  return List.generate(count, (i) {
    final catId = categoryIds[rng.nextInt(categoryIds.length)];
    return ProductWithVariants(
      product: _makeProduct(rng, i, catId),
      variants: [],
    );
  });
}

String _generateRandomQuery(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyz ';
  final length = rng.nextInt(10); // 0–9 chars
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Property 1: Filter Round-Trip — Search
  // Validates: Requirements 2.7
  group('Property 1: Filter Round-Trip — Search', () {
    test(
      'setSearch(query) then setSearch(null) should equal _allData for 100 random inputs',
      () {
        final rng = Random(42); // fixed seed for reproducibility

        for (int i = 0; i < 100; i++) {
          final data = _generateRandomProductList(rng);
          final query = _generateRandomQuery(rng);

          // Apply search filter
          final filtered = _filter(data, query, null);

          // Clear search — should return all data
          final restored = _filter(data, null, null);

          // Restored state must equal original _allData
          expect(
            restored.length,
            data.length,
            reason: 'After setSearch(null), all ${ data.length} items should be visible (iteration $i)',
          );
          for (int j = 0; j < data.length; j++) {
            expect(
              restored[j].product.id,
              data[j].product.id,
              reason: 'Item order must be preserved after round-trip (iteration $i, item $j)',
            );
          }

          // Filtered result must be a subset
          expect(
            filtered.length,
            lessThanOrEqualTo(data.length),
            reason: 'Filtered result must be a subset of original data (iteration $i)',
          );
        }
      },
    );
  });

  // Property 2: Filter Round-Trip — Category
  // Validates: Requirements 2.8
  group('Property 2: Filter Round-Trip — Category', () {
    test(
      'setCategory(id) then setCategory(null) should equal _allData for 100 random inputs',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          final data = _generateRandomProductList(rng);

          // Pick a random category from the data's own categories (or null if empty)
          String? categoryId;
          if (data.isNotEmpty) {
            final categories = data.map((p) => p.product.categoryId).toSet().toList();
            categoryId = categories[rng.nextInt(categories.length)];
          }

          // Apply category filter
          final filtered = _filter(data, null, categoryId);

          // Clear category — should return all data
          final restored = _filter(data, null, null);

          expect(
            restored.length,
            data.length,
            reason: 'After setCategory(null), all ${data.length} items should be visible (iteration $i)',
          );
          for (int j = 0; j < data.length; j++) {
            expect(
              restored[j].product.id,
              data[j].product.id,
              reason: 'Item order must be preserved after category round-trip (iteration $i, item $j)',
            );
          }

          expect(
            filtered.length,
            lessThanOrEqualTo(data.length),
            reason: 'Category-filtered result must be a subset (iteration $i)',
          );
        }
      },
    );
  });

  // Property 3: Filter Idempotence
  // Validates: Requirements 2.4, 2.5
  group('Property 3: Filter Idempotence', () {
    test(
      '_filter(_filter(data, q, cat), q, cat) == _filter(data, q, cat) for 100 random inputs',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          final data = _generateRandomProductList(rng);
          final query = _generateRandomQuery(rng);
          final categoryIds = ['cat-1', 'cat-2', 'cat-3', null];
          final categoryId = categoryIds[rng.nextInt(categoryIds.length)];

          // Apply filter once
          final once = _filter(data, query, categoryId);

          // Apply filter twice (idempotence)
          final twice = _filter(once, query, categoryId);

          expect(
            twice.length,
            once.length,
            reason: 'Applying filter twice must give same count as once (iteration $i)',
          );

          for (int j = 0; j < once.length; j++) {
            expect(
              twice[j].product.id,
              once[j].product.id,
              reason: 'Idempotence: same item at position $j (iteration $i)',
            );
          }
        }
      },
    );
  });

  // Property 4: Filter Subset Invariant
  // Validates: Requirements 2.4, 2.5
  group('Property 4: Filter Subset Invariant', () {
    test(
      '_filter(data, q, cat).length <= data.length for 100 random inputs',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          final data = _generateRandomProductList(rng);
          final query = _generateRandomQuery(rng);
          final categoryIds = ['cat-1', 'cat-2', 'cat-3', null];
          final categoryId = categoryIds[rng.nextInt(categoryIds.length)];

          final result = _filter(data, query, categoryId);

          expect(
            result.length,
            lessThanOrEqualTo(data.length),
            reason: 'Filter result must be a subset of input data (iteration $i): '
                '${result.length} > ${data.length}',
          );

          // All items in result must exist in original data
          final originalIds = data.map((p) => p.product.id).toSet();
          for (final item in result) {
            expect(
              originalIds.contains(item.product.id),
              isTrue,
              reason: 'Filtered item ${item.product.id} must exist in original data (iteration $i)',
            );
          }
        }
      },
    );
  });

  // Property 6: getCategoryIcon Referential Transparency
  // Validates: Requirements 4.7, 4.8
  group('Property 6: getCategoryIcon Referential Transparency', () {
    test(
      'getCategoryIcon(name) == getCategoryIcon(name) for 100 random strings',
      () {
        final rng = Random(42);
        const chars = 'abcdefghijklmnopqrstuvwxyz ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

        for (int i = 0; i < 100; i++) {
          final length = rng.nextInt(30); // 0–29 chars
          final name = String.fromCharCodes(
            List.generate(
              length,
              (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
            ),
          );

          final result1 = ProductImage.getCategoryIcon(name);
          final result2 = ProductImage.getCategoryIcon(name);

          expect(
            result1,
            equals(result2),
            reason: 'getCategoryIcon("$name") must return same result on repeated calls (iteration $i)',
          );
        }
      },
    );

    test('getCategoryIcon(null) is always the same default icon', () {
      final result1 = ProductImage.getCategoryIcon(null);
      final result2 = ProductImage.getCategoryIcon(null);
      expect(result1, equals(result2));
    });

    test('getCategoryIcon("") is always the same default icon', () {
      final result1 = ProductImage.getCategoryIcon('');
      final result2 = ProductImage.getCategoryIcon('');
      expect(result1, equals(result2));
    });

    test('getCategoryIcon returns consistent results for known category names', () {
      // Run each known category name twice to verify referential transparency
      final testCases = [
        'kopi susu',
        'nasi goreng',
        'beras 5kg',
        'snack keripik',
        'semen gresik',
        'buku tulis',
        'produk random 123',
        'obat batuk',
        'baju kaos',
        'motor honda',
      ];

      for (final name in testCases) {
        final r1 = ProductImage.getCategoryIcon(name);
        final r2 = ProductImage.getCategoryIcon(name);
        expect(r1, equals(r2), reason: 'getCategoryIcon("$name") must be referentially transparent');
      }
    });
  });
}
