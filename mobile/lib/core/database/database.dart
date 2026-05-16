import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math';

import '../utils/uuid_generator.dart';

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
import 'tables/transaction_payments_table.dart';
import 'tables/outlets_table.dart';
import 'tables/sync_queue_table.dart';

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
    TransactionPayments,
    Outlets,
    SyncQueue,
  ],
)
class LumioDatabase extends _$LumioDatabase {
  final syncQueueNotifier = StreamController<void>.broadcast();

  LumioDatabase() : super(_openConnection());

  // For testing
  LumioDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 28;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (m) async {
        await m.createAll();
        await _createSyncTriggers(m);
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
          await m.addColumn(
            ingredientStockHistory,
            ingredientStockHistory.supplierId,
          );
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
              ExpenseCategoriesCompanion.insert(
                name: 'Bahan Baku',
                icon: const Value('inventory_2'),
                color: const Value('#E67E22'),
                isDefault: const Value(true),
              ),
              ExpenseCategoriesCompanion.insert(
                name: 'Gaji & Upah',
                icon: const Value('people'),
                color: const Value('#27AE60'),
                isDefault: const Value(true),
              ),
              ExpenseCategoriesCompanion.insert(
                name: 'Listrik & Air',
                icon: const Value('bolt'),
                color: const Value('#2980B9'),
                isDefault: const Value(true),
              ),
              ExpenseCategoriesCompanion.insert(
                name: 'Operasional',
                icon: const Value('build'),
                color: const Value('#1E3A5F'),
                isDefault: const Value(true),
              ),
              ExpenseCategoriesCompanion.insert(
                name: 'Lain-lain',
                icon: const Value('more_horiz'),
                color: const Value('#7F8C8D'),
                isDefault: const Value(true),
              ),
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
          await m.database.customStatement(
            'DROP TABLE IF EXISTS transaction_items;',
          );
          await m.database.customStatement(
            'DROP TABLE IF EXISTS transactions;',
          );
          await m.createTable(transactions);
          await m.createTable(transactionItems);
          await m.database.customStatement('PRAGMA foreign_keys = ON;');
        }
        if (from < 21) {
          await m.createTable(transactionPayments);
        }
        if (from < 22) {
          await m.addColumn(printerSettings, printerSettings.autoPrint);
        }
        if (from < 24) {
          await _createSyncTriggers(m);
        }
        if (from < 25) {
          await m.addColumn(licenses, licenses.tierLevel);
          await m.addColumn(licenses, licenses.maxDevices);
          await m.addColumn(licenses, licenses.maxOutlets);
          // Set default values for existing licenses to prevent null-checks failure
          await m.database.customStatement(
            'UPDATE licenses SET max_devices = 1, max_outlets = 1 WHERE max_outlets IS NULL',
          );
        }
        if (from < 26) {
          // Critical fix: All UUID-based tables were missing primaryKey override.
          // Drift's replace() and ON CONFLICT(id) SQL upsert both require a real
          // SQLite PRIMARY KEY constraint. We must recreate affected tables.
          // Safe to use destructive recreation because data is synced from Supabase.
          await m.database.customStatement('PRAGMA foreign_keys = OFF;');

          // Recreate all tables that need PRIMARY KEY fix
          const tablesToRecreate = [
            'outlets',
            'employees',
            'categories',
            'products',
            'product_variants',
            'customers',
            'suppliers',
            'shifts',
            'transactions',
            'transaction_items',
            'transaction_payments',
            'discounts',
            'expenses',
            'expense_categories',
            'purchase_orders',
            'purchase_order_items',
            'stock_opname',
            'stock_opname_items',
            'ingredients',
            'store_profile',
            'licenses',
          ];

          for (final t in tablesToRecreate) {
            await m.database.customStatement('DROP TABLE IF EXISTS ${t}_old;');
            await m.database.customStatement(
              'ALTER TABLE $t RENAME TO ${t}_old;',
            );
          }

          // Recreate all tables fresh (with correct PRIMARY KEY via Drift)
          await m.createAll();
          await _createSyncTriggers(m);

          // Restore data row by row
          for (final t in tablesToRecreate) {
            try {
              // Copy columns that exist in both old and new table
              await m.database.customStatement(
                'INSERT OR IGNORE INTO $t SELECT * FROM ${t}_old;',
              );
            } catch (_) {
              // Some columns may have changed - best effort copy
            }
            await m.database.customStatement('DROP TABLE IF EXISTS ${t}_old;');
          }

          await m.database.customStatement('PRAGMA foreign_keys = ON;');
        }
        if (from < 27) {
          await m.database.customStatement('PRAGMA foreign_keys = OFF;');
          const allTables = [
            'outlets',
            'employees',
            'categories',
            'products',
            'product_variants',
            'customers',
            'suppliers',
            'shifts',
            'transactions',
            'transaction_items',
            'transaction_payments',
            'discounts',
            'expenses',
            'expense_categories',
            'purchase_orders',
            'purchase_order_items',
            'stock_opname',
            'stock_opname_items',
            'ingredients',
            'store_profile',
            'licenses',
            'product_recipes',
            'stock_transactions',
            'unit_conversions',
            'ingredient_stock_history',
            'printer_settings',
          ];
          for (final t in allTables) {
            await m.database.customStatement('DROP TABLE IF EXISTS $t;');
          }
          await m.createAll();
          await _createSyncTriggers(m);
          await m.database.customStatement('PRAGMA foreign_keys = ON;');
        }
        if (from < 28) {
          await m.createTable(syncQueue);
          await _dropSyncTriggers(m); // Clean up old triggers
        }
      },
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
        await _fixLegacyDummyIds();
      },
    );
  }

  Future<void> _dropSyncTriggers(Migrator m) async {
    final tables = [
      'outlets',
      'categories',
      'suppliers',
      'customers',
      'products',
      'product_variants',
      'ingredients',
      'discounts',
      'employees',
      'shifts',
      'transactions',
      'transaction_items',
      'transaction_payments',
      'expenses',
      'purchase_orders',
      'stock_opname',
      'stock_opname_items',
      'licenses',
      'store_profile',
      'printer_settings',
      'product_recipes',
      'unit_conversions',
    ];

    for (final table in tables) {
      await m.database.customStatement(
        'DROP TRIGGER IF EXISTS trg_${table}_mark_dirty;',
      );
    }
  }

  Future<void> _createSyncTriggers(Migrator m) async {
    // Triggers are no longer created starting schema 28
  }

  Future<void> enqueueSync(
    String tableName,
    String operation,
    String recordId,
  ) async {
    await into(syncQueue).insert(
      SyncQueueCompanion.insert(
        targetTable: tableName,
        operation: operation,
        recordId: recordId,
      ),
    );
    syncQueueNotifier.add(null);
  }

  // ===== License Queries =====
  Future<License?> getLocalLicense() =>
      (select(licenses)..limit(1)).getSingleOrNull();

  Future<String> insertLicense(LicensesCompanion entry) async {
    final row = await into(licenses).insertReturning(entry);
    return row.id;
  }

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

  Future<Employee?> getEmployeeById(String id) =>
      (select(employees)..where((e) => e.id.equals(id))).getSingleOrNull();

  Future<Employee?> getOwner() => (select(
    employees,
  )..where((e) => e.role.equals('owner'))).getSingleOrNull();

  Future<String> insertEmployee(EmployeesCompanion entry) async {
    final row = await into(employees).insertReturning(entry);
    await enqueueSync('employees', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateEmployee(Employee entry) async {
    final success = await update(employees).replace(entry);
    if (success) await enqueueSync('employees', 'UPDATE', entry.id);
    return success;
  }

  Future<int> updateEmployeePin(String employeeId, String newPin) async {
    final count =
        await (update(employees)..where((t) => t.id.equals(employeeId))).write(
          EmployeesCompanion(pin: Value(newPin)),
        );
    if (count > 0) await enqueueSync('employees', 'UPDATE', employeeId);
    return count;
  }

  // ===== Store Profile Queries =====
  Future<StoreProfileData?> getStoreProfile() =>
      (select(storeProfile)..limit(1)).getSingleOrNull();

  Stream<StoreProfileData?> watchStoreProfile() =>
      (select(storeProfile)..limit(1)).watchSingleOrNull();

  Future<String> insertStoreProfile(StoreProfileCompanion entry) async {
    final row = await into(storeProfile).insertReturning(entry);
    await enqueueSync('store_profile', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateStoreProfile(StoreProfileData entry) async {
    final success = await update(storeProfile).replace(entry);
    if (success) await enqueueSync('store_profile', 'UPDATE', entry.id);
    return success;
  }

  // ===== Outlet Queries =====
  Future<List<Outlet>> getAllOutlets() => select(outlets).get();

  Stream<List<Outlet>> watchAllOutlets() => select(outlets).watch();

  Future<Outlet?> getOutlet(String id) =>
      (select(outlets)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<String> insertOutlet(OutletsCompanion entry) async {
    final row = await into(outlets).insertReturning(entry);
    await enqueueSync('outlets', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateOutlet(Outlet entry) async {
    final success = await update(outlets).replace(entry);
    if (success) await enqueueSync('outlets', 'UPDATE', entry.id);
    return success;
  }

  // ===== Category Queries =====
  Future<List<Category>> getAllCategories(String outletId) => (select(
    categories,
  )..where((c) => c.outletId.equals(outletId) & c.deletedAt.isNull())).get();

  Stream<List<Category>> watchAllCategories(String outletId) => (select(
    categories,
  )..where((c) => c.outletId.equals(outletId) & c.deletedAt.isNull())).watch();

  Future<String> insertCategory(CategoriesCompanion entry) async {
    final row = await into(categories).insertReturning(entry);
    await enqueueSync('categories', 'INSERT', row.id);
    return row.id;
  }

  // ===== Product Management =====
  Future<List<Product>> getAllProducts(String outletId) => (select(
    products,
  )..where((p) => p.outletId.equals(outletId) & p.deletedAt.isNull())).get();
  Stream<List<Product>> watchAllProducts(String outletId) => (select(
    products,
  )..where((p) => p.outletId.equals(outletId) & p.deletedAt.isNull())).watch();
  Future<String> insertProduct(ProductsCompanion entry) async {
    final row = await into(products).insertReturning(entry);
    await enqueueSync('products', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateProduct(Product entry) async {
    final success = await update(products).replace(entry);
    if (success) await enqueueSync('products', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteProduct(Product entry) async {
    final count = await delete(products).delete(entry);
    if (count > 0) await enqueueSync('products', 'DELETE', entry.id);
    return count;
  }

  Future<void> insertMultipleProducts(List<ProductsCompanion> entries) async {
    await batch((batch) {
      batch.insertAll(products, entries, mode: InsertMode.insertOrReplace);
      final syncTasks = entries
          .map(
            (e) => SyncQueueCompanion.insert(
              targetTable: 'products',
              operation: 'UPSERT',
              recordId: e.id.value,
            ),
          )
          .toList();
      batch.insertAll(syncQueue, syncTasks);
    });
  }

  // ===== Product Variants =====
  Future<List<ProductVariant>> getAllVariants() =>
      (select(productVariants)..where((v) => v.deletedAt.isNull())).get();

  Stream<List<ProductVariant>> watchVariantsByProduct(String productId) =>
      (select(
            productVariants,
          )..where((v) => v.productId.equals(productId) & v.deletedAt.isNull()))
          .watch();

  Future<List<ProductVariant>> getVariantsByProduct(String productId) async {
    return (select(productVariants)
          ..where((v) => v.productId.equals(productId) & v.deletedAt.isNull()))
        .get();
  }

  Future<String> insertVariant(ProductVariantsCompanion entry) async {
    final row = await into(productVariants).insertReturning(entry);
    await enqueueSync('product_variants', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateVariant(ProductVariant entry) async {
    final success = await update(productVariants).replace(entry);
    if (success) await enqueueSync('product_variants', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteVariant(ProductVariant entry) async {
    final count = await delete(productVariants).delete(entry);
    if (count > 0) await enqueueSync('product_variants', 'DELETE', entry.id);
    return count;
  }

  Future<ProductVariant?> getVariant(String id) => (select(
    productVariants,
  )..where((v) => v.id.equals(id))).getSingleOrNull();

  Future<void> deleteVariantsByProduct(String productId) => (delete(
    productVariants,
  )..where((v) => v.productId.equals(productId))).go();

  Future<void> replaceVariants(
    String productId,
    List<ProductVariantsCompanion> newVariants,
  ) async {
    await transaction(() async {
      // Queue deletions for existing variants before removing them
      final existing = await getVariantsByProduct(productId);
      for (final v in existing) {
        await enqueueSync('product_variants', 'DELETE', v.id);
      }
      await deleteVariantsByProduct(productId);

      if (newVariants.isNotEmpty) {
        await batch((b) {
          b.insertAll(productVariants, newVariants);
          final syncTasks = newVariants
              .map(
                (e) => SyncQueueCompanion.insert(
                  targetTable: 'product_variants',
                  operation: 'INSERT',
                  recordId: e.id.value,
                ),
              )
              .toList();
          b.insertAll(syncQueue, syncTasks);
        });
      }
    });
  }

  // ===== Shift Queries =====
  Future<Product?> getProduct(String id) =>
      (select(products)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<Product?> getProductBySku(String sku) =>
      (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();

  Future<ProductWithVariants?> getProductWithVariants(String id) async {
    final product = await (select(
      products,
    )..where((p) => p.id.equals(id) & p.deletedAt.isNull())).getSingleOrNull();
    if (product == null) return null;

    final variants = await (select(
      productVariants,
    )..where((p) => p.productId.equals(id) & p.deletedAt.isNull())).get();
    return ProductWithVariants(product: product, variants: variants);
  }

  Future<List<ProductWithVariants>> getAllProductsWithVariants(
    String outletId,
  ) async {
    final allProducts = await getAllProducts(outletId);
    final allVariants = await getAllVariants();

    return allProducts.map((p) {
      final productVariants = allVariants
          .where((v) => v.productId == p.id)
          .toList();
      return ProductWithVariants(product: p, variants: productVariants);
    }).toList();
  }

  Stream<List<ProductWithVariants>> watchAllProductsWithVariants(
    String outletId,
  ) {
    final query = select(products).join([
      leftOuterJoin(
        productVariants,
        productVariants.productId.equalsExp(products.id) &
            productVariants.deletedAt.isNull(),
      ),
    ])..where(products.outletId.equals(outletId) & products.deletedAt.isNull());

    return query.watch().map((rows) {
      final results = <String, ProductWithVariants>{};

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

  Future<Shift?> getOpenShift(String outletId) =>
      (select(shifts)..where(
            (s) => s.outletId.equals(outletId) & s.status.equals('open'),
          ))
          .getSingleOrNull();

  Stream<Shift?> watchOpenShift(String outletId) =>
      (select(shifts)..where(
            (s) => s.outletId.equals(outletId) & s.status.equals('open'),
          ))
          .watchSingleOrNull();

  Future<String> insertShift(ShiftsCompanion entry) async {
    final row = await into(shifts).insertReturning(entry);
    await enqueueSync('shifts', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateShift(Shift entry) async {
    final success = await update(shifts).replace(entry);
    if (success) await enqueueSync('shifts', 'UPDATE', entry.id);
    return success;
  }

  // ===== Transaction Queries =====
  Stream<List<Transaction>> watchTransactionsByShift(String shiftId) =>
      (select(transactions)..where((t) => t.shiftId.equals(shiftId))).watch();

  Future<String> insertTransaction(TransactionsCompanion entry) async {
    final row = await into(transactions).insertReturning(entry);
    await enqueueSync('transactions', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateTransaction(Transaction entry) async {
    final success = await update(transactions).replace(entry);
    if (success) await enqueueSync('transactions', 'UPDATE', entry.id);
    return success;
  }

  // ===== Transaction Items =====
  Future<List<TransactionItem>> getItemsByTransaction(String transactionId) =>
      (select(
        transactionItems,
      )..where((ti) => ti.transactionId.equals(transactionId))).get();

  Future<String> insertTransactionItem(TransactionItemsCompanion entry) async {
    final row = await into(transactionItems).insertReturning(entry);
    await enqueueSync('transaction_items', 'INSERT', row.id);
    return row.id;
  }

  // ===== Stock Transactions =====
  Future<String> insertStockTransaction(
    StockTransactionsCompanion entry,
  ) async {
    final row = await into(stockTransactions).insertReturning(entry);
    await enqueueSync('stock_transactions', 'INSERT', row.id);
    return row.id;
  }

  Future<DateTime?> getLastAdjustDate(
    String productId, {
    String? variantId,
  }) async {
    final query = select(stockTransactions);

    if (productId != '0') {
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
  Future<List<Customer>> getAllCustomers(String outletId) => (select(
    customers,
  )..where((c) => c.outletId.equals(outletId) & c.deletedAt.isNull())).get();
  Stream<List<Customer>> watchAllCustomers(String outletId) => (select(
    customers,
  )..where((c) => c.outletId.equals(outletId) & c.deletedAt.isNull())).watch();
  Future<String> insertCustomer(CustomersCompanion entry) async {
    final row = await into(customers).insertReturning(entry);
    await enqueueSync('customers', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateCustomer(Customer entry) async {
    final success = await update(customers).replace(entry);
    if (success) await enqueueSync('customers', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteCustomer(Customer entry) async {
    final count = await (delete(
      customers,
    )..where((c) => c.id.equals(entry.id))).go();
    if (count > 0) await enqueueSync('customers', 'DELETE', entry.id);
    return count;
  }

  /// Returns all customers who have at least 1 transaction, with aggregated stats.
  /// Sorted by points descending by default.
  Future<List<CustomerLoyaltyStat>> getLoyaltyLeaderboard(
    String outletId,
  ) async {
    final result = await customSelect(
      '''
      SELECT
        c.*,
        COUNT(t.id) AS transaction_count,
        COALESCE(SUM(t.total_amount), 0) AS total_spend
      FROM customers c
      INNER JOIN transactions t ON t.customer_id = c.id
      WHERE c.outlet_id = ?
      GROUP BY c.id
      ORDER BY c.points DESC
      ''',
      variables: [Variable.withString(outletId)],
      readsFrom: {customers, transactions},
    ).get();

    return result.map((row) {
      final customer = Customer(
        id: row.read<String>('id'),
        name: row.read<String>('name'),
        phone: row.readNullable<String>('phone'),
        email: row.readNullable<String>('email'),
        address: row.readNullable<String>('address'),
        isMember: row.read<bool>('is_member'),
        points: row.read<int>('points'),
        createdAt: row.read<DateTime>('created_at'),
        updatedAt: row.read<DateTime>('updated_at'),
        isDirty: row.read<bool>('is_dirty'),
      );
      return CustomerLoyaltyStat(
        customer: customer,
        transactionCount: row.read<int>('transaction_count'),
        totalSpend: row.read<int>('total_spend'),
      );
    }).toList();
  }

  Future<List<Supplier>> getAllSuppliers(String outletId) => (select(
    suppliers,
  )..where((s) => s.outletId.equals(outletId) & s.deletedAt.isNull())).get();
  Stream<List<Supplier>> watchAllSuppliers(String outletId) => (select(
    suppliers,
  )..where((s) => s.outletId.equals(outletId) & s.deletedAt.isNull())).watch();
  Future<String> insertSupplier(SuppliersCompanion entry) async {
    final row = await into(suppliers).insertReturning(entry);
    await enqueueSync('suppliers', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateSupplier(Supplier entry) async {
    final success = await update(suppliers).replace(entry);
    if (success) await enqueueSync('suppliers', 'UPDATE', entry.id);
    return success;
  }

  // ===== Atomic Stock Update Helpers =====
  Future<void> _atomicProductStock(String productId, int quantityDelta) async {
    if (quantityDelta == 0) return;
    final sign = quantityDelta > 0 ? '+' : '-';
    await customStatement(
      'UPDATE products SET stock = stock $sign ? WHERE id = ?',
      [quantityDelta.abs(), productId],
    );
    await (update(products)..where((p) => p.id.equals(productId))).write(
      ProductsCompanion(updatedAt: Value(DateTime.now())),
    );
    await enqueueSync('products', 'UPDATE', productId);
  }

  Future<void> _atomicVariantStock(String variantId, int quantityDelta) async {
    if (quantityDelta == 0) return;
    final sign = quantityDelta > 0 ? '+' : '-';
    await customStatement(
      'UPDATE product_variants SET stock = stock $sign ? WHERE id = ?',
      [quantityDelta.abs(), variantId],
    );
    await (update(productVariants)..where((v) => v.id.equals(variantId))).write(
      ProductVariantsCompanion(updatedAt: Value(DateTime.now())),
    );
    await enqueueSync('product_variants', 'UPDATE', variantId);
  }

  // ===== Stock In (Purchase from Supplier) =====
  Future<void> processStockIn({
    required String productId,
    String? variantId,
    required int quantity,
    required int unitCost,
    String? supplierId,
    String? note,
    String? invoiceRef,
    String? outletId,
  }) async {
    return transaction(() async {
      final now = DateTime.now();

      if (variantId != null) {
        final variant = await (select(
          productVariants,
        )..where((v) => v.id.equals(variantId))).getSingleOrNull();
        if (variant == null) throw Exception('Variant not found');

        final product = await (select(
          products,
        )..where((p) => p.id.equals(productId))).getSingleOrNull();
        if (product == null) throw Exception('Product not found');

        final newStock = variant.stock + quantity;
        final newProductStock = product.stock + quantity;

        // Update variant stock
        await _atomicVariantStock(variantId, quantity);

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

        await _atomicProductStock(productId, quantity);
        await (update(products)..where((p) => p.id.equals(productId))).write(
          ProductsCompanion(purchasePrice: Value(newHpp)),
        );

        await insertStockTransaction(
          StockTransactionsCompanion.insert(
            productId: productId,
            variantId: Value(variantId),
            supplierId: Value(supplierId),
            type: 'IN',
            quantity: quantity,
            previousStock: variant.stock,
            newStock: newStock,
            reason: Value(note),
            reference: Value(invoiceRef),
            createdAt: Value(now),
            outletId: outletId != null ? Value(outletId) : const Value.absent(),
          ),
        );
      } else {
        final product = await (select(
          products,
        )..where((p) => p.id.equals(productId))).getSingleOrNull();
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

        await _atomicProductStock(productId, quantity);
        await (update(products)..where((p) => p.id.equals(productId))).write(
          ProductsCompanion(purchasePrice: Value(newHpp)),
        );
        await insertStockTransaction(
          StockTransactionsCompanion.insert(
            productId: productId,
            supplierId: Value(supplierId),
            type: 'IN',
            quantity: quantity,
            previousStock: product.stock,
            newStock: newStock,
            reason: Value(note),
            reference: Value(invoiceRef),
            createdAt: Value(now),
            outletId: outletId != null ? Value(outletId) : const Value.absent(),
          ),
        );
      }
    });
  }

  Future<void> processStockOut({
    required String productId,
    String? variantId,
    required int quantity,
    String? supplierId,
    String? note,
    String? invoiceRef,
    String? outletId,
  }) async {
    final now = DateTime.now();
    await transaction(() async {
      if (variantId != null) {
        final variant = await (select(
          productVariants,
        )..where((v) => v.id.equals(variantId))).getSingleOrNull();
        if (variant == null) throw Exception('Variant not found');

        final product = await (select(
          products,
        )..where((p) => p.id.equals(productId))).getSingleOrNull();
        if (product == null) throw Exception('Product not found');

        final newStock = variant.stock - quantity;

        // Update variant stock
        await _atomicVariantStock(variantId, -quantity);

        // Also update main product aggregate stock
        await _atomicProductStock(productId, -quantity);

        await insertStockTransaction(
          StockTransactionsCompanion.insert(
            productId: productId,
            variantId: Value(variantId),
            supplierId: Value(supplierId),
            type: 'OUT',
            quantity: quantity,
            previousStock: variant.stock,
            newStock: newStock,
            reason: Value(note),
            reference: Value(invoiceRef),
            createdAt: Value(now),
            outletId: outletId != null ? Value(outletId) : const Value.absent(),
          ),
        );
      } else {
        final product = await (select(
          products,
        )..where((p) => p.id.equals(productId))).getSingleOrNull();
        if (product == null) throw Exception('Product not found');

        final newStock = product.stock - quantity;
        await _atomicProductStock(productId, -quantity);

        await insertStockTransaction(
          StockTransactionsCompanion.insert(
            productId: productId,
            supplierId: Value(supplierId),
            type: 'OUT',
            quantity: quantity,
            previousStock: product.stock,
            newStock: newStock,
            reason: Value(note),
            reference: Value(invoiceRef),
            createdAt: Value(now),
            outletId: outletId != null ? Value(outletId) : const Value.absent(),
          ),
        );
      }
    });
  }

  // ===== Stock Card (Full log for a product) =====
  Stream<List<StockTransactionWithProduct>>
  watchAllStockTransactionsWithProduct() {
    final query = select(stockTransactions).join([
      innerJoin(products, products.id.equalsExp(stockTransactions.productId)),
      leftOuterJoin(
        productVariants,
        productVariants.id.equalsExp(stockTransactions.variantId),
      ),
    ])..orderBy([OrderingTerm.desc(stockTransactions.createdAt)]);

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

  Future<List<StockTransaction>> getStockCard(
    String productId, {
    String? variantId,
  }) {
    final query = select(stockTransactions)
      ..where((t) => t.productId.equals(productId))
      ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);
    if (variantId != null) {
      query.where((t) => t.variantId.equals(variantId));
    }
    return query.get();
  }

  // ===== Low Stock products =====
  Future<List<Product>> getLowStockProducts() =>
      (select(products)..where(
            (p) =>
                p.lowStockThreshold.isBiggerThanValue(0) &
                p.stock.isSmallerThanValue(999999),
          )) // will filter in Dart below
          .get();

  Future<List<Product>> getLowStockProductsFiltered({String? outletId}) async {
    final query = select(products);
    if (outletId != null) {
      query.where((p) => p.outletId.equals(outletId));
    }
    final all = await query.get();
    return all
        .where((p) => p.lowStockThreshold > 0 && p.stock <= p.lowStockThreshold)
        .toList();
  }

  Future<List<Ingredient>> getLowStockIngredients({String? outletId}) async {
    final query = select(ingredients);
    if (outletId != null) {
      query.where((i) => i.outletId.equals(outletId));
    }
    final all = await query.get();
    return all
        .where(
          (i) =>
              i.minStockThreshold > 0 && i.stockQuantity <= i.minStockThreshold,
        )
        .toList();
  }

  // ===== Purchase Order (PO) Queries =====

  Future<List<PurchaseOrder>> getAllPurchaseOrders(String outletId) =>
      (select(purchaseOrders)
            ..where((po) => po.outletId.equals(outletId))
            ..orderBy([(po) => OrderingTerm.desc(po.orderedAt)]))
          .get();

  Stream<List<PurchaseOrder>> watchAllPurchaseOrders(String outletId) =>
      (select(purchaseOrders)
            ..where((po) => po.outletId.equals(outletId))
            ..orderBy([(po) => OrderingTerm.desc(po.orderedAt)]))
          .watch();

  Future<List<PurchaseOrderItem>> getPurchaseOrderItems(String poId) => (select(
    purchaseOrderItems,
  )..where((i) => i.purchaseOrderId.equals(poId))).get();

  Future<String> createPurchaseOrder(PurchaseOrdersCompanion entry) async {
    final row = await into(purchaseOrders).insertReturning(entry);
    await enqueueSync('purchase_orders', 'INSERT', row.id);
    return row.id;
  }

  Future<void> addPurchaseOrderItem(PurchaseOrderItemsCompanion entry) async {
    final row = await into(purchaseOrderItems).insertReturning(entry);
    await enqueueSync('purchase_order_items', 'INSERT', row.id);
  }

  Future<void> updatePurchaseOrderStatus(String poId, String status) async {
    await (update(purchaseOrders)..where((po) => po.id.equals(poId))).write(
      PurchaseOrdersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await enqueueSync('purchase_orders', 'UPDATE', poId);
  }

  /// Marks PO as received, updates received quantities,
  /// and auto-increments product or ingredient stock.
  Future<void> receivePurchaseOrder({
    required String poId,
    required List<({String itemId, double receivedQty})> receivedItems,
  }) async {
    await transaction(() async {
      final now = DateTime.now();

      for (final received in receivedItems) {
        // Update received quantity on the PO item
        await (update(
          purchaseOrderItems,
        )..where((i) => i.id.equals(received.itemId))).write(
          PurchaseOrderItemsCompanion(
            receivedQuantity: Value(received.receivedQty),
          ),
        );

        // Fetch the PO item to determine which stock to update
        final item = await (select(
          purchaseOrderItems,
        )..where((i) => i.id.equals(received.itemId))).getSingleOrNull();
        if (item == null || received.receivedQty <= 0) continue;

        if (item.productId != null) {
          // Update product stock
          final product = await (select(
            products,
          )..where((p) => p.id.equals(item.productId!))).getSingleOrNull();
          if (product != null) {
            final qty = received.receivedQty.round();
            final newStock = product.stock + qty;
            await _atomicProductStock(product.id, qty);
            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: product.id,
                type: 'IN',
                quantity: qty,
                previousStock: product.stock,
                newStock: newStock,
                reason: Value('Penerimaan PO #$poId'),
                reference: Value('PO-$poId'),
                createdAt: Value(now),
                outletId: Value(item.outletId!),
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
            outletId: item.outletId,
          );
        }
      }

      // Mark PO as received
      await updatePurchaseOrderStatus(poId, 'received');
    });
  }

  // ===== Discount Queries =====

  Future<List<Discount>> getAllDiscounts(String outletId) =>
      (select(discounts)
            ..where((d) => d.outletId.equals(outletId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .get();

  Stream<List<Discount>> watchAllDiscounts(String outletId) =>
      (select(discounts)
            ..where((d) => d.outletId.equals(outletId))
            ..orderBy([(d) => OrderingTerm.desc(d.createdAt)]))
          .watch();

  Future<int> upsertDiscount(DiscountsCompanion entry) async {
    final id = await into(discounts).insertOnConflictUpdate(entry);
    await enqueueSync('discounts', 'UPSERT', entry.id.value);
    return id;
  }

  Future<int> deleteDiscount(String id) async {
    final count = await (delete(discounts)..where((d) => d.id.equals(id))).go();
    if (count > 0) await enqueueSync('discounts', 'DELETE', id);
    return count;
  }

  Future<List<Discount>> getValidDiscounts({
    required double cartTotal,
    required String scope,
    required String outletId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final all =
        await (select(discounts)..where(
              (d) =>
                  d.outletId.equals(outletId) &
                  d.isActive.equals(true) &
                  d.scope.equals(scope),
            ))
            .get();
    return all.where((d) {
      final afterStart = !d.startDate.isAfter(today);
      final beforeEnd = d.endDate == null || !d.endDate!.isBefore(today);
      final meetsMin = cartTotal >= d.minSpend;
      return afterStart && beforeEnd && meetsMin;
    }).toList();
  }

  // ===== Expense Category Queries =====

  Future<List<ExpenseCategory>> getAllExpenseCategories(String outletId) =>
      (select(expenseCategories)
            ..where((c) => c.outletId.equals(outletId))
            ..orderBy([(c) => OrderingTerm.asc(c.name)]))
          .get();

  Future<int> upsertExpenseCategory(ExpenseCategoriesCompanion entry) async {
    final id = await into(expenseCategories).insertOnConflictUpdate(entry);
    await enqueueSync('expense_categories', 'UPSERT', entry.id.value);
    return id;
  }

  Future<int> deleteExpenseCategory(String id) async {
    final count = await (delete(
      expenseCategories,
    )..where((c) => c.id.equals(id))).go();
    if (count > 0) await enqueueSync('expense_categories', 'DELETE', id);
    return count;
  }

  // ===== Expense Queries =====

  /// Returns all expenses for a given day, joined with their category.
  Future<List<ExpenseWithCategory>> getExpensesWithCategory({
    required DateTime date,
    required String outletId,
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows =
        await (select(expenses)
              ..where(
                (e) =>
                    e.outletId.equals(outletId) &
                    e.createdAt.isBiggerOrEqualValue(startOfDay) &
                    e.createdAt.isSmallerThanValue(endOfDay),
              )
              ..orderBy([(e) => OrderingTerm.desc(e.createdAt)]))
            .get();

    final categories = {
      for (final c in await getAllExpenseCategories(outletId)) c.id: c,
    };

    return rows.map((e) {
      return ExpenseWithCategory(
        expense: e,
        category: categories[e.categoryId],
      );
    }).toList();
  }

  Future<String> insertExpense(ExpensesCompanion entry) async {
    final row = await into(expenses).insertReturning(entry);
    await enqueueSync('expenses', 'INSERT', row.id);
    return row.id;
  }

  Future<int> deleteExpense(String id) async {
    final count = await (delete(expenses)..where((e) => e.id.equals(id))).go();
    if (count > 0) await enqueueSync('expenses', 'DELETE', id);
    return count;
  }

  Future<int> getTotalExpenseByShift(String shiftId) async {
    final rows = await (select(
      expenses,
    )..where((e) => e.shiftId.equals(shiftId))).get();
    return rows.fold<int>(0, (sum, e) => sum + e.amount);
  }

  /// Returns cash flow data for the given date range.
  Future<CashFlowData> getCashFlowData({
    required DateTime from,
    required DateTime to,
    required String outletId,
  }) async {
    // Total revenue from paid transactions
    final txRows =
        await (select(transactions)..where(
              (t) =>
                  t.outletId.equals(outletId) &
                  t.createdAt.isBiggerOrEqualValue(from) &
                  t.createdAt.isSmallerThanValue(
                    to.add(const Duration(days: 1)),
                  ) &
                  t.paymentStatus.equals('paid'),
            ))
            .get();
    final totalRevenue = txRows.fold(0, (sum, t) => sum + t.totalAmount);

    // Total expenses
    final expenseRows =
        await (select(expenses)..where(
              (e) =>
                  e.outletId.equals(outletId) &
                  e.createdAt.isBiggerOrEqualValue(from) &
                  e.createdAt.isSmallerThanValue(
                    to.add(const Duration(days: 1)),
                  ),
            ))
            .get();
    final totalExpense = expenseRows.fold(0, (sum, e) => sum + e.amount);

    // Daily expense summaries (for chart)
    final Map<String, int> dailyMap = {};
    for (final e in expenseRows) {
      final key =
          '${e.createdAt.year}-${e.createdAt.month.toString().padLeft(2, '0')}-${e.createdAt.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + e.amount;
    }

    final daily =
        dailyMap.entries
            .map(
              (e) => DailyExpenseSummary(
                date: DateTime.parse(e.key),
                total: e.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return CashFlowData(
      totalRevenue: totalRevenue,
      totalExpense: totalExpense,
      daily: daily,
    );
  }

  Future<String> processCheckout({
    required TransactionsCompanion transactionEntry,
    required List<TransactionItemsCompanion> itemsParams,
    List<TransactionPaymentsCompanion> paymentEntries = const [],
    required String outletId,
  }) async {
    return transaction(() async {
      // 1. Insert Transaction with outletId
      final finalTxEntry = transactionEntry.copyWith(outletId: Value(outletId));
      final insertedTx = await into(transactions).insertReturning(finalTxEntry);
      final txId = insertedTx.id;
      await enqueueSync('transactions', 'INSERT', txId);

      final isPending =
          transactionEntry.paymentStatus.present &&
          transactionEntry.paymentStatus.value == 'pending';

      // 2. Insert Items & 3. Update Stocks
      for (final itemParam in itemsParams) {
        final finalItem = itemParam.copyWith(
          transactionId: Value(txId),
          outletId: Value(outletId),
        );
        final insertedItem = await into(
          transactionItems,
        ).insertReturning(finalItem);
        await enqueueSync('transaction_items', 'INSERT', insertedItem.id);

        // If it's a pending bill (Hold Bill), we DON'T deduct stock yet.
        if (isPending) continue;

        final qty = itemParam.quantity.value;
        final variantId = itemParam.variantId.present
            ? itemParam.variantId.value
            : null;

        final productId = itemParam.productId.value;

        if (variantId != null) {
          // Variable product: decrement variant stock
          final variant = await (select(
            productVariants,
          )..where((v) => v.id.equals(variantId))).getSingleOrNull();
          if (variant != null) {
            final newStock = variant.stock - qty;
            await _atomicVariantStock(variant.id, -qty);
            final refStr =
                transactionEntry.receiptNumber.present &&
                    transactionEntry.receiptNumber.value != null
                ? transactionEntry.receiptNumber.value!
                : 'TX-$txId';

            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: productId,
                variantId: Value(variant.id),
                type: 'SALE',
                quantity: -qty,
                previousStock: variant.stock,
                newStock: newStock,
                reference: Value(refStr),
                createdAt: Value(DateTime.now()),
                outletId: Value(outletId),
              ),
            );
          }
        } else {
          // Simple product: decrement product stock
          final product = await (select(
            products,
          )..where((p) => p.id.equals(productId))).getSingleOrNull();
          if (product != null) {
            final newStock = product.stock - qty;
            await _atomicProductStock(product.id, -qty);
            final refStr =
                transactionEntry.receiptNumber.present &&
                    transactionEntry.receiptNumber.value != null
                ? transactionEntry.receiptNumber.value!
                : 'TX-$txId';

            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: productId,
                type: 'SALE',
                quantity: -qty,
                previousStock: product.stock,
                newStock: newStock,
                reference: Value(refStr),
                createdAt: Value(DateTime.now()),
                outletId: Value(outletId),
              ),
            );
          }
        }

        // 4. Update Ingredients Stock (New Recipe Integration)
        final recipes = await getRecipesByProductId(productId);
        final refStr =
            transactionEntry.receiptNumber.present &&
                transactionEntry.receiptNumber.value != null
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
            outletId: outletId,
          );
        }
      }

      // 5. Update Customer Points (Only for paid transactions)
      if (!isPending &&
          transactionEntry.customerId.present &&
          transactionEntry.customerId.value != null) {
        final customerId = transactionEntry.customerId.value!;
        final earned = transactionEntry.pointsEarned.present
            ? transactionEntry.pointsEarned.value
            : 0;
        final redeemed = transactionEntry.pointsRedeemed.present
            ? transactionEntry.pointsRedeemed.value
            : 0;

        if (earned > 0 || redeemed > 0) {
          final customer = await (select(
            customers,
          )..where((c) => c.id.equals(customerId))).getSingleOrNull();
          if (customer != null) {
            final newPoints = customer.points + earned - redeemed;
            await update(
              customers,
            ).replace(customer.copyWith(points: newPoints));
            await enqueueSync('customers', 'UPDATE', customer.id);
          }
        }
      }

      // 6. Insert payment breakdown rows (Split Payment support)
      for (final payment in paymentEntries) {
        final insertedPayment = await into(transactionPayments).insertReturning(
          payment.copyWith(
            transactionId: Value(txId),
            outletId: Value(outletId),
          ),
        );
        await enqueueSync('transaction_payments', 'INSERT', insertedPayment.id);
      }

      return txId;
    });
  }

  // ===== Additional Transaction Queries =====
  Future<List<Transaction>> getAllTransactions(String outletId) =>
      (select(transactions)
            ..where((t) => t.outletId.equals(outletId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<Transaction>> watchAllTransactions(String outletId) =>
      (select(transactions)
            ..where((t) => t.outletId.equals(outletId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<Transaction>> watchPendingTransactions(String outletId) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.outletId.equals(outletId) &
                  t.paymentStatus.equals('pending'),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<void> deleteTransaction(String id) async {
    await transaction(() async {
      // Find items and payments first
      final items = await (select(
        transactionItems,
      )..where((t) => t.transactionId.equals(id))).get();
      final payments = await (select(
        transactionPayments,
      )..where((t) => t.transactionId.equals(id))).get();

      await (delete(
        transactionPayments,
      )..where((t) => t.transactionId.equals(id))).go();
      for (final p in payments) {
        await enqueueSync('transaction_payments', 'DELETE', p.id);
      }

      await (delete(
        transactionItems,
      )..where((t) => t.transactionId.equals(id))).go();
      for (final i in items) {
        await enqueueSync('transaction_items', 'DELETE', i.id);
      }

      await (delete(transactions)..where((t) => t.id.equals(id))).go();
      await enqueueSync('transactions', 'DELETE', id);
    });
  }

  Future<List<TransactionPayment>> getTransactionPayments(
    String transactionId,
  ) {
    return (select(
      transactionPayments,
    )..where((t) => t.transactionId.equals(transactionId))).get();
  }

  Future<List<TransactionItem>> getTransactionItems(String transactionId) {
    return (select(
      transactionItems,
    )..where((t) => t.transactionId.equals(transactionId))).get();
  }

  Stream<List<Transaction>> watchTransactionsByRange(
    DateTime start,
    DateTime end,
    String outletId,
  ) =>
      (select(transactions)
            ..where(
              (t) =>
                  t.outletId.equals(outletId) &
                  t.createdAt.isBetweenValues(start, end),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  // ===== All Shifts =====
  Future<List<ShiftWithEmployee>> getAllShifts(String outletId) async {
    final query =
        select(shifts).join([
            innerJoin(employees, employees.id.equalsExp(shifts.employeeId)),
          ])
          ..where(shifts.outletId.equals(outletId))
          ..orderBy([OrderingTerm.desc(shifts.startTime)]);

    final rows = await query.get();
    return rows.map((row) {
      return ShiftWithEmployee(
        shift: row.readTable(shifts),
        employee: row.readTable(employees),
      );
    }).toList();
  }

  Stream<List<ShiftWithEmployee>> watchAllShifts(String outletId) {
    final query =
        select(shifts).join([
            innerJoin(employees, employees.id.equalsExp(shifts.employeeId)),
          ])
          ..where(shifts.outletId.equals(outletId))
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
  Future<bool> updateCategory(Category category) async {
    final success =
        await (update(categories)..where((t) => t.id.equals(category.id)))
            .write(CategoriesCompanion(updatedAt: Value(DateTime.now())))
            .then((rows) => rows > 0);
    if (success) await enqueueSync('categories', 'UPDATE', category.id);
    return success;
  }

  Future<int> deleteCategory(Category entry) async {
    final count = await delete(categories).delete(entry);
    if (count > 0) await enqueueSync('categories', 'DELETE', entry.id);
    return count;
  }

  // ===== Detail & Void Transaction =====
  Future<TransactionWithItems?> getTransactionWithItems(
    String transactionId,
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

    final payments = await (select(
      transactionPayments,
    )..where((p) => p.transactionId.equals(transactionId))).get();

    return TransactionWithItems(
      transaction: transaction,
      items: itemsList,
      payments: payments,
    );
  }

  Future<bool> voidTransaction(
    String transactionId,
    String supervisorId,
  ) async {
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
          final variant = await (select(
            productVariants,
          )..where((v) => v.id.equals(item.variantId!))).getSingleOrNull();
          if (variant != null) {
            final newStock = variant.stock + item.quantity;
            await _atomicVariantStock(variant.id, item.quantity);
            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: item.productId,
                variantId: Value(variant.id),
                type: 'VOID',
                quantity: item.quantity,
                previousStock: variant.stock,
                newStock: newStock,
                reference: Value('VOID-${t.receiptNumber}'),
                createdAt: Value(DateTime.now()),
                outletId: Value(t.outletId),
              ),
            );
          }
        } else {
          // Restore product stock
          final product = await (select(
            products,
          )..where((p) => p.id.equals(item.productId))).getSingleOrNull();
          if (product != null) {
            final newStock = product.stock + item.quantity;
            await _atomicProductStock(product.id, item.quantity);
            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: item.productId,
                type: 'VOID',
                quantity: item.quantity,
                previousStock: product.stock,
                newStock: newStock,
                reference: Value('VOID-${t.receiptNumber}'),
                createdAt: Value(DateTime.now()),
                outletId: Value(t.outletId),
              ),
            );
          }
        }
      }

      return true;
    });
  }

  // ===== Sales Analytics =====
  Future<int> getTotalRevenue(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.totalAmount.sum()])
      ..where(transactions.outletId.equals(outletId))
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final result = await query.getSingle();
    final total = result.read(transactions.totalAmount.sum());
    return total ?? 0;
  }

  Future<List<ProductSales>> getTopProducts(
    DateTime start,
    DateTime end,
    String outletId,
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
          ..where(transactions.outletId.equals(outletId))
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

  Future<List<DailySales>> getDailySales(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final list =
        await (select(transactions)
              ..where((t) => t.outletId.equals(outletId))
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

  Future<int> getTotalTransactions(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final query = selectOnly(transactions)
      ..addColumns([transactions.id.count()])
      ..where(transactions.outletId.equals(outletId))
      ..where(transactions.createdAt.isBetweenValues(start, end))
      ..where(transactions.paymentStatus.equals('paid'));

    final result = await query.getSingle();
    return result.read(transactions.id.count()) ?? 0;
  }

  Future<List<PaymentMethodSales>> getPaymentMethodBreakdown(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    // Aggregate from transaction_payments so split payments are attributed
    // to their respective methods instead of showing "mixed".
    final amountExp = transactionPayments.amount.sum();
    final countExp = transactionPayments.transactionId.count();

    final query =
        select(transactionPayments).join([
            innerJoin(
              transactions,
              transactions.id.equalsExp(transactionPayments.transactionId),
            ),
          ])
          ..addColumns([transactionPayments.method, amountExp, countExp])
          ..where(transactions.outletId.equals(outletId))
          ..where(transactions.createdAt.isBetweenValues(start, end))
          ..where(transactions.paymentStatus.equals('paid'))
          ..groupBy([transactionPayments.method]);

    final result = await query.get();
    return result.map((row) {
      return PaymentMethodSales(
        row.read(transactionPayments.method) ?? 'unknown',
        row.read(amountExp) ?? 0,
        row.read(countExp) ?? 0,
      );
    }).toList();
  }

  /// Returns total payment amount grouped by method for a specific shift.
  /// Used by ShiftReportModal to accurately calculate cash in drawer,
  /// including partial cash amounts from split payment transactions.
  Future<Map<String, int>> getShiftPaymentTotals(String shiftId) async {
    final amountExp = transactionPayments.amount.sum();

    final query =
        select(transactionPayments).join([
            innerJoin(
              transactions,
              transactions.id.equalsExp(transactionPayments.transactionId),
            ),
          ])
          ..addColumns([transactionPayments.method, amountExp])
          ..where(transactions.shiftId.equals(shiftId))
          ..where(transactions.paymentStatus.equals('paid'))
          ..groupBy([transactionPayments.method]);

    final result = await query.get();
    return {
      for (final row in result)
        (row.read(transactionPayments.method) ?? 'unknown'):
            row.read(amountExp) ?? 0,
    };
  }

  Future<int> getTotalGrossProfit(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final report = await getProductProfitReport(start, end, outletId);
    final totalProfit = report.fold<int>(0, (sum, p) => sum + p.totalProfit);
    return totalProfit;
  }

  Future<List<ProductProfit>> getProductProfitReport(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final query =
        select(transactionItems).join([
            innerJoin(
              products,
              products.id.equalsExp(transactionItems.productId),
            ),
            innerJoin(
              transactions,
              transactions.id.equalsExp(transactionItems.transactionId),
            ),
          ])
          ..where(transactions.outletId.equals(outletId))
          ..where(transactions.createdAt.isBetweenValues(start, end))
          ..where(transactions.paymentStatus.equals('paid'));

    final results = await query.get();

    final Map<String, ProductProfit> profitMap = {};

    for (var row in results) {
      final item = row.readTable(transactionItems);
      final product = row.readTable(products);

      final revenue = item.subtotal;
      double cost = 0.0;

      // 1. Check if it has recipe
      final recipeCostQuery =
          selectOnly(productRecipes).join([
              innerJoin(
                ingredients,
                ingredients.id.equalsExp(productRecipes.ingredientId),
              ),
            ])
            ..addColumns([
              productRecipes.quantityNeeded,
              ingredients.averageCost,
            ])
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

  Future<List<CategoryProfit>> getCategoryProfitReport(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final query =
        select(transactionItems).join([
            innerJoin(
              products,
              products.id.equalsExp(transactionItems.productId),
            ),
            innerJoin(categories, categories.id.equalsExp(products.categoryId)),
            innerJoin(
              transactions,
              transactions.id.equalsExp(transactionItems.transactionId),
            ),
          ])
          ..where(transactions.outletId.equals(outletId))
          ..where(transactions.createdAt.isBetweenValues(start, end))
          ..where(transactions.paymentStatus.equals('paid'));

    final results = await query.get();

    final Map<String, CategoryProfit> profitMap = {};

    for (var row in results) {
      final item = row.readTable(transactionItems);
      final product = row.readTable(products);
      final category = row.readTable(categories);

      final revenue = item.subtotal;
      double cost = 0.0;

      // 1. Check if it has recipe
      final recipeCostQuery =
          selectOnly(productRecipes).join([
              innerJoin(
                ingredients,
                ingredients.id.equalsExp(productRecipes.ingredientId),
              ),
            ])
            ..addColumns([
              productRecipes.quantityNeeded,
              ingredients.averageCost,
            ])
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

  Future<List<DailySales>> getHourlySales(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
    final list =
        await (select(transactions)
              ..where((t) => t.outletId.equals(outletId))
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
  Future<List<Ingredient>> getAllIngredients(String outletId) =>
      (select(ingredients)..where((i) => i.outletId.equals(outletId))).get();

  Stream<List<Ingredient>> watchAllIngredients(String outletId) =>
      (select(ingredients)..where((i) => i.outletId.equals(outletId))).watch();

  Future<String> insertIngredient(IngredientsCompanion entry) async {
    final row = await into(ingredients).insertReturning(entry);
    await enqueueSync('ingredients', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateIngredient(Ingredient entry) async {
    final success = await update(ingredients).replace(entry);
    if (success) await enqueueSync('ingredients', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteIngredient(Ingredient entry) async {
    final count = await delete(ingredients).delete(entry);
    if (count > 0) await enqueueSync('ingredients', 'DELETE', entry.id);
    return count;
  }

  Future<Ingredient?> getIngredientById(String id) =>
      (select(ingredients)..where((t) => t.id.equals(id))).getSingleOrNull();

  // ===== Product Recipes Queries =====
  Future<List<ProductRecipe>> getRecipesByProductId(String productId) =>
      (select(
        productRecipes,
      )..where((t) => t.productId.equals(productId))).get();

  Stream<List<ProductRecipe>> watchRecipesByProductId(String productId) =>
      (select(
        productRecipes,
      )..where((t) => t.productId.equals(productId))).watch();

  Future<String> insertProductRecipe(ProductRecipesCompanion entry) async {
    final row = await into(productRecipes).insertReturning(entry);
    await enqueueSync('product_recipes', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateProductRecipe(ProductRecipe entry) async {
    final success = await update(productRecipes).replace(entry);
    if (success) await enqueueSync('product_recipes', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteProductRecipe(ProductRecipe entry) async {
    final count = await delete(productRecipes).delete(entry);
    if (count > 0) await enqueueSync('product_recipes', 'DELETE', entry.id);
    return count;
  }

  Future<void> replaceProductRecipes(
    String productId,
    List<ProductRecipesCompanion> newRecipes,
  ) async {
    await transaction(() async {
      final existing = await (select(
        productRecipes,
      )..where((r) => r.productId.equals(productId))).get();
      await (delete(
        productRecipes,
      )..where((r) => r.productId.equals(productId))).go();

      for (final old in existing) {
        await enqueueSync('product_recipes', 'DELETE', old.id);
      }

      for (final r in newRecipes) {
        await insertProductRecipe(r);
      }
    });
  }

  // ===== Ingredient Stock History Queries =====
  Future<List<IngredientStockHistoryData>> getIngredientHistory(
    String ingredientId,
  ) =>
      (select(ingredientStockHistory)
            ..where((t) => t.ingredientId.equals(ingredientId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<IngredientStockHistoryData>> watchIngredientHistory(
    String ingredientId,
  ) =>
      (select(ingredientStockHistory)
            ..where((t) => t.ingredientId.equals(ingredientId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<String> insertIngredientStockHistory(
    IngredientStockHistoryCompanion entry,
  ) async {
    final row = await into(ingredientStockHistory).insertReturning(entry);
    await enqueueSync('ingredient_stock_history', 'INSERT', row.id);
    return row.id;
  }

  /// Atomically adds stock to an ingredient and records it in history.
  /// [quantityInBaseUnit] must already be converted to the base unit.
  Future<void> addIngredientStock({
    required String ingredientId,
    required double quantityInBaseUnit,
    String? supplierId,
    double? newCostPerUnit,
    String? reason,
    String? outletId,
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

      await updateIngredient(
        ingredient.copyWith(
          stockQuantity: newBalance,
          averageCost: updatedCost,
          lastSupplierId: Value(supplierId),
        ),
      );

      await insertIngredientStockHistory(
        IngredientStockHistoryCompanion.insert(
          ingredientId: ingredientId,
          supplierId: Value(supplierId),
          type: 'PURCHASE',
          quantityChange: quantityInBaseUnit,
          previousBalance: previousBalance,
          newBalance: newBalance,
          reason: Value(reason ?? 'Tambah Stok Manual'),
          outletId: outletId != null ? Value(outletId) : const Value.absent(),
        ),
      );
    });
  }

  /// Atomically removes stock from an ingredient (e.g. from a sale).
  Future<void> deductIngredientStock({
    required String ingredientId,
    required double quantityInBaseUnit,
    String type = 'SALE',
    String? referenceId,
    String? reason,
    String? outletId,
  }) async {
    await transaction(() async {
      final ingredient = await getIngredientById(ingredientId);
      if (ingredient == null) return;

      final previousBalance = ingredient.stockQuantity;
      final newBalance = (previousBalance - quantityInBaseUnit).clamp(
        0.0,
        double.infinity,
      );

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
          outletId: outletId != null ? Value(outletId) : const Value.absent(),
        ),
      );
    });
  }

  // ===== Unit Conversion Queries =====
  Stream<List<UnitConversion>> watchAllUnitConversions() =>
      select(unitConversions).watch();

  Future<List<UnitConversion>> getAllUnitConversions() =>
      select(unitConversions).get();

  Future<String> insertUnitConversion(UnitConversionsCompanion entry) async {
    final row = await into(unitConversions).insertReturning(entry);
    await enqueueSync('unit_conversions', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateUnitConversion(UnitConversion entry) async {
    final success = await update(unitConversions).replace(entry);
    if (success) await enqueueSync('unit_conversions', 'UPDATE', entry.id);
    return success;
  }

  Future<int> deleteUnitConversion(String id) async {
    final count = await (delete(
      unitConversions,
    )..where((t) => t.id.equals(id))).go();
    if (count > 0) await enqueueSync('unit_conversions', 'DELETE', id);
    return count;
  }

  Future<List<UnitConversion>> getConversionsForBaseUnit(String baseUnit) =>
      (select(unitConversions)..where((t) => t.toUnit.equals(baseUnit))).get();

  // ===== Full-Structured Stock Opname =====
  Future<String> createDraftOpname(StockOpnameCompanion entry) async {
    final row = await into(stockOpname).insertReturning(entry);
    await enqueueSync('stock_opname', 'INSERT', row.id);
    return row.id;
  }

  Future<List<StockOpnameData>> getDraftOpnames(String outletId) =>
      (select(stockOpname)..where(
            (o) => o.outletId.equals(outletId) & o.status.equals('DRAFT'),
          ))
          .get();

  Stream<List<StockOpnameData>> watchDraftOpnames(String outletId) =>
      (select(stockOpname)..where(
            (o) => o.outletId.equals(outletId) & o.status.equals('DRAFT'),
          ))
          .watch();

  Future<StockOpnameData?> getOpnameById(String id) =>
      (select(stockOpname)..where((o) => o.id.equals(id))).getSingleOrNull();

  Future<List<StockOpnameItem>> getOpnameItems(String opnameId) => (select(
    stockOpnameItems,
  )..where((i) => i.stockOpnameId.equals(opnameId))).get();

  Stream<List<StockOpnameItem>> watchOpnameItems(String opnameId) => (select(
    stockOpnameItems,
  )..where((i) => i.stockOpnameId.equals(opnameId))).watch();

  Future<String> addOpnameItem(StockOpnameItemsCompanion entry) async {
    final row = await into(stockOpnameItems).insertReturning(entry);
    await enqueueSync('stock_opname_items', 'INSERT', row.id);
    return row.id;
  }

  Future<bool> updateOpnameItem(StockOpnameItem entry) async {
    final success = await update(stockOpnameItems).replace(entry);
    if (success) await enqueueSync('stock_opname_items', 'UPDATE', entry.id);
    return success;
  }

  Future<int> removeOpnameItem(String id) async {
    final count = await (delete(
      stockOpnameItems,
    )..where((i) => i.id.equals(id))).go();
    if (count > 0) await enqueueSync('stock_opname_items', 'DELETE', id);
    return count;
  }

  Future<void> submitOpname(String opnameId) async {
    await transaction(() async {
      final opname = await getOpnameById(opnameId);
      if (opname == null || opname.status == 'COMPLETED') return;

      final items = await getOpnameItems(opnameId);

      for (final item in items) {
        if (item.variance == 0.0) continue;

        if (opname.type == 'INGREDIENT' && item.ingredientId != null) {
          final ingredient = await getIngredientById(item.ingredientId!);
          if (ingredient != null) {
            await updateIngredient(
              ingredient.copyWith(stockQuantity: item.physicalStock),
            );
            await insertIngredientStockHistory(
              IngredientStockHistoryCompanion.insert(
                ingredientId: ingredient.id,
                type: 'ADJUST',
                quantityChange: item.variance,
                previousBalance: item.systemStock,
                newBalance: item.physicalStock,
                reason: Value(
                  item.varianceReason ?? 'Opname ${opname.opnameNumber}',
                ),
                outletId: opname.outletId != null
                    ? Value(opname.outletId!)
                    : const Value.absent(),
              ),
            );
          }
        } else if (opname.type == 'PRODUCT' && item.productId != null) {
          final baseProduct = await getProduct(item.productId!);
          if (item.variantId != null) {
            final variant = await getVariant(item.variantId!);
            if (variant != null) {
              await _atomicVariantStock(variant.id, item.variance.toInt());
              await insertStockTransaction(
                StockTransactionsCompanion.insert(
                  productId: item.productId!,
                  variantId: Value(item.variantId!),
                  type: 'ADJUST',
                  quantity: item.variance.toInt(),
                  previousStock: item.systemStock.toInt(),
                  newStock: item.physicalStock.toInt(),
                  reason: Value(
                    item.varianceReason ?? 'Opname ${opname.opnameNumber}',
                  ),
                  createdAt: Value(DateTime.now()),
                  outletId: Value(opname.outletId!),
                ),
              );
            }
          } else if (baseProduct != null) {
            await _atomicProductStock(baseProduct.id, item.variance.toInt());
            await insertStockTransaction(
              StockTransactionsCompanion.insert(
                productId: item.productId!,
                type: 'ADJUST',
                quantity: item.variance.toInt(),
                previousStock: item.systemStock.toInt(),
                newStock: item.physicalStock.toInt(),
                reason: Value(
                  item.varianceReason ?? 'Opname ${opname.opnameNumber}',
                ),
                createdAt: Value(DateTime.now()),
                outletId: Value(opname.outletId!),
              ),
            );
          }
        }
      }

      await update(stockOpname).replace(
        opname.copyWith(status: 'COMPLETED', updatedAt: DateTime.now()),
      );
      await enqueueSync('stock_opname', 'UPDATE', opnameId);
    });
  }

  Stream<List<StockOpnameData>> watchCompletedOpnames(String type) =>
      (select(stockOpname)
            ..where((o) => o.status.equals('COMPLETED') & o.type.equals(type))
            ..orderBy([(o) => OrderingTerm.desc(o.createdAt)]))
          .watch();

  // ===== Stock Loss Report =====
  Future<List<StockLossItem>> getStockLossReport(
    DateTime start,
    DateTime end,
    String outletId,
  ) async {
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
        AND o.outlet_id = ?
        AND o.created_at >= ? AND o.created_at <= ?
      ''',
      variables: [
        Variable<String>(outletId),
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
    ).get();

    for (final row in productQuery) {
      results.add(
        StockLossItem(
          row.read<String>('item_name'),
          row.read<String>('type'),
          row.read<String>('reason'),
          row.read<double>('loss_qty'),
          row.read<double>('loss_value').round(),
        ),
      );
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
        AND o.outlet_id = ?
        AND o.created_at >= ? AND o.created_at <= ?
      ''',
      variables: [
        Variable<String>(outletId),
        Variable<DateTime>(start),
        Variable<DateTime>(end),
      ],
    ).get();

    for (final row in ingredientQuery) {
      results.add(
        StockLossItem(
          row.read<String>('item_name'),
          row.read<String>('type'),
          row.read<String>('reason'),
          row.read<double>('loss_qty'),
          row.read<double>('loss_value').round(),
        ),
      );
    }

    return results;
  }

  // ===== Cloud Sync Helpers =====

  Future<List<SyncQueueData>> getPendingSyncTasks(int limit) =>
      (select(syncQueue)
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<void> removeSyncTasks(List<String> ids) =>
      (delete(syncQueue)..where((t) => t.id.isIn(ids))).go();

  Future<Map<String, dynamic>?> getRecordAsMap(
    String tableName,
    String recordId,
  ) async {
    try {
      final rows = await customSelect(
        'SELECT * FROM $tableName WHERE id = ?',
        variables: [Variable<String>(recordId)],
      ).get();
      if (rows.isEmpty) return null;

      final map = <String, dynamic>{};
      for (final col in rows.first.data.entries) {
        final val = col.value;
        if (val is int && col.key.contains('_at')) {
          map[col.key] = DateTime.fromMillisecondsSinceEpoch(
            val,
          ).toUtc().toIso8601String();
        } else if (val is int && col.key == 'is_dirty') {
          map[col.key] = val == 1;
        } else {
          map[col.key] = val;
        }
      }
      return map;
    } catch (_) {
      return null;
    }
  }

  /// Merges pulled records from Supabase into the local SQLite database using Last Write Wins logic.
  Future<void> importCloudRows(
    String tableName,
    List<Map<String, dynamic>> cloudRows,
  ) async {
    if (cloudRows.isEmpty) return;

    await transaction(() async {
      for (final row in cloudRows) {
        final id = row['id'];
        if (id == null) continue;

        // 1. Check if there is an active local sync task for this record
        final localQueueCount = await customSelect(
          'SELECT COUNT(*) as c FROM sync_queue WHERE record_id = ? AND target_table = ?',
          variables: [Variable<String>(id), Variable<String>(tableName)],
          readsFrom: {syncQueue},
        ).getSingle();
        final isLocallyDirty = localQueueCount.read<int>('c') > 0;

        if (isLocallyDirty) {
          debugPrint(
            'Sync: Collision detected for $tableName:$id - Keeping local version (in sync queue)',
          );
          continue;
        }

        // 2. Fetch existing local record metadata
        final localRow = await customSelect(
          'SELECT updated_at FROM $tableName WHERE id = ?',
          variables: [Variable<String>(id)],
          readsFrom: {},
        ).getSingleOrNull();

        // 3. Conflict Resolution Logic (Phase 1: LWW)
        if (localRow != null) {
          final localUpdatedAtMs = localRow.read<int>('updated_at');
          final cloudUpdatedAtStr = row['updated_at'] as String?;
          if (cloudUpdatedAtStr != null) {
            final cloudUpdatedAtMs = DateTime.parse(
              cloudUpdatedAtStr,
            ).millisecondsSinceEpoch;
            // Only skip if local is STRICTLY newer.
            // If equal, it's a Realtime echo of our own push — accept silently.
            if (localUpdatedAtMs > cloudUpdatedAtMs) {
              debugPrint(
                'Sync: Conflict for $tableName:$id - Local is newer, keeping local.',
              );
              continue;
            }
          }
        }

        // 4. Prepare values for INSERT/UPDATE
        final columns = <String>[];
        final placeholders = <String>[];
        final values = <dynamic>[];

        // Get actual columns in the local table to avoid "no such column" errors
        final tableInfo = allTables.firstWhere((t) => t.actualTableName == tableName);
        final validColumns = tableInfo.$columns.map((c) => c.$name).toSet();

        row.forEach((key, value) {
          if (!validColumns.contains(key)) return;

          if (value is String &&
              key.contains('_at') &&
              DateTime.tryParse(value) != null) {
            values.add(DateTime.parse(value).millisecondsSinceEpoch);
          } else {
            values.add(value);
          }
          columns.add(key);
          placeholders.add('?');
        });

        // We can optionally set is_dirty = 0 if the column still exists for backward compatibility,
        // but since we no longer rely on it, we can omit it if the DB defaults it to 0.
        // We'll leave it out.

        final colsStr = columns.join(', ');
        final valsStr = placeholders.join(', ');
        final updatesStr = columns.map((c) => '$c = EXCLUDED.$c').join(', ');

        try {
          await customStatement(
            'INSERT INTO $tableName ($colsStr) VALUES ($valsStr) '
            'ON CONFLICT(id) DO UPDATE SET $updatesStr',
            values,
          );
        } catch (e) {
          debugPrint('Failed to upsert $tableName:$id - $e');
        }
      }
    });

    // Notify Drift stream watchers so UI auto-updates without pull-to-refresh
    _notifyTableUpdate(tableName);
  }

  /// Deletes a record that was deleted in the cloud (Realtime sync).
  Future<void> deleteCloudRow(String tableName, String id) async {
    // 1. Check if there is an active local sync task for this record
    final localQueueCount = await customSelect(
      'SELECT COUNT(*) as c FROM sync_queue WHERE record_id = ? AND target_table = ?',
      variables: [Variable<String>(id), Variable<String>(tableName)],
      readsFrom: {syncQueue},
    ).getSingle();

    if (localQueueCount.read<int>('c') > 0) {
      debugPrint(
        'Sync: Collision detected for $tableName:$id delete - Keeping local version',
      );
      return;
    }

    try {
      await customStatement('DELETE FROM $tableName WHERE id = ?', [id]);
      // Notify Drift stream watchers so UI auto-updates
      _notifyTableUpdate(tableName);
    } catch (e) {
      debugPrint('Failed to delete cloud row $tableName:$id - $e');
    }
  }

  /// Notifies Drift's table watchers after a raw SQL change,
  /// ensuring all [watch] streams (and thus the UI) are refreshed automatically.
  void _notifyTableUpdate(String tableName) {
    final tableMap = <String, TableInfo>{
      'products': products,
      'categories': categories,
      'product_variants': productVariants,
      'outlets': outlets,
      'employees': employees,
      'shifts': shifts,
      'transactions': transactions,
      'transaction_items': transactionItems,
      'transaction_payments': transactionPayments,
      'customers': customers,
      'suppliers': suppliers,
      'discounts': discounts,
      'store_profile': storeProfile,
      'ingredients': ingredients,
      'product_recipes': productRecipes,
      'expenses': expenses,
      'purchase_orders': purchaseOrders,
      'purchase_order_items': purchaseOrderItems,
      'stock_opname': stockOpname,
      'stock_opname_items': stockOpnameItems,
      'stock_transactions': stockTransactions,
      'ingredient_stock_history': ingredientStockHistory,
      'unit_conversions': unitConversions,
      'printer_settings': printerSettings,
    };
    final table = tableMap[tableName];
    if (table != null) markTablesUpdated({table});
  }

  Future<void> _fixLegacyDummyIds() async {
    // Mapping placeholder IDs to valid UUIDs matching pos_providers.dart
    final mapping = {
      'cat-1': '88265004-8975-4c07-b3f9-7f3e803d3511',
      'cat-2': '77465004-8975-4c07-b3f9-7f3e803d3522',
      'cat-3': '66365004-8975-4c07-b3f9-7f3e803d3533',
    };

    await transaction(() async {
      for (final entry in mapping.entries) {
        final oldId = entry.key;
        final newId = entry.value;

        final affectedProducts = await (select(
          products,
        )..where((p) => p.categoryId.equals(oldId))).get();

        // Update products that reference the old dummy ID
        await (update(products)..where((p) => p.categoryId.equals(oldId)))
            .write(ProductsCompanion(categoryId: Value(newId)));

        for (final p in affectedProducts) {
          await enqueueSync('products', 'UPDATE', p.id);
        }

        final affectedCats = await (select(
          categories,
        )..where((c) => c.id.equals(oldId))).get();

        // If categories table contains the old ID, update it too
        await (update(categories)..where((c) => c.id.equals(oldId))).write(
          CategoriesCompanion(id: Value(newId)),
        );

        for (final _ in affectedCats) {
          await enqueueSync('categories', 'UPDATE', newId);
        }
      }
    });
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
  final List<TransactionPayment> payments;
  TransactionWithItems({
    required this.transaction,
    required this.items,
    this.payments = const [],
  });
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

  StockLossItem(
    this.itemName,
    this.type,
    this.reason,
    this.varianceQuantity,
    this.lossValue,
  );
}

class ExpenseWithCategory {
  final Expense expense;
  final ExpenseCategory? category;
  ExpenseWithCategory({required this.expense, this.category});
}

class DailyExpenseSummary {
  final DateTime date;
  final int total;
  const DailyExpenseSummary({required this.date, required this.total});
}

class CashFlowData {
  final int totalRevenue;
  final int totalExpense;
  final List<DailyExpenseSummary> daily;

  const CashFlowData({
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
    final file = File(p.join(dbFolder.path, 'lumio.db'));

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
