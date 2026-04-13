import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

class StockTransactions extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get productId => text()();
  TextColumn get variantId => text().nullable()();
  TextColumn get supplierId => text().nullable()();
  TextColumn get type => text()(); // IN, OUT, ADJUST, SALE
  IntColumn get quantity => integer()();
  IntColumn get previousStock => integer()();
  IntColumn get newStock => integer()();
  TextColumn get reason => text().nullable()();
  TextColumn get reference => text().nullable()();
  TextColumn get createdAt => text()();
    TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}