import 'package:drift/drift.dart';
import 'transactions_table.dart';

class TransactionPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  // 'tunai', 'qris', 'debit', 'kredit' — kasbon not allowed in split
  TextColumn get method => text()();
  IntColumn get amount => integer()();
  IntColumn get changeGiven => integer().withDefault(const Constant(0))();
}
