import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

class StockOpnameItems extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get stockOpnameId => text()();
  TextColumn get productId => text().nullable()();
  TextColumn get variantId => text().nullable()();
  TextColumn get ingredientId => text().nullable()();
  RealColumn get systemStock => real()();
  RealColumn get physicalStock => real()();
  RealColumn get variance => real()();
  TextColumn get varianceReason => text().nullable()(); // Waste, Rusak, dll
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}