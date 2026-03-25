import 'package:drift/drift.dart';
import 'products_table.dart';
import 'ingredients_table.dart';

class ProductRecipes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get ingredientId => integer().references(Ingredients, #id)();
  RealColumn get quantityNeeded => real()(); // In Base Unit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
