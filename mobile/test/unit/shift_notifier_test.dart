import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';

class MockDatabase extends Mock implements PosifyDatabase {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeShift());
  });

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

  group('ShiftNotifier', () {
    final mockShift = Shift(
      id: 1,
      employeeId: 1,
      startTime: DateTime.now(),
      startingCash: 100000,
      status: 'open',
      expectedEndingCash: 100000,
    );

    final mockTransactions = [
      Transaction(
        id: 1,
        receiptNumber: 'R1',
        shiftId: 1,
        totalAmount: 50000,
        paymentMethod: 'tunai',
        paymentStatus: 'paid',
        subtotal: 50000,
        taxAmount: 0,
        serviceChargeAmount: 0,
        createdAt: DateTime.now(),
      ),
      Transaction(
        id: 2,
        receiptNumber: 'R2',
        shiftId: 1,
        totalAmount: 30000,
        paymentMethod: 'debit', // Should be ignored in cash calculation
        paymentStatus: 'paid',
        subtotal: 30000,
        taxAmount: 0,
        serviceChargeAmount: 0,
        createdAt: DateTime.now(),
      ),
    ];

    test('closeShift should calculate expectedEndingCash correctly (startingCash + totalTunaiSales)', () async {
      when(() => mockDb.getOpenShift()).thenAnswer((_) async => mockShift);
      when(() => mockDb.watchTransactionsByShift(1))
          .thenAnswer((_) => Stream.value(mockTransactions));
      
      when(() => mockDb.updateShift(any())).thenAnswer((_) async => true);

      final notifier = container.read(shiftControllerProvider.notifier);
      final result = await notifier.closeShift(1, 150000);

      expect(result, isTrue);
      
      final verification = verify(() => mockDb.updateShift(captureAny()));
      final capturedShift = verification.captured.first as Shift;
      
      expect(capturedShift.expectedEndingCash, 150000);
      expect(capturedShift.actualEndingCash, 150000);
      expect(capturedShift.status, 'closed');
    });

    test('closeShift should fail if shift is missing or mismatch', () async {
      when(() => mockDb.getOpenShift()).thenAnswer((_) async => null);

      final notifier = container.read(shiftControllerProvider.notifier);
      final result = await notifier.closeShift(99, 100000);

      expect(result, isFalse);
    });
  });
}

class FakeShift extends Fake implements Shift {}
