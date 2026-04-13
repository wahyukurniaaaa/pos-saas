import 'package:flutter_test/flutter_test.dart';
import 'package:posify_app/features/pos/providers/discount_provider.dart';
import 'package:posify_app/core/database/database.dart';

void main() {
  group('Discount Calculation Logic', () {
    test('Percentage discount calculation', () {
      final now = DateTime.now();
      final discount = Discount(
        id: '1',
        name: 'Test 10%',
        scope: 'transaction',
        type: 'percentage',
        value: 10.0,
        minSpend: 50000,
        minQty: 1,
        isAutomatic: false,
        isStackable: true,
        isActive: true,
        startDate: now,
        createdAt: now,
        updatedAt: now,
        isDirty: false,
      );
      
      expect(calculateDiscountAmount(discount, 60000), 6000);
      expect(calculateDiscountAmount(discount, 100000), 10000);
    });

    test('Fixed discount calculation', () {
      final now = DateTime.now();
      final discount = Discount(
        id: '2',
        name: 'Test Rp 5000',
        scope: 'transaction',
        type: 'fixed',
        value: 5000.0,
        minSpend: 20000,
        minQty: 1,
        isAutomatic: false,
        isStackable: true,
        isActive: true,
        startDate: now,
        createdAt: now,
        updatedAt: now,
        isDirty: false,
      );
      
      expect(calculateDiscountAmount(discount, 30000), 5000);
    });
  });
}
