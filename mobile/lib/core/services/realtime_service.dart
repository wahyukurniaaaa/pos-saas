import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

/// Service to listen for real-time updates from Supabase.
/// This complements SyncService by providing immediate updates when cloud data changes.
class RealtimeService {
  final Ref _ref;
  RealtimeChannel? _channel;

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
    'expenses',
    'purchase_orders',
  ];

  RealtimeService(this._ref);

  /// Starts listening to real-time events.
  void start() {
    final user = _ref.read(authProvider).value;
    if (user == null) {
      debugPrint('RealtimeService: Skipping - User not authenticated');
      return;
    }

    final supabase = Supabase.instance.client;
    
    // 1. Get outlet_id for filtering
    final currentEmployee = _ref.read(sessionProvider).value;
    final outletId = currentEmployee?.outletId;

    if (outletId == null) {
      debugPrint('RealtimeService: No outlet_id in session - listening to everything (not recommended)');
    }

    // Subscribe to all syncable tables
    _channel = supabase.channel('public:posify_sync');

    for (final table in _syncableTables) {
      _channel?.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: table,
        // Apply outlet filter if available (Supabase syntax: column=eq.value)
        filter: (outletId != null && table != 'outlets') 
          ? PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'outlet_id',
              value: outletId,
            ) 
          : null,
        callback: (payload) async {
          debugPrint('RealtimeService: Received ${payload.eventType} Event for $table');
          
          final record = payload.newRecord;
          if (record.isNotEmpty) {
            final db = _ref.read(databaseProvider);
            try {
              // Directly import the changed record into Drift
              await db.importCloudRows(table, [record]);
              debugPrint('RealtimeService: Successfully updated $table from Realtime');
            } catch (e) {
              debugPrint('RealtimeService: Error importing realtime record - $e');
            }
          }
        },
      );
    }

    _channel?.subscribe((status, error) {
      if (status == RealtimeSubscribeStatus.subscribed) {
        debugPrint('RealtimeService: Subscribed to Supabase changes');
      } else if (error != null) {
        debugPrint('RealtimeService: Subscription error - $error');
      }
    });
  }

  /// Stops the realtime listeners.
  void stop() {
    _channel?.unsubscribe();
    _channel = null;
    debugPrint('RealtimeService: Unsubscribed');
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService(ref);
});
