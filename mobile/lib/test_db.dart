import 'package:flutter/material.dart';
import 'package:posify_app/core/database/database.dart';

Future<void> testDB(PosifyDatabase db) async {
  final l1 = await db.getAllProducts();
  print('getAllProducts: \${l1.length}');
  final l2 = await db.getAllProductsWithVariants();
  print('getAllProductsWithVariants: \${l2.length}');
}
