import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

// ===== Category Provider =====

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    
    // Listen to changes and apply dummy if empty
    db.watchAllCategories().listen((categories) {
      if (ref.mounted) {
        state = AsyncValue.data(categories.isEmpty ? _getDummyCategories() : categories);
      }
    });

    final all = await db.getAllCategories();
    return all.isEmpty ? _getDummyCategories() : all;
  }

  List<Category> _getDummyCategories() {
    return [
      Category(id: 1, name: 'Makanan'),
      Category(id: 2, name: 'Minuman'),
      Category(id: 3, name: 'Camilan'),
    ];
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

// ===== Product with Variants Provider (for Inventory/Opname) =====

class ProductWithVariantsNotifier extends AsyncNotifier<List<ProductWithVariants>> {
  String? _searchQuery;
  int? _categoryId;

  @override
  Future<List<ProductWithVariants>> build() async {
    final db = ref.watch(databaseProvider);
    
    // Start watching the stream for updates
    final subscription = db.watchAllProductsWithVariants().listen((data) {
      if (ref.mounted) {
        state = AsyncValue.data(_filter(data));
      }
    });

    ref.onDispose(() => subscription.cancel());

    // Pull initial data directly for the build phase
    final initialData = await db.getAllProductsWithVariants();
    return _filter(initialData);
  }

  List<ProductWithVariants> _filter(List<ProductWithVariants> data) {
    return data.where((pwv) {
      final matchesCategory = _categoryId == null || pwv.product.categoryId == _categoryId;
      final matchesSearch = _searchQuery == null ||
          pwv.product.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          pwv.product.sku.toLowerCase().contains(_searchQuery!.toLowerCase());
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

final productWithVariantsProvider =
    AsyncNotifierProvider<ProductWithVariantsNotifier, List<ProductWithVariants>>(
      ProductWithVariantsNotifier.new,
    );

// ===== Ingredient Provider =====

class IngredientNotifier extends AsyncNotifier<List<Ingredient>> {
  String? _searchQuery;

  @override
  Future<List<Ingredient>> build() async {
    final db = ref.watch(databaseProvider);
    
    final subscription = db.watchAllIngredients().listen((data) {
      if (ref.mounted) {
        state = AsyncValue.data(_filter(data));
      }
    });

    ref.onDispose(() => subscription.cancel());

    final initialData = await db.getAllIngredients();
    return _filter(initialData);
  }

  List<Ingredient> _filter(List<Ingredient> data) {
    if (_searchQuery == null || _searchQuery!.isEmpty) return data;
    return data.where((i) => i.name.toLowerCase().contains(_searchQuery!.toLowerCase())).toList();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    ref.invalidateSelf();
  }
}

final ingredientProvider = AsyncNotifierProvider<IngredientNotifier, List<Ingredient>>(
  IngredientNotifier.new,
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
    int? customerId,
    int? discountId,
    int discountAmount = 0,
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
        customerId: drift.Value(customerId),
        discountId: drift.Value(discountId),
        discountAmount: drift.Value(discountAmount),
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
      debugPrint('Checkout error: $e');
      return null;
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, List<CartItem>>(
  CartNotifier.new,
);

// ===== History Filter Provider =====

enum HistoryFilterType {
  currentShift,
  today,
  thisWeek,
  thisMonth,
  thisYear,
  custom
}

class HistoryFilter {
  final HistoryFilterType type;
  final DateTimeRange? range;

  HistoryFilter({required this.type, this.range});

  String get label {
    switch (type) {
      case HistoryFilterType.currentShift:
        return 'Shift Sekarang';
      case HistoryFilterType.today:
        return 'Hari Ini';
      case HistoryFilterType.thisWeek:
        return 'Minggu Ini';
      case HistoryFilterType.thisMonth:
        return 'Bulan Ini';
      case HistoryFilterType.thisYear:
        return 'Tahun Ini';
      case HistoryFilterType.custom:
        return 'Pilih Tanggal';
    }
  }
}

class HistoryFilterNotifier extends Notifier<HistoryFilter> {
  @override
  HistoryFilter build() {
    return HistoryFilter(type: HistoryFilterType.currentShift);
  }

  void setFilter(HistoryFilter filter) {
    state = filter;
  }
}

final historyFilterProvider = NotifierProvider<HistoryFilterNotifier, HistoryFilter>(
  HistoryFilterNotifier.new,
);

// ===== Customer Provider =====

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final db = ref.watch(databaseProvider);
    db.watchAllCustomers().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });
    return db.watchAllCustomers().first;
  }
}

final customerProvider = AsyncNotifierProvider<CustomerNotifier, List<Customer>>(
  CustomerNotifier.new,
);

// ===== Supplier Provider =====

class SupplierNotifier extends AsyncNotifier<List<Supplier>> {
  @override
  Future<List<Supplier>> build() async {
    final db = ref.watch(databaseProvider);
    db.watchAllSuppliers().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });
    return db.watchAllSuppliers().first;
  }
}

final supplierProvider = AsyncNotifierProvider<SupplierNotifier, List<Supplier>>(
  SupplierNotifier.new,
);

// ===== Stock History Provider =====

class StockHistoryNotifier extends AsyncNotifier<List<StockTransactionWithProduct>> {
  @override
  Future<List<StockTransactionWithProduct>> build() async {
    final db = ref.watch(databaseProvider);
    
    // Watch stream for updates
    db.watchAllStockTransactionsWithProduct().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });

    // Initial data
    final query = db.select(db.stockTransactions).join([
      drift.innerJoin(db.products, db.products.id.equalsExp(db.stockTransactions.productId)),
      drift.leftOuterJoin(db.productVariants, db.productVariants.id.equalsExp(db.stockTransactions.variantId)),
    ])..orderBy([drift.OrderingTerm.desc(db.stockTransactions.createdAt)]);

    final rows = await query.get();
    return rows.map((row) {
      return StockTransactionWithProduct(
        transaction: row.readTable(db.stockTransactions),
        product: row.readTable(db.products),
        variant: row.readTableOrNull(db.productVariants),
      );
    }).toList();
  }
}

final stockHistoryProvider = AsyncNotifierProvider<StockHistoryNotifier, List<StockTransactionWithProduct>>(
  StockHistoryNotifier.new,
);
