import 'package:drift/drift.dart';

class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get pin => text().withLength(min: 6, max: 6).unique()();
  TextColumn get role => text()(); // owner, supervisor, cashier
  IntColumn get failedLoginAttempts =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lockedUntil => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  TextColumn get photoUri => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
