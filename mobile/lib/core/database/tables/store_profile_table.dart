import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

class StoreProfile extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  TextColumn get address => text().nullable()();
  TextColumn get phone => text().nullable()();
  IntColumn get taxPercentage => integer().withDefault(const Constant(0))();
  TextColumn get taxType =>
      text().withDefault(const Constant('exclusive'))(); // inclusive, exclusive
  IntColumn get serviceChargePercentage =>
      integer().withDefault(const Constant(0))();
  TextColumn get logoUri => text().nullable()();
  IntColumn get loyaltyPointConversion =>
      integer().withDefault(const Constant(10000))();
  IntColumn get loyaltyPointValue =>
      integer().withDefault(const Constant(100))();
  BoolColumn get deductStockOnHold =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}