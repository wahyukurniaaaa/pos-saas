import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

// ─── Providers ──────────────────────────────────────────────────────────────

final purchaseOrdersProvider =
    AsyncNotifierProvider<PurchaseOrderNotifier, List<PurchaseOrder>>(
        PurchaseOrderNotifier.new);

// ─── Notifier ───────────────────────────────────────────────────────────────

class PurchaseOrderNotifier extends AsyncNotifier<List<PurchaseOrder>> {
  @override
  Future<List<PurchaseOrder>> build() {
    final session = ref.watch(sessionProvider).value;
    if (session == null || session.outletId == null) return Future.value([]);
    return ref.read(databaseProvider).getAllPurchaseOrders(session.outletId!);
  }

  Future<String> createPO({
    String? supplierId,
    String? notes,
    required List<PurchaseOrderItemsCompanion> items,
  }) async {
    final db = ref.read(databaseProvider);
    final session = ref.read(sessionProvider).value;
    final String? outletId = session?.outletId;
    final now = DateTime.now();
    
    final poId = await db.createPurchaseOrder(
      PurchaseOrdersCompanion.insert(
        supplierId: supplierId != null ? Value(supplierId) : const Value.absent(),
        notes: notes != null ? Value(notes) : const Value.absent(),
        orderedAt: Value(now),
        updatedAt: Value(now),
        outletId: outletId != null ? Value(outletId) : const Value.absent(),
      ),
    );

    for (var item in items) {
      if (outletId != null) {
        item = item.copyWith(outletId: Value(outletId));
      }
      await db.addPurchaseOrderItem(
        item.copyWith(purchaseOrderId: Value(poId)),
      );
    }

    await refresh();
    return poId;
  }

  Future<void> updateStatus(String poId, String status) async {
    await ref.read(databaseProvider).updatePurchaseOrderStatus(poId, status);
    await refresh();
  }

  Future<void> receivePO({
    required String poId,
    required List<({String itemId, double receivedQty})> receivedItems,
  }) async {
    await ref.read(databaseProvider).receivePurchaseOrder(
          poId: poId,
          receivedItems: receivedItems,
        );
    await refresh();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    final session = ref.read(sessionProvider).value;
    if (session == null || session.outletId == null) return;
    
    state = await AsyncValue.guard(
      () => ref.read(databaseProvider).getAllPurchaseOrders(session.outletId!),
    );
  }
}

// ─── PO Items provider (per-PO) ─────────────────────────────────────────────

final poItemsProvider = FutureProvider.family<List<PurchaseOrderItem>, String>(
  (ref, poId) => ref.read(databaseProvider).getPurchaseOrderItems(poId),
);
