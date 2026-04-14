import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';
import 'package:posify_app/core/database/database.dart';

final outletLimitProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final license = await db.getLocalLicense();
  return license?.maxOutlets ?? 1;
});

final currentOutletsCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = await (db.select(db.outlets)).get().then((value) => value.length);
  return count;
});

final canAddOutletProvider = FutureProvider<bool>((ref) async {
  final limit = await ref.watch(outletLimitProvider.future);
  final count = await ref.watch(currentOutletsCountProvider.future);
  
  return count < limit;
});
