import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'shifts_table.dart';
import 'employees_table.dart';
import 'discounts_table.dart';

class Transactions extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get receiptNumber => text().unique().nullable()();
  TextColumn get shiftId => text().references(Shifts, #id)();
  TextColumn get customerId => text().nullable()();
  IntColumn get subtotal => integer()();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceChargeAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()();
  TextColumn get paymentMethod => text().nullable()(); // cash, qris, debit, credit, bon (nullable for drafts)
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('paid'))(); // paid, void, pending
  TextColumn get voidBy => text().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerName => text().nullable()();
  // Discount (Bill Level)
  TextColumn get discountId => text().nullable().references(Discounts, #id)();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  // Loyalty Points
  IntColumn get pointsEarned => integer().withDefault(const Constant(0))();
  IntColumn get pointsRedeemed => integer().withDefault(const Constant(0))();
  // Notes
  TextColumn get notes => text().nullable()();
    TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}