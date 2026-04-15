import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'employees_table.dart';
import 'outlets_table.dart';

class Shifts extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get employeeId => text().references(Employees, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get startingCash => integer().withDefault(const Constant(0))();
  IntColumn get expectedEndingCash => integer().nullable()();
  IntColumn get actualEndingCash => integer().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))(); // open, closed
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}