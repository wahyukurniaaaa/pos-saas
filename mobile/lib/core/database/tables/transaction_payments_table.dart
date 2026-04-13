import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'transactions_table.dart';

class TransactionPayments extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get transactionId => text().references(Transactions, #id)();
  // 'tunai', 'qris', 'debit', 'kredit' — kasbon not allowed in split
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  IntColumn get changeGiven => integer().withDefault(const Constant(0))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}