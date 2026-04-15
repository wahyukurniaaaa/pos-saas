import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/providers/license_tier_provider.dart';

/// Enumeration of possible sync states for the UI indicator.
enum SyncStatus { idle, syncing, error }

/// Manages background synchronization of local Drift data to Supabase Cloud.
///
/// RESTRICTED TO PRO USERS ONLY:
/// Users authenticated via Supabase (email/Google) are considered 'Pro'.
/// Activation Key-only users will not receive cloud sync.
class SyncService {
  final Ref _ref;

  /// Supabase tables to sync, ordered by dependency (parents before children).
  static const _syncableTables = [
    'outlets',
    'categories',
    'suppliers',
    'customers',
    'employees',
    'products',
    'product_variants',
    'ingredients',
    'discounts',
    'shifts',
    'transactions',
    'transaction_items',
    'transaction_payments',
    'expenses',
    'purchase_orders',
    'stock_opname',
    'stock_opname_items',
    'stock_transactions',
  ];

  SyncService(this._ref);

  Timer? _syncTimer;
  bool _isSyncing = false;

  /// Starts the background sync polling (every 30 seconds).
  void start() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => performSync(),
    );
    // Perform an immediate sync on start
    performSync();
    debugPrint('SyncService: Started');
  }

  /// Stops the sync timer.
  void stop() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.idle);
    debugPrint('SyncService: Stopped');
  }

  /// Push all dirty local records to Supabase.
  /// Guard: Only runs if the user is authenticated (Pro user).
  Future<void> performSync() async {
    if (_isSyncing) return;

    // Auth Guard: Pro users only
    final user = _ref.read(authProvider).value;
    if (user == null) {
      debugPrint('SyncService: Skipping — user not authenticated (non-Pro)');
      return;
    }

    // Tier Guard: Pro users only
    // Use read instead of future if possible, or handle async carefully
    final license = _ref.read(licenseProvider).value;
    final isPro = license?.tierLevel?.toLowerCase() == 'pro';

    if (!isPro) {
      debugPrint('SyncService: Skipping — Lite tier user...');
      return;
    }

    _isSyncing = true;
    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
    debugPrint('SyncService: Sync started for ${user.email}');

    try {
      await _pullChanges();
      await _pushAllDirty();
      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.idle);
      debugPrint('SyncService: Sync completed');
    } catch (e) {
      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.error);
      debugPrint('SyncService: Sync failed — $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _pushAllDirty() async {
    final db = _ref.read(databaseProvider);
    final supabase = Supabase.instance.client;

    for (final table in _syncableTables) {
      final dirtyRows = await db.getDirtyRows(table);
      if (dirtyRows.isEmpty) continue;

      debugPrint('SyncService: Pushing ${dirtyRows.length} rows → $table');

      // Remove internal-only / Supabase-incompatible fields before upsert
      final payload = dirtyRows.map((row) {
        final cleaned = Map<String, dynamic>.from(row);
        cleaned.remove('is_dirty'); // Supabase doesn't need this flag

        // Strip 'stock' component to prevent conflict with Supabase triggers (Delta approach)
        if (table == 'products' || table == 'product_variants') {
          cleaned.remove('stock');
        }

        // Strip local-only security columns from employees table
        if (table == 'employees') {
          cleaned.remove('failed_login_attempts');
          cleaned.remove('locked_until');
          cleaned.remove('photo_uri'); // Local file path, not syncable
        }

        return cleaned;
      }).toList();

      await supabase.from(table).upsert(payload);

      // Mark as clean after successful push
      final ids = dirtyRows.map((r) => r['id'] as String).toList();
      await db.markAsClean(table, ids);
    }
  }

  Future<void> _pullChanges() async {
    final db = _ref.read(databaseProvider);
    final supabase = Supabase.instance.client;
    const storage = FlutterSecureStorage();

    // 1. Get current session to filter by outlet
    final currentEmployee = _ref.read(sessionProvider).value;
    final outletId = currentEmployee?.outletId;

    final lastSyncStr = await storage.read(key: 'last_pull_sync');
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    for (final table in _syncableTables) {
      if (outletId == null && table != 'outlets') {
        debugPrint(
          'SyncService: Skipping $table - No outlet assigned to session',
        );
        continue;
      }

      var query = supabase.from(table).select();

      // Apply Outlet Filter (Efficiency Phase 1)
      // Note: 'outlets' table might be visible across branches for owners,
      // but for now we filter it as well or keep it global if needed.
      if (table != 'outlets' && outletId != null) {
        query = query.eq('outlet_id', outletId);
      }

      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toUtc().toIso8601String());
      }

      final List<dynamic> records = await query;
      if (records.isNotEmpty) {
        debugPrint('SyncService: Pulled ${records.length} rows ← $table');
        await db.importCloudRows(
          table,
          List<Map<String, dynamic>>.from(records),
        );
      }
    }

    await storage.write(
      key: 'last_pull_sync',
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

class SyncStatusNotifier extends Notifier<SyncStatus> {
  @override
  SyncStatus build() => SyncStatus.idle;

  void setStatus(SyncStatus newStatus) {
    state = newStatus;
  }
}

/// Provider for the current Sync Status (for UI)
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(
  SyncStatusNotifier.new,
);
