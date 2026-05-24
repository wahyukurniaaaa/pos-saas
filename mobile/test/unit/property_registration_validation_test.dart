// Feature: mobile-registration-subscription
// Property-based tests for registration form validation and price formatting.
//
// Pattern: Random with fixed seed (42), 100 iterations per property.
// Mirrors the pattern used in property_filter_test.dart.

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lumio/features/auth/models/subscription_package.dart';

// ─── Standalone validation functions ─────────────────────────────────────────
// These mirror the inline validation logic in _RegistrationScreenState._validateStep1()
// in registration_screen.dart, extracted as pure functions for testability.

/// Validates Nama Toko (store name).
/// Returns null if valid, or an error message string if invalid.
String? validateStoreName(String? value) {
  final storeName = value?.trim() ?? '';
  if (storeName.isEmpty) return 'Nama toko wajib diisi';
  if (storeName.length > 50) return 'Nama toko maksimal 50 karakter';
  return null;
}

/// Validates Nomor WhatsApp.
/// Returns null if valid, or an error message string if invalid.
String? validatePhone(String? value) {
  final phone = value?.trim() ?? '';
  if (phone.isEmpty) return 'Nomor WA wajib diisi';
  if (phone.length < 9 || phone.length > 15) return 'Nomor WA tidak valid';
  return null;
}

/// Validates Email.
/// Returns null if valid, or an error message string if invalid.
String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (email.isEmpty) return 'Email wajib diisi';
  if (!email.contains('@')) return 'Email tidak valid';
  return null;
}

/// Validates Password.
/// Returns null if valid, or an error message string if invalid.
String? validatePassword(String? value) {
  final password = value ?? '';
  if (password.isEmpty) return 'Password wajib diisi';
  if (password.length < 6) return 'Password min. 6 karakter';
  return null;
}

// ─── Random string generators ─────────────────────────────────────────────────

/// Generates a random string of exactly [length] characters using printable ASCII.
String _randomString(Random rng, int length) {
  // Use a safe set of printable characters (no '@' to keep generators neutral)
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  if (length == 0) return '';
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

/// Generates a random string of exactly [length] characters that contains '@'.
String _randomStringWithAt(Random rng, int length) {
  if (length == 0) return '@';
  final base = _randomString(rng, length);
  // Replace a random position with '@'
  final pos = rng.nextInt(base.length);
  return base.substring(0, pos) + '@' + base.substring(pos + 1);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Property 1: Validasi panjang Nama Toko ──────────────────────────────────
  // Feature: mobile-registration-subscription, Property 1: Validasi panjang field menolak input di luar batas
  // Validates: Requirements 1.3
  group('Property 1: Validasi panjang Nama Toko', () {
    test(
      'validateStoreName mengembalikan error yang benar untuk semua panjang 0–100 (100 iterasi)',
      () {
        final rng = Random(42); // fixed seed for reproducibility

        for (int i = 0; i < 100; i++) {
          final length = rng.nextInt(101); // 0–100 inclusive
          final input = _randomString(rng, length);

          final result = validateStoreName(input);

          if (length == 0) {
            expect(
              result,
              equals('Nama toko wajib diisi'),
              reason:
                  'Panjang 0 harus mengembalikan "Nama toko wajib diisi" (iterasi $i)',
            );
          } else if (length > 50) {
            expect(
              result,
              equals('Nama toko maksimal 50 karakter'),
              reason:
                  'Panjang $length (> 50) harus mengembalikan "Nama toko maksimal 50 karakter" (iterasi $i)',
            );
          } else {
            // length 1–50: valid
            expect(
              result,
              isNull,
              reason:
                  'Panjang $length (1–50) harus valid (null) (iterasi $i)',
            );
          }
        }
      },
    );

    test('validateStoreName — boundary: panjang tepat 50 harus valid', () {
      final input = 'a' * 50;
      expect(validateStoreName(input), isNull);
    });

    test('validateStoreName — boundary: panjang tepat 51 harus error', () {
      final input = 'a' * 51;
      expect(validateStoreName(input), equals('Nama toko maksimal 50 karakter'));
    });

    test('validateStoreName — string kosong harus error wajib diisi', () {
      expect(validateStoreName(''), equals('Nama toko wajib diisi'));
      expect(validateStoreName(null), equals('Nama toko wajib diisi'));
    });
  });

  // ── Property 2: Validasi panjang Nomor WhatsApp ─────────────────────────────
  // Feature: mobile-registration-subscription, Property 2: Validasi panjang Nomor WhatsApp
  // Validates: Requirements 1.5, 1.6
  group('Property 2: Validasi panjang Nomor WhatsApp', () {
    test(
      'validatePhone mengembalikan error yang benar untuk semua panjang 0–20 (100 iterasi)',
      () {
        final rng = Random(42); // fixed seed

        for (int i = 0; i < 100; i++) {
          final length = rng.nextInt(21); // 0–20 inclusive
          final input = _randomString(rng, length);

          final result = validatePhone(input);

          if (length == 0) {
            expect(
              result,
              equals('Nomor WA wajib diisi'),
              reason:
                  'Panjang 0 harus mengembalikan "Nomor WA wajib diisi" (iterasi $i)',
            );
          } else if (length < 9 || length > 15) {
            expect(
              result,
              equals('Nomor WA tidak valid'),
              reason:
                  'Panjang $length (< 9 atau > 15) harus mengembalikan "Nomor WA tidak valid" (iterasi $i)',
            );
          } else {
            // length 9–15: valid
            expect(
              result,
              isNull,
              reason:
                  'Panjang $length (9–15) harus valid (null) (iterasi $i)',
            );
          }
        }
      },
    );

    test('validatePhone — boundary: panjang 9 harus valid', () {
      expect(validatePhone('0' * 9), isNull);
    });

    test('validatePhone — boundary: panjang 15 harus valid', () {
      expect(validatePhone('0' * 15), isNull);
    });

    test('validatePhone — boundary: panjang 8 harus error tidak valid', () {
      expect(validatePhone('0' * 8), equals('Nomor WA tidak valid'));
    });

    test('validatePhone — boundary: panjang 16 harus error tidak valid', () {
      expect(validatePhone('0' * 16), equals('Nomor WA tidak valid'));
    });

    test('validatePhone — string kosong harus error wajib diisi', () {
      expect(validatePhone(''), equals('Nomor WA wajib diisi'));
      expect(validatePhone(null), equals('Nomor WA wajib diisi'));
    });
  });

  // ── Property 3: Validasi format email ──────────────────────────────────────
  // Feature: mobile-registration-subscription, Property 3: Validasi format email
  // Validates: Requirements 1.7, 1.8
  group('Property 3: Validasi format email', () {
    test(
      'validateEmail mengembalikan error yang benar berdasarkan ada/tidaknya "@" (100 iterasi)',
      () {
        final rng = Random(42); // fixed seed

        for (int i = 0; i < 100; i++) {
          final hasAt = rng.nextBool();
          final length = rng.nextInt(20) + 1; // 1–20 chars (non-empty)

          final input = hasAt
              ? _randomStringWithAt(rng, length)
              : _randomString(rng, length);

          final result = validateEmail(input);

          if (hasAt) {
            expect(
              result,
              isNull,
              reason:
                  'String dengan "@" ("$input") harus valid (null) (iterasi $i)',
            );
          } else {
            expect(
              result,
              equals('Email tidak valid'),
              reason:
                  'String tanpa "@" ("$input") harus mengembalikan "Email tidak valid" (iterasi $i)',
            );
          }
        }
      },
    );

    test('validateEmail — string kosong harus error wajib diisi', () {
      expect(validateEmail(''), equals('Email wajib diisi'));
      expect(validateEmail(null), equals('Email wajib diisi'));
    });

    test('validateEmail — string tanpa "@" harus error tidak valid', () {
      expect(validateEmail('emailtanpaat'), equals('Email tidak valid'));
      expect(validateEmail('user.domain.com'), equals('Email tidak valid'));
    });

    test('validateEmail — string dengan "@" harus valid', () {
      expect(validateEmail('user@domain.com'), isNull);
      expect(validateEmail('@'), isNull); // minimal: just '@'
      expect(validateEmail('a@b'), isNull);
    });
  });

  // ── Property 4: Validasi panjang password ──────────────────────────────────
  // Feature: mobile-registration-subscription, Property 4: Validasi panjang password
  // Validates: Requirements 1.9
  group('Property 4: Validasi panjang password', () {
    test(
      'validatePassword mengembalikan error yang benar untuk semua panjang 0–10 (100 iterasi)',
      () {
        final rng = Random(42); // fixed seed

        for (int i = 0; i < 100; i++) {
          final length = rng.nextInt(11); // 0–10 inclusive
          final input = _randomString(rng, length);

          final result = validatePassword(input);

          if (length == 0) {
            expect(
              result,
              equals('Password wajib diisi'),
              reason:
                  'Panjang 0 harus mengembalikan "Password wajib diisi" (iterasi $i)',
            );
          } else if (length < 6) {
            // length 1–5
            expect(
              result,
              equals('Password min. 6 karakter'),
              reason:
                  'Panjang $length (1–5) harus mengembalikan "Password min. 6 karakter" (iterasi $i)',
            );
          } else {
            // length 6–10: valid
            expect(
              result,
              isNull,
              reason:
                  'Panjang $length (≥ 6) harus valid (null) (iterasi $i)',
            );
          }
        }
      },
    );

    test('validatePassword — boundary: panjang 6 harus valid', () {
      expect(validatePassword('abcdef'), isNull);
    });

    test('validatePassword — boundary: panjang 5 harus error', () {
      expect(validatePassword('abcde'), equals('Password min. 6 karakter'));
    });

    test('validatePassword — string kosong harus error wajib diisi', () {
      expect(validatePassword(''), equals('Password wajib diisi'));
      expect(validatePassword(null), equals('Password wajib diisi'));
    });
  });

  // ── Property 6: Format harga paket locale id_ID ─────────────────────────────
  // Feature: mobile-registration-subscription, Property 6: Format harga paket selalu menggunakan locale id_ID
  // Validates: Requirements 2.2
  group('Property 6: Format harga paket locale id_ID', () {
    test(
      'formattedPrice mengandung pemisah ribuan titik untuk harga 1.000–10.000.000 (100 iterasi)',
      () {
        final rng = Random(42); // fixed seed

        for (int i = 0; i < 100; i++) {
          // Generate random price between 1.000 and 10.000.000
          final price = 1000 + rng.nextInt(9999001); // 1000–10000000

          final pkg = SubscriptionPackage(
            name: 'Test',
            slug: 'test',
            price: price,
            durationMonths: 1,
            features: [],
          );

          final formatted = pkg.formattedPrice;

          // All prices >= 1000 must contain at least one thousands separator (dot)
          expect(
            formatted.contains('.'),
            isTrue,
            reason:
                'formattedPrice untuk harga $price harus mengandung titik sebagai pemisah ribuan, '
                'tapi mendapat: "$formatted" (iterasi $i)',
          );

          // Must start with "Rp " prefix
          expect(
            formatted.startsWith('Rp '),
            isTrue,
            reason:
                'formattedPrice harus diawali "Rp " (iterasi $i), mendapat: "$formatted"',
          );
        }
      },
    );

    test('formattedPrice — contoh konkret: 249000 → mengandung "249.000"', () {
      final pkg = SubscriptionPackage(
        name: 'Pro',
        slug: 'pro',
        price: 249000,
        durationMonths: 1,
        features: [],
      );
      expect(pkg.formattedPrice, contains('249.000'));
    });

    test('formattedPrice — contoh konkret: 99000 → mengandung "99.000"', () {
      final pkg = SubscriptionPackage(
        name: 'Lite',
        slug: 'lite',
        price: 99000,
        durationMonths: 0,
        features: [],
      );
      expect(pkg.formattedPrice, contains('99.000'));
    });

    test('formattedPrice — contoh konkret: 1000000 → mengandung "1.000.000"', () {
      final pkg = SubscriptionPackage(
        name: 'Premium',
        slug: 'premium',
        price: 1000000,
        durationMonths: 12,
        features: [],
      );
      expect(pkg.formattedPrice, contains('1.000.000'));
    });

    test('formattedPrice — fallbackPackages menggunakan locale id_ID', () {
      for (final pkg in SubscriptionPackage.fallbackPackages) {
        final formatted = pkg.formattedPrice;
        expect(
          formatted.contains('.'),
          isTrue,
          reason:
              'fallbackPackage "${pkg.name}" (price: ${pkg.price}) harus mengandung titik, '
              'mendapat: "$formatted"',
        );
        expect(
          formatted.startsWith('Rp '),
          isTrue,
          reason: 'fallbackPackage "${pkg.name}" harus diawali "Rp "',
        );
      }
    });

    test('formattedPrice — konsisten dengan NumberFormat.currency locale id_ID', () {
      final rng = Random(42);
      for (int i = 0; i < 20; i++) {
        final price = 1000 + rng.nextInt(9999001);
        final pkg = SubscriptionPackage(
          name: 'Test',
          slug: 'test',
          price: price,
          durationMonths: 1,
          features: [],
        );
        final expected = NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(price);
        expect(
          pkg.formattedPrice,
          equals(expected),
          reason:
              'formattedPrice($price) harus sama dengan NumberFormat.currency(locale: id_ID) (iterasi $i)',
        );
      }
    });
  });
}
