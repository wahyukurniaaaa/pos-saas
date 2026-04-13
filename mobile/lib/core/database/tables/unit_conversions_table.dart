import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class UnitConversions extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get fromUnit => text()(); // e.g., 'kg', 'liter', 'box', 'karton'
  TextColumn get toUnit => text()(); // e.g., 'gr', 'ml', 'pcs'
  RealColumn get multiplier => real()(); // 1 fromUnit = multiplier toUnit
  TextColumn get notes => text().nullable()(); // e.g., '1 Karton Susu = 12 Botol'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}