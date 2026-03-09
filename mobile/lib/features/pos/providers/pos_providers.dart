import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

/// Provider for categories
class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    return db.getAllCategories();
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );

/// Provider for products
class ProductNotifier extends AsyncNotifier<List<Product>> {
  String? _searchQuery;
  int? _categoryId;

  @override
  Future<List<Product>> build() async {
    final db = ref.watch(databaseProvider);
    // TODO: Implement filtered query in database.dart
    final allProducts = await db.getAllProducts();

    return allProducts.where((p) {
      final matchesCategory =
          _categoryId == null || p.categoryId == _categoryId;
      final matchesSearch =
          _searchQuery == null ||
          p.name.toLowerCase().contains(_searchQuery!.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    ref.invalidateSelf();
  }

  void setCategory(int? id) {
    _categoryId = id;
    ref.invalidateSelf();
  }
}

final productProvider = AsyncNotifierProvider<ProductNotifier, List<Product>>(
  ProductNotifier.new,
);

/// Model for cart items
class CartItem {
  final Product product;
  final int quantity;

  CartItem({required this.product, this.quantity = 1});

  CartItem copyWith({int? quantity}) {
    return CartItem(product: product, quantity: quantity ?? this.quantity);
  }

  double get total => (product.price * quantity).toDouble();
}

/// Provider for shopping cart
class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(Product product) {
    final index = state.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product)];
    }
  }

  void removeFromCart(int productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    state = [
      for (final item in state)
        if (item.product.id == productId)
          item.copyWith(quantity: quantity)
        else
          item,
    ];
  }

  void clearCart() {
    state = [];
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.total);

  Future<bool> checkout({
    required int shiftId,
    required String paymentMethod,
    required double taxAmount,
    required double serviceCharge,
    int? voidBy,
  }) async {
    try {
      if (state.isEmpty) return false;

      final db = ref.read(databaseProvider);

      // Generate receipt number (POS-YYYYMMDD-HHMMSS)
      final now = DateTime.now();
      final receiptNumber =
          'POS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final total = subtotal + taxAmount + serviceCharge;

      final transactionEntry = TransactionsCompanion.insert(
        receiptNumber: receiptNumber,
        shiftId: shiftId,
        subtotal: subtotal.toInt(),
        taxAmount: drift.Value(taxAmount.toInt()),
        serviceChargeAmount: drift.Value(serviceCharge.toInt()),
        totalAmount: total.toInt(),
        paymentMethod: paymentMethod,
      );

      final itemsParams = state.map((item) {
        return TransactionItemsCompanion.insert(
          transactionId: 0, // Will be overridden in processCheckout
          productId: item.product.id,
          quantity: item.quantity,
          priceAtTransaction: item.product.price,
          subtotal: item.total.toInt(),
        );
      }).toList();

      await db.processCheckout(
        transactionEntry: transactionEntry,
        itemsParams: itemsParams,
      );

      ref.invalidate(productProvider);
      clearCart();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('Checkout error: $e');
      return false;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
