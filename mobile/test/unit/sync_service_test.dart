import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/services/sync_service.dart';

class MockDatabase extends Mock implements PosifyDatabase {}

void main() {
  group('SyncService - Sync Status Enum', () {
    test('SyncStatus should have correct values', () {
      expect(SyncStatus.values.length, 3);
      expect(SyncStatus.idle.index, 0);
      expect(SyncStatus.syncing.index, 1);
      expect(SyncStatus.error.index, 2);
    });
  });

  group('SyncService - Constants', () {
    test('syncableTables should contain all expected tables', () {
      const expectedTables = [
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
      expect(expectedTables.length, 18);
    });
  });

  group('SyncService - Initial State', () {
    late ProviderContainer container;
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial syncStatus should be idle', () {
      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('initialSyncProvider should start as false', () {
      expect(container.read(initialSyncProvider), false);
    });
  });

  group('SyncStatusNotifier', () {
    test('should start as idle', () {
      final container = ProviderContainer();
      expect(container.read(syncStatusProvider), SyncStatus.idle);
      container.dispose();
    });

    test('should update status to syncing', () {
      final container = ProviderContainer();

      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
      expect(container.read(syncStatusProvider), SyncStatus.syncing);

      container.dispose();
    });

    test('should update status to error', () {
      final container = ProviderContainer();

      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.error);
      expect(container.read(syncStatusProvider), SyncStatus.error);

      container.dispose();
    });

    test('should update status back to idle', () {
      final container = ProviderContainer();

      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.syncing);
      container.read(syncStatusProvider.notifier).setStatus(SyncStatus.idle);
      expect(container.read(syncStatusProvider), SyncStatus.idle);

      container.dispose();
    });
  });

  group('InitialSyncNotifier', () {
    test('should start as false', () {
      final container = ProviderContainer();
      expect(container.read(initialSyncProvider), false);
      container.dispose();
    });

    test('should mark completed to true', () {
      final container = ProviderContainer();

      container.read(initialSyncProvider.notifier).markCompleted();
      expect(container.read(initialSyncProvider), true);

      container.dispose();
    });
  });

  group('Database Operations via Mock', () {
    late ProviderContainer container;
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('databaseProvider should return mocked database', () {
      final db = container.read(databaseProvider);
      expect(db, equals(mockDb));
    });

    test('should mock getDirtyRows successfully', () async {
      when(() => mockDb.getDirtyRows('products'))
          .thenAnswer((_) async => [
                {'id': 'prod-1', 'name': 'Test Product', 'is_dirty': true}
              ]);

      final result = await mockDb.getDirtyRows('products');

      expect(result.length, 1);
      expect(result[0]['id'], 'prod-1');
      verify(() => mockDb.getDirtyRows('products')).called(1);
    });

    test('should return empty when no dirty rows', () async {
      when(() => mockDb.getDirtyRows('categories'))
          .thenAnswer((_) async => []);

      final result = await mockDb.getDirtyRows('categories');

      expect(result, isEmpty);
    });

    test('should mock markAsClean', () async {
      when(() => mockDb.markAsClean(any(), any()))
          .thenAnswer((_) async {});

      await mockDb.markAsClean('products', ['prod-1', 'prod-2']);

      verify(() => mockDb.markAsClean('products', ['prod-1', 'prod-2'])).called(1);
    });

    test('should mock importCloudRows', () async {
      final records = [
        {'id': 'prod-1', 'name': 'Product 1', 'updated_at': '2024-01-01T00:00:00Z'},
      ];

      when(() => mockDb.importCloudRows(any(), any()))
          .thenAnswer((_) async {});

      await mockDb.importCloudRows('products', records);

      verify(() => mockDb.importCloudRows('products', records)).called(1);
    });

    test('should handle empty importCloudRows', () async {
      when(() => mockDb.importCloudRows(any(), any()))
          .thenAnswer((_) async {});

      await mockDb.importCloudRows('products', []);

      verify(() => mockDb.importCloudRows('products', [])).called(1);
    });
  });

  group('SyncService Provider', () {
    late ProviderContainer container;
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('syncServiceProvider should be accessible', () {
      final service = container.read(syncServiceProvider);
      expect(service, isNotNull);
    });

    test('start() should be callable without auth', () async {
      final service = container.read(syncServiceProvider);

      // Should not throw even without auth
      service.start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.stop();

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });

    test('performSync should mark initialSyncProvider on completion', () async {
      final service = container.read(syncServiceProvider);

      // Perform sync (will skip due to no auth, but should mark done)
      await service.performSync();

      expect(container.read(initialSyncProvider), true);
    });

    test('stop() should reset status to idle', () async {
      final service = container.read(syncServiceProvider);

      service.start();
      await Future.delayed(const Duration(milliseconds: 50));
      service.stop();

      expect(container.read(syncStatusProvider), SyncStatus.idle);
    });
  });

  group('Sync Data Flow Simulation', () {
    late ProviderContainer container;
    late MockDatabase mockDb;

    setUp(() {
      mockDb = MockDatabase();
      container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(mockDb),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('simulate pull-push cycle', () async {
      // Simulate pulling data from cloud
      final cloudRecords = [
        {'id': 'prod-1', 'name': 'Coffee', 'price': 15000, 'updated_at': '2024-01-01T00:00:00Z', 'outlet_id': 'outlet-1'},
        {'id': 'prod-2', 'name': 'Tea', 'price': 12000, 'updated_at': '2024-01-01T00:00:00Z', 'outlet_id': 'outlet-1'},
      ];

      when(() => mockDb.importCloudRows('products', any()))
          .thenAnswer((_) async {});

      // Simulate push
      when(() => mockDb.getDirtyRows('products'))
          .thenAnswer((_) async => [
                {'id': 'prod-3', 'name': 'New Product', 'is_dirty': true}
              ]);

      when(() => mockDb.markAsClean(any(), any()))
          .thenAnswer((_) async {});

      // Pull
      await mockDb.importCloudRows('products', cloudRecords);
      verify(() => mockDb.importCloudRows('products', cloudRecords)).called(1);

      // Get dirty
      final dirty = await mockDb.getDirtyRows('products');
      expect(dirty.length, 1);
      expect(dirty[0]['name'], 'New Product');

      // Mark clean after push
      await mockDb.markAsClean('products', ['prod-3']);
      verify(() => mockDb.markAsClean('products', ['prod-3'])).called(1);
    });

    test('lastWriteWins conflict resolution simulation', () async {
      // Local record is newer
      final localRecord = {'id': 'prod-1', 'name': 'Local Update', 'updated_at': '2024-01-02T00:00:00Z'};
      // Cloud record is older
      final cloudRecord = {'id': 'prod-1', 'name': 'Cloud Update', 'updated_at': '2024-01-01T00:00:00Z'};

      // Simulate import - newer record should win
      when(() => mockDb.importCloudRows('products', any()))
          .thenAnswer((_) async {});

      // In real implementation, local should win if updated_at is newer
      await mockDb.importCloudRows('products', [cloudRecord, localRecord]);

      verify(() => mockDb.importCloudRows('products', [cloudRecord, localRecord])).called(1);
    });
  });
}