import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';

class UnitConversions extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get fromUnit => text()(); // e.g., 'kg', 'liter', 'box', 'karton'
  TextColumn get toUnit => text()(); // e.g., 'gr', 'ml', 'pcs'
  RealColumn get multiplier => real()(); // 1 fromUnit = multiplier toUnit
  TextColumn get notes => text().nullable()(); // e.g., '1 Karton Susu = 12 Botol'
  TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}