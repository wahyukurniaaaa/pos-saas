import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

final openShiftProvider = StreamProvider<Shift?>((ref) {
  final db = ref.watch(databaseProvider);
  final session = ref.watch(sessionProvider).value;
  if (session == null || session.outletId == null) return Stream.value(null);
  return db.watchOpenShift(session.outletId!);
});

class ShiftNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> openShift(int startingCash) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(databaseProvider);
      final employee = await ref.read(sessionProvider.future);

      if (employee == null) {
        state = AsyncError('No employee session found', StackTrace.current);
        return false;
      }

      await db.insertShift(
        ShiftsCompanion.insert(
          employeeId: employee.id,
          startTime: DateTime.now(),
          startingCash: drift.Value(startingCash),
          status: const drift.Value('open'),
          expectedEndingCash: drift.Value(startingCash),
          outletId: drift.Value(employee.outletId),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }

  Future<bool> closeShift(String shiftId, int actualEndingCash) async {
    state = const AsyncLoading();
    try {
      final db = ref.read(databaseProvider);
      final employee = await ref.read(sessionProvider.future);
      if (employee == null || employee.outletId == null) {
        state = AsyncError('No valid session', StackTrace.current);
        return false;
      }
      final currentShift = await db.getOpenShift(employee.outletId!);

      if (currentShift == null || currentShift.id != shiftId) {
        state = AsyncError(
          'Invalid shift or shift already closed',
          StackTrace.current,
        );
        return false;
      }

      final transactions = await db.watchTransactionsByShift(shiftId).first;
      int totalSales = 0;
      for (final t in transactions) {
        if (t.paymentStatus == 'paid' && t.paymentMethod == 'tunai') {
          totalSales += t.totalAmount;
        }
      }

      final expectedEndingCash = currentShift.startingCash + totalSales;

      await db.updateShift(
        currentShift.copyWith(
          endTime: drift.Value(DateTime.now()),
          status: 'closed',
          actualEndingCash: drift.Value(actualEndingCash),
          expectedEndingCash: drift.Value(expectedEndingCash),
        ),
      );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(e, st);
      return false;
    }
  }
}

final shiftControllerProvider = AsyncNotifierProvider<ShiftNotifier, void>(
  ShiftNotifier.new,
);
