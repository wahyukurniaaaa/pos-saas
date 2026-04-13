import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'outlets_table.dart';

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}