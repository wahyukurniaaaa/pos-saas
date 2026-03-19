import 'package:drift/drift.dart';

class StockTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer()();
  IntColumn get variantId => integer().nullable()();
  IntColumn get supplierId => integer().nullable()();
  TextColumn get type => text()(); // IN, OUT, ADJUST, SALE
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get createdAt => text()();
}
