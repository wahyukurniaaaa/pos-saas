import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

// Scope: 'transaction' = applies to total bill; 'item' = applies per product.
// Type:  'fixed' = nominal (Rp), 'percentage' = percent (%).
class Discounts extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text().withLength(min: 2, max: 100)();
  TextColumn get scope => text().withDefault(const Constant('transaction'))(); // transaction | item
  TextColumn get type => text().withDefault(const Constant('percentage'))();   // fixed | percentage
  RealColumn get value => real()(); // amount (Rp) if fixed, percent if percentage
  IntColumn get minSpend => integer().withDefault(const Constant(0))(); // minimum cart total (Rp)
  IntColumn get minQty => integer().withDefault(const Constant(1))(); // minimum item quantity (for item scope)
  BoolColumn get isAutomatic => boolean().withDefault(const Constant(false))(); // auto-apply if conditions met
  BoolColumn get isStackable => boolean().withDefault(const Constant(true))(); // can combine with other discounts
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get startDate => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}