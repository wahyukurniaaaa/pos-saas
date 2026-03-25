import 'package:drift/drift.dart';

class UnitConversions extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get fromUnit => text()(); // e.g., 'kg', 'liter', 'box', 'karton'
  TextColumn get toUnit => text()(); // e.g., 'gr', 'ml', 'pcs'
  RealColumn get multiplier => real()(); // 1 fromUnit = multiplier toUnit
  TextColumn get notes => text().nullable()(); // e.g., '1 Karton Susu = 12 Botol'
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
