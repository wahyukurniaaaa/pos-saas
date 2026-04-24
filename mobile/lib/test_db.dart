import 'package:flutter/material.dart';
import 'package:posify_app/core/database/database.dart';

Future<void> testDB(PosifyDatabase db) async {
  final l1 = await db.getAllProducts('test-outlet');
  print('getAllProducts: \${l1.length}');
  final l2 = await db.getAllProductsWithVariants('test-outlet');
  print('getAllProductsWithVariants: \${l2.length}');
}
