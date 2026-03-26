import 'package:drift/drift.dart';

class StoreProfile extends Table {
  IntColumn get id => integer().autoIncrement()();
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
}
