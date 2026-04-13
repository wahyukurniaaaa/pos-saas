import 'package:drift/drift.dart';
import 'outlets_table.dart';
import '../../utils/uuid_generator.dart';
import 'employees_table.dart';

class ExpenseCategories extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get name => text().withLength(min: 2, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('shopping_bag'))(); // material icon name
  TextColumn get color => text().withDefault(const Constant('#1E3A5F'))(); // hex color
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  TextColumn get shiftId => text().nullable()(); // nullable: expense may be entered outside shift
  TextColumn get recordedBy => text().references(Employees, #id)();
  IntColumn get amount => integer()(); // in Rupiah
  TextColumn get note => text().nullable()();
  TextColumn get photoUri => text().nullable()(); // local path to receipt photo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
    TextColumn get outletId => text().nullable().references(Outlets, #id)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}