import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class Customers extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  BoolColumn get isMember => boolean().withDefault(const Constant(true))();
  IntColumn get points => integer().withDefault(const Constant(0))();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}