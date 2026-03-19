import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

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

part 'database.g.dart';

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
  ],
)
class PosifyDatabase extends _$PosifyDatabase {
  PosifyDatabase() : super(_openConnection());

  // For testing
  PosifyDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 8;

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
        final newStock = variant.stock + quantity;
        await (update(productVariants)..where((v) => v.id.equals(variantId)))
            .write(ProductVariantsCompanion(stock: Value(newStock)));
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
        final newStock = product.stock + quantity;
        await (update(products)..where((p) => p.id.equals(productId)))
            .write(ProductsCompanion(stock: Value(newStock)));
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

  // ===== Checkout Process =====
  Future<int> processCheckout({
    required TransactionsCompanion transactionEntry,
    required List<TransactionItemsCompanion> itemsParams,
  }) async {
    return transaction(() async {
      // 1. Insert Transaction
      final txId = await into(transactions).insert(transactionEntry);

      // 2. Insert Items & 3. Update Stocks (supports both simple and variant products)
      for (final itemParam in itemsParams) {
        final finalItem = itemParam.copyWith(transactionId: Value(txId));
        await into(transactionItems).insert(finalItem);

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
            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: productId,
              variantId: Value(variant.id),
              type: 'SALE',
              quantity: -qty,
              previousStock: variant.stock,
              newStock: newStock,
              reference: transactionEntry.receiptNumber,
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
            await into(stockTransactions).insert(StockTransactionsCompanion.insert(
              productId: productId,
              type: 'SALE',
              quantity: -qty,
              previousStock: product.stock,
              newStock: newStock,
              reference: transactionEntry.receiptNumber,
              createdAt: DateTime.now().toIso8601String(),
            ));
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
}

class ProductWithVariants {
  final Product product;
  final List<ProductVariant> variants;
  ProductWithVariants({required this.product, required this.variants});
}

class ProductSales {
  final String productName;
  final int totalQuantity;
  ProductSales(this.productName, this.totalQuantity);
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

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'posify.db'));
    return NativeDatabase.createInBackground(file);
  });
}
