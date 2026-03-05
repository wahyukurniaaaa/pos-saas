import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'posify.db'));
    return NativeDatabase.createInBackground(file);
  });
}
