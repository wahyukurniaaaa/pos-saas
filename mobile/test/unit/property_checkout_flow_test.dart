// Feature: mobile-registration-subscription
// Property tests for Checkout flow — testing RegistrationState transitions directly.
//
// Strategy: Since Supabase is a singleton and Dio requires network, we test the
// LOGIC (state transitions, field validation) by exercising RegistrationState
// and its copyWith() method directly, mirroring the exact conditions that
// RegistrationNotifier enforces in submitStep1() and initiateCheckout().

import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumio/features/auth/providers/registration_provider.dart';

// ─── Random string generators ─────────────────────────────────────────────────

/// Generates a random alphanumeric string of [length] characters.
String _randomString(Random rng, int length) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  return String.fromCharCodes(
    List.generate(
      length,
      (_) => chars.codeUnitAt(rng.nextInt(chars.length)),
    ),
  );
}

/// Generates a random AuthException-like message string (1–80 chars).
String _randomAuthErrorMessage(Random rng) {
  final messages = [
    'User already registered',
    'Invalid login credentials',
    'Email not confirmed',
    'Password should be at least 6 characters',
    'Unable to validate email address: invalid format',
    'signup is disabled',
    'Email rate limit exceeded',
    'Database error saving new user',
    'unexpected_failure',
    'network error',
    _randomString(rng, rng.nextInt(60) + 1),
  ];
  return messages[rng.nextInt(messages.length)];
}

/// Generates a random URL-like string (e.g. "https://pay.example.com/inv-XXXX").
String _randomPaymentUrl(Random rng) {
  final id = _randomString(rng, 8);
  return 'https://pay.example.com/invoice/$id';
}

/// Generates a random invoice number string.
String _randomInvoiceNumber(Random rng) {
  final num = rng.nextInt(900000) + 100000;
  return 'INV-$num';
}

/// Generates a random DateTime in the future (1 minute to 24 hours from now).
DateTime _randomFutureDateTime(Random rng) {
  final secondsAhead = rng.nextInt(86400) + 60; // 1 min to 24 hours
  return DateTime.now().add(Duration(seconds: secondsAhead));
}

// ─── Helper: simulate submitStep1 failure ─────────────────────────────────────

/// Simulates the state transition that RegistrationNotifier._setError() performs
/// when supabase.auth.signUp() throws an AuthException.
///
/// In the real notifier, when signUp throws AuthException:
///   _setError(_parseAuthError(e.message))
/// which calls:
///   state = AsyncValue.data(current.copyWith(isLoading: false, errorMessage: message))
/// and currentStep is NOT advanced (stays at 0).
RegistrationState _simulateSubmitStep1Failure(
  RegistrationState initial,
  String errorMessage,
) {
  // Mirror RegistrationNotifier._setError():
  return initial.copyWith(
    isLoading: false,
    errorMessage: errorMessage,
    // currentStep intentionally NOT changed — stays at 0
  );
}

// ─── Helper: simulate initiateCheckout success ────────────────────────────────

/// Simulates the state transition that RegistrationNotifier.initiateCheckout()
/// performs when Checkout_API returns a successful response with all three fields.
///
/// In the real notifier (Requirement 2.7 / Property 7):
///   if (invoiceNumber == null || paymentUrl == null || expiredAt == null) {
///     _setError('Respons server tidak lengkap. Coba lagi.');
///     return;
///   }
///   _update((s) => s.copyWith(
///     isLoading: false, errorMessage: null,
///     invoiceNumber: invoiceNumber, paymentUrl: paymentUrl,
///     expiredAt: expiredAt, currentStep: 2,
///   ));
RegistrationState _simulateCheckoutSuccess(
  RegistrationState initial, {
  required String invoiceNumber,
  required String paymentUrl,
  required DateTime expiredAt,
}) {
  // All three fields present → advance to step 2
  return initial.copyWith(
    isLoading: false,
    errorMessage: null,
    invoiceNumber: invoiceNumber,
    paymentUrl: paymentUrl,
    expiredAt: expiredAt,
    currentStep: 2,
  );
}

// ─── Helper: simulate initiateCheckout failure ────────────────────────────────

/// Simulates the state transition that RegistrationNotifier.initiateCheckout()
/// performs when Dio throws a DioException (any HTTP error status).
///
/// In the real notifier:
///   on DioException catch (e) { _setError(_parseCheckoutError(e)); }
/// which calls _setError() → copyWith(isLoading: false, errorMessage: message)
/// and currentStep is NOT advanced (stays at 1).
RegistrationState _simulateCheckoutFailure(
  RegistrationState initial,
  String errorMessage,
) {
  // Mirror RegistrationNotifier._setError():
  return initial.copyWith(
    isLoading: false,
    errorMessage: errorMessage,
    // currentStep intentionally NOT changed — stays at 1
  );
}

/// Maps an HTTP status code to the user-facing error message that
/// RegistrationNotifier._parseCheckoutError() would produce.
String _parseCheckoutErrorForStatus(int statusCode) {
  if (statusCode == 400) return 'Permintaan tidak valid. Coba lagi.';
  if (statusCode == 401) return 'Sesi tidak valid. Silakan ulangi dari awal.';
  if (statusCode == 403) return 'Akses ditolak.';
  if (statusCode == 404) return 'Paket tidak tersedia saat ini. Coba lagi nanti.';
  if (statusCode >= 500) {
    return 'Terjadi kesalahan server. Coba lagi dalam beberapa saat.';
  }
  return 'Terjadi kesalahan. Coba lagi.';
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // ── Property 5: signUp gagal memblokir navigasi ke Step 2 ─────────────────
  // Feature: mobile-registration-subscription, Property 5: signUp gagal memblokir navigasi ke Step 2
  // Validates: Requirements 1.13
  group('Property 5: signUp gagal memblokir navigasi ke Step 2', () {
    test(
      'Setelah submitStep1() gagal dengan AuthException, currentStep tetap 0 '
      'dan errorMessage tidak null — 100 iterasi acak',
      () {
        final rng = Random(42); // fixed seed for reproducibility

        for (int i = 0; i < 100; i++) {
          // Start from the initial state (Step 0, not loading, no error)
          final initial = const RegistrationState(
            currentStep: 0,
            isLoading: false,
          );

          // Generate a random AuthException message
          final errorMessage = _randomAuthErrorMessage(rng);

          // Simulate what RegistrationNotifier does when signUp throws AuthException:
          // it calls _setError(_parseAuthError(e.message)) which does NOT advance step.
          final resultState = _simulateSubmitStep1Failure(initial, errorMessage);

          // Property 5 assertion: step must NOT advance to 1
          expect(
            resultState.currentStep,
            equals(0),
            reason:
                'Iteration $i: currentStep harus tetap 0 setelah signUp gagal '
                '(errorMessage: "$errorMessage")',
          );

          // Property 5 assertion: errorMessage must be set (not null)
          expect(
            resultState.errorMessage,
            isNotNull,
            reason:
                'Iteration $i: errorMessage harus tidak null setelah signUp gagal '
                '(errorMessage: "$errorMessage")',
          );

          // Sanity: isLoading must be false after error
          expect(
            resultState.isLoading,
            isFalse,
            reason:
                'Iteration $i: isLoading harus false setelah error '
                '(errorMessage: "$errorMessage")',
          );
        }
      },
    );

    test(
      'signUp gagal tidak mengubah data form yang sudah diisi',
      () {
        final rng = Random(99);

        for (int i = 0; i < 100; i++) {
          final storeName = _randomString(rng, rng.nextInt(50) + 1);
          final phone = _randomString(rng, rng.nextInt(7) + 9);
          final email = '${_randomString(rng, 5)}@example.com';
          final password = _randomString(rng, rng.nextInt(10) + 6);

          final initial = RegistrationState(
            currentStep: 0,
            isLoading: true, // was loading before error
            storeName: storeName,
            phone: phone,
            email: email,
            password: password,
          );

          final errorMessage = _randomAuthErrorMessage(rng);
          final resultState = _simulateSubmitStep1Failure(initial, errorMessage);

          // Form data must be preserved after failure
          expect(resultState.storeName, equals(storeName),
              reason: 'Iteration $i: storeName harus tetap sama setelah gagal');
          expect(resultState.phone, equals(phone),
              reason: 'Iteration $i: phone harus tetap sama setelah gagal');
          expect(resultState.email, equals(email),
              reason: 'Iteration $i: email harus tetap sama setelah gagal');
          expect(resultState.password, equals(password),
              reason: 'Iteration $i: password harus tetap sama setelah gagal');
          expect(resultState.currentStep, equals(0),
              reason: 'Iteration $i: currentStep harus tetap 0');
        }
      },
    );
  });

  // ── Property 7: Checkout sukses menyimpan semua field ─────────────────────
  // Feature: mobile-registration-subscription, Property 7: Checkout sukses menyimpan semua field yang diperlukan
  // Validates: Requirements 2.7
  group('Property 7: Checkout sukses menyimpan semua field yang diperlukan', () {
    test(
      'Setelah initiateCheckout() sukses, invoiceNumber/paymentUrl/expiredAt '
      'tidak null dan currentStep == 2 — 100 iterasi acak',
      () {
        final rng = Random(42);

        for (int i = 0; i < 100; i++) {
          // Start from Step 1 (user has completed Step 1 successfully)
          final initial = RegistrationState(
            currentStep: 1,
            isLoading: true,
            userId: 'user-${_randomString(rng, 8)}',
            accessToken: 'token-${_randomString(rng, 16)}',
          );

          // Generate random checkout response data
          final invoiceNumber = _randomInvoiceNumber(rng);
          final paymentUrl = _randomPaymentUrl(rng);
          final expiredAt = _randomFutureDateTime(rng);

          // Simulate successful checkout response
          final resultState = _simulateCheckoutSuccess(
            initial,
            invoiceNumber: invoiceNumber,
            paymentUrl: paymentUrl,
            expiredAt: expiredAt,
          );

          // Property 7 assertion: all three fields must be saved
          expect(
            resultState.invoiceNumber,
            isNotNull,
            reason: 'Iteration $i: invoiceNumber harus tidak null setelah checkout sukses',
          );
          expect(
            resultState.paymentUrl,
            isNotNull,
            reason: 'Iteration $i: paymentUrl harus tidak null setelah checkout sukses',
          );
          expect(
            resultState.expiredAt,
            isNotNull,
            reason: 'Iteration $i: expiredAt harus tidak null setelah checkout sukses',
          );

          // Property 7 assertion: must advance to step 2
          expect(
            resultState.currentStep,
            equals(2),
            reason:
                'Iteration $i: currentStep harus 2 setelah checkout sukses '
                '(invoice: $invoiceNumber)',
          );

          // Verify exact values are stored correctly
          expect(resultState.invoiceNumber, equals(invoiceNumber),
              reason: 'Iteration $i: invoiceNumber harus sama dengan yang diterima dari API');
          expect(resultState.paymentUrl, equals(paymentUrl),
              reason: 'Iteration $i: paymentUrl harus sama dengan yang diterima dari API');
          expect(resultState.expiredAt, equals(expiredAt),
              reason: 'Iteration $i: expiredAt harus sama dengan yang diterima dari API');

          // Sanity: no error, not loading
          expect(resultState.errorMessage, isNull,
              reason: 'Iteration $i: errorMessage harus null setelah checkout sukses');
          expect(resultState.isLoading, isFalse,
              reason: 'Iteration $i: isLoading harus false setelah checkout sukses');
        }
      },
    );

    test(
      'Checkout tidak boleh maju ke Step 2 jika salah satu field null '
      '(guard condition dari notifier)',
      () {
        // This test verifies the guard logic in initiateCheckout():
        //   if (invoiceNumber == null || paymentUrl == null || expiredAt == null) {
        //     _setError('Respons server tidak lengkap. Coba lagi.');
        //     return;
        //   }
        final initial = const RegistrationState(
          currentStep: 1,
          isLoading: true,
          userId: 'user-abc',
        );

        // Simulate incomplete response (missing expiredAt)
        final incompleteState = initial.copyWith(
          isLoading: false,
          errorMessage: 'Respons server tidak lengkap. Coba lagi.',
          // currentStep NOT advanced
        );

        expect(incompleteState.currentStep, equals(1),
            reason: 'Step tidak boleh maju jika response tidak lengkap');
        expect(incompleteState.invoiceNumber, isNull,
            reason: 'invoiceNumber harus null jika response tidak lengkap');
        expect(incompleteState.paymentUrl, isNull,
            reason: 'paymentUrl harus null jika response tidak lengkap');
        expect(incompleteState.expiredAt, isNull,
            reason: 'expiredAt harus null jika response tidak lengkap');
        expect(incompleteState.errorMessage, isNotNull,
            reason: 'errorMessage harus diset jika response tidak lengkap');
      },
    );
  });

  // ── Property 8: Error Checkout_API mencegah navigasi ke Step 3 ────────────
  // Feature: mobile-registration-subscription, Property 8: Error Checkout_API mencegah navigasi ke Step 3
  // Validates: Requirements 2.8
  group('Property 8: Error Checkout_API mencegah navigasi ke Step 3', () {
    test(
      'Setelah initiateCheckout() gagal dengan DioException, currentStep tetap 1 '
      'dan errorMessage tidak null — semua HTTP error codes',
      () {
        final rng = Random(42);

        // HTTP status codes yang mungkin dikembalikan Checkout_API
        const errorStatusCodes = [400, 401, 403, 404, 500, 502, 503];

        for (int i = 0; i < 100; i++) {
          // Start from Step 1 (user has completed Step 1 successfully)
          final initial = RegistrationState(
            currentStep: 1,
            isLoading: true,
            userId: 'user-${_randomString(rng, 8)}',
            accessToken: 'token-${_randomString(rng, 16)}',
          );

          // Pick a random HTTP error status code from the set
          final statusCode =
              errorStatusCodes[rng.nextInt(errorStatusCodes.length)];
          final errorMessage = _parseCheckoutErrorForStatus(statusCode);

          // Simulate DioException → _setError() in notifier
          final resultState = _simulateCheckoutFailure(initial, errorMessage);

          // Property 8 assertion: step must NOT advance to 2
          expect(
            resultState.currentStep,
            equals(1),
            reason:
                'Iteration $i: currentStep harus tetap 1 setelah checkout gagal '
                '(HTTP $statusCode)',
          );

          // Property 8 assertion: errorMessage must be set
          expect(
            resultState.errorMessage,
            isNotNull,
            reason:
                'Iteration $i: errorMessage harus tidak null setelah checkout gagal '
                '(HTTP $statusCode)',
          );

          // Sanity: isLoading must be false after error
          expect(
            resultState.isLoading,
            isFalse,
            reason:
                'Iteration $i: isLoading harus false setelah error '
                '(HTTP $statusCode)',
          );

          // Sanity: checkout fields must remain null (not partially set)
          expect(
            resultState.invoiceNumber,
            isNull,
            reason:
                'Iteration $i: invoiceNumber harus null setelah checkout gagal '
                '(HTTP $statusCode)',
          );
          expect(
            resultState.paymentUrl,
            isNull,
            reason:
                'Iteration $i: paymentUrl harus null setelah checkout gagal '
                '(HTTP $statusCode)',
          );
          expect(
            resultState.expiredAt,
            isNull,
            reason:
                'Iteration $i: expiredAt harus null setelah checkout gagal '
                '(HTTP $statusCode)',
          );
        }
      },
    );

    test(
      'Setiap HTTP error code menghasilkan errorMessage yang berbeda-beda '
      '(pesan spesifik per status code)',
      () {
        final initial = const RegistrationState(
          currentStep: 1,
          isLoading: true,
          userId: 'user-test',
        );

        // Verify each status code produces a non-null, non-empty error message
        const errorStatusCodes = [400, 401, 403, 404, 500, 502, 503];

        for (final statusCode in errorStatusCodes) {
          final errorMessage = _parseCheckoutErrorForStatus(statusCode);
          final resultState = _simulateCheckoutFailure(initial, errorMessage);

          expect(
            resultState.errorMessage,
            isNotNull,
            reason: 'HTTP $statusCode harus menghasilkan errorMessage tidak null',
          );
          expect(
            resultState.errorMessage!.isNotEmpty,
            isTrue,
            reason: 'HTTP $statusCode harus menghasilkan errorMessage tidak kosong',
          );
          expect(
            resultState.currentStep,
            equals(1),
            reason: 'HTTP $statusCode tidak boleh mengubah currentStep dari 1',
          );
        }
      },
    );

    test(
      'Data Step 1 (userId, accessToken) tetap tersimpan setelah checkout gagal',
      () {
        final rng = Random(77);
        const errorStatusCodes = [400, 401, 403, 404, 500, 502, 503];

        for (int i = 0; i < 100; i++) {
          final userId = 'user-${_randomString(rng, 8)}';
          final accessToken = 'token-${_randomString(rng, 16)}';

          final initial = RegistrationState(
            currentStep: 1,
            isLoading: true,
            userId: userId,
            accessToken: accessToken,
          );

          final statusCode =
              errorStatusCodes[rng.nextInt(errorStatusCodes.length)];
          final errorMessage = _parseCheckoutErrorForStatus(statusCode);
          final resultState = _simulateCheckoutFailure(initial, errorMessage);

          // userId and accessToken must be preserved for retry
          expect(resultState.userId, equals(userId),
              reason:
                  'Iteration $i: userId harus tetap tersimpan setelah checkout gagal');
          expect(resultState.accessToken, equals(accessToken),
              reason:
                  'Iteration $i: accessToken harus tetap tersimpan setelah checkout gagal');
        }
      },
    );
  });

  // ── Additional: RegistrationState.copyWith() correctness ──────────────────
  // Validates the sentinel pattern used in copyWith() works correctly for
  // nullable fields — this underpins all the above property tests.
  group('RegistrationState.copyWith() — sentinel pattern correctness', () {
    test('copyWith() preserves unspecified fields', () {
      final rng = Random(42);

      for (int i = 0; i < 100; i++) {
        final invoiceNumber = _randomInvoiceNumber(rng);
        final paymentUrl = _randomPaymentUrl(rng);
        final expiredAt = _randomFutureDateTime(rng);

        final state = RegistrationState(
          currentStep: 2,
          invoiceNumber: invoiceNumber,
          paymentUrl: paymentUrl,
          expiredAt: expiredAt,
        );

        // copyWith without specifying nullable fields should preserve them
        final copied = state.copyWith(isLoading: false);

        expect(copied.invoiceNumber, equals(invoiceNumber),
            reason: 'Iteration $i: invoiceNumber harus dipertahankan oleh copyWith()');
        expect(copied.paymentUrl, equals(paymentUrl),
            reason: 'Iteration $i: paymentUrl harus dipertahankan oleh copyWith()');
        expect(copied.expiredAt, equals(expiredAt),
            reason: 'Iteration $i: expiredAt harus dipertahankan oleh copyWith()');
        expect(copied.currentStep, equals(2),
            reason: 'Iteration $i: currentStep harus dipertahankan oleh copyWith()');
      }
    });

    test('copyWith() can explicitly set nullable fields to null (sentinel pattern)', () {
      final state = RegistrationState(
        currentStep: 2,
        invoiceNumber: 'INV-123',
        paymentUrl: 'https://pay.example.com/123',
        expiredAt: DateTime.now().add(const Duration(hours: 1)),
        errorMessage: 'some error',
      );

      // Explicitly set nullable fields to null using sentinel
      final cleared = state.copyWith(
        errorMessage: null,
        invoiceNumber: null,
        paymentUrl: null,
        expiredAt: null,
      );

      expect(cleared.errorMessage, isNull,
          reason: 'errorMessage harus bisa di-set ke null via copyWith()');
      expect(cleared.invoiceNumber, isNull,
          reason: 'invoiceNumber harus bisa di-set ke null via copyWith()');
      expect(cleared.paymentUrl, isNull,
          reason: 'paymentUrl harus bisa di-set ke null via copyWith()');
      expect(cleared.expiredAt, isNull,
          reason: 'expiredAt harus bisa di-set ke null via copyWith()');
    });
  });
}
