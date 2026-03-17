import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:posify_app/core/database/database.dart' hide isNull, isNotNull;
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:flutter/services.dart';

class MockDatabase extends Mock implements PosifyDatabase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late ProviderContainer container;
  late MockDatabase mockDb;
  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');

  setUpAll(() {
    registerFallbackValue(FakeEmployee());
    
    // Mock FlutterSecureStorage method channel
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'read') {
        return null; // Simulate no lockout/fail count
      }
      if (methodCall.method == 'write') {
        return null;
      }
      if (methodCall.method == 'delete') {
        return null;
      }
      return null;
    });
  });

  setUp(() {
    mockDb = MockDatabase();
    container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(mockDb),
      ],
    );
  });

  final mockEmployee = Employee(
    id: 1,
    name: 'Owner',
    pin: '123456',
    role: 'owner',
    status: 'active',
    failedLoginAttempts: 0,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  group('SessionNotifier', () {
    test('initial state should be null', () {
      expect(container.read(sessionProvider).value, isNull);
    });

    test('loginWithPin should succeed with correct PIN', () async {
      when(() => mockDb.getEmployeeByPin('123456')).thenAnswer((_) async => mockEmployee);
      when(() => mockDb.updateEmployee(any())).thenAnswer((_) async => true);

      final notifier = container.read(sessionProvider.notifier);
      final result = await notifier.loginWithPin('123456');

      expect(result, isNotNull);
      expect(result?.id, 1);
      expect(container.read(sessionProvider).value, mockEmployee);
    });

    test('loginWithPin should fail with incorrect PIN', () async {
      when(() => mockDb.getEmployeeByPin('wrong')).thenAnswer((_) async => null);

      final notifier = container.read(sessionProvider.notifier);
      final result = await notifier.loginWithPin('wrong');

      expect(result, isNull);
      expect(container.read(sessionProvider).hasError, isTrue);
    });

    test('logout should clear session', () async {
      when(() => mockDb.getEmployeeByPin('123456')).thenAnswer((_) async => mockEmployee);
      when(() => mockDb.updateEmployee(any())).thenAnswer((_) async => true);
      
      final notifier = container.read(sessionProvider.notifier);
      await notifier.loginWithPin('123456');
      expect(container.read(sessionProvider).value, isNotNull);

      notifier.logout();
      expect(container.read(sessionProvider).value, isNull);
    });
  });
}

class FakeEmployee extends Fake implements Employee {}
