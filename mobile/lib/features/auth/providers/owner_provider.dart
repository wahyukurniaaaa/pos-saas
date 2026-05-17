import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/database/database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:lumio/core/providers/license_tier_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reactive stream of the owner employee record.
/// Emits a new value whenever the employees table changes.
final ownerStreamProvider = StreamProvider<Employee?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchOwner();
});

/// Notifier for owner setup.
/// Non-autoDispose so owner state persists throughout app lifecycle.
class OwnerNotifier extends AsyncNotifier<Employee?> {
  @override
  Future<Employee?> build() async {
    // Watch the stream reactively — UI auto-updates when sync pulls owner data.
    return ref.watch(ownerStreamProvider.future);
  }

  /// Automatically creates an owner employee record if the store was set up on the web,
  /// but no owner employee record was generated.
  Future<void> autoCreateOwnerFromCloud(String storeName) async {
    final db = ref.read(databaseProvider);
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    final email = authUser.email ?? 'owner@lumio.pos';
    String displayName = authUser.userMetadata?['name'] ?? 
                          authUser.userMetadata?['full_name'] ?? 
                          email.split('@')[0];

    if (displayName.isNotEmpty) {
      displayName = displayName[0].toUpperCase() + displayName.substring(1);
    }

    try {
      // 1. Get first outlet or create a default one
      String? targetOutletId;
      final localOutlets = await db.customSelect('SELECT id FROM outlets LIMIT 1').get();
      
      if (localOutlets.isNotEmpty) {
        targetOutletId = localOutlets.first.read<String>('id');
      } else {
        // Create default outlet
        targetOutletId = await db.insertOutlet(
          OutletsCompanion.insert(
            name: storeName,
            address: const Value(''),
            phone: const Value(''),
          ),
        );
      }

      // 2. Insert owner employee with targetOutletId and default PIN '123456'
      await db.insertEmployee(
        EmployeesCompanion.insert(
          name: displayName,
          pin: '123456', // Default secure PIN for initial login
          role: 'owner',
          outletId: Value(targetOutletId),
        ),
      );

      debugPrint('Sync: Auto-created owner employee for $displayName with PIN 123456');
      
      // Force refresh owner notification state
      ref.invalidateSelf();
    } catch (e) {
      debugPrint('Sync: Error auto-creating owner employee: $e');
    }
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

      // 1.1 Seed Default Categories for the new outlet
      await db.insertCategory(CategoriesCompanion.insert(
        name: 'Makanan',
        outletId: Value(outletId),
      ));
      await db.insertCategory(CategoriesCompanion.insert(
        name: 'Minuman',
        outletId: Value(outletId),
      ));
      await db.insertCategory(CategoriesCompanion.insert(
        name: 'Camilan',
        outletId: Value(outletId),
      ));

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

final storeProfileProvider = StreamProvider<StoreProfileData?>((ref) {
  final db = ref.watch(databaseProvider);
  return db.watchStoreProfile();
});

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
      final inputPin = pin.trim();
      
      // 2. Fetch the latest employee data directly from DB to ensure source-of-truth PIN
      // This protects against stale objects passed from UI stream snapshots.
      final latestEmployee = await db.getEmployeeById(employee.id);
      if (latestEmployee == null) {
        state = AsyncValue.error('Akun tidak ditemukan', StackTrace.current);
        return null;
      }

      final storedPin = latestEmployee.pin.trim();
      
      // 3. Verify PIN matches
      debugPrint('Auth: Stored PIN for ${latestEmployee.name} is "${storedPin.replaceAll(RegExp(r'.'), '*')}" (len: ${storedPin.length})');
      debugPrint('Auth: Input PIN is "${inputPin.replaceAll(RegExp(r'.'), '*')}" (len: ${inputPin.length})');
      
      if (storedPin != inputPin) {
        debugPrint('Auth: Result -> PIN MISMATCH');
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

      // 4. Check if locked
      if (latestEmployee.lockedUntil != null &&
          latestEmployee.lockedUntil!.isAfter(DateTime.now())) {
        debugPrint('Auth: Result -> ACCOUNT LOCKED until ${latestEmployee.lockedUntil}');
        state = AsyncValue.error(
          'Akun terkunci. Coba lagi nanti.',
          StackTrace.current,
        );
        return null;
      }

      // 5. Check if active
      if (latestEmployee.status != 'active') {
        debugPrint('Auth: Result -> ACCOUNT INACTIVE (status: ${latestEmployee.status})');
        state = AsyncValue.error(
          'Akun tidak aktif. Hubungi pemilik.',
          StackTrace.current,
        );
        return null;
      }

      debugPrint('Auth: Result -> SUCCESS');

      // Reset failed attempts on success
      await _storage.delete(key: _failCountKey);
      await _storage.delete(key: _lockoutKey);

      await db.updateEmployee(
        latestEmployee.copyWith(
          failedLoginAttempts: 0,
          lockedUntil: const Value(null),
        ),
      );

      if (!ref.mounted) return null;

      state = AsyncValue.data(latestEmployee);
      return latestEmployee;
    } catch (e, st) {
      debugPrint('Auth: Result -> EXCEPTION: $e');
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

  Future<void> hardLogout() async {
    final db = ref.read(databaseProvider);
    // Clear all tables
    await db.transaction(() async {
      final tables = [
        'transaction_items', 'transactions', 'shifts', 'stock_transactions',
        'product_variants', 'products', 'categories', 'employees',
        'licenses', 'store_profile', 'printer_settings', 'outlets',
        'ingredients', 'product_recipes', 'ingredient_stock_history',
        'unit_conversions', 'stock_opname', 'stock_opname_items',
        'discounts', 'expense_categories', 'expenses', 'sync_queue'
      ];
      
      for (final table in tables) {
        try {
          await db.customStatement('DELETE FROM "$table"');
        } catch (_) {
          // Some tables might not exist yet or have different names
        }
      }
    });

    state = const AsyncValue.data(null);
    ref.invalidate(ownerProvider);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionNotifier, Employee?>(
  SessionNotifier.new,
);
