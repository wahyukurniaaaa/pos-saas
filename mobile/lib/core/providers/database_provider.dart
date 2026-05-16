import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database.dart';

final databaseProvider = Provider<LumioDatabase>((ref) {
  final db = LumioDatabase();
  ref.onDispose(() => db.close());
  return db;
});
