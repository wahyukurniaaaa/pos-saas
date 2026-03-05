import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final databaseProvider = Provider<PosifyDatabase>((ref) {
  final db = PosifyDatabase();
  ref.onDispose(() => db.close());
  return db;
});
