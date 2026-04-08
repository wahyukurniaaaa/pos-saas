import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'cart_notes_provider.dart';
import 'selected_customer_provider.dart';
import 'split_payment_provider.dart';

// ===== Category Provider =====

class CategoryNotifier extends AsyncNotifier<List<Category>> {
  @override
  Future<List<Category>> build() async {
    final db = ref.watch(databaseProvider);
    
    final subscription = db.watchAllCategories().listen((categories) {
      if (ref.mounted) {
        state = AsyncValue.data(categories.isEmpty ? _getDummyCategories() : categories);
      }
    });

    ref.onDispose(() => subscription.cancel());

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
  List<Product> _allProducts = [];

  @override
  Future<List<Product>> build() async {
    final db = ref.watch(databaseProvider);

    // Stream for realtime updates
    final subscription = db.watchAllProducts().listen((products) {
      if (ref.mounted) {
        _allProducts = products;
        state = AsyncValue.data(_filter(products));
      }
    });

    ref.onDispose(() => subscription.cancel());

    _allProducts = await db.getAllProducts();
    return _filter(_allProducts);
  }

  List<Product> _filter(List<Product> products) {
    final query = _searchQuery?.toLowerCase() ?? '';
    
    return products.where((p) {
      final matchesCategory = _categoryId == null || p.categoryId == _categoryId;
      
      if (query.isEmpty) return matchesCategory;
      
      final matchesSearch =
          p.name.toLowerCase().contains(query) ||
          p.sku.toLowerCase().contains(query);
          
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setSearch(String? query) {
    _searchQuery = query;
    state = AsyncValue.data(_filter(_allProducts));
  }

  void setCategory(int? id) {
    _categoryId = id;
    state = AsyncValue.data(_filter(_allProducts));
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
    final query = _searchQuery?.toLowerCase() ?? '';
    
    return data.where((pwv) {
      final matchesCategory = _categoryId == null || pwv.product.categoryId == _categoryId;
      
      if (query.isEmpty) return matchesCategory;
      
      final matchesSearch = 
          pwv.product.name.toLowerCase().contains(query) ||
          pwv.product.sku.toLowerCase().contains(query);
          
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
  final Discount? appliedDiscount;

  CartItem({required this.product, this.variant, this.quantity = 1, this.appliedDiscount});

  CartItem copyWith({int? quantity, Discount? appliedDiscount, bool removeDiscount = false}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
      appliedDiscount: removeDiscount ? null : (appliedDiscount ?? this.appliedDiscount),
    );
  }

  /// Variant price takes priority over product base price.
  int get effectivePrice {
    final v = variant;
    if (v != null && v.price != null && v.price! > 0) {
      return v.price!;
    }
    return product.price;
  }

  int get itemDiscountAmount {
    final discount = appliedDiscount;
    if (discount == null) return 0;
    
    final baseAmount = effectivePrice * quantity;
    if (discount.type == 'fixed') {
      return discount.value.toInt().clamp(0, baseAmount);
    }
    // Percentage
    return ((baseAmount * discount.value / 100)).round().clamp(0, baseAmount);
  }

  double get total => ((effectivePrice * quantity) - itemDiscountAmount).toDouble();

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

  /// Alias for backward compatibility
  void addItem(Product product, [ProductVariant? variant]) =>
      addToCart(product, variant: variant);

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

  void updateItemDiscount(String cartKey, Discount? discount) {
    state = [
      for (final item in state)
        if (item.cartKey == cartKey) item.copyWith(appliedDiscount: discount, removeDiscount: discount == null) else item,
    ];
  }

  void clearCart() {
    state = [];
    ref.read(cartNotesProvider.notifier).state = null;
    // Clear customer info
    ref.read(selectedCustomerProvider.notifier).state = null;
    ref.read(manualCustomerNameProvider.notifier).state = null;
    ref.read(manualCustomerPhoneProvider.notifier).state = null;
  }

  double get subtotal => state.fold(0, (sum, item) => sum + item.total);

  Future<int?> checkout({
    required int shiftId,
    required List<PaymentEntry> payments,
    required double taxAmount,
    required double serviceCharge,
    String? customerPhone,
    String? customerName,
    int? customerId,
    int? discountId,
    int discountAmount = 0,
    int pointsEarned = 0,
    int pointsRedeemed = 0,
    String? notes,
  }) async {
    try {
      if (state.isEmpty) return null;
      if (payments.isEmpty) return null;

      final db = ref.read(databaseProvider);
      final now = DateTime.now();
      final receiptNumber =
          'POS-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}';

      final total = subtotal + taxAmount + serviceCharge;

      // Determine the paymentMethod string for the main transaction record
      final effectiveMethod = payments.length == 1
          ? payments.first.method.toLowerCase()
          : 'mixed';

      final transactionEntry = TransactionsCompanion.insert(
        receiptNumber: drift.Value(receiptNumber),
        shiftId: shiftId,
        subtotal: subtotal.toInt(),
        taxAmount: drift.Value(taxAmount.toInt()),
        serviceChargeAmount: drift.Value(serviceCharge.toInt()),
        totalAmount: total.toInt(),
        paymentMethod: drift.Value(effectiveMethod),
        customerPhone: drift.Value(customerPhone),
        customerName: drift.Value(customerName),
        customerId: drift.Value(customerId),
        discountId: drift.Value(discountId),
        discountAmount: drift.Value(discountAmount),
        pointsEarned: drift.Value(pointsEarned),
        pointsRedeemed: drift.Value(pointsRedeemed),
        notes: drift.Value(notes),
      );

      final itemsParams = state.map((item) {
        final variantLabel = item.variant != null
            ? '${item.variant!.name}: ${item.variant!.optionValue}'
            : null;

        return TransactionItemsCompanion.insert(
          transactionId: 0,
          productId: item.product.id,
          variantId: drift.Value(item.variant?.id),
          variantName: drift.Value(variantLabel),
          quantity: item.quantity,
          priceAtTransaction: item.effectivePrice,
          subtotal: item.total.toInt(),
          discountId: drift.Value(item.appliedDiscount?.id),
          discountAmount: drift.Value(item.itemDiscountAmount),
        );
      }).toList();

      // Build payment breakdown for the split payment table
      // Calculate remaining after non-cash methods to find true cash change
      double nonCashTotal = payments
          .where((p) => p.method.toLowerCase() != 'tunai')
          .fold(0.0, (sum, p) => sum + p.amount);
      double cashRemaining = total - nonCashTotal;

      final paymentEntries = payments.map((p) {
        int changeGiven = 0;
        if (p.method.toLowerCase() == 'tunai') {
          final change = p.amount - cashRemaining;
          changeGiven = change > 0 ? change.toInt() : 0;
        }
        return TransactionPaymentsCompanion.insert(
          transactionId: 0, // Overridden by processCheckout
          method: p.method.toLowerCase(),
          amount: p.amount.toInt(),
          changeGiven: drift.Value(changeGiven),
        );
      }).toList();

      final id = await db.processCheckout(
        transactionEntry: transactionEntry,
        itemsParams: itemsParams,
        paymentEntries: paymentEntries,
      );

      ref.invalidate(productProvider);
      clearCart();
      return id;
    } catch (e) {
      debugPrint('Checkout error: $e');
      return null;
    }
  }

  Future<int?> holdBill({
    required int shiftId,
    String? customerName,
    int? customerId,
    String? notes,
  }) async {
    try {
      if (state.isEmpty) return null;

      final db = ref.read(databaseProvider);
      
      // Total for draft usually doesn't include tax/service yet unless specified
      final total = subtotal;

      final transactionEntry = TransactionsCompanion.insert(
        shiftId: shiftId,
        subtotal: subtotal.toInt(),
        totalAmount: total.toInt(),
        paymentStatus: const drift.Value('pending'),
        customerName: drift.Value(customerName),
        customerId: drift.Value(customerId),
        notes: drift.Value(notes),
      );

      final itemsParams = state.map((item) {
        final variantLabel = item.variant != null
            ? '${item.variant!.name}: ${item.variant!.optionValue}'
            : null;

        return TransactionItemsCompanion.insert(
          transactionId: 0,
          productId: item.product.id,
          variantId: drift.Value(item.variant?.id),
          variantName: drift.Value(variantLabel),
          quantity: item.quantity,
          priceAtTransaction: item.effectivePrice,
          subtotal: item.total.toInt(),
          discountId: drift.Value(item.appliedDiscount?.id),
          discountAmount: drift.Value(item.itemDiscountAmount),
        );
      }).toList();

      final id = await db.processCheckout(
        transactionEntry: transactionEntry,
        itemsParams: itemsParams,
      );

      clearCart();
      return id;
    } catch (e) {
      debugPrint('Hold bill error: $e');
      return null;
    }
  }

  Future<void> resumeBill(Transaction transaction, List<TransactionItem> items) async {
    try {
      final db = ref.read(databaseProvider);
      
      // Clear current cart before resuming
      clearCart();
      
      final List<CartItem> resumedItems = [];
      
      for (final item in items) {
        final product = await db.getProduct(item.productId);
        if (product == null) continue;
        
        ProductVariant? variant;
        if (item.variantId != null) {
          variant = await db.getVariant(item.variantId!);
        }
        
        // Handle discount if any
        Discount? discount;
        if (item.discountId != null) {
          final allDiscounts = await db.getAllDiscounts();
          discount = allDiscounts.where((d) => d.id == item.discountId).firstOrNull;
        }
        
        resumedItems.add(CartItem(
          product: product,
          variant: variant,
          quantity: item.quantity,
          appliedDiscount: discount,
        ));
      }
      
      state = resumedItems;
      
      // Set notes to provider
      ref.read(cartNotesProvider.notifier).state = transaction.notes;

      // === NEW: RESTORE CUSTOMER INFO ===
      if (transaction.customerId != null) {
        final customers = await db.getAllCustomers();
        final selected = customers.where((c) => c.id == transaction.customerId).firstOrNull;
        if (selected != null) {
          ref.read(selectedCustomerProvider.notifier).state = selected;
        }
      }
      
      if (transaction.customerName != null) {
        ref.read(manualCustomerNameProvider.notifier).state = transaction.customerName;
      }
      
      if (transaction.customerPhone != null) {
        ref.read(manualCustomerPhoneProvider.notifier).state = transaction.customerPhone;
      }
      // ===================================
      
      // Mark as resumed instead of deleting to prevent loss if crash before re-saved
      // This also removes it from the pending list (since it only watches status='pending')
      await (db.update(db.transactions)..where((t) => t.id.equals(transaction.id)))
          .write(const TransactionsCompanion(paymentStatus: drift.Value('resumed')));
          
    } catch (e) {
      debugPrint('Resume bill error: $e');
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

// ===== History Data Provider (eliminates nested StreamBuilders) =====

class HistoryData {
  final StoreProfileData? profile;
  final Shift? openShift;
  final List<Transaction> transactions;

  const HistoryData({
    this.profile,
    this.openShift,
    required this.transactions,
  });
}

class HistoryDataNotifier extends AsyncNotifier<HistoryData> {
  @override
  Future<HistoryData> build() async {
    final db = ref.watch(databaseProvider);
    final filter = ref.watch(historyFilterProvider);

    final profile = await db.getStoreProfile();

    // Watch open shift for realtime updates
    final shiftSub = db.watchOpenShift().listen((shift) async {
      if (!ref.mounted) return;
      final txns = await _getTransactions(db, filter, shift);
      state = AsyncValue.data(HistoryData(
        profile: profile,
        openShift: shift,
        transactions: txns,
      ));
    });
    ref.onDispose(() => shiftSub.cancel());

    // Get initial shift
    Shift? openShift;
    try {
      openShift = await db.getOpenShift();
    } catch (_) {}

    // Watch transactions for realtime updates
    final txnStream = _getTransactionStream(db, filter, openShift);
    final txnSub = txnStream.listen((txns) {
      if (!ref.mounted) return;
      state = AsyncValue.data(HistoryData(
        profile: profile,
        openShift: openShift,
        transactions: txns,
      ));
    });
    ref.onDispose(() => txnSub.cancel());

    final txns = await _getTransactions(db, filter, openShift);
    return HistoryData(
      profile: profile,
      openShift: openShift,
      transactions: txns,
    );
  }

  Stream<List<Transaction>> _getTransactionStream(
    PosifyDatabase db, HistoryFilter filter, Shift? openShift,
  ) {
    if (filter.type == HistoryFilterType.currentShift) {
      if (openShift == null) return Stream.value([]);
      return db.watchTransactionsByShift(openShift.id);
    }
    final range = _getDateRange(filter);
    if (range == null) return db.watchAllTransactions();
    return db.watchTransactionsByRange(range.start, range.end);
  }

  Future<List<Transaction>> _getTransactions(
    PosifyDatabase db, HistoryFilter filter, Shift? openShift,
  ) {
    return _getTransactionStream(db, filter, openShift).first;
  }

  DateTimeRange? _getDateRange(HistoryFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (filter.type) {
      case HistoryFilterType.today:
        return DateTimeRange(start: today, end: now);
      case HistoryFilterType.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: now);
      case HistoryFilterType.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case HistoryFilterType.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case HistoryFilterType.custom:
        return filter.range;
      case HistoryFilterType.currentShift:
        return null;
    }
  }
}

final historyDataProvider = AsyncNotifierProvider<HistoryDataNotifier, HistoryData>(
  HistoryDataNotifier.new,
);

// ===== Customer Provider =====

class CustomerNotifier extends AsyncNotifier<List<Customer>> {
  @override
  Future<List<Customer>> build() async {
    final db = ref.watch(databaseProvider);

    final subscription = db.watchAllCustomers().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });
    ref.onDispose(() => subscription.cancel());

    return db.getAllCustomers();
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

    final subscription = db.watchAllSuppliers().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });
    ref.onDispose(() => subscription.cancel());

    return db.getAllSuppliers();
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
    
    final subscription = db.watchAllStockTransactionsWithProduct().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });

    ref.onDispose(() => subscription.cancel());

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

// ===== Pending Transactions Provider =====

final pendingTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchPendingTransactions();
});

// ===== Ingredient History Provider =====

final ingredientHistoryProvider = StreamProvider.family<List<IngredientStockHistoryData>, int>((ref, ingredientId) {
  final db = ref.watch(databaseProvider);
  return db.watchIngredientHistory(ingredientId);
});

class CustomerSearchNotifier extends Notifier<String> {
  @override
  String build() => '';

  set state(String val) => super.state = val;
}

final customerSearchProvider = NotifierProvider<CustomerSearchNotifier, String>(
  CustomerSearchNotifier.new,
);

// ===== Stock Opname History Providers =====

final stockOpnameHistoryProvider = StreamProvider.family<List<StockOpnameData>, String>((ref, type) {
  final db = ref.watch(databaseProvider);
  return db.watchCompletedOpnames(type);
});

final stockOpnameItemsProvider = StreamProvider.family<List<StockOpnameItem>, int>((ref, opnameId) {
  final db = ref.watch(databaseProvider);
  return db.watchOpnameItems(opnameId);
});
