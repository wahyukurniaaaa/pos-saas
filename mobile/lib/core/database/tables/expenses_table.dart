import 'package:drift/drift.dart';
import 'employees_table.dart';

class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 2, max: 50)();
  TextColumn get icon => text().withDefault(const Constant('shopping_bag'))(); // material icon name
  TextColumn get color => text().withDefault(const Constant('#1E3A5F'))(); // hex color
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  IntColumn get shiftId => integer().nullable()(); // nullable: expense may be entered outside shift
  IntColumn get recordedBy => integer().references(Employees, #id)();
  IntColumn get amount => integer()(); // in Rupiah
  TextColumn get note => text().nullable()();
  TextColumn get photoUri => text().nullable()(); // local path to receipt photo
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
