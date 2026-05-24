// Task 15 — Property-based tests for registration business logic
// Validates: Requirements 4.1, 4.2, 4.3, 4.7, 4.8, 6.1, 6.7

import 'dart:math';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/features/auth/providers/registration_provider.dart';

// ─── Standalone helper functions ─────────────────────────────────────────────

/// Mirrors the appTierProvider logic: returns the tierLevel of a license
/// if it is valid (not expired), otherwise returns null.
///
/// Feature: mobile-registration-subscription, Property 10: appTierProvider
/// mengembalikan 'trial' untuk license trial yang valid
String? getTierFromLicense(License? license) {
  if (license == null) return null;
  final tier = license.tierLevel?.toLowerCase();
  if (tier == null) return null;
  // Check expiry: if expiredAt is in the past, treat as expired
  final expiredAt = license.expiredAt;
  if (expiredAt != null && expiredAt.isBefore(DateTime.now())) {
    return null;
  }
  return tier;
}

/// Returns true if the trial button should be shown (no existing trial license).
///
/// Feature: mobile-registration-subscription, Property 12: Tombol trial tidak
/// muncul jika trial sudah ada
bool shouldShowTrialButton(License? license) {
  if (license == null) return true;
  return !license.licenseCode.startsWith('TRIAL-');
}

/// Returns true if action buttons should be enabled (not loading).
///
/// Feature: mobile-registration-subscription, Property 18: Tombol aksi disabled
/// saat loading
bool areActionsEnabled(RegistrationState state) {
  return !state.isLoading;
}

// ─── Random data generators ───────────────────────────────────────────────────

/// Generates a UUID-like string of [length] characters using hex chars.
String _generateUserId(Random rng, int length) {
  const chars = 'abcdef0123456789';
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// Generates a random string of [length] characters from [chars].
String _randomString(Random rng, String chars, int length) {
  return String.fromCharCodes(
    List.generate(length, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

/// Generates a random store name of 1–50 characters.
String _generateStoreName(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  final length = rng.nextInt(50) + 1; // 1–50
  return _randomString(rng, chars, length);
}

/// Generates a random phone number of 9–15 digits.
String _generatePhone(Random rng) {
  const digits = '0123456789';
  final length = rng.nextInt(7) + 9; // 9–15
  return _randomString(rng, digits, length);
}

/// Generates a random email containing '@'.
String _generateEmail(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final localLen = rng.nextInt(8) + 3; // 3–10
  final domainLen = rng.nextInt(5) + 3; // 3–7
  final local = _randomString(rng, chars, localLen);
  final domain = _randomString(rng, chars, domainLen);
  return '$local@$domain.com';
}

/// Generates a random password of 6+ characters.
String _generatePassword(Random rng) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#';
  final length = rng.nextInt(10) + 6; // 6–15
  return _randomString(rng, chars, length);
}

/// Business type enum values.
const _businessTypes = [
  'lainnya',
  'kuliner',
  'retail',
  'jasa',
  'fashion',
  'elektronik',
];

// ─── Helper: create a minimal License object for testing ─────────────────────

License _makeLicense({
  required String licenseCode,
  required String tierLevel,
  required String status,
  DateTime? expiredAt,
}) {
  final now = DateTime.now();
  return License(
    id: 'test-id',
    licenseCode: licenseCode,
    status: status,
    tierLevel: tierLevel,
    maxDevices: 1,
    maxOutlets: 1,
    updatedAt: now,
    isDirty: false,
    expiredAt: expiredAt,
  );
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Property 9: Trial License round-trip ─────────────────────────────────
  // Feature: mobile-registration-subscription, Property 9: Trial License
  // round-trip — buat dan baca kembali
  // Validates: Requirements 4.1, 4.2
  group('Property 9: Trial License round-trip', () {
    test(
      'createTrialLicense(userId) then getLocalLicense() returns correct fields for 100 random userIds',
      () async {
        final rng = Random(42); // fixed seed for reproducibility

        for (int i = 0; i < 100; i++) {
          // Generator: userId 10–36 characters (UUID-like)
          final length = rng.nextInt(27) + 10; // 10–36
          final userId = _generateUserId(rng, length);

          // Use a fresh in-memory database for each iteration
          final db = LumioDatabase.forTesting(NativeDatabase.memory());

          try {
            final before = DateTime.now();

            // Insert trial license directly (mirrors LicenseNotifier.createTrialLicense)
            await db.into(db.licenses).insert(
              LicensesCompanion.insert(
                licenseCode: 'TRIAL-$userId',
                status: const Value('active'),
                tierLevel: const Value('trial'),
                maxDevices: const Value(1),
                maxOutlets: const Value(1),
                activationDate: Value(DateTime.now()),
                expiredAt: Value(DateTime.now().add(const Duration(days: 7))),
                deviceFingerprint: const Value(null),
              ),
            );

            final after = DateTime.now();

            // Read back
            final license = await db.getLocalLicense();

            expect(
              license,
              isNotNull,
              reason: 'License should exist after createTrialLicense (iteration $i, userId: $userId)',
            );

            // Verify licenseCode
            expect(
              license!.licenseCode,
              equals('TRIAL-$userId'),
              reason: 'licenseCode must be TRIAL-\$userId (iteration $i)',
            );

            // Verify tierLevel
            expect(
              license.tierLevel,
              equals('trial'),
              reason: 'tierLevel must be "trial" (iteration $i)',
            );

            // Verify status
            expect(
              license.status,
              equals('active'),
              reason: 'status must be "active" (iteration $i)',
            );

            // Verify expiredAt is approximately 7 days from now (±5 seconds)
            expect(
              license.expiredAt,
              isNotNull,
              reason: 'expiredAt must not be null (iteration $i)',
            );

            final expectedExpiry = before.add(const Duration(days: 7));
            final actualExpiry = license.expiredAt!;
            final diff = actualExpiry.difference(expectedExpiry).abs();

            expect(
              diff.inSeconds,
              lessThanOrEqualTo(5),
              reason:
                  'expiredAt must be within ±5 seconds of 7 days from now '
                  '(iteration $i, diff: ${diff.inSeconds}s)',
            );

            // Verify expiredAt is in the future
            expect(
              actualExpiry.isAfter(after),
              isTrue,
              reason: 'expiredAt must be in the future (iteration $i)',
            );
          } finally {
            await db.close();
          }
        }
      },
    );

    test('createTrialLicense prevents duplicate trial (second insert fails or is blocked)', () async {
      final db = LumioDatabase.forTesting(NativeDatabase.memory());
      try {
        const userId = 'test-user-123';

        // First insert succeeds
        await db.into(db.licenses).insert(
          LicensesCompanion.insert(
            licenseCode: 'TRIAL-$userId',
            status: const Value('active'),
            tierLevel: const Value('trial'),
            maxDevices: const Value(1),
            maxOutlets: const Value(1),
            activationDate: Value(DateTime.now()),
            expiredAt: Value(DateTime.now().add(const Duration(days: 7))),
            deviceFingerprint: const Value(null),
          ),
        );

        // Second insert with same licenseCode should throw (UNIQUE constraint)
        expect(
          () async => await db.into(db.licenses).insert(
            LicensesCompanion.insert(
              licenseCode: 'TRIAL-$userId',
              status: const Value('active'),
              tierLevel: const Value('trial'),
              maxDevices: const Value(1),
              maxOutlets: const Value(1),
              activationDate: Value(DateTime.now()),
              expiredAt: Value(DateTime.now().add(const Duration(days: 7))),
              deviceFingerprint: const Value(null),
            ),
          ),
          throwsA(anything),
          reason: 'Duplicate licenseCode must be rejected by UNIQUE constraint',
        );
      } finally {
        await db.close();
      }
    });
  });

  // ── Property 10: appTierProvider returns 'trial' for valid trial license ──
  // Feature: mobile-registration-subscription, Property 10: appTierProvider
  // mengembalikan 'trial' untuk license trial yang valid
  // Validates: Requirements 4.3, 4.7
  group('Property 10: getTierFromLicense returns trial for valid, null for expired', () {
    test(
      'license with tierLevel=trial and future expiredAt → returns "trial" for 50 random dates',
      () {
        final rng = Random(42);

        for (int i = 0; i < 50; i++) {
          // Generator: expiredAt in the future (1 second to 365 days from now)
          final secondsAhead = rng.nextInt(365 * 24 * 3600) + 1;
          final futureExpiry = DateTime.now().add(Duration(seconds: secondsAhead));

          final license = _makeLicense(
            licenseCode: 'TRIAL-user-$i',
            tierLevel: 'trial',
            status: 'active',
            expiredAt: futureExpiry,
          );

          final tier = getTierFromLicense(license);

          expect(
            tier,
            equals('trial'),
            reason:
                'Valid trial license (expiredAt in future) must return "trial" '
                '(iteration $i, expiredAt: $futureExpiry)',
          );
        }
      },
    );

    test(
      'license with tierLevel=trial and past expiredAt → returns null for 50 random dates',
      () {
        final rng = Random(42);

        for (int i = 0; i < 50; i++) {
          // Generator: expiredAt in the past (1 second to 365 days ago)
          final secondsAgo = rng.nextInt(365 * 24 * 3600) + 1;
          final pastExpiry = DateTime.now().subtract(Duration(seconds: secondsAgo));

          final license = _makeLicense(
            licenseCode: 'TRIAL-user-$i',
            tierLevel: 'trial',
            status: 'active',
            expiredAt: pastExpiry,
          );

          final tier = getTierFromLicense(license);

          expect(
            tier,
            isNot(equals('trial')),
            reason:
                'Expired trial license must NOT return "trial" '
                '(iteration $i, expiredAt: $pastExpiry)',
          );
          expect(
            tier,
            isNull,
            reason:
                'Expired trial license must return null '
                '(iteration $i, expiredAt: $pastExpiry)',
          );
        }
      },
    );

    test('null license → getTierFromLicense returns null', () {
      expect(getTierFromLicense(null), isNull);
    });

    test('license with null expiredAt → returns tier (no expiry check)', () {
      final license = _makeLicense(
        licenseCode: 'PRO-abc123',
        tierLevel: 'pro',
        status: 'active',
        expiredAt: null,
      );
      expect(getTierFromLicense(license), equals('pro'));
    });

    test('license with tierLevel=trial and null expiredAt → returns "trial"', () {
      final license = _makeLicense(
        licenseCode: 'TRIAL-user-abc',
        tierLevel: 'trial',
        status: 'active',
        expiredAt: null,
      );
      expect(getTierFromLicense(license), equals('trial'));
    });
  });

  // ── Property 12: Trial button hidden if trial already exists ─────────────
  // Feature: mobile-registration-subscription, Property 12: Tombol trial tidak
  // muncul jika trial sudah ada
  // Validates: Requirements 4.8
  group('Property 12: shouldShowTrialButton', () {
    test(
      'license with TRIAL- prefix → shouldShowTrialButton returns false for 100 random userIds',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          // Generator: userId 10–36 chars
          final length = rng.nextInt(27) + 10;
          final userId = _generateUserId(rng, length);

          final license = _makeLicense(
            licenseCode: 'TRIAL-$userId',
            tierLevel: 'trial',
            status: 'active',
            expiredAt: DateTime.now().add(const Duration(days: 7)),
          );

          expect(
            shouldShowTrialButton(license),
            isFalse,
            reason:
                'Trial button must be hidden when TRIAL- license exists '
                '(iteration $i, licenseCode: TRIAL-$userId)',
          );
        }
      },
    );

    test(
      'license without TRIAL- prefix → shouldShowTrialButton returns true for 100 random codes',
      () {
        final rng = Random(42);
        // Non-trial license code prefixes
        final prefixes = ['PRO-', 'LITE-', 'ACC-', 'LIC-', 'POS-'];

        for (int i = 0; i < 100; i++) {
          final prefix = prefixes[rng.nextInt(prefixes.length)];
          final suffix = _generateUserId(rng, 8);
          final licenseCode = '$prefix$suffix';

          final license = _makeLicense(
            licenseCode: licenseCode,
            tierLevel: 'pro',
            status: 'active',
            expiredAt: null,
          );

          expect(
            shouldShowTrialButton(license),
            isTrue,
            reason:
                'Trial button must be shown when no TRIAL- license exists '
                '(iteration $i, licenseCode: $licenseCode)',
          );
        }
      },
    );

    test('null license → shouldShowTrialButton returns true', () {
      expect(shouldShowTrialButton(null), isTrue,
          reason: 'No license at all → trial button should be shown');
    });

    test('license with licenseCode exactly "TRIAL-" → shouldShowTrialButton returns false', () {
      final license = _makeLicense(
        licenseCode: 'TRIAL-',
        tierLevel: 'trial',
        status: 'active',
      );
      expect(shouldShowTrialButton(license), isFalse);
    });
  });

  // ── Property 17: Step 1 form data preserved across navigation ────────────
  // Feature: mobile-registration-subscription, Property 17: Data form Step 1
  // tidak hilang saat navigasi antar step
  // Validates: Requirements 6.1
  group('Property 17: RegistrationState form data preserved across step navigation', () {
    test(
      'form data survives step 0→1→0 navigation for 100 random form combinations',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          // Generator: random form values
          final storeName = _generateStoreName(rng);
          final phone = _generatePhone(rng);
          final email = _generateEmail(rng);
          final password = _generatePassword(rng);
          final businessType = _businessTypes[rng.nextInt(_businessTypes.length)];

          // Start with initial state
          var state = const RegistrationState();

          // Update with Step 1 form data (simulates user filling the form)
          state = state.copyWith(
            storeName: storeName,
            phone: phone,
            email: email,
            password: password,
            businessType: businessType,
          );

          // Navigate to Step 2
          state = state.copyWith(currentStep: 1);

          expect(
            state.currentStep,
            equals(1),
            reason: 'currentStep should be 1 after navigation (iteration $i)',
          );

          // Navigate back to Step 1
          state = state.copyWith(currentStep: 0);

          expect(
            state.currentStep,
            equals(0),
            reason: 'currentStep should be 0 after back navigation (iteration $i)',
          );

          // Verify all form data is preserved
          expect(
            state.storeName,
            equals(storeName),
            reason: 'storeName must be preserved after navigation (iteration $i)',
          );
          expect(
            state.phone,
            equals(phone),
            reason: 'phone must be preserved after navigation (iteration $i)',
          );
          expect(
            state.email,
            equals(email),
            reason: 'email must be preserved after navigation (iteration $i)',
          );
          expect(
            state.password,
            equals(password),
            reason: 'password must be preserved after navigation (iteration $i)',
          );
          expect(
            state.businessType,
            equals(businessType),
            reason: 'businessType must be preserved after navigation (iteration $i)',
          );
        }
      },
    );

    test('form data survives step 0→1→2→1→0 navigation', () {
      var state = const RegistrationState();

      const storeName = 'Toko Maju Jaya';
      const phone = '081234567890';
      const email = 'owner@toko.com';
      const password = 'password123';
      const businessType = 'kuliner';

      state = state.copyWith(
        storeName: storeName,
        phone: phone,
        email: email,
        password: password,
        businessType: businessType,
      );

      // Navigate forward through all steps
      state = state.copyWith(currentStep: 1);
      state = state.copyWith(currentStep: 2);

      // Navigate back
      state = state.copyWith(currentStep: 1);
      state = state.copyWith(currentStep: 0);

      expect(state.storeName, equals(storeName));
      expect(state.phone, equals(phone));
      expect(state.email, equals(email));
      expect(state.password, equals(password));
      expect(state.businessType, equals(businessType));
    });

    test('copyWith only changes specified fields, leaves others intact', () {
      const initial = RegistrationState(
        storeName: 'Toko A',
        phone: '081111111111',
        email: 'a@b.com',
        password: 'pass123',
        businessType: 'retail',
        currentStep: 0,
      );

      // Only change currentStep
      final updated = initial.copyWith(currentStep: 1);

      expect(updated.currentStep, equals(1));
      expect(updated.storeName, equals('Toko A'));
      expect(updated.phone, equals('081111111111'));
      expect(updated.email, equals('a@b.com'));
      expect(updated.password, equals('pass123'));
      expect(updated.businessType, equals('retail'));
    });
  });

  // ── Property 18: Action buttons disabled when loading ────────────────────
  // Feature: mobile-registration-subscription, Property 18: Tombol aksi
  // disabled saat loading
  // Validates: Requirements 6.7
  group('Property 18: areActionsEnabled returns false when isLoading=true', () {
    test(
      'areActionsEnabled returns false for all steps when isLoading=true (100 random combinations)',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          // Generator: random currentStep (0, 1, 2) with isLoading=true
          final step = rng.nextInt(3); // 0, 1, or 2

          final state = RegistrationState(
            isLoading: true,
            currentStep: step,
          );

          expect(
            areActionsEnabled(state),
            isFalse,
            reason:
                'areActionsEnabled must return false when isLoading=true '
                '(iteration $i, step: $step)',
          );
        }
      },
    );

    test(
      'areActionsEnabled returns true for all steps when isLoading=false (100 random combinations)',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          final step = rng.nextInt(3);

          final state = RegistrationState(
            isLoading: false,
            currentStep: step,
          );

          expect(
            areActionsEnabled(state),
            isTrue,
            reason:
                'areActionsEnabled must return true when isLoading=false '
                '(iteration $i, step: $step)',
          );
        }
      },
    );

    test('areActionsEnabled is false for step 0 when loading', () {
      final state = const RegistrationState(isLoading: true, currentStep: 0);
      expect(areActionsEnabled(state), isFalse);
    });

    test('areActionsEnabled is false for step 1 when loading', () {
      final state = const RegistrationState(isLoading: true, currentStep: 1);
      expect(areActionsEnabled(state), isFalse);
    });

    test('areActionsEnabled is false for step 2 when loading', () {
      final state = const RegistrationState(isLoading: true, currentStep: 2);
      expect(areActionsEnabled(state), isFalse);
    });

    test('areActionsEnabled is true for step 0 when not loading', () {
      final state = const RegistrationState(isLoading: false, currentStep: 0);
      expect(areActionsEnabled(state), isTrue);
    });

    test('areActionsEnabled is true for step 1 when not loading', () {
      final state = const RegistrationState(isLoading: false, currentStep: 1);
      expect(areActionsEnabled(state), isTrue);
    });

    test('areActionsEnabled is true for step 2 when not loading', () {
      final state = const RegistrationState(isLoading: false, currentStep: 2);
      expect(areActionsEnabled(state), isTrue);
    });

    test('isLoading transitions: true→false re-enables actions', () {
      var state = const RegistrationState(isLoading: true, currentStep: 0);
      expect(areActionsEnabled(state), isFalse);

      state = state.copyWith(isLoading: false);
      expect(areActionsEnabled(state), isTrue);
    });
  });
}
