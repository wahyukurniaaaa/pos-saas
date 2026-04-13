import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';
import 'products_table.dart';
import 'ingredients_table.dart';

class ProductRecipes extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get productId => text().references(Products, #id)();
  TextColumn get ingredientId => text().references(Ingredients, #id)();
  RealColumn get quantityNeeded => real()(); // In Base Unit
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}