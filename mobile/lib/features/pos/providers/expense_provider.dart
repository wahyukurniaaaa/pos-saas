import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

// ─── CRUD Providers ──────────────────────────────────────────────────────────

final expenseCategoryProvider =
    AsyncNotifierProvider<ExpenseCategoryNotifier, List<ExpenseCategory>>(
        ExpenseCategoryNotifier.new);

class ExpenseCategoryNotifier extends AsyncNotifier<List<ExpenseCategory>> {
  @override
  Future<List<ExpenseCategory>> build() async {
    final db = ref.watch(databaseProvider);
    return db.getAllExpenseCategories();
  }

  Future<void> upsert(ExpenseCategoriesCompanion entry) async {
    final db = ref.read(databaseProvider);
    await db.upsertExpenseCategory(entry);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteExpenseCategory(id);
    ref.invalidateSelf();
  }
}

// ─── Expense CRUD Provider ───────────────────────────────────────────────────

final expenseProvider =
    AsyncNotifierProvider<ExpenseNotifier, List<ExpenseWithCategory>>(
        ExpenseNotifier.new);

class ExpenseNotifier extends AsyncNotifier<List<ExpenseWithCategory>> {
  DateTime? _filterDate;

  @override
  Future<List<ExpenseWithCategory>> build() async {
    final db = ref.watch(databaseProvider);
    _filterDate ??= DateTime.now();
    return db.getExpensesWithCategory(date: _filterDate!);
  }

  void setDate(DateTime date) {
    _filterDate = date;
    ref.invalidateSelf();
  }

  Future<void> add(ExpensesCompanion entry) async {
    final db = ref.read(databaseProvider);
    await db.insertExpense(entry);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final db = ref.read(databaseProvider);
    await db.deleteExpense(id);
    ref.invalidateSelf();
  }
}

// ─── Analytics Providers ─────────────────────────────────────────────────────

final cashFlowProvider =
    AsyncNotifierProvider<CashFlowNotifier, CashFlowData>(
        CashFlowNotifier.new);

class CashFlowNotifier extends AsyncNotifier<CashFlowData> {
  @override
  Future<CashFlowData> build() async {
    final db = ref.watch(databaseProvider);
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 6);
    return db.getCashFlowData(from: from, to: now);
  }
}

// ─── Expense for current shift summary ───────────────────────────────────────

final shiftExpenseTotalProvider =
    FutureProvider.family<int, String>((ref, shiftId) async {
  final db = ref.watch(databaseProvider);
  return db.getTotalExpenseByShift(shiftId);
});
