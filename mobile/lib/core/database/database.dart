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
import 'tables/shifts_table.dart';
import 'tables/transactions_table.dart';
import 'tables/transaction_items_table.dart';
import 'tables/stock_adjustments_table.dart';
import 'tables/printer_settings_table.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [
    Licenses,
    Employees,
    StoreProfile,
    Categories,
    Products,
    Shifts,
    Transactions,
    TransactionItems,
    StockAdjustments,
    PrinterSettings,
  ],
)
class PosifyDatabase extends _$PosifyDatabase {
  PosifyDatabase() : super(_openConnection());

  // For testing
  PosifyDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  // ===== License Queries =====
  Future<License?> getLocalLicense() =>
      (select(licenses)..limit(1)).getSingleOrNull();

  Future<int> insertLicense(LicensesCompanion entry) =>
      into(licenses).insert(entry);

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

  Future<int> insertStoreProfile(StoreProfileCompanion entry) =>
      into(storeProfile).insert(entry);

  Future<bool> updateStoreProfile(StoreProfileData entry) =>
      update(storeProfile).replace(entry);

  // ===== Category Queries =====
  Future<List<Category>> getAllCategories() => select(categories).get();

  Stream<List<Category>> watchAllCategories() => select(categories).watch();

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  // ===== Product Queries =====
  Future<List<Product>> getAllProducts() => select(products).get();

  Stream<List<Product>> watchAllProducts() => select(products).watch();

  Future<List<Product>> getProductsByCategory(int categoryId) =>
      (select(products)..where((p) => p.categoryId.equals(categoryId))).get();

  Future<Product?> getProductBySku(String sku) =>
      (select(products)..where((p) => p.sku.equals(sku))).getSingleOrNull();

  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<bool> updateProduct(Product entry) => update(products).replace(entry);

  Future<int> deleteProduct(Product entry) => delete(products).delete(entry);

  // ===== Shift Queries =====
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

  // ===== Stock Adjustments =====
  Future<int> insertStockAdjustment(StockAdjustmentsCompanion entry) =>
      into(stockAdjustments).insert(entry);

  // ===== Additional Transaction Queries =====
  Future<List<Transaction>> getAllTransactions() => (select(
    transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  Stream<List<Transaction>> watchAllTransactions() => (select(
    transactions,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  // ===== All Shifts =====
  Future<List<Shift>> getAllShifts() =>
      (select(shifts)..orderBy([(s) => OrderingTerm.desc(s.startTime)])).get();

  Stream<List<Shift>> watchAllShifts() => (select(
    shifts,
  )..orderBy([(s) => OrderingTerm.desc(s.startTime)])).watch();

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

      // 3. Restore stock
      final items = await (select(
        transactionItems,
      )..where((tbl) => tbl.transactionId.equals(transactionId))).get();
      for (final item in items) {
        final product = await (select(
          products,
        )..where((p) => p.id.equals(item.productId))).getSingleOrNull();
        if (product != null) {
          await (update(products)..where((p) => p.id.equals(product.id))).write(
            ProductsCompanion(stock: Value(product.stock + item.quantity)),
          );
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
