import 'package:drift/drift.dart';
import 'products_table.dart';
import 'product_variants_table.dart';
import 'employees_table.dart';

class StockAdjustments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get variantId => integer().nullable().references(ProductVariants, #id)();
  IntColumn get employeeId => integer().references(Employees, #id)();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  TextColumn get reason => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
