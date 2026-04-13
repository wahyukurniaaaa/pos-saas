import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class Categories extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text().withLength(min: 1, max: 50).unique()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}