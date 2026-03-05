import 'package:drift/drift.dart';
import 'transactions_table.dart';
import 'products_table.dart';

class TransactionItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get transactionId => integer().references(Transactions, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get quantity => integer()();
  IntColumn get priceAtTransaction => integer()(); // Snapshot harga saat dibeli
  IntColumn get subtotal => integer()(); // quantity * priceAtTransaction
}
