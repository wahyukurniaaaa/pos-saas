import 'package:drift/drift.dart';
import 'ingredients_table.dart';
import 'suppliers_table.dart';

class IngredientStockHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  TextColumn get type => text()(); // SALE, PURCHASE, ADJUST, WASTE
  RealColumn get quantityChange => real()(); // +/-
  RealColumn get previousBalance => real()();
  RealColumn get newBalance => real()();
  TextColumn get referenceId => text().nullable()(); // Transaction ID or Batch ID
  IntColumn get supplierId => integer().nullable().references(Suppliers, #id)();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

