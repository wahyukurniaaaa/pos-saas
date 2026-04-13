import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'ingredients_table.dart';
import 'suppliers_table.dart';

class IngredientStockHistory extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  TextColumn get type => text()(); // SALE, PURCHASE, ADJUST, WASTE
  RealColumn get quantityChange => real()(); // +/-
  RealColumn get previousBalance => real()();
  RealColumn get newBalance => real()();
  TextColumn get referenceId => text().nullable()(); // Transaction ID or Batch ID
  TextColumn get supplierId => text().nullable().references(Suppliers, #id)();
  TextColumn get reason => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}