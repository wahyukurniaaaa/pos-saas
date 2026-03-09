import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

final storeProfileProvider = StreamProvider<StoreProfileData?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchStoreProfile();
});

class StoreNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> updateTaxAndService({
    required int taxPercentage,
    required String taxType,
    required int serviceChargePercentage,
  }) async {
    state = const AsyncValue.loading();
    try {
      final db = ref.read(databaseProvider);
      final current = await db.getStoreProfile();

      if (current == null) return false;

      await db.updateStoreProfile(
        current.copyWith(
          taxPercentage: taxPercentage,
          taxType: taxType,
          serviceChargePercentage: serviceChargePercentage,
        ),
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final storeControllerProvider = AsyncNotifierProvider<StoreNotifier, void>(
  StoreNotifier.new,
);
