import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  final productA = Product(
    id: 1,
    name: 'Product A',
    price: 10000,
    categoryId: 1,
    stock: 10,
    sku: 'sku1',
    hasVariants: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final productB = Product(
    id: 2,
    name: 'Product B',
    price: 20000,
    categoryId: 1,
    stock: 5,
    sku: 'sku2',
    hasVariants: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('CartNotifier', () {
    test('initial state should be empty', () {
      final cart = container.read(cartProvider);
      expect(cart, isEmpty);
    });

    test('addToCart should add a new item with quantity 1', () {
      container.read(cartProvider.notifier).addToCart(productA);
      final cart = container.read(cartProvider);
      
      expect(cart.length, 1);
      expect(cart[0].product.id, 1);
      expect(cart[0].quantity, 1);
    });

    test('addToCart should increment quantity for same product', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA);
      notifier.addToCart(productA);
      
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart[0].quantity, 2);
    });

    test('addToCart with different variants should create separate entries', () {
      final v1 = ProductVariant(
        id: 1, 
        productId: 1, 
        name: 'V1', 
        optionValue: 'A', 
        price: 10000, 
        stock: 10, 
        createdAt: DateTime.now()
      );
      final v2 = ProductVariant(
        id: 2, 
        productId: 1, 
        name: 'V2', 
        optionValue: 'B', 
        price: 12000, 
        stock: 5, 
        createdAt: DateTime.now()
      );
      
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA, variant: v1);
      notifier.addToCart(productA, variant: v2);
      
      final cart = container.read(cartProvider);
      expect(cart.length, 2);
      expect(cart[0].cartKey, '1_v1');
      expect(cart[1].cartKey, '1_v2');
    });

    test('updateQuantity should change quantity correctly', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA);
      final key = container.read(cartProvider)[0].cartKey;
      
      notifier.updateQuantity(key, 5);
      expect(container.read(cartProvider)[0].quantity, 5);
    });

    test('updateQuantity to 0 should remove item', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA);
      final key = container.read(cartProvider)[0].cartKey;
      
      notifier.updateQuantity(key, 0);
      expect(container.read(cartProvider), isEmpty);
    });

    test('removeFromCart should remove specific item', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA);
      notifier.addToCart(productB);
      
      final keyA = container.read(cartProvider).firstWhere((i) => i.product.id == 1).cartKey;
      notifier.removeFromCart(keyA);
      
      final cart = container.read(cartProvider);
      expect(cart.length, 1);
      expect(cart[0].product.id, 2);
    });

    test('clearCart should empty the list', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA);
      notifier.addToCart(productB);
      
      notifier.clearCart();
      expect(container.read(cartProvider), isEmpty);
    });

    test('subtotal should calculate correctly across items', () {
      final notifier = container.read(cartProvider.notifier);
      notifier.addToCart(productA); // 10000
      notifier.addToCart(productA); // +10000
      notifier.addToCart(productB); // +20000
      
      // subtotal is a getter on the notifier
      final subtotal = notifier.subtotal;
      expect(subtotal, 40000.0);
    });
  });
}
