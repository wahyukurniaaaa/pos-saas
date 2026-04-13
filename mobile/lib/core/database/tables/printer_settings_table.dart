import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class PrinterSettings extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get deviceName => text()();
  TextColumn get macAddress => text().unique()();
  TextColumn get status =>
      text().withDefault(const Constant('paired'))(); // paired, last_connected
  BoolColumn get autoPrint => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}