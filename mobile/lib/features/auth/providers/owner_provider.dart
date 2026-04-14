import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:posify_app/core/providers/license_tier_provider.dart';

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
    final cleanPin = pin.trim();
    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);

    try {
      // 0. Create Default Outlet (Bootstrapping Phase 0.0)
      final outletId = await db.insertOutlet(
        OutletsCompanion.insert(
          name: storeName, // Use store name as initial outlet name
          address: const Value(''),
          phone: const Value(''),
        ),
      );

      // 1. Save Owner to employees table, linked to the new outlet
      await db.insertEmployee(
        EmployeesCompanion.insert(
          name: name,
          pin: cleanPin,
          role: 'owner',
          outletId: Value(outletId),
        ),
      );

      if (!ref.mounted) return false;

      // 2. Save Store Profile (Global)
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

  Future<String?> addOutlet({
    required String name,
    required String address,
    required String phone,
  }) async {
    final db = ref.read(databaseProvider);
    
    // Evaluate Gate
    final canAdd = await ref.read(canAddOutletProvider.future);
    if (!canAdd) {
      return 'Batas maksimum outlet tercapai. Silakan upgrade lisensi Anda.';
    }

    try {
      await db.insertOutlet(
        OutletsCompanion.insert(
          name: name,
          address: Value(address),
          phone: Value(phone),
        ),
      );
      return null; // Success
    } catch (e) {
      return e.toString();
    }
  }
}

final ownerProvider = AsyncNotifierProvider<OwnerNotifier, Employee?>(
  OwnerNotifier.new,
);

/// Provider for current logged-in employee (via PIN).
/// Non-autoDispose so session persists throughout app lifecycle.
class SessionNotifier extends AsyncNotifier<Employee?> {
  final _storage = const FlutterSecureStorage();
  static const _failCountKey = 'login_fail_count';
  static const _lockoutKey = 'login_lockout_until';

  @override
  Future<Employee?> build() async => null;

  Future<Employee?> loginWithEmployeeAndPin(
    Employee employee,
    String pin,
  ) async {
    // 1. Check Device Lockout
    final lockoutStr = await _storage.read(key: _lockoutKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil != null && lockoutUntil.isAfter(DateTime.now())) {
        state = AsyncValue.error(
          'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.',
          StackTrace.current,
        );
        return null;
      }
    }

    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);

    try {
      // 2. Verify PIN matches the specific selected employee
      if (employee.pin != pin.trim()) {
        // Increment failure count
        final countStr = await _storage.read(key: _failCountKey) ?? '0';
        int count = int.parse(countStr) + 1;
        await _storage.write(key: _failCountKey, value: count.toString());

        if (count >= 5) {
          final lockoutTime = DateTime.now().add(const Duration(minutes: 30));
          await _storage.write(
            key: _lockoutKey,
            value: lockoutTime.toIso8601String(),
          );
        }

        state = AsyncValue.error('PIN salah', StackTrace.current);
        return null;
      }

      // 3. Check if locked
      if (employee.lockedUntil != null &&
          employee.lockedUntil!.isAfter(DateTime.now())) {
        state = AsyncValue.error(
          'Akun terkunci. Coba lagi nanti.',
          StackTrace.current,
        );
        return null;
      }

      // 4. Check if active
      if (employee.status != 'active') {
        state = AsyncValue.error(
          'Akun tidak aktif. Hubungi pemilik.',
          StackTrace.current,
        );
        return null;
      }

      // Reset failed attempts on success
      await _storage.delete(key: _failCountKey);
      await _storage.delete(key: _lockoutKey);

      await db.updateEmployee(
        employee.copyWith(
          failedLoginAttempts: 0,
          lockedUntil: const Value(null),
        ),
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

  Future<Employee?> loginWithPin(String pin) async {
    // 1. Check Device Lockout
    final lockoutStr = await _storage.read(key: _lockoutKey);
    if (lockoutStr != null) {
      final lockoutUntil = DateTime.tryParse(lockoutStr);
      if (lockoutUntil != null && lockoutUntil.isAfter(DateTime.now())) {
        state = AsyncValue.error(
          'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.',
          StackTrace.current,
        );
        return null;
      }
    }

    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);

    try {
      final employee = await db.getEmployeeByPin(pin.trim());
      if (!ref.mounted) return null;

      if (employee == null) {
        // Increment failure count
        final countStr = await _storage.read(key: _failCountKey) ?? '0';
        int count = int.parse(countStr) + 1;
        await _storage.write(key: _failCountKey, value: count.toString());

        if (count >= 5) {
          final lockoutTime = DateTime.now().add(const Duration(minutes: 30));
          await _storage.write(
            key: _lockoutKey,
            value: lockoutTime.toIso8601String(),
          );
        }

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
      await _storage.delete(key: _failCountKey);
      await _storage.delete(key: _lockoutKey);

      await db.updateEmployee(
        employee.copyWith(
          failedLoginAttempts: 0,
          lockedUntil: const Value(null),
        ),
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
