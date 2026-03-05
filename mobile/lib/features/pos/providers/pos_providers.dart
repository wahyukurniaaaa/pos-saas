import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

/// Provider for categories
class CategoryNotifier extends AutoDisposeAsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    return db.getAllCategories();
  }
}

final categoryProvider =
    AsyncNotifierProvider.autoDispose<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );

/// Provider for products
class ProductNotifier extends AutoDisposeAsyncNotifier<List<Product>> {
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

final productProvider =
    AsyncNotifierProvider.autoDispose<ProductNotifier, List<Product>>(
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

  double get total => product.price * quantity;
}

/// Provider for shopping cart
class CartNotifier extends AutoDisposeNotifier<List<CartItem>> {
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
}

final cartProvider = NotifierProvider.autoDispose<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
