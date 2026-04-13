import 'package:flutter_test/flutter_test.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';

void main() {
  group('CartItem', () {
    final product = Product(
      id: '1',
      name: 'Test Product',
      price: 10000,
      categoryId: '1',
      stock: 10,
      sku: 'SKU123',
      hasVariants: false,
      lowStockThreshold: 0,
      purchasePrice: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('effectivePrice should fallback to product price when variant is null', () {
      final cartItem = CartItem(product: product, quantity: 2);
      expect(cartItem.effectivePrice, 10000);
    });

    test('effectivePrice should use variant price when available', () {
      final variant = ProductVariant(
        id: '10',
        productId: '1',
        name: 'Size',
        optionValue: 'Large',
        price: 15000,
        stock: 5,
        createdAt: DateTime.now(),
      );
      final cartItem = CartItem(product: product, variant: variant, quantity: 1);
      expect(cartItem.effectivePrice, 15000);
    });

    test('total should calculate correctly (price * quantity)', () {
      final cartItem = CartItem(product: product, quantity: 3);
      expect(cartItem.total, 30000.0);
    });

    test('cartKey should be product id for simple products', () {
      final cartItem = CartItem(product: product, quantity: 1);
      expect(cartItem.cartKey, '1');
    });

    test('cartKey should include variant id for variable products', () {
      final variant = ProductVariant(
        id: '10',
        productId: '1',
        name: 'Size',
        optionValue: 'Large',
        price: 15000,
        stock: 5,
        createdAt: DateTime.now(),
      );
      final cartItem = CartItem(product: product, variant: variant, quantity: 1);
      expect(cartItem.cartKey, '1_v10');
    });

    test('copyWith should update quantity correctly', () {
      final cartItem = CartItem(product: product, quantity: 1);
      final updated = cartItem.copyWith(quantity: 5);
      expect(updated.quantity, 5);
      expect(updated.product.id, '1');
    });
  });
}
