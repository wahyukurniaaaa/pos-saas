import 'package:drift/drift.dart';
import 'categories_table.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get name => text().withLength(min: 3, max: 100)();
  TextColumn get sku => text().withLength(min: 3, max: 30).unique()();
  IntColumn get price => integer()(); // Harga jual (dalam rupiah)
  IntColumn get purchasePrice =>
      integer().withDefault(const Constant(0))(); // Harga beli
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get imageUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
