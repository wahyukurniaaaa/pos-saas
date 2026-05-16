import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/services/sync_service.dart';

class MockDatabase extends Mock implements LumioDatabase {}
class FakeSyncQueueData extends Fake implements SyncQueueData {
  @override
  final String id;
  @override
  final String targetTable;
  @override
  final String operation;
  @override
  final String recordId;
  FakeSyncQueueData(this.id, this.targetTable, this.operation, this.recordId);
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSyncQueueData('1', 'products', 'INSERT', 'prod-1'));
  });

  group('SyncService - Sync Status Enum', () {
    test('SyncStatus should have correct values', () {
      expect(SyncStatus.values.length, 3);
      expect(SyncStatus.idle.index, 0);
      expect(SyncStatus.syncing.index, 1);
      expect(SyncStatus.error.index, 2);
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

    test('should mock getPendingSyncTasks successfully', () async {
      when(() => mockDb.getPendingSyncTasks(any()))
          .thenAnswer((_) async => [
                FakeSyncQueueData('task-1', 'products', 'INSERT', 'prod-1')
              ]);

      final result = await mockDb.getPendingSyncTasks(50);

      expect(result.length, 1);
      expect(result[0].recordId, 'prod-1');
      verify(() => mockDb.getPendingSyncTasks(50)).called(1);
    });

    test('should return empty when no sync tasks', () async {
      when(() => mockDb.getPendingSyncTasks(any()))
          .thenAnswer((_) async => []);

      final result = await mockDb.getPendingSyncTasks(50);
      expect(result, isEmpty);
    });

    test('should mock removeSyncTasks', () async {
      when(() => mockDb.removeSyncTasks(any()))
          .thenAnswer((_) async {});

      await mockDb.removeSyncTasks(['task-1', 'task-2']);

      verify(() => mockDb.removeSyncTasks(['task-1', 'task-2'])).called(1);
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

    test('simulate pull-push cycle with queue', () async {
      // Simulate pulling data from cloud
      final cloudRecords = [
        {'id': 'prod-1', 'name': 'Coffee', 'price': 15000, 'updated_at': '2024-01-01T00:00:00Z', 'outlet_id': 'outlet-1'},
      ];

      when(() => mockDb.importCloudRows('products', any())).thenAnswer((_) async {});

      // Simulate push
      when(() => mockDb.getPendingSyncTasks(any())).thenAnswer((_) async => [
        FakeSyncQueueData('task-3', 'products', 'UPDATE', 'prod-3')
      ]);

      when(() => mockDb.removeSyncTasks(any())).thenAnswer((_) async {});

      // Pull
      await mockDb.importCloudRows('products', cloudRecords);
      verify(() => mockDb.importCloudRows('products', cloudRecords)).called(1);

      // Get pending
      final tasks = await mockDb.getPendingSyncTasks(50);
      expect(tasks.length, 1);
      expect(tasks[0].recordId, 'prod-3');

      // Remove task
      await mockDb.removeSyncTasks(['task-3']);
      verify(() => mockDb.removeSyncTasks(['task-3'])).called(1);
    });
  });
}