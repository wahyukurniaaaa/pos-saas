import 'package:drift/drift.dart';
import 'shifts_table.dart';
import 'employees_table.dart';
import 'discounts_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptNumber => text().unique().nullable()();
  IntColumn get shiftId => integer().references(Shifts, #id)();
  IntColumn get customerId => integer().nullable()();
  IntColumn get subtotal => integer()();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceChargeAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()();
  TextColumn get paymentMethod => text().nullable()(); // cash, qris, debit, credit, bon (nullable for drafts)
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('paid'))(); // paid, void, pending
  IntColumn get voidBy => integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerName => text().nullable()();
  // Discount (Bill Level)
  IntColumn get discountId => integer().nullable().references(Discounts, #id)();
  IntColumn get discountAmount => integer().withDefault(const Constant(0))();
  // Loyalty Points
  IntColumn get pointsEarned => integer().withDefault(const Constant(0))();
  IntColumn get pointsRedeemed => integer().withDefault(const Constant(0))();
  // Notes
  TextColumn get notes => text().nullable()();
}
