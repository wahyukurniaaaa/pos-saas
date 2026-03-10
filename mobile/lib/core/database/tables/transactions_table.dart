import 'package:drift/drift.dart';
import 'shifts_table.dart';
import 'employees_table.dart';

class Transactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get receiptNumber => text().unique()();
  IntColumn get shiftId => integer().references(Shifts, #id)();
  IntColumn get subtotal => integer()();
  IntColumn get taxAmount => integer().withDefault(const Constant(0))();
  IntColumn get serviceChargeAmount =>
      integer().withDefault(const Constant(0))();
  IntColumn get totalAmount => integer()();
  TextColumn get paymentMethod => text()(); // cash, qris, debit, credit, bon
  TextColumn get paymentStatus =>
      text().withDefault(const Constant('paid'))(); // paid, void
  IntColumn get voidBy => integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get customerPhone => text().nullable()();
  TextColumn get customerName => text().nullable()();
}
