import 'package:drift/drift.dart';
import 'suppliers_table.dart';

class Ingredients extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get unit => text()(); // Base Unit: gr, ml, pcs
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  RealColumn get minStockThreshold => real().withDefault(const Constant(0.0))();
  RealColumn get averageCost => real().withDefault(const Constant(0.0))(); // HPP per Base Unit
  IntColumn get lastSupplierId => integer().nullable().references(Suppliers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
