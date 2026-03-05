import 'package:drift/drift.dart';
import 'employees_table.dart';

class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get startingCash => integer().withDefault(const Constant(0))();
  IntColumn get expectedEndingCash => integer().nullable()();
  IntColumn get actualEndingCash => integer().nullable()();
  TextColumn get status =>
      text().withDefault(const Constant('open'))(); // open, closed
}
