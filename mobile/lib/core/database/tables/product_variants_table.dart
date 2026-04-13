import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'products_table.dart';

class ProductVariants extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get name => text().withLength(min: 1, max: 50)(); // e.g. "Ukuran", "Rasa"
  TextColumn get optionValue => text().withLength(min: 1, max: 50)(); // e.g. "L", "Coklat"
  IntColumn get price =>
      integer().nullable()(); // null = use product base price
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get sku => text().nullable()(); // Optional, for barcode-per-variant
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}