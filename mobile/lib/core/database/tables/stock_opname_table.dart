import 'package:drift/drift.dart';

class StockOpname extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get opnameNumber => text()(); // e.g. OP-20231024-001
  TextColumn get type => text()(); // PRODUCT or INGREDIENT
  TextColumn get status => text()(); // DRAFT or COMPLETED
  IntColumn get createdBy => integer()(); // Employee ID
  TextColumn get notes => text().nullable()();
  TextColumn get createdAt => text()();
}
