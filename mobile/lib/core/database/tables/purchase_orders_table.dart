import 'package:drift/drift.dart';

import 'suppliers_table.dart';
import 'ingredients_table.dart';
import 'products_table.dart';

// Status: draft → sent → received | cancelled
class PurchaseOrders extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId =>
      integer().nullable().references(Suppliers, #id)();
  TextColumn get status =>
      text().withDefault(const Constant('draft'))(); // draft/sent/received/cancelled
  IntColumn get totalEstimate => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get orderedAt => text()();
  TextColumn get updatedAt => text()();
}

class PurchaseOrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseOrderId =>
      integer().references(PurchaseOrders, #id)();
  // One of these must be non-null depending on whether it's a product or ingredient
  IntColumn get productId =>
      integer().nullable().references(Products, #id)();
  IntColumn get ingredientId =>
      integer().nullable().references(Ingredients, #id)();
  TextColumn get itemName => text()(); // Snapshot name at time of PO creation
  TextColumn get unit => text()(); // Snapshot unit
  RealColumn get quantity => real()();
  IntColumn get purchasePrice => integer().withDefault(const Constant(0))();
  RealColumn get receivedQuantity =>
      real().withDefault(const Constant(0))();
}
