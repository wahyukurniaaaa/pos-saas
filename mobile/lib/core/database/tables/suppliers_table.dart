import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

class Suppliers extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get address => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}