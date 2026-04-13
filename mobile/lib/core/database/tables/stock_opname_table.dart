import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

class StockOpname extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get opnameNumber => text()(); // e.g. OP-20231024-001
  TextColumn get type => text()(); // PRODUCT or INGREDIENT
  TextColumn get status => text()(); // DRAFT or COMPLETED
  TextColumn get createdBy => text()(); // Employee ID
  TextColumn get notes => text().nullable()();
  TextColumn get varianceReason => text().nullable()(); // Waste, Rusak, dll
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}