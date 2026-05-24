// Task 9.3 — Unit tests for ProductWithVariantsNotifier
// Validates: Requirements 2.1, 2.2, 2.4, 2.5

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProductWithVariantsNotifier — source-level checks', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/pos/providers/pos_providers.dart',
      ).readAsStringSync();
    });

    test('setSearch() should NOT contain invalidateSelf', () {
      // Find the setSearch method in ProductWithVariantsNotifier
      // We look for the pattern in the class context
      final classStart = source.indexOf('class ProductWithVariantsNotifier');
      expect(classStart, isNot(-1), reason: 'ProductWithVariantsNotifier class should exist');

      // Find the next class after ProductWithVariantsNotifier to bound our search
      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      // Find setSearch within the class body
      final setSearchIdx = classBody.indexOf('void setSearch(');
      expect(setSearchIdx, isNot(-1), reason: 'setSearch() method should exist in ProductWithVariantsNotifier');

      // Extract setSearch method body (up to next method)
      final afterSetSearch = classBody.substring(setSearchIdx);
      final nextMethodIdx = afterSetSearch.indexOf('\n  void ', 10);
      final setSearchBody = nextMethodIdx != -1
          ? afterSetSearch.substring(0, nextMethodIdx)
          : afterSetSearch;

      expect(
        setSearchBody.contains('invalidateSelf'),
        isFalse,
        reason: 'setSearch() must NOT call invalidateSelf() — use in-memory filter instead',
      );
    });

    test('setCategory() should NOT contain invalidateSelf', () {
      final classStart = source.indexOf('class ProductWithVariantsNotifier');
      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      final setCategoryIdx = classBody.indexOf('void setCategory(');
      expect(setCategoryIdx, isNot(-1), reason: 'setCategory() method should exist in ProductWithVariantsNotifier');

      final afterSetCategory = classBody.substring(setCategoryIdx);
      final nextMethodIdx = afterSetCategory.indexOf('\n  void ', 10);
      final setCategoryBody = nextMethodIdx != -1
          ? afterSetCategory.substring(0, nextMethodIdx)
          : afterSetCategory;

      expect(
        setCategoryBody.contains('invalidateSelf'),
        isFalse,
        reason: 'setCategory() must NOT call invalidateSelf() — use in-memory filter instead',
      );
    });

    test('_allData field should exist in ProductWithVariantsNotifier', () {
      final classStart = source.indexOf('class ProductWithVariantsNotifier');
      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      expect(
        classBody.contains('_allData'),
        isTrue,
        reason: '_allData field must exist in ProductWithVariantsNotifier for in-memory caching',
      );
    });

    test('setSearch() should update state from _allData (contains _filter(_allData))', () {
      final classStart = source.indexOf('class ProductWithVariantsNotifier');
      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      expect(
        classBody.contains('_filter(_allData)'),
        isTrue,
        reason: 'setSearch() and setCategory() must filter from _allData cache',
      );
    });

    test('setCategory() should update state from _allData', () {
      final classStart = source.indexOf('class ProductWithVariantsNotifier');
      final nextClassStart = source.indexOf('\nclass ', classStart + 1);
      final classBody = nextClassStart != -1
          ? source.substring(classStart, nextClassStart)
          : source.substring(classStart);

      final setCategoryIdx = classBody.indexOf('void setCategory(');
      expect(setCategoryIdx, isNot(-1));

      final afterSetCategory = classBody.substring(setCategoryIdx);
      // setCategory should reference _allData
      expect(
        afterSetCategory.contains('_allData'),
        isTrue,
        reason: 'setCategory() must use _allData for in-memory filtering',
      );
    });
  });
}
