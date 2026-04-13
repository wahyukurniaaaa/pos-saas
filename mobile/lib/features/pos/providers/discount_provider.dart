import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final discountProvider =
    AsyncNotifierProvider<DiscountNotifier, List<Discount>>(
        DiscountNotifier.new);

/// Provider that returns valid *transaction-scope* discounts for a given cart total.
final validTransactionDiscountsProvider =
    FutureProvider.family<List<Discount>, double>((ref, cartTotal) {
  return ref
      .read(databaseProvider)
      .getValidDiscounts(cartTotal: cartTotal, scope: 'transaction');
});

/// Provider that returns valid *item-scope* discounts.
final validItemDiscountsProvider =
    FutureProvider.family<List<Discount>, double>((ref, cartTotal) {
  return ref
      .read(databaseProvider)
      .getValidDiscounts(cartTotal: cartTotal, scope: 'item');
});

// ─── Currently selected bill-level discount ──────────────────────────────────

class SelectedDiscountNotifier extends Notifier<Discount?> {
  bool _userExplicitlyRemoved = false;

  @override
  Discount? build() => null;
  
  set state(Discount? val) {
    if (val == null) {
      _userExplicitlyRemoved = true;
    } else {
      _userExplicitlyRemoved = false;
    }
    super.state = val;
  }

  void reset() {
    _userExplicitlyRemoved = false;
    super.state = null;
  }

  void autoApplyIfNeeded(List<Discount> validDiscounts, double totalAmount) {
    if (super.state != null || _userExplicitlyRemoved) return;

    final autoDiscounts = validDiscounts
        .where((d) => d.isAutomatic && d.minSpend <= totalAmount)
        .toList();

    if (autoDiscounts.isNotEmpty) {
      autoDiscounts.sort((a, b) => 
          calculateDiscountAmount(b, totalAmount.toInt())
          .compareTo(calculateDiscountAmount(a, totalAmount.toInt())));
      
      Future.microtask(() {
        if (super.state == null && !_userExplicitlyRemoved) {
          super.state = autoDiscounts.first;
        }
      });
    }
  }
}

final selectedDiscountProvider =
    NotifierProvider<SelectedDiscountNotifier, Discount?>(SelectedDiscountNotifier.new);

// ─── DiscountNotifier ────────────────────────────────────────────────────────

class DiscountNotifier extends AsyncNotifier<List<Discount>> {
  @override
  Future<List<Discount>> build() {
    final db = ref.read(databaseProvider);
    db.watchAllDiscounts().listen((data) {
      if (ref.mounted) state = AsyncValue.data(data);
    });
    return ref.read(databaseProvider).getAllDiscounts();
  }

  Future<void> save(DiscountsCompanion entry) async {
    await ref.read(databaseProvider).upsertDiscount(entry);
    await _refresh();
  }

  Future<void> remove(String id) async {
    await ref.read(databaseProvider).deleteDiscount(id);
    await _refresh();
  }

  Future<void> _refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(databaseProvider).getAllDiscounts(),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Calculates the discount amount to subtract for a given discount and base amount.
int calculateDiscountAmount(Discount discount, int baseAmount) {
  if (discount.type == 'fixed') {
    return discount.value.toInt().clamp(0, baseAmount);
  }
  // percentage
  return ((baseAmount * discount.value) / 100).round().clamp(0, baseAmount);
}
