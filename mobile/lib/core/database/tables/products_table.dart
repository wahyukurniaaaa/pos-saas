import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'categories_table.dart';

class Products extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 3, max: 100)();
  TextColumn get sku => text().withLength(min: 3, max: 30).unique()();
  IntColumn get price => integer()(); // Base price (used when variant has no specific price)
  IntColumn get purchasePrice => integer().withDefault(const Constant(0))(); // HPP retail (Rp)
  BoolColumn get hasVariants =>
      boolean().withDefault(const Constant(false))(); // true = Variable Product
  IntColumn get stock => integer().withDefault(const Constant(0))();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(0))();
  TextColumn get imageUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
    TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}