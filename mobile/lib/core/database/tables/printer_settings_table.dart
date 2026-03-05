import 'package:drift/drift.dart';

class PrinterSettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get deviceName => text()();
  TextColumn get macAddress => text().unique()();
  TextColumn get status =>
      text().withDefault(const Constant('paired'))(); // paired, last_connected
}
