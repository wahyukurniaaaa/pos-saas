import 'package:drift/drift.dart';
import '../../utils/uuid_generator.dart';

import 'suppliers_table.dart';
import 'ingredients_table.dart';
import 'products_table.dart';

// Status: draft → sent → received | cancelled
class PurchaseOrders extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get supplierId =>
      text().nullable().references(Suppliers, #id)();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))(); // draft/sent/received/cancelled
  IntColumn get totalEstimate => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get orderedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class PurchaseOrderItems extends Table {
  TextColumn get id => text().clientDefault(() => UuidGenerator.generate())();
  TextColumn get purchaseOrderId =>
      text().references(PurchaseOrders, #id)();
  // One of these must be non-null depending on whether it's a product or ingredient
  TextColumn get productId =>
      text().nullable().references(Products, #id)();
  TextColumn get ingredientId =>
      text().nullable().references(Ingredients, #id)();
  TextColumn get itemName => text()(); // Snapshot name at time of PO creation
  TextColumn get unit => text()(); // Snapshot unit
  RealColumn get quantity => real()();
  IntColumn get purchasePrice => integer().withDefault(const Constant(0))();
  RealColumn get receivedQuantity =>
      real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}