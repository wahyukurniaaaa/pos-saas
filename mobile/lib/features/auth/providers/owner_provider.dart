import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/database/database.dart';

/// Notifier for owner setup.
/// Non-autoDispose so owner state persists throughout app lifecycle.
class OwnerNotifier extends AsyncNotifier<Employee?> {
  @override
  Future<Employee?> build() async {
    final db = ref.watch(databaseProvider);
    return db.getOwner();
  }

  Future<bool> setupOwner({
    required String name,
    required String storeName,
    required String pin,
  }) async {
    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);

    try {
      // 1. Save Owner to employees table
      await db.insertEmployee(
        EmployeesCompanion.insert(name: name, pin: pin, role: 'owner'),
      );

      if (!ref.mounted) return false;

      // 2. Save Store Profile
      await db.insertStoreProfile(
        StoreProfileCompanion.insert(name: storeName),
      );

      if (!ref.mounted) return false;

      // 3. Refresh
      ref.invalidateSelf();
      return true;
    } catch (e, st) {
      if (!ref.mounted) return false;
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

final ownerProvider = AsyncNotifierProvider<OwnerNotifier, Employee?>(
  OwnerNotifier.new,
);

/// Provider for current logged-in employee (via PIN).
/// Non-autoDispose so session persists throughout app lifecycle.
class SessionNotifier extends AsyncNotifier<Employee?> {
  @override
  Future<Employee?> build() async => null;

  Future<Employee?> loginWithPin(String pin) async {
    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);

    try {
      final employee = await db.getEmployeeByPin(pin);
      if (!ref.mounted) return null;

      if (employee == null) {
        state = AsyncValue.error('PIN tidak ditemukan', StackTrace.current);
        return null;
      }

      // Check if locked
      if (employee.lockedUntil != null &&
          employee.lockedUntil!.isAfter(DateTime.now())) {
        state = AsyncValue.error(
          'Akun terkunci. Coba lagi nanti.',
          StackTrace.current,
        );
        return null;
      }

      // Check if active
      if (employee.status != 'active') {
        state = AsyncValue.error(
          'Akun tidak aktif. Hubungi pemilik.',
          StackTrace.current,
        );
        return null;
      }

      // Reset failed attempts on success
      await db.updateEmployee(
        employee.copyWith(failedLoginAttempts: 0, lockedUntil: Value(null)),
      );

      if (!ref.mounted) return null;

      state = AsyncValue.data(employee);
      return employee;
    } catch (e, st) {
      if (!ref.mounted) return null;
      state = AsyncValue.error(e.toString(), st);
      return null;
    }
  }

  void logout() {
    state = const AsyncValue.data(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Employee?>(
  SessionNotifier.new,
);
