import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'transactions_table.dart';

class TransactionPayments extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get transactionId => text().references(Transactions, #id)();
  // 'tunai', 'qris', 'debit', 'kredit' — kasbon not allowed in split
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  IntColumn get changeGiven => integer().withDefault(const Constant(0))();
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}