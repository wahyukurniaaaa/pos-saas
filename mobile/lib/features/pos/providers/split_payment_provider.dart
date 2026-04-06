import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported payment methods for split payment.
/// 'kasbon' is intentionally excluded from this list.
const kSplitPaymentMethods = ['Tunai', 'QRIS', 'Debit', 'Kredit'];
const kMaxSplitMethods = 4;

/// Represents a single payment line in a split transaction.
class PaymentEntry {
  final String method;
  final double amount;

  const PaymentEntry({required this.method, required this.amount});

  PaymentEntry copyWith({String? method, double? amount}) {
    return PaymentEntry(
      method: method ?? this.method,
      amount: amount ?? this.amount,
    );
  }
}

/// Manages the list of payment entries for split payment.
class SplitPaymentNotifier extends Notifier<List<PaymentEntry>> {
  @override
  List<PaymentEntry> build() => [];

  void addPayment(PaymentEntry entry) {
    if (state.length >= kMaxSplitMethods) return;
    state = [...state, entry];
  }

  void updatePayment(int index, PaymentEntry entry) {
    final updated = [...state];
    updated[index] = entry;
    state = updated;
  }

  void removePayment(int index) {
    if (state.length <= index) return;
    final updated = [...state];
    updated.removeAt(index);
    state = updated;
  }

  /// Reset to a single default payment entry.
  void reset() => state = [];

  /// Total amount paid across all entries.
  double get totalPaid => state.fold(0.0, (sum, e) => sum + e.amount);

  /// Remaining amount that still needs to be paid.
  double remaining(double finalTotal) =>
      (finalTotal - totalPaid).clamp(0, double.infinity);

  /// Whether the total paid covers the full amount.
  bool isComplete(double finalTotal) => totalPaid >= finalTotal;

  /// Whether more payment methods can be added.
  bool get canAddMore => state.length < kMaxSplitMethods;

  /// True if more than one method is active.
  bool get isSplitMode => state.length > 1;

  /// The effective `paymentMethod` string to store in transactions table.
  String effectiveMethod() {
    if (state.isEmpty) return 'tunai';
    if (state.length == 1) return state.first.method.toLowerCase();
    return 'mixed';
  }

  /// Change amount for the Tunai entry (last one wins if multiple).
  double changeFor(double finalTotal) {
    final remaining = finalTotal - state
        .where((e) => e.method.toLowerCase() != 'tunai')
        .fold(0.0, (sum, e) => sum + e.amount);
    final cashEntry = state.lastWhere(
      (e) => e.method.toLowerCase() == 'tunai',
      orElse: () => const PaymentEntry(method: 'tunai', amount: 0),
    );
    final change = cashEntry.amount - remaining;
    return change > 0 ? change : 0;
  }
}

final splitPaymentProvider =
    NotifierProvider<SplitPaymentNotifier, List<PaymentEntry>>(
  SplitPaymentNotifier.new,
);
