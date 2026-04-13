import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';

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

    _isSyncing = true;
    _ref.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
    debugPrint('SyncService: Sync started for ${user.email}');

    try {
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
        return cleaned;
      }).toList();

      await supabase.from(table).upsert(payload);

      // Mark as clean after successful push
      final ids = dirtyRows.map((r) => r['id'] as String).toList();
      await db.markAsClean(table, ids);
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
final syncStatusProvider = NotifierProvider<SyncStatusNotifier, SyncStatus>(SyncStatusNotifier.new);
