import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'suppliers_table.dart';

class Ingredients extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text()();
  TextColumn get unit => text()(); // Base Unit: gr, ml, pcs
  RealColumn get stockQuantity => real().withDefault(const Constant(0.0))();
  RealColumn get minStockThreshold => real().withDefault(const Constant(0.0))();
  RealColumn get averageCost => real().withDefault(const Constant(0.0))(); // HPP per Base Unit
  TextColumn get lastSupplierId => text().nullable().references(Suppliers, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
    TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}