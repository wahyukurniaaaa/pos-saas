import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';
import 'package:lumio/features/auth/providers/owner_provider.dart';

/// Enumeration of possible sync states for the UI indicator.
enum SyncStatus { idle, syncing, error }

/// Manages background synchronization of local Drift data to Supabase Cloud.
///
/// RESTRICTED TO PRO USERS ONLY:
/// Users authenticated via Supabase (email/Google) are considered 'Pro'.
/// Activation Key-only users will not receive cloud sync.
class SyncService {
  final Ref _ref;

  SyncService(this._ref);

  StreamSubscription<void>? _syncQueueSub;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Timer? _syncDebounceTimer;
  bool _isSyncing = false;

  static const _liteAuthTables = [
    'outlets',
    'store_profile',
    'employees',
  ];

  /// Starts the event-driven background sync.
  void start() {
    _syncQueueSub?.cancel();
    _connectivitySub?.cancel();

    final db = _ref.read(databaseProvider);

    // Listen for local changes (debounced 500ms to coalesce rapid events, e.g. during checkout)
    _syncQueueSub = db.syncQueueNotifier.stream.listen((_) {
      _syncDebounceTimer?.cancel();
      _syncDebounceTimer = Timer(const Duration(milliseconds: 500), () {
        _processSyncQueue();
      });
    });

    // Listen for network recovery
    _connectivitySub = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      if (!results.contains(ConnectivityResult.none)) {
        performSync();
      }
    });

    // Perform an immediate sync on start
    performSync();
    debugPrint('SyncService: Started (Event-Driven)');
  }

  /// Stops the background sync and listeners.
  void stop() {
    _syncDebounceTimer?.cancel();
    _syncDebounceTimer = null;

    _syncQueueSub?.cancel();
    _syncQueueSub = null;

    _connectivitySub?.cancel();
    _connectivitySub = null;

    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.idle);
    debugPrint('SyncService: Stopped');
  }

  /// Push all dirty local records to Supabase.
  /// Guard: Runs if the user is authenticated and tier is Pro or Lite.
  Future<void> performSync() async {
    if (_isSyncing) return;

    // Auth Guard: Pro/Lite users only
    final user = _ref.read(authProvider).value;
    if (user == null) {
      debugPrint('SyncService: Skipping — user not authenticated');
      if (!_ref.read(initialSyncProvider)) {
        _ref.read(initialSyncProvider.notifier).markCompleted();
      }
      return;
    }

    // Tier Guard: Pro or Lite users only
    final license = _ref.read(licenseProvider).value;
    final tier = license?.tierLevel?.toLowerCase();
    final isPro = tier == 'pro';
    final isLite = tier == 'lite';

    if (!isPro && !isLite) {
      debugPrint('SyncService: Skipping — tier is not Pro or Lite (tier: $tier)');
      if (!_ref.read(initialSyncProvider)) {
        _ref.read(initialSyncProvider.notifier).markCompleted();
      }
      return;
    }

    _isSyncing = true;
    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
    debugPrint('SyncService: Sync started for ${user.email} (tier: $tier)');

    try {
      if (isPro) {
        await _pullChanges();
        await _processSyncQueue();
      } else if (isLite) {
        await _performLiteSync();
      }
      if (!_ref.read(initialSyncProvider)) {
        _ref.invalidate(ownerProvider);
        _ref.read(initialSyncProvider.notifier).markCompleted();
      }
      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.idle);
      debugPrint('SyncService: Sync completed');
    } catch (e) {
      if (!_ref.read(initialSyncProvider)) {
        _ref.read(initialSyncProvider.notifier).markCompleted();
      }
      _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.error);
      debugPrint('SyncService: Sync failed — $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _performLiteSync() async {
    final db = _ref.read(databaseProvider);
    final supabase = Supabase.instance.client;
    const storage = FlutterSecureStorage();

    final lastSyncStr = await storage.read(key: 'last_pull_sync_lite');
    final lastSync = lastSyncStr != null ? DateTime.parse(lastSyncStr) : null;

    debugPrint('SyncService: Lite Auth-Only Sync started');

    // Pull sequentially to respect foreign key constraints
    for (final table in _liteAuthTables) {
      await _pullTableWithPagination(
        table,
        null, // Pull globally for employee pin screens & multi-outlet selector
        lastSync,
        db,
        supabase,
      );
    }

    await storage.write(
      key: 'last_pull_sync_lite',
      value: DateTime.now().toUtc().toIso8601String(),
    );
    debugPrint('SyncService: Lite Auth-Only Sync completed');
  }

  Future<void> _processSyncQueue() async {
    final db = _ref.read(databaseProvider);
    final supabase = Supabase.instance.client;

    debugPrint('SyncService: Processing Sync Queue...');

    while (true) {
      final tasks = await db.getPendingSyncTasks(50);
      if (tasks.isEmpty) break;

      final processedIds = <String>[];

      for (final task in tasks) {
        try {
          if (task.operation == 'DELETE') {
            await supabase
                .from(task.targetTable)
                .delete()
                .eq('id', task.recordId);
            processedIds.add(task.id);
            debugPrint(
              'SyncService: Deleted \${task.recordId} from \${task.targetTable}',
            );
          } else {
            final record = await db.getRecordAsMap(
              task.targetTable,
              task.recordId,
            );
            if (record != null) {
              // Strip unnecessary columns
              record.remove('is_dirty');
              if (task.targetTable == 'products' ||
                  task.targetTable == 'product_variants') {
                record.remove('stock');
              }
              if (task.targetTable == 'employees') {
                record.remove('failed_login_attempts');
                record.remove('locked_until');
                record.remove('photo_uri');
              }
              await supabase.from(task.targetTable).upsert(record);
              debugPrint(
                'SyncService: Upserted \${task.recordId} to \${task.targetTable}',
              );
            } else {
              debugPrint(
                'SyncService: Record \${task.recordId} not found locally for \${task.targetTable}. Skipping.',
              );
            }
            processedIds.add(task.id);
          }
        } catch (e) {
          debugPrint(
            'SyncService: Error processing queue task \${task.id} (\${task.targetTable}): $e',
          );
          // Stop processing this batch on first error to maintain sequential order.
          break;
        }
      }

      if (processedIds.isNotEmpty) {
        await db.removeSyncTasks(processedIds);
      }

      // If we didn't process all tasks in this batch, an error occurred.
      // Break the loop to retry later.
      if (processedIds.length < tasks.length) {
        break;
      }
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

    // Group tables to parallelize pulling without breaking foreign key constraints
    final groups = [
      ['outlets', 'categories', 'suppliers', 'customers', 'employees', 'store_profile', 'unit_conversions', 'printer_settings'],
      ['products', 'ingredients'],
      ['product_variants', 'discounts', 'product_recipes'],
      ['shifts', 'transactions', 'expenses', 'purchase_orders', 'stock_opname'],
      ['transaction_items', 'transaction_payments', 'stock_opname_items', 'stock_transactions', 'ingredient_stock_history'],
    ];

    for (final group in groups) {
      await Future.wait(
        group.map(
          (table) => _pullTableWithPagination(
            table,
            outletId,
            lastSync,
            db,
            supabase,
          ),
        ),
      );
    }

    await storage.write(
      key: 'last_pull_sync',
      value: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<void> _pullTableWithPagination(
    String table,
    String? outletId,
    DateTime? lastSync,
    LumioDatabase db,
    SupabaseClient supabase,
  ) async {
    // Removed: Do not skip tables if outletId is null.
    // On fresh install, we MUST pull employees and store_profile even before
    // an outlet is selected so the user can actually log in.
    if (outletId == null) {
      debugPrint('SyncService: Pulling $table globally (no outlet filter)');
    }

    bool hasMore = true;
    int from = 0;
    const pageSize = 500;

    while (hasMore) {
      var query = supabase.from(table).select();

      // Tables that do not have an outlet_id column (Owner-level or global)
      const globalTables = {
        'outlets',
        'store_profile',
        'product_recipes',
        'unit_conversions',
      };

      // Apply Outlet Filter (Efficiency Phase 1)
      if (!globalTables.contains(table) && outletId != null) {
        query = query.eq('outlet_id', outletId);
      }

      if (lastSync != null) {
        query = query.gt('updated_at', lastSync.toUtc().toIso8601String());
      }

      final queryBuilder = query.order('updated_at', ascending: true).range(from, from + pageSize - 1);

      try {
        final List<dynamic> records = await queryBuilder;
        if (records.isNotEmpty) {
          debugPrint(
            'SyncService: Pulled ${records.length} rows ← $table (offset: $from)',
          );
          await db.importCloudRows(
            table,
            List<Map<String, dynamic>>.from(records),
          );

          if (records.length < pageSize) {
            hasMore = false;
          } else {
            from += pageSize;
          }
        } else {
          hasMore = false;
        }
      } catch (e) {
        debugPrint('SyncService: Error pulling $table at offset $from: $e');
        // Stop pulling this table on error to prevent infinite loop or incomplete data issues
        hasMore = false;
      }
    }
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

class InitialSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void markCompleted() {
    state = true;
  }
}

/// Provider to track if the initial sync has completed on boot.
final initialSyncProvider = NotifierProvider.autoDispose<InitialSyncNotifier, bool>(
  InitialSyncNotifier.new,
);
