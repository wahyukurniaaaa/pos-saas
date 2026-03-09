import 'package:drift/drift.dart';

class Licenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get licenseCode => text().unique()();
  TextColumn get deviceFingerprint => text().nullable()();
  DateTimeColumn get activationDate => dateTime().nullable()();
  DateTimeColumn get lastVerified => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
}
