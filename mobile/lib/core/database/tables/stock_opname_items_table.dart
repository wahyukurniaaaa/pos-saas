import 'package:drift/drift.dart';

class StockOpnameItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stockOpnameId => integer()();
  IntColumn get productId => integer().nullable()();
  IntColumn get variantId => integer().nullable()();
  IntColumn get ingredientId => integer().nullable()();
  RealColumn get systemStock => real()();
  RealColumn get physicalStock => real()();
  RealColumn get variance => real()();
  TextColumn get varianceReason => text().nullable()(); // Waste, Rusak, dll
}
