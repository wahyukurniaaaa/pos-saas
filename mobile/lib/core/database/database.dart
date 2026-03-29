import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

import 'tables/licenses_table.dart';
import 'tables/employees_table.dart';
import 'tables/store_profile_table.dart';
import 'tables/categories_table.dart';
import 'tables/products_table.dart';
import 'tables/product_variants_table.dart';
import 'tables/shifts_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/stock_transactions_table.dart';
import 'tables/customers_table.dart';
import 'tables/suppliers_table.dart';
import 'tables/printer_settings_table.dart';
import 'tables/ingredients_table.dart';
import 'tables/product_recipes_table.dart';
import 'tables/ingredient_stock_history_table.dart';
import 'tables/unit_conversions_table.dart';
import 'tables/stock_opname_table.dart';
import 'tables/stock_opname_items_table.dart';
import 'tables/purchase_orders_table.dart';
import 'tables/discounts_table.dart';
import 'tables/expenses_table.dart';

part 'database.g.dart';

class StockTransactionWithProduct {
  final StockTransaction transaction;
  final Product product;
  final ProductVariant? variant;

  StockTransactionWithProduct({
    required this.transaction,
    required this.product,
    this.variant,
  });
}

@DriftDatabase(
  tables: [
    Licenses,
    Employees,
    StoreProfile,
    Categories,
    Products,
    ProductVariants,
    Shifts,
    Transactions,
    TransactionItems,
    StockTransactions,
    Customers,
    Suppliers,
    PrinterSettings,
    Ingredients,
    ProductRecipes,
    IngredientStockHistory,
    UnitConversions,
    StockOpname,
    StockOpnameItems,
    PurchaseOrders,
    PurchaseOrderItems,
    Discounts,
    ExpenseCategories,
    Expenses,
  ],
)
class PosifyDatabase extends _$PosifyDatabase {
  PosifyDatabase() : super(_openConnection());

  // For testing
  PosifyDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 20;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          await m.addColumn(licenses, licenses.lastVerified);
        }
        if (from < 3) {
          await m.addColumn(storeProfile, storeProfile.logoUri);
        }
        if (from < 4) {
          await m.addColumn(transactions, transactions.customerPhone);
          await m.addColumn(transactions, transactions.customerName);
        }
        if (from < 5) {
          await m.createTable(productVariants);
          await m.addColumn(products, products.hasVariants);
          await m.addColumn(transactionItems, transactionItems.variantId);
          await m.addColumn(transactionItems, transactionItems.variantName);
        }
        if (from < 6) {
          // stock_adjustments replaced by stock_transactions; add column via raw SQL if old table exists.
          try {
            await m.database.customStatement(
              'ALTER TABLE stock_adjustments ADD COLUMN variant_id INTEGER;',
            );
          } catch (_) {
            // Ignore – table may not exist or column already present.
          }
        }
        if (from < 7) {
          await m.addColumn(productVariants, productVariants.updatedAt);
        }
        if (from < 8) {
          await m.createTable(customers);
          await m.createTable(suppliers);
          await m.createTable(stockTransactions);
          await m.addColumn(products, products.lowStockThreshold);
          await m.addColumn(transactions, transactions.customerId);
        }
        if (from < 9) {
          await m.createTable(ingredients);
          await m.createTable(productRecipes);
          await m.createTable(ingredientStockHistory);
        }
        if (from < 10) {
          await m.addColumn(ingredients, ingredients.lastSupplierId);
          await m.addColumn(ingredientStockHistory, ingredientStockHistory.supplierId);
        }
        if (from < 11) {
          await m.createTable(unitConversions);
        }
        if (from < 12) {
          await m.createTable(stockOpname);
          await m.createTable(stockOpnameItems);
        }
        if (from < 13) {
          await m.createTable(purchaseOrders);
          await m.createTable(purchaseOrderItems);
        }
        if (from < 14) {
          await m.createTable(discounts);
          await m.addColumn(transactions, transactions.discountId);
          await m.addColumn(transactions, transactions.discountAmount);
          await m.addColumn(transactionItems, transactionItems.discountId);
          await m.addColumn(transactionItems, transactionItems.discountAmount);
        }
        if (from < 15) {
          await m.createTable(expenseCategories);
          await m.createTable(expenses);
          // Seed default expense categories
          await batch((b) {
            b.insertAll(expenseCategories, [
              ExpenseCategoriesCompanion.insert(name: 'Bahan Baku', icon: const Value('inventory_2'), color: const Value('#E67E22'), isDefault: const Value(true)),
              ExpenseCategoriesCompanion.insert(name: 'Gaji & Upah', icon: const Value('people'), color: const Value('#27AE60'), isDefault: const Value(true)),
              ExpenseCategoriesCompanion.insert(name: 'Listrik & Air', icon: const Value('bolt'), color: const Value('#2980B9'), isDefault: const Value(true)),
              ExpenseCategoriesCompanion.insert(name: 'Operasional', icon: const Value('build'), color: const Value('#1E3A5F'), isDefault: const Value(true)),
              ExpenseCategoriesCompanion.insert(name: 'Lain-lain', icon: const Value('more_horiz'), color: const Value('#7F8C8D'), isDefault: const Value(true)),
            ]);
          });
        }
        if (from < 16) {
          await m.addColumn(products, products.purchasePrice);
        }
        if (from < 17) {
          await m.addColumn(customers, customers.points);
          await m.addColumn(transactions, transactions.pointsEarned);
          await m.addColumn(transactions, transactions.pointsRedeemed);
          await m.addColumn(storeProfile, storeProfile.loyaltyPointConversion);
          await m.addColumn(storeProfile, storeProfile.loyaltyPointValue);
        }
        if (from < 20) {
          // Force recreate transactions to handle nullable constraints and notes field cleanly
          await m.database.customStatement('PRAGMA foreign_keys = OFF;');
          await m.database.customStatement('DROP TABLE IF EXISTS transaction_items;');
          await m.database.customStatement('DROP TABLE IF EXISTS transactions;');
          await m.createTable(transactions);
          await m.createTable(transactionItems);
          await m.database.customStatement('PRAGMA foreign_keys = ON;');
        }
      },
    );
  }

  // ===== License Queries =====
  Future<License?> getLocalLicense() =>
      (select(licenses)..limit(1)).getSingleOrNull();

  Future<int> insertLicense(LicensesCompanion entry) =>
      into(licenses).insert(entry);

  Future<void> updateLicenseVerification(String code) {
    return (update(licenses)..where((t) => t.licenseCode.equals(code))).write(
      LicensesCompanion(lastVerified: Value(DateTime.now())),
    );
  }

  Future<void> updateLicenseFingerprint(String code, String fingerprint) {
    return (update(licenses)..where((t) => t.licenseCode.equals(code))).write(
      LicensesCompanion(
        deviceFingerprint: Value(fingerprint),
        lastVerified: Value(DateTime.now()),
      ),
    );
  }


  // ===== Employee Queries =====
  Future<List<Employee>> getAllEmployees() => select(employees).get();

  Stream<List<Employee>> watchAllEmployees() => select(employees).watch();

  Future<Employee?> getEmployeeByPin(String pin) =>
      (select(employees)..where((e) => e.pin.equals(pin))).getSingleOrNull();

  Future<Employee?> getOwner() => (select(
    employees,
  )..where((e) => e.role.equals('owner'))).getSingleOrNull();

  Future<int> insertEmployee(EmployeesCompanion entry) =>
      into(employees).insert(entry);

  Future<bool> updateEmployee(Employee entry) =>
      update(employees).replace(entry);

  // ===== Store Profile Queries =====
  Future<StoreProfileData?> getStoreProfile() =>
      (select(storeProfile)..limit(1)).getSingleOrNull();

  Stream<StoreProfileData?> watchStoreProfile() =>
      (select(storeProfile)..limit(1)).watchSingleOrNull();

  Future<int> insertStoreProfile(StoreProfileCompanion entry) =>
      into(storeProfile).insert(entry);

  Future<bool> updateStoreProfile(StoreProfileData entry) =>
      update(storeProfile).replace(entry);

  // ===== Category Queries =====
  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  // ===== Product Management =====
  Future<List<Product>> getAllProducts() => select(products).get();
  Stream<List<Product>> watchAllProducts() => select(products).watch();
  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);
  Future<bool> updateProduct(Product entry) => update(products).replace(entry);
  Future<int> deleteProduct(Product entry) => delete(products).delete(entry);

  Future<void> insertMultipleProducts(List<ProductsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(products, entries, mode: InsertMode.insertOrReplace);
    });
  }

  // ===== Product Variants =====
  Future<List<ProductVariant>> getAllVariants() => select(productVariants).get();

  Stream<List<ProductVariant>> watchVariantsByProduct(int productId) =>
      (select(productVariants)
            ..where((v) => v.productId.equals(productId)))
          .watch();

  Future<List<ProductVariant>> getVariantsByProduct(int productId) async {
    return (select(productVariants)
          ..where((v) => v.productId.equals(productId)))
        .get();
  }

  Future<int> insertVariant(ProductVariantsCompanion entry) =>
      into(productVariants).insert(entry);

  Future<bool> updateVariant(ProductVariant entry) =>
      update(productVariants).replace(entry);

  Future<int> deleteVariant(ProductVariant entry) =>
      delete(productVariants).delete(entry);

  Future<ProductVariant?> getVariant(int id) =>
      (select(productVariants)..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<void> deleteVariantsByProduct(int productId) =>
      (delete(productVariants)
            ..where((v) => v.productId.equals(productId)))
          .go();

  Future<void> replaceVariants(
    int productId,
    List<ProductVariantsCompanion> newVariants,
  ) async {
    await transaction(() async {
      await deleteVariantsByProduct(productId);
      if (newVariants.isNotEmpty) {
        await batch((b) => b.insertAll(productVariants, newVariants));
      }
    });
  }

  // ===== Shift Queries =====
  Future<Product?> getProduct(int id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Product?> getProductBySku(String sku) =>
      (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();

  Future<ProductWithVariants?> getProductWithVariants(int id) async {
    final product = await (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();
    if (product == null) return null;
    
    final variants = await (select(productVariants)..where((p) => p.productId.equals(id))).get();
    return ProductWithVariants(product: product, variants: variants);
  }

  Future<List<ProductWithVariants>> getAllProductsWithVariants() async {
    final allProducts = await getAllProducts();
    final allVariants = await getAllVariants();
    
    return allProducts.map((p) {
      final productVariants = allVariants.where((v) => v.productId == p.id).toList();
      return ProductWithVariants(product: p, variants: productVariants);
    }).toList();
  }

  Stream<List<ProductWithVariants>> watchAllProductsWithVariants() {
    final query = select(products).join([
      leftOuterJoin(
        productVariants,
        productVariants.productId.equalsExp(products.id),
      ),
    ]);

    return query.watch().map((rows) {
      final results = <int, ProductWithVariants>{};

      for (final row in rows) {
        final product = row.readTable(products);
        final variant = row.readTableOrNull(productVariants);

        final entry = results.putIfAbsent(
          product.id,
          () => ProductWithVariants(product: product, variants: []),
        );

        if (variant != null) {
          entry.variants.add(variant);
        }
      }
      return results.values.toList();
    });
  }

  Future<Shift?> getOpenShift() =>
      (select(shifts)..where((s) => s.status.equals('open'))).getSingleOrNull();

  Stream<Shift?> watchOpenShift() => (select(
    shifts,
  )..where((s) => s.status.equals('open'))).watchSingleOrNull();

  Future<int> insertShift(ShiftsCompanion entry) => into(shifts).insert(entry);

  Future<bool> updateShift(Shift entry) => update(shifts).replace(entry);

  // ===== Transaction Queries =====
  Stream<List<Transaction>> watchTransactionsByShift(int shiftId) =>
      (select(transactions)..where((t) => t.shiftId.equals(shiftId))).watch();

  Future<int> insertTransaction(TransactionsCompanion entry) =>
      into(transactions).insert(entry);

  Future<bool> updateTransaction(Transaction entry) =>
      update(transactions).replace(entry);

  // ===== Transaction Items =====
  Future<List<TransactionItem>> getItemsByTransaction(int transactionId) =>
      (select(
        transactionItems,
      )..where((ti) => ti.transactionId.equals(transactionId))).get();

  Future<int> insertTransactionItem(TransactionItemsCompanion entry) =>
      into(transactionItems).insert(entry);

  // ===== Stock Transactions =====
  Future<int> insertStockTransaction(StockTransactionsCompanion entry) =>
      into(stockTransactions).insert(entry);

  Future<String?> getLastAdjustDate(int productId, {int? variantId}) async {
    final query = select(stockTransactions);
    
    if (productId != 0) {
      query.where((t) => t.productId.equals(productId));
    }
    
    query.where((t) => t.type.equals('ADJUST'));

    if (variantId != null) {
      query.where((t) => t.variantId.equals(variantId));
    }

    query.orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    query.limit(1);

    final result = await query.getSingleOrNull();
    return result?.createdAt;
  }

  // ===== Customers & Suppliers =====
  Future<List<Customer>> getAllCustomers() => select(customers).get();
  Stream<List<Customer>> watchAllCustomers() => select(customers).watch();
  Future<int> insertCustomer(CustomersCompanion entry) =>
      into(customers).insert(entry);
  Future<bool> updateCustomer(Customer entry) => update(customers).replace(entry);

  /// Returns all customers who have at least 1 transaction, with aggregated stats.
  /// Sorted by points descending by default.
  Future<List<CustomerLoyaltyStat>> getLoyaltyLeaderboard() async {
    final result = await customSelect(
      '''
      SELECT
        c.*,
        COUNT(t.id) AS transaction_count,
        COALESCE(SUM(t.total_amount), 0) AS total_spend
      FROM customers c
      INNER JOIN transactions t ON t.customer_id = c.id
      GROUP BY c.id
      ORDER BY c.points DESC
      ''',
      readsFrom: {customers, transactions},
    ).get();

    return result.map((row) {
      final customer = Customer(
        id: row.read<int>('id'),
        name: row.read<String>('name'),
        phone: row.readNullable<String>('phone'),
        email: row.readNullable<String>('email'),
        address: row.readNullable<String>('address'),
        isMember: row.read<bool>('is_member'),
        points: row.read<int>('points'),
        createdAt: row.read<String>('created_at'),
        updatedAt: row.read<String>('updated_at'),
      );
      return CustomerLoyaltyStat(
        customer: customer,
        transactionCount: row.read<int>('transaction_count'),
        totalSpend: row.read<int>('total_spend'),
      );
    }).toList();
  }


  Future<List<Supplier>> getAllSuppliers() => select(suppliers).get();
  Stream<List<Supplier>> watchAllSuppliers() => select(suppliers).watch();
  Future<int> insertSupplier(SuppliersCompanion entry) =>
      into(suppliers).insert(entry);
  Future<bool> updateSupplier(Supplier entry) => update(suppliers).replace(entry);

  // ===== Stock In (Purchase from Supplier) =====
  Future<void> processStockIn({
    required int productId,
    int? variantId,
    required int quantity,
    required int unitCost,
    int? supplierId,
    String? note,
    String? invoiceRef,
  }) async {
    return transaction(() async {
      final now = DateTime.now().toIso8601String();

      if (variantId != null) {
        final variant = await (select(productVariants)
              ..where((v) => v.id.equals(variantId)))
            .getSingleOrNull();
        if (variant == null) throw Exception('Variant not found');
        
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) throw Exception('Product not found');

        final newStock = variant.stock + quantity;
        final newProductStock = product.stock + quantity;

        // Update variant stock
        await (update(productVariants)..where((v) => v.id.equals(variantId)))
            .write(ProductVariantsCompanion(stock: Value(newStock)));
            
        // Updates main product aggregate stock
        final oldStock = product.stock;
        final oldHpp = product.purchasePrice;
        int newHpp = oldHpp;

        if (unitCost > 0) {
           final totalOldValue = oldStock * oldHpp;
           final totalNewValue = quantity * unitCost;
           newHpp = newProductStock > 0 
               ? ((totalOldValue + totalNewValue) / newProductStock).round()
               : unitCost;
        }

        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(
              stock: Value(newProductStock),
              purchasePrice: Value(newHpp),
            ));

        await into(stockTransactions).insert(StockTransactionsCompanion.insert(
          productId: productId,
          variantId: Value(variantId),
          supplierId: Value(supplierId),
          type: 'IN',
          quantity: quantity,
          previousStock: variant.stock,
          newStock: newStock,
          reason: Value(note),
          reference: Value(invoiceRef),
          createdAt: now,
        ));
      } else {
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) throw Exception('Product not found');
        final oldStock = product.stock;
        final oldHpp = product.purchasePrice;
        int newHpp = oldHpp;
        final newStock = product.stock + quantity;

        if (unitCost > 0) {
           final totalOldValue = oldStock * oldHpp;
           final totalNewValue = quantity * unitCost;
           newHpp = newStock > 0 
               ? ((totalOldValue + totalNewValue) / newStock).round()
               : unitCost;
        }

        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(
              stock: Value(newStock),
              purchasePrice: Value(newHpp),
            ));
        await into(stockTransactions).insert(StockTransactionsCompanion.insert(
          productId: productId,
          supplierId: Value(supplierId),
          type: 'IN',
          quantity: quantity,
          previousStock: product.stock,
          newStock: newStock,
          reason: Value(note),
          reference: Value(invoiceRef),
          createdAt: now,
        ));
      }
    });
  }

  Future<void> processStockOut({
    required int productId,
    int? variantId,
    required int quantity,
    int? supplierId,
    String? note,
    String? invoiceRef,
  }) async {
    final now = DateTime.now().toIso8601String();
    await transaction(() async {
      if (variantId != null) {
        final variant = await (select(productVariants)
              ..where((v) => v.id.equals(variantId)))
            .getSingleOrNull();
        if (variant == null) throw Exception('Variant not found');
        
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) throw Exception('Product not found');

        final newStock = variant.stock - quantity;
        final newProductStock = product.stock - quantity;

        // Update variant stock
        await (update(productVariants)..where((v) => v.id.equals(variantId)))
            .write(ProductVariantsCompanion(stock: Value(newStock)));
            
        // Also update main product aggregate stock
        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(stock: Value(newProductStock)));

        await into(stockTransactions).insert(StockTransactionsCompanion.insert(
          productId: productId,
          variantId: Value(variantId),
          supplierId: Value(supplierId),
          type: 'OUT',
          quantity: quantity,
          previousStock: variant.stock,
          newStock: newStock,
          reason: Value(note),
          reference: Value(invoiceRef),
          createdAt: now,
        ));
      } else {
        final product = await (select(products)
              ..where((p) => p.id.equals(productId)))
            .getSingleOrNull();
        if (product == null) throw Exception('Product not found');
        
        final newStock = product.stock - quantity;
        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(stock: Value(newStock)));

        await into(stockTransactions).insert(StockTransactionsCompanion.insert(
          productId: productId,
          supplierId: Value(supplierId),
          type: 'OUT',
          quantity: quantity,
          previousStock: product.stock,
          newStock: newStock,
          reason: Value(note),
          reference: Value(invoiceRef),
          createdAt: now,
        ));
      }
    });
  }

  // ===== Stock Card (Full log for a product) =====
  Stream<List<StockTransactionWithProduct>> watchAllStockTransactionsWithProduct() {
    final query = select(stockTransactions).join([
      innerJoin(products, products.id.equalsExp(stockTransactions.productId)),
      leftOuterJoin(productVariants, productVariants.id.equalsExp(stockTransactions.variantId)),
    ])
      ..orderBy([OrderingTerm.desc(stockTransactions.createdAt)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return StockTransactionWithProduct(
          transaction: row.readTable(stockTransactions),
          product: row.readTable(products),
          variant: row.readTableOrNull(productVariants),
        );
      }).toList();
    });
  }

  Future<List<StockTransaction>> getStockCard(int productId, {int? variantId}) {
    final query = select(stockTransactions)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (variantId != null) {
      query.where((t) => t.variantId.equals(variantId));
    }
    return query.get();
  }

  // ===== Low Stock products =====
  Future<List<Product>> getLowStockProducts() => (select(products)
        ..where((p) => p.lowStockThreshold.isBiggerThanValue(0) &
            p.stock.isSmallerThanValue(999999))) // will filter in Dart below
      .get();

  Future<List<Product>> getLowStockProductsFiltered() async {
    final all = await select(products).get();
    return all
        .where((p) => p.lowStockThreshold > 0 && p.stock <= p.lowStockThreshold)
        .toList();
  }

  Future<List<Ingredient>> getLowStockIngredients() async {
    final all = await select(ingredients).get();
    return all
        .where((i) => i.minStockThreshold > 0 && i.stockQuantity <= i.minStockThreshold)
        .toList();
  }

  // ===== Purchase Order (PO) Queries =====

  Future<List<PurchaseOrder>> getAllPurchaseOrders() =>
      (select(purchaseOrders)
        ..orderBy([(po) => OrderingTerm.desc(po.orderedAt)]))
          .get();

  Stream<List<PurchaseOrder>> watchAllPurchaseOrders() =>
      (select(purchaseOrders)
        ..orderBy([(po) => OrderingTerm.desc(po.orderedAt)]))
          .watch();

  Future<List<PurchaseOrderItem>> getPurchaseOrderItems(int poId) =>
      (select(purchaseOrderItems)
        ..where((i) => i.purchaseOrderId.equals(poId)))
          .get();

  Future<int> createPurchaseOrder(PurchaseOrdersCompanion entry) =>
      into(purchaseOrders).insert(entry);

  Future<void> addPurchaseOrderItem(PurchaseOrderItemsCompanion entry) =>
      into(purchaseOrderItems).insert(entry).then((_) {});

  Future<void> updatePurchaseOrderStatus(int poId, String status) =>
      (update(purchaseOrders)..where((po) => po.id.equals(poId))).write(
        PurchaseOrdersCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

  /// Marks PO as received, updates received quantities,
  /// and auto-increments product or ingredient stock.
  Future<void> receivePurchaseOrder({
    required int poId,
    required List<({int itemId, double receivedQty})> receivedItems,
  }) async {
    await transaction(() async {
      final now = DateTime.now().toIso8601String();

      for (final received in receivedItems) {
        // Update received quantity on the PO item
        await (update(purchaseOrderItems)
              ..where((i) => i.id.equals(received.itemId)))
            .write(
          PurchaseOrderItemsCompanion(
            receivedQuantity: Value(received.receivedQty),
          ),
        );

        // Fetch the PO item to determine which stock to update
        final item = await (select(purchaseOrderItems)
              ..where((i) => i.id.equals(received.itemId)))
            .getSingleOrNull();
        if (item == null || received.receivedQty <= 0) continue;

        if (item.productId != null) {
          // Update product stock
          final product = await (select(products)
                ..where((p) => p.id.equals(item.productId!)))
              .getSingleOrNull();
          if (product != null) {
            final qty = received.receivedQty.round();
            final newStock = product.stock + qty;
            await (update(products)..where((p) => p.id.equals(product.id)))
                .write(ProductsCompanion(stock: Value(newStock)));
            await into(stockTransactions).insert(
              StockTransactionsCompanion.insert(
                productId: product.id,
                type: 'IN',
                quantity: qty,
                previousStock: product.stock,
                newStock: newStock,
                reason: Value('Penerimaan PO #$poId'),
                reference: Value('PO-$poId'),
                createdAt: now,
              ),
            );
          }
        } else if (item.ingredientId != null) {
          // Update ingredient stock
          await deductIngredientStock(
            ingredientId: item.ingredientId!,
            quantityInBaseUnit: -received.receivedQty, // negative = add
            type: 'PURCHASE',
            referenceId: 'PO-$poId',
            reason: 'Penerimaan PO #$poId',
          );
        }
      }

      // Mark PO as received
      await updatePurchaseOrderStatus(poId, 'received');
    });
  }

  // ===== Discount Queries =====

  Future<List<Discount>> getAllDiscounts() =>
      (select(discounts)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).get();

  Stream<List<Discount>> watchAllDiscounts() =>
      (select(discounts)..orderBy([(d) => OrderingTerm.desc(d.createdAt)])).watch();

  Future<int> upsertDiscount(DiscountsCompanion entry) =>
      into(discounts).insertOnConflictUpdate(entry);

  Future<int> deleteDiscount(int id) =>
      (delete(discounts)..where((d) => d.id.equals(id))).go();

  Future<List<Discount>> getValidDiscounts({required double cartTotal, required String scope}) async {
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final all = await (select(discounts)
          ..where((d) => d.isActive.equals(true) & d.scope.equals(scope)))
        .get();
    return all.where((d) {
      final afterStart = d.startDate == null || d.startDate!.substring(0, 10).compareTo(todayStr) <= 0;
      final beforeEnd = d.endDate == null || d.endDate!.substring(0, 10).compareTo(todayStr) >= 0;
      final meetsMin = cartTotal >= d.minSpend;
      return afterStart && beforeEnd && meetsMin;
    }).toList();
  }

  // ===== Expense Category Queries =====

  Future<List<ExpenseCategory>> getAllExpenseCategories() =>
      (select(expenseCategories)..orderBy([(c) => OrderingTerm.asc(c.name)])).get();

  Future<int> upsertExpenseCategory(ExpenseCategoriesCompanion entry) =>
      into(expenseCategories).insertOnConflictUpdate(entry);

  Future<int> deleteExpenseCategory(int id) =>
      (delete(expenseCategories)..where((c) => c.id.equals(id))).go();

  // ===== Expense Queries =====

  /// Returns all expenses for a given day, joined with their category.
  Future<List<ExpenseWithCategory>> getExpensesWithCategory({required DateTime date}) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows = await (select(expenses)
          ..where((e) =>
              e.createdAt.isBiggerOrEqualValue(startOfDay) &
              e.createdAt.isSmallerThanValue(endOfDay))
          ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
        .get();

    final categories = {
      for (final c in await getAllExpenseCategories()) c.id: c
    };

    return rows.map((e) {
      return ExpenseWithCategory(
        expense: e,
        category: categories[e.categoryId],
      );
    }).toList();
  }

  Future<int> insertExpense(ExpensesCompanion entry) =>
      into(expenses).insert(entry);

  Future<int> deleteExpense(int id) =>
      (delete(expenses)..where((e) => e.id.equals(id))).go();

  Future<int> getTotalExpenseByShift(int shiftId) async {
    final rows = await (select(expenses)
          ..where((e) => e.shiftId.equals(shiftId)))
        .get();
    return rows.fold<int>(0, (sum, e) => sum + e.amount);
  }

  /// Returns cash flow data for the given date range.
  Future<CashFlowData> getCashFlowData({required DateTime from, required DateTime to}) async {
    // Total revenue from paid transactions
    final txRows = await (select(transactions)
          ..where((t) =>
              t.createdAt.isBiggerOrEqualValue(from) &
              t.createdAt.isSmallerThanValue(to.add(const Duration(days: 1))) &
              t.paymentStatus.equals('paid')))
        .get();
    final totalRevenue = txRows.fold(0, (sum, t) => sum + t.totalAmount);

    // Total expenses
    final expenseRows = await (select(expenses)
          ..where((e) =>
              e.createdAt.isBiggerOrEqualValue(from) &
              e.createdAt.isSmallerThanValue(to.add(const Duration(days: 1)))))
        .get();
    final totalExpense = expenseRows.fold(0, (sum, e) => sum + e.amount);

    // Daily expense summaries (for chart)
    final Map<String, int> dailyMap = {};
    for (final e in expenseRows) {
      final key = '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + e.amount;
    }

    final daily = dailyMap.entries
        .map((e) => DailyExpenseSummary(
              date: DateTime.parse(e.key),
              total: e.value,
            ))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return CashFlowData(
      totalRevenue: totalRevenue,
      totalExpense: totalExpense,
      daily: daily,
    );
  }

  Future<int> processCheckout({
    required TransactionsCompanion transactionEntry,
    required List<TransactionItemsCompanion> itemsParams,
  }) async {
    return transaction(() async {
      // 1. Insert Transaction
      final txId = await into(transactions).insert(transactionEntry);

      final isPending = transactionEntry.paymentStatus.present && 
                        transactionEntry.paymentStatus.value == 'pending';

      // 2. Insert Items & 3. Update Stocks
      for (final itemParam in itemsParams) {
        final finalItem = itemParam.copyWith(transactionId: Value(txId));
        await into(transactionItems).insert(finalItem);

        // If it's a pending bill (Hold Bill), we DON'T deduct stock yet.
        if (isPending) continue;

        final qty = itemParam.quantity.value;
        final variantId = itemParam.variantId.present
            ? itemParam.variantId.value
            : null;

        final productId = itemParam.productId.value;

        if (variantId != null) {
          // Variable product: decrement variant stock
          final variant = await (select(productVariants)
                ..where((v) => v.id.equals(variantId)))
              .getSingleOrNull();
          if (variant != null) {
            final newStock = variant.stock - qty;
            await (update(productVariants)
                  ..where((v) => v.id.equals(variant.id)))
                .write(ProductVariantsCompanion(
                  stock: Value(newStock),
                ));
            final refStr = transactionEntry.receiptNumber.present && transactionEntry.receiptNumber.value != null
                ? transactionEntry.receiptNumber.value!
                : 'TX-$txId';

            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: productId,
              variantId: Value(variant.id),
              type: 'SALE',
              quantity: -qty,
              previousStock: variant.stock,
              newStock: newStock,
              reference: Value(refStr),
              createdAt: DateTime.now().toIso8601String(),
            ));
          }
        } else {
          // Simple product: decrement product stock
          final product = await (select(products)
                ..where((p) => p.id.equals(productId)))
              .getSingleOrNull();
          if (product != null) {
            final newStock = product.stock - qty;
            await update(products)
                .replace(product.copyWith(stock: newStock));
            final refStr = transactionEntry.receiptNumber.present && transactionEntry.receiptNumber.value != null
                ? transactionEntry.receiptNumber.value!
                : 'TX-$txId';

            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: productId,
              type: 'SALE',
              quantity: -qty,
              previousStock: product.stock,
              newStock: newStock,
              reference: Value(refStr),
              createdAt: DateTime.now().toIso8601String(),
            ));
          }
        }

        // 4. Update Ingredients Stock (New Recipe Integration)
        final recipes = await getRecipesByProductId(productId);
        final refStr = transactionEntry.receiptNumber.present && transactionEntry.receiptNumber.value != null
            ? transactionEntry.receiptNumber.value!
            : 'TX-$txId';
            
        for (final recipe in recipes) {
            final totalDeduction = recipe.quantityNeeded * qty;
            await deductIngredientStock(
              ingredientId: recipe.ingredientId,
              quantityInBaseUnit: totalDeduction,
              type: 'SALE',
              referenceId: refStr,
              reason: 'Penjualan: $refStr',
            );
        }
      }

      // 5. Update Customer Points (Only for paid transactions)
      if (!isPending && transactionEntry.customerId.present && transactionEntry.customerId.value != null) {
        final customerId = transactionEntry.customerId.value!;
        final earned = transactionEntry.pointsEarned.present ? transactionEntry.pointsEarned.value : 0;
        final redeemed = transactionEntry.pointsRedeemed.present ? transactionEntry.pointsRedeemed.value : 0;

        if (earned > 0 || redeemed > 0) {
          final customer = await (select(customers)..where((c) => c.id.equals(customerId))).getSingleOrNull();
          if (customer != null) {
            final newPoints = customer.points + earned - redeemed;
            await update(customers).replace(customer.copyWith(points: newPoints));
          }
        }
      }

      return txId;
    });
  }

  // ===== Additional Transaction Queries =====
  Future<List<Transaction>> getAllTransactions() => (select(
    transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Stream<List<Transaction>> watchAllTransactions() => (select(
    transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<List<Transaction>> watchPendingTransactions() =>
      (select(transactions)
            ..where((t) => t.paymentStatus.equals('pending'))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> deleteTransaction(int id) async {
    await transaction(() async {
      await (delete(transactionItems)..where((t) => t.transactionId.equals(id))).go();
      await (delete(transactions)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<List<TransactionItem>> getTransactionItems(int transactionId) {
    return (select(transactionItems)..where((t) => t.transactionId.equals(transactionId))).get();
  }

  Stream<List<Transaction>> watchTransactionsByRange(
    DateTime start,
    DateTime end,
  ) => (select(
    transactions,
  )
    ..where((t) => t.createdAt.isBetweenValues(start, end))
    ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // ===== All Shifts =====
  Future<List<ShiftWithEmployee>> getAllShifts() async {
    final query = select(shifts).join([
      innerJoin(employees, employees.id.equalsExp(shifts.employeeId)),
    ])
      ..orderBy([OrderingTerm.desc(shifts.startTime)]);

    final rows = await query.get();
    return rows.map((row) {
      return ShiftWithEmployee(
        shift: row.readTable(shifts),
        employee: row.readTable(employees),
      );
    }).toList();
  }

  Stream<List<ShiftWithEmployee>> watchAllShifts() {
    final query = select(shifts).join([
      innerJoin(employees, employees.id.equalsExp(shifts.employeeId)),
    ])
      ..orderBy([OrderingTerm.desc(shifts.startTime)]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return ShiftWithEmployee(
          shift: row.readTable(shifts),
          employee: row.readTable(employees),
        );
      }).toList();
    });
  }

  // ===== Category Management =====
  Future<bool> updateCategory(Category entry) =>
      update(categories).replace(entry);

  Future<int> deleteCategory(Category entry) =>
      delete(categories).delete(entry);

  // ===== Detail & Void Transaction =====
  Future<TransactionWithItems?> getTransactionWithItems(
    int transactionId,
  ) async {
    final transaction = await (select(
      transactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();
    if (transaction == null) return null;

    final itemsQuery = select(transactionItems).join([
      innerJoin(products, products.id.equalsExp(transactionItems.productId)),
    ])..where(transactionItems.transactionId.equals(transactionId));

    final itemsResult = await itemsQuery.get();
    final itemsList = itemsResult.map((row) {
      return TransactionItemWithProduct(
        item: row.readTable(transactionItems),
        product: row.readTable(products),
      );
    }).toList();

    return TransactionWithItems(transaction: transaction, items: itemsList);
  }

  Future<bool> voidTransaction(int transactionId, int supervisorId) async {
    return transaction(() async {
      // 1. Get transaction
      final t = await (select(
        transactions,
      )..where((tbl) => tbl.id.equals(transactionId))).getSingleOrNull();
      if (t == null || t.paymentStatus == 'void') return false;

      // 2. Update status and voidBy
      await (update(
        transactions,
      )..where((tbl) => tbl.id.equals(transactionId))).write(
        TransactionsCompanion(
          paymentStatus: const Value('void'),
          voidBy: Value(supervisorId),
        ),
      );

      // 3. Restore stock (supports both simple and variant products)
      final items = await (select(
        transactionItems,
      )..where((tbl) => tbl.transactionId.equals(transactionId))).get();
      for (final item in items) {
        if (item.variantId != null) {
          // Restore variant stock
          final variant = await (select(productVariants)
                ..where((v) => v.id.equals(item.variantId!)))
              .getSingleOrNull();
          if (variant != null) {
            final newStock = variant.stock + item.quantity;
            await (update(productVariants)
                  ..where((v) => v.id.equals(variant.id)))
                .write(ProductVariantsCompanion(
                  stock: Value(newStock),
                ));
            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: item.productId,
              variantId: Value(variant.id),
              type: 'VOID',
              quantity: item.quantity,
              previousStock: variant.stock,
              newStock: newStock,
              reference: Value('VOID-${t.receiptNumber}'),
              createdAt: DateTime.now().toIso8601String(),
            ));
          }
        } else {
          // Restore product stock
          final product = await (select(
            products,
          )..where((p) => p.id.equals(item.productId))).getSingleOrNull();
          if (product != null) {
            final newStock = product.stock + item.quantity;
            await (update(products)..where((p) => p.id.equals(product.id)))
                .write(
              ProductsCompanion(stock: Value(newStock)),
            );
            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: item.productId,
              type: 'VOID',
              quantity: item.quantity,
              previousStock: product.stock,
              newStock: newStock,
              reference: Value('VOID-${t.receiptNumber}'),
              createdAt: DateTime.now().toIso8601String(),
            ));
          }
        }
      }

      return true;
    });
  }


  // ===== Sales Analytics =====
  Future<int> getTotalRevenue(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.totalAmount.sum()])
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final result = await query.getSingle();
    final total = result.read(transactions.totalAmount.sum());
    return total ?? 0;
  }

  Future<List<ProductSales>> getTopProducts(
    DateTime start,
    DateTime end,
  ) async {
    final amountExp = transactionItems.quantity.sum();
    final query =
        selectOnly(transactionItems).join([
            innerJoin(
              products,
              products.id.equalsExp(transactionItems.productId),
            ),
            innerJoin(
              transactions,
              transactions.id.equalsExp(transactionItems.transactionId),
            ),
          ])
          ..addColumns([products.name, amountExp])
          ..where(transactions.createdAt.isBetweenValues(start, end))
          ..where(transactions.paymentStatus.equals('paid'))
          ..groupBy([products.id])
          ..orderBy([
            OrderingTerm(expression: amountExp, mode: OrderingMode.desc),
          ])
          ..limit(5);

    final result = await query.get();
    return result.map((row) {
      return ProductSales(
        row.read(products.name) ?? 'Unknown',
        row.read(amountExp) ?? 0,
      );
    }).toList();
  }

  Future<List<DailySales>> getDailySales(DateTime start, DateTime end) async {
    final list =
        await (select(transactions)
              ..where((t) => t.createdAt.isBetweenValues(start, end))
              ..where((t) => t.paymentStatus.equals('paid'))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    final Map<String, int> grouped = {};
    for (final t in list) {
      final dateStr = DateFormat('yyyy-MM-dd').format(t.createdAt);
      grouped[dateStr] = (grouped[dateStr] ?? 0) + t.totalAmount;
    }

    return grouped.entries.map((e) => DailySales(e.key, e.value)).toList();
  }

  Future<int> getTotalTransactions(DateTime start, DateTime end) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  Future<List<PaymentMethodSales>> getPaymentMethodBreakdown(
    DateTime start,
    DateTime end,
  ) async {
    final countExp = transactions.id.count();
    final amountExp = transactions.totalAmount.sum();
    final query = selectOnly(transactions)
      ..addColumns([transactions.paymentMethod, countExp, amountExp])
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'))
      ..groupBy([transactions.paymentMethod]);

    final result = await query.get();
    return result.map((row) {
      return PaymentMethodSales(
        row.read(transactions.paymentMethod) ?? 'unknown',
        row.read(amountExp) ?? 0,
        row.read(countExp) ?? 0,
      );
    }).toList();
  }

  Future<int> getTotalGrossProfit(DateTime start, DateTime end) async {
    final report = await getProductProfitReport(start, end);
    final totalProfit = report.fold<int>(0, (sum, p) => sum + p.totalProfit);
    return totalProfit;
  }

  Future<List<ProductProfit>> getProductProfitReport(DateTime start, DateTime end) async {
    final query = select(transactionItems).join([
      innerJoin(products, products.id.equalsExp(transactionItems.productId)),
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)),
    ])
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final results = await query.get();

    final Map<int, ProductProfit> profitMap = {};

    for (var row in results) {
      final item = row.readTable(transactionItems);
      final product = row.readTable(products);

      final revenue = item.subtotal;
      double cost = 0.0;

      // 1. Check if it has recipe
      final recipeCostQuery = selectOnly(productRecipes).join([
        innerJoin(ingredients, ingredients.id.equalsExp(productRecipes.ingredientId)),
      ])
        ..addColumns([productRecipes.quantityNeeded, ingredients.averageCost])
        ..where(productRecipes.productId.equals(product.id));

      final recipeCostResults = await recipeCostQuery.get();
      if (recipeCostResults.isNotEmpty) {
        double unitCost = 0.0;
        for (var rcRow in recipeCostResults) {
          final qtyNeeded = rcRow.read(productRecipes.quantityNeeded) ?? 0.0;
          final avgCost = rcRow.read(ingredients.averageCost) ?? 0.0;
          unitCost += (qtyNeeded * avgCost);
        }
        cost = unitCost * item.quantity;
      } else {
        // 2. Retail HPP Support
        cost = (product.purchasePrice * item.quantity).toDouble();
      }

      int profit = revenue - cost.round();

      if (profitMap.containsKey(product.id)) {
        profitMap[product.id] = ProductProfit(
          product.name,
          profitMap[product.id]!.totalRevenue + revenue,
          profitMap[product.id]!.totalProfit + profit,
        );
      } else {
        profitMap[product.id] = ProductProfit(product.name, revenue, profit);
      }
    }

    final list = profitMap.values.toList();
    list.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return list;
  }

  Future<List<CategoryProfit>> getCategoryProfitReport(DateTime start, DateTime end) async {
    final query = select(transactionItems).join([
      innerJoin(products, products.id.equalsExp(transactionItems.productId)),
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
      innerJoin(transactions, transactions.id.equalsExp(transactionItems.transactionId)),
    ])
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final results = await query.get();

    final Map<int, CategoryProfit> profitMap = {};

    for (var row in results) {
      final item = row.readTable(transactionItems);
      final product = row.readTable(products);
      final category = row.readTable(categories);

      final revenue = item.subtotal;
      double cost = 0.0;

      // 1. Check if it has recipe
      final recipeCostQuery = selectOnly(productRecipes).join([
        innerJoin(ingredients, ingredients.id.equalsExp(productRecipes.ingredientId)),
      ])
        ..addColumns([productRecipes.quantityNeeded, ingredients.averageCost])
        ..where(productRecipes.productId.equals(product.id));

      final recipeCostResults = await recipeCostQuery.get();
      if (recipeCostResults.isNotEmpty) {
        double unitCost = 0.0;
        for (var rcRow in recipeCostResults) {
          final qtyNeeded = rcRow.read(productRecipes.quantityNeeded) ?? 0.0;
          final avgCost = rcRow.read(ingredients.averageCost) ?? 0.0;
          unitCost += (qtyNeeded * avgCost);
        }
        cost = unitCost * item.quantity;
      } else {
        // 2. Retail HPP Support
        cost = (product.purchasePrice * item.quantity).toDouble();
      }

      int profit = revenue - cost.round();

      if (profitMap.containsKey(category.id)) {
        profitMap[category.id] = CategoryProfit(
          category.name,
          profitMap[category.id]!.totalRevenue + revenue,
          profitMap[category.id]!.totalProfit + profit,
        );
      } else {
        profitMap[category.id] = CategoryProfit(category.name, revenue, profit);
      }
    }

    final list = profitMap.values.toList();
    list.sort((a, b) => b.totalRevenue.compareTo(a.totalRevenue));
    return list;
  }

  Future<List<DailySales>> getHourlySales(DateTime start, DateTime end) async {
    final list =
        await (select(transactions)
              ..where((t) => t.createdAt.isBetweenValues(start, end))
              ..where((t) => t.paymentStatus.equals('paid'))
              ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
            .get();

    final Map<String, int> grouped = {};
    for (final t in list) {
      final hourStr = DateFormat('HH:00').format(t.createdAt);
      grouped[hourStr] = (grouped[hourStr] ?? 0) + t.totalAmount;
    }

    return grouped.entries.map((e) => DailySales(e.key, e.value)).toList();
  }

  Future<int> deleteLicense(String code) {
    return (delete(licenses)..where((t) => t.licenseCode.equals(code))).go();
  }

  // ===== Maintenance =====
  Future<void> clearTransactionalData() async {
    await transaction(() async {
      await delete(transactionItems).go();
      await delete(transactions).go();
      await delete(shifts).go();
      await delete(stockTransactions).go();
      await delete(productVariants).go();
      await delete(products).go();
      // categories, employees, licenses, storeProfile, and printerSettings are preserved
    });
  }

  // ===== Ingredients Queries =====
  Future<List<Ingredient>> getAllIngredients() => select(ingredients).get();

  Stream<List<Ingredient>> watchAllIngredients() => select(ingredients).watch();

  Future<int> insertIngredient(IngredientsCompanion entry) =>
      into(ingredients).insert(entry);

  Future<bool> updateIngredient(Ingredient entry) =>
      update(ingredients).replace(entry);

  Future<int> deleteIngredient(Ingredient entry) =>
      delete(ingredients).delete(entry);

  Future<Ingredient?> getIngredientById(int id) =>
      (select(ingredients)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ===== Product Recipes Queries =====
  Future<List<ProductRecipe>> getRecipesByProductId(int productId) =>
      (select(productRecipes)..where((t) => t.productId.equals(productId))).get();

  Stream<List<ProductRecipe>> watchRecipesByProductId(int productId) =>
      (select(productRecipes)..where((t) => t.productId.equals(productId))).watch();

  Future<int> insertProductRecipe(ProductRecipesCompanion entry) =>
      into(productRecipes).insert(entry);

  Future<bool> updateProductRecipe(ProductRecipe entry) =>
      update(productRecipes).replace(entry);

  Future<int> deleteProductRecipe(ProductRecipe entry) =>
      delete(productRecipes).delete(entry);

  Future<void> replaceProductRecipes(
    int productId,
    List<ProductRecipesCompanion> newRecipes,
  ) async {
    await transaction(() async {
      await (delete(productRecipes)..where((r) => r.productId.equals(productId)))
          .go();
      if (newRecipes.isNotEmpty) {
        await batch((b) => b.insertAll(productRecipes, newRecipes));
      }
    });
  }

  // ===== Ingredient Stock History Queries =====
  Future<List<IngredientStockHistoryData>> getIngredientHistory(int ingredientId) =>
      (select(ingredientStockHistory)
            ..where((t) => t.ingredientId.equals(ingredientId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<IngredientStockHistoryData>> watchIngredientHistory(int ingredientId) =>
      (select(ingredientStockHistory)
            ..where((t) => t.ingredientId.equals(ingredientId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<int> insertIngredientStockHistory(
          IngredientStockHistoryCompanion entry) =>
      into(ingredientStockHistory).insert(entry);

  /// Atomically adds stock to an ingredient and records it in history.
  /// [quantityInBaseUnit] must already be converted to the base unit.
  Future<void> addIngredientStock({
    required int ingredientId,
    required double quantityInBaseUnit,
    int? supplierId,
    double? newCostPerUnit,
    String? reason,
  }) async {
    await transaction(() async {
      final ingredient = await getIngredientById(ingredientId);
      if (ingredient == null) return;

      final previousBalance = ingredient.stockQuantity;
      final newBalance = previousBalance + quantityInBaseUnit;

      // Weighted average cost calculation
      double updatedCost = ingredient.averageCost;
      if (newCostPerUnit != null && newCostPerUnit > 0) {
        final totalOldValue = previousBalance * ingredient.averageCost;
        final totalNewValue = quantityInBaseUnit * newCostPerUnit;
        updatedCost = newBalance > 0
            ? (totalOldValue + totalNewValue) / newBalance
            : newCostPerUnit;
      }

      await updateIngredient(ingredient.copyWith(
        stockQuantity: newBalance,
        averageCost: updatedCost,
        lastSupplierId: Value(supplierId),
      ));

      await insertIngredientStockHistory(
        IngredientStockHistoryCompanion.insert(
          ingredientId: ingredientId,
          supplierId: Value(supplierId),
          type: 'PURCHASE',
          quantityChange: quantityInBaseUnit,
          previousBalance: previousBalance,
          newBalance: newBalance,
          reason: Value(reason ?? 'Tambah Stok Manual'),
        ),
      );
    });
  }

  /// Atomically removes stock from an ingredient (e.g. from a sale).
  Future<void> deductIngredientStock({
    required int ingredientId,
    required double quantityInBaseUnit,
    String type = 'SALE',
    String? referenceId,
    String? reason,
  }) async {
    await transaction(() async {
      final ingredient = await getIngredientById(ingredientId);
      if (ingredient == null) return;

      final previousBalance = ingredient.stockQuantity;
      final newBalance = (previousBalance - quantityInBaseUnit).clamp(0.0, double.infinity);

      await updateIngredient(ingredient.copyWith(stockQuantity: newBalance));

      await insertIngredientStockHistory(
        IngredientStockHistoryCompanion.insert(
          ingredientId: ingredientId,
          type: type,
          quantityChange: -quantityInBaseUnit,
          previousBalance: previousBalance,
          newBalance: newBalance,
          referenceId: Value(referenceId),
          reason: Value(reason),
        ),
      );
    });
  }

  // ===== Unit Conversion Queries =====
  Stream<List<UnitConversion>> watchAllUnitConversions() =>
      select(unitConversions).watch();

  Future<List<UnitConversion>> getAllUnitConversions() =>
      select(unitConversions).get();

  Future<int> insertUnitConversion(UnitConversionsCompanion entry) =>
      into(unitConversions).insert(entry);

  Future<bool> updateUnitConversion(UnitConversion entry) =>
      update(unitConversions).replace(entry);

  Future<int> deleteUnitConversion(int id) =>
      (delete(unitConversions)..where((t) => t.id.equals(id))).go();

  Future<List<UnitConversion>> getConversionsForBaseUnit(String baseUnit) =>
      (select(unitConversions)..where((t) => t.toUnit.equals(baseUnit))).get();

  // ===== Full-Structured Stock Opname =====
  Future<int> createDraftOpname(StockOpnameCompanion entry) =>
      into(stockOpname).insert(entry);

  Future<List<StockOpnameData>> getDraftOpnames() =>
      (select(stockOpname)..where((o) => o.status.equals('DRAFT'))).get();

  Stream<List<StockOpnameData>> watchDraftOpnames() =>
      (select(stockOpname)..where((o) => o.status.equals('DRAFT'))).watch();

  Future<StockOpnameData?> getOpnameById(int id) =>
      (select(stockOpname)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<List<StockOpnameItem>> getOpnameItems(int opnameId) =>
      (select(stockOpnameItems)..where((i) => i.stockOpnameId.equals(opnameId))).get();

  Stream<List<StockOpnameItem>> watchOpnameItems(int opnameId) =>
      (select(stockOpnameItems)..where((i) => i.stockOpnameId.equals(opnameId))).watch();

  Future<int> addOpnameItem(StockOpnameItemsCompanion entry) =>
      into(stockOpnameItems).insert(entry);

  Future<bool> updateOpnameItem(StockOpnameItem entry) =>
      update(stockOpnameItems).replace(entry);

  Future<int> removeOpnameItem(int id) =>
      (delete(stockOpnameItems)..where((i) => i.id.equals(id))).go();

  Future<void> submitOpname(int opnameId) async {
    await transaction(() async {
      final opname = await getOpnameById(opnameId);
      if (opname == null || opname.status == 'COMPLETED') return;

      final items = await getOpnameItems(opnameId);
      
      for (final item in items) {
        if (item.variance == 0.0) continue;

        if (opname.type == 'INGREDIENT' && item.ingredientId != null) {
          final ingredient = await getIngredientById(item.ingredientId!);
          if (ingredient != null) {
            await updateIngredient(ingredient.copyWith(stockQuantity: item.physicalStock));
            await insertIngredientStockHistory(
              IngredientStockHistoryCompanion.insert(
                ingredientId: ingredient.id,
                type: 'ADJUST',
                quantityChange: item.variance,
                previousBalance: item.systemStock,
                newBalance: item.physicalStock,
                reason: Value(item.varianceReason ?? 'Opname ${opname.opnameNumber}'),
              ),
            );
          }
        } else if (opname.type == 'PRODUCT' && item.productId != null) {
           final baseProduct = await getProduct(item.productId!);
           if (item.variantId != null) {
             final variant = await getVariant(item.variantId!);
             if (variant != null) {
               await updateVariant(variant.copyWith(stock: item.physicalStock.toInt()));
               await insertStockTransaction(
                 StockTransactionsCompanion.insert(
                   productId: item.productId!,
                   variantId: Value(item.variantId!),
                   type: 'ADJUST',
                   quantity: item.variance.toInt(),
                   previousStock: item.systemStock.toInt(),
                   newStock: item.physicalStock.toInt(),
                   reason: Value(item.varianceReason ?? 'Opname ${opname.opnameNumber}'),
                   createdAt: DateTime.now().toIso8601String(),
                 ),
               );
             }
           } else if (baseProduct != null) {
             await updateProduct(baseProduct.copyWith(stock: item.physicalStock.toInt()));
             await insertStockTransaction(
               StockTransactionsCompanion.insert(
                 productId: item.productId!,
                 type: 'ADJUST',
                 quantity: item.variance.toInt(),
                 previousStock: item.systemStock.toInt(),
                 newStock: item.physicalStock.toInt(),
                 reason: Value(item.varianceReason ?? 'Opname ${opname.opnameNumber}'),
                 createdAt: DateTime.now().toIso8601String(),
               ),
             );
           }
        }
      }

      await update(stockOpname).replace(opname.copyWith(status: 'COMPLETED'));
    });
  }

  // ===== Stock Loss Report =====
  Future<List<StockLossItem>> getStockLossReport(DateTime start, DateTime end) async {
    final startStr = start.toIso8601String();
    final endStr = end.toIso8601String();
    
    final List<StockLossItem> results = [];

    // Products and Variants
    final productQuery = await customSelect(
      '''
      SELECT 
        CASE 
          WHEN p.has_variants = 1 THEN p.name || ' - ' || v.name 
          ELSE p.name 
        END as item_name,
        'PRODUCT' as type,
        IFNULL(i.variance_reason, 'Lainnya') as reason,
        ABS(i.variance) as loss_qty,
        ABS(i.variance) * IFNULL(v.price, p.price) as loss_value
      FROM stock_opname_items i
      INNER JOIN stock_opname o ON o.id = i.stock_opname_id
      INNER JOIN products p ON p.id = i.product_id
      LEFT JOIN product_variants v ON v.id = i.variant_id
      WHERE o.status = 'COMPLETED' AND i.variance < 0
        AND o.created_at >= ? AND o.created_at <= ?
      ''',
      variables: [Variable.withString(startStr), Variable.withString(endStr)],
    ).get();

    for (final row in productQuery) {
      results.add(StockLossItem(
        row.read<String>('item_name'),
        row.read<String>('type'),
        row.read<String>('reason'),
        row.read<double>('loss_qty'),
        row.read<double>('loss_value').round(),
      ));
    }

    // Ingredients
    final ingredientQuery = await customSelect(
      '''
      SELECT 
        ing.name as item_name,
        'INGREDIENT' as type,
        IFNULL(i.variance_reason, 'Lainnya') as reason,
        ABS(i.variance) as loss_qty,
        ABS(i.variance) * ing.average_cost as loss_value
      FROM stock_opname_items i
      INNER JOIN stock_opname o ON o.id = i.stock_opname_id
      INNER JOIN ingredients ing ON ing.id = i.ingredient_id
      WHERE o.status = 'COMPLETED' AND i.variance < 0
        AND o.created_at >= ? AND o.created_at <= ?
      ''',
      variables: [Variable.withString(startStr), Variable.withString(endStr)],
    ).get();

    for (final row in ingredientQuery) {
      results.add(StockLossItem(
        row.read<String>('item_name'),
        row.read<String>('type'),
        row.read<String>('reason'),
        row.read<double>('loss_qty'),
        row.read<double>('loss_value').round(),
      ));
    }

    return results;
  }
}

class ProductWithVariants {
  final Product product;
  final List<ProductVariant> variants;
  ProductWithVariants({required this.product, required this.variants});

  int get totalStock {
    if (variants.isEmpty) return product.stock;
    return variants.fold(0, (sum, v) => sum + v.stock);
  }
}

class ProductSales {
  final String productName;
  final int totalQuantity;
  ProductSales(this.productName, this.totalQuantity);
}

class ProductProfit {
  final String productName;
  final int totalRevenue;
  final int totalProfit;
  ProductProfit(this.productName, this.totalRevenue, this.totalProfit);
}

class CategoryProfit {
  final String categoryName;
  final int totalRevenue;
  final int totalProfit;
  CategoryProfit(this.categoryName, this.totalRevenue, this.totalProfit);
}

class DailySales {
  final String dateStr;
  final int totalAmount;
  DailySales(this.dateStr, this.totalAmount);
}

class PaymentMethodSales {
  final String method;
  final int totalAmount;
  final int transactionCount;
  PaymentMethodSales(this.method, this.totalAmount, this.transactionCount);
}

class ShiftWithEmployee {
  final Shift shift;
  final Employee employee;
  ShiftWithEmployee({required this.shift, required this.employee});
}

class TransactionWithItems {
  final Transaction transaction;
  final List<TransactionItemWithProduct> items;
  TransactionWithItems({required this.transaction, required this.items});
}

class TransactionItemWithProduct {
  final TransactionItem item;
  final Product product;
  TransactionItemWithProduct({required this.item, required this.product});
}

class StockLossItem {
  final String itemName;
  final String type; // 'PRODUCT', 'INGREDIENT'
  final String reason;
  final double varianceQuantity;
  final int lossValue;

  StockLossItem(this.itemName, this.type, this.reason, this.varianceQuantity, this.lossValue);
}

class ExpenseWithCategory {
  final Expense expense;
  final ExpenseCategory? category;
  ExpenseWithCategory({required this.expense, this.category});
}

class DailyExpenseSummary {
  final DateTime date;
  final int total;
  DailyExpenseSummary({required this.date, required this.total});
}

class CashFlowData {
  final int totalRevenue;
  final int totalExpense;
  final List<DailyExpenseSummary> daily;

  CashFlowData({
    required this.totalRevenue,
    required this.totalExpense,
    required this.daily,
  });

  int get netProfit => totalRevenue - totalExpense;
}

class CustomerLoyaltyStat {
  final Customer customer;
  final int transactionCount;
  final int totalSpend;

  const CustomerLoyaltyStat({
    required this.customer,
    required this.transactionCount,
    required this.totalSpend,
  });
}

String _generateRandomKey() {
  final random = Random.secure();
  final values = List<int>.generate(32, (i) => random.nextInt(256));
  return base64UrlEncode(values);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'posify.db'));

    // Ambil atau buat kunci dekripsi dari memori aman (Secure Storage)
    const storage = FlutterSecureStorage();
    String? encryptionKey = await storage.read(key: 'db_encryption_key');
    
    if (encryptionKey == null) {
      encryptionKey = _generateRandomKey();
      await storage.write(key: 'db_encryption_key', value: encryptionKey);
    }

    // Buat database di latar belakang dan gunakan konfigurasi kunci PRAGMA
    return NativeDatabase.createInBackground(
      file,
      setup: (database) {
        // Peringatan: Jalankan PRAGMA key untuk dekripsi
        database.execute("PRAGMA key = '\$encryptionKey';");
      },
    );
  });
}
