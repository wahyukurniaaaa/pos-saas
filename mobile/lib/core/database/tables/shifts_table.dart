import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'employees_table.dart';

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
  DateTimeColumn get deletedAt => dateTime().nullable()();
}