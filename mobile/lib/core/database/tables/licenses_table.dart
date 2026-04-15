import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class Licenses extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get licenseCode => text().unique()();
  TextColumn get deviceFingerprint => text().nullable()();
  DateTimeColumn get activationDate => dateTime().nullable()();
  DateTimeColumn get lastVerified => dateTime().nullable()();
  TextColumn get status => text().withDefault(const Constant('active'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get tierLevel => text().nullable()();
  IntColumn get maxDevices => integer().withDefault(const Constant(1))();
  IntColumn get maxOutlets => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}