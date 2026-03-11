import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

// ===== Category Provider =====

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    db.watchAllCategories().listen((categories) {
      if (ref.mounted) state = AsyncValue.data(categories);
    });
    return db.getAllCategories();
  }
}

final categoryProvider =
    AsyncNotifierProvider<CategoryNotifier, List<Category>>(
      CategoryNotifier.new,
    );

// ===== Product Provider =====

class ProductNotifier extends AsyncNotifier<List<Product>> {
  String? _searchQuery;
  int? _categoryId;

  @override
  Future<List<Product>> build() async {
    final db = ref.watch(databaseProvider);
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

// ===== Cart Model =====

/// Represents one line in the shopping cart.
/// Supports both simple products and variable products (with variants).
class CartItem {
  final Product product;
  final ProductVariant? variant; // null = simple product
  final int quantity;

  CartItem({required this.product, this.variant, this.quantity = 1});

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }

  /// Variant price takes priority over product base price.
  int get effectivePrice =>
      (variant?.price != null && variant!.price! > 0)
          ? variant!.price!
          : product.price;

  double get total => (effectivePrice * quantity).toDouble();

  /// Unique key: same product with different variants = different cart lines.
  String get cartKey =>
      variant != null ? '${product.id}_v${variant!.id}' : '${product.id}';
}

// ===== Cart Provider =====

class CartNotifier extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(Product product, {ProductVariant? variant}) {
    final key =
        variant != null ? '${product.id}_v${variant.id}' : '${product.id}';
    final index = state.indexWhere((item) => item.cartKey == key);
    if (index >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == index)
            state[i].copyWith(quantity: state[i].quantity + 1)
          else
            state[i],
      ];
    } else {
      state = [...state, CartItem(product: product, variant: variant)];
    }
  }

  void removeFromCart(String cartKey) {
    state = state.where((item) => item.cartKey != cartKey).toList();
  }

  void updateQuantity(String cartKey, int quantity) {
    if (quantity <= 0) {
      removeFromCart(cartKey);
      return;
    }
    state = [
      for (final item in state)
        if (item.cartKey == cartKey) item.copyWith(quantity: quantity) else item,
    ];
  }

  void clearCart() => state = [];

  double get subtotal => state.fold(0, (sum, item) => sum + item.total);

  Future<int?> checkout({
    required int shiftId,
    required String paymentMethod,
    required double taxAmount,
    required double serviceCharge,
    String? customerPhone,
    String? customerName,
  }) async {
    try {
      if (state.isEmpty) return null;

      final db = ref.read(databaseProvider);
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
        customerPhone: drift.Value(customerPhone),
        customerName: drift.Value(customerName),
      );

      final itemsParams = state.map((item) {
        // Snapshot variant label for permanent audit trail on receipts/history
        final variantLabel = item.variant != null
            ? '${item.variant!.name}: ${item.variant!.optionValue}'
            : null;

        return TransactionItemsCompanion.insert(
          transactionId: 0, // Overridden by processCheckout
          productId: item.product.id,
          variantId: drift.Value(item.variant?.id),
          variantName: drift.Value(variantLabel),
          quantity: item.quantity,
          priceAtTransaction: item.effectivePrice,
          subtotal: item.total.toInt(),
        );
      }).toList();

      final id = await db.processCheckout(
        transactionEntry: transactionEntry,
        itemsParams: itemsParams,
      );

      ref.invalidate(productProvider);
      clearCart();
      return id;
    } catch (e) {
      // ignore: avoid_print
      print('Checkout error: $e');
      return null;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);
