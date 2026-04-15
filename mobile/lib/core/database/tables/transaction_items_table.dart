import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'transactions_table.dart';
import 'products_table.dart';
import 'product_variants_table.dart';
import 'discounts_table.dart';

class TransactionItems extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get transactionId => text().references(Transactions, #id)();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get variantId =>
      text().nullable().references(ProductVariants, #id)(); // null = simple product
  TextColumn get variantName =>
      text().nullable()(); // Snapshot: "Ukuran: L" - preserved even if variant is deleted
  IntColumn get quantity => integer()();
  IntColumn get priceAtTransaction => integer()(); // Snapshot harga saat dibeli
  IntColumn get subtotal => integer()(); // quantity * priceAtTransaction
  // Discount (Item Level)
  TextColumn get discountId => text().nullable().references(Discounts, #id)();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}