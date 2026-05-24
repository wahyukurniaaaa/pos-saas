// Task 9.4 — Unit tests for ProductImage widget
// Validates: Requirements 4.1, 4.3, 12.1, 12.5

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductImage — source-level checks', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/core/widgets/product_image.dart',
      ).readAsStringSync();
    });

    test('ProductImage should extend StatelessWidget (not ConsumerWidget)', () {
      expect(
        source.contains('class ProductImage extends StatelessWidget'),
        isTrue,
        reason: 'ProductImage must be a StatelessWidget for performance (no Riverpod dependency)',
      );
      expect(
        source.contains('class ProductImage extends ConsumerWidget'),
        isFalse,
        reason: 'ProductImage must NOT be a ConsumerWidget',
      );
    });

    test('product_image.dart should NOT contain ref.watch()', () {
      expect(
        source.contains('ref.watch('),
        isFalse,
        reason: 'ProductImage must not call ref.watch() — it is a StatelessWidget',
      );
    });

    test('product_image.dart should NOT contain WidgetRef parameter in build()', () {
      expect(
        source.contains('WidgetRef ref'),
        isFalse,
        reason: 'StatelessWidget build() does not take WidgetRef',
      );
    });

    test('CachedNetworkImageProvider should be used for http URLs', () {
      expect(
        source.contains('CachedNetworkImageProvider'),
        isTrue,
        reason: 'ProductImage must use CachedNetworkImageProvider for network images',
      );
      // Verify it is used for http URLs
      expect(
        source.contains("startsWith('http')"),
        isTrue,
        reason: 'CachedNetworkImageProvider should be used for URLs starting with http',
      );
    });

    test('FileImage should be used for local paths', () {
      expect(
        source.contains('FileImage'),
        isTrue,
        reason: 'ProductImage must use FileImage for local file paths',
      );
    });

    test('constructor should have categoryName parameter (not categoryId)', () {
      expect(
        source.contains('categoryName'),
        isTrue,
        reason: 'ProductImage constructor must have categoryName parameter',
      );
      expect(
        source.contains('categoryId'),
        isFalse,
        reason: 'ProductImage must NOT have categoryId parameter — it was replaced by categoryName',
      );
    });

    test('getCategoryIcon should be a static method', () {
      expect(
        source.contains('static IconData getCategoryIcon('),
        isTrue,
        reason: 'getCategoryIcon must be a static method for pure function behavior',
      );
    });
  });
}
