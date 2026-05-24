import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lumio/core/constants/app_constants.dart';
import 'package:lumio/features/auth/models/subscription_package.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';

// ==========================================
// REGISTRATION STATE
// ==========================================

/// Immutable state for the multi-step registration flow.
///
/// Step 0 = Data Akun & Toko
/// Step 1 = Pilih Paket Berlangganan
/// Step 2 = Tunggu Konfirmasi Pembayaran
class RegistrationState {
  /// Current active step (0-indexed).
  final int currentStep;

  /// Whether an async operation is in progress.
  final bool isLoading;

  /// Error message to display, or null if no error.
  final String? errorMessage;

  // ── Step 1 form data ──────────────────────────────────────────────────────
  final String storeName;
  final String businessType;
  final String phone;
  final String email;
  final String password;

  // ── Step 1 result (from Supabase signUp) ─────────────────────────────────
  final String? userId;
  final String? accessToken;

  // ── Step 2 data ───────────────────────────────────────────────────────────
  final List<SubscriptionPackage> packages;
  final String selectedPackageSlug;

  // ── Step 3 data (from Checkout_API) ──────────────────────────────────────
  final String? invoiceNumber;
  final String? paymentUrl;
  final DateTime? expiredAt;

  const RegistrationState({
    this.currentStep = 0,
    this.isLoading = false,
    this.errorMessage,
    this.storeName = '',
    this.businessType = 'lainnya',
    this.phone = '',
    this.email = '',
    this.password = '',
    this.userId,
    this.accessToken,
    this.packages = const [],
    this.selectedPackageSlug = 'pro',
    this.invoiceNumber,
    this.paymentUrl,
    this.expiredAt,
  });

  RegistrationState copyWith({
    int? currentStep,
    bool? isLoading,
    Object? errorMessage = _sentinel,
    String? storeName,
    String? businessType,
    String? phone,
    String? email,
    String? password,
    Object? userId = _sentinel,
    Object? accessToken = _sentinel,
    List<SubscriptionPackage>? packages,
    String? selectedPackageSlug,
    Object? invoiceNumber = _sentinel,
    Object? paymentUrl = _sentinel,
    Object? expiredAt = _sentinel,
  }) {
    return RegistrationState(
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _sentinel
          ? this.errorMessage
          : errorMessage as String?,
      storeName: storeName ?? this.storeName,
      businessType: businessType ?? this.businessType,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      password: password ?? this.password,
      userId: userId == _sentinel ? this.userId : userId as String?,
      accessToken: accessToken == _sentinel
          ? this.accessToken
          : accessToken as String?,
      packages: packages ?? this.packages,
      selectedPackageSlug: selectedPackageSlug ?? this.selectedPackageSlug,
      invoiceNumber: invoiceNumber == _sentinel
          ? this.invoiceNumber
          : invoiceNumber as String?,
      paymentUrl:
          paymentUrl == _sentinel ? this.paymentUrl : paymentUrl as String?,
      expiredAt:
          expiredAt == _sentinel ? this.expiredAt : expiredAt as DateTime?,
    );
  }

  /// Sentinel object used to distinguish "not provided" from explicit null.
  static const Object _sentinel = Object();
}

// ==========================================
// REGISTRATION NOTIFIER
// ==========================================

class RegistrationNotifier extends AsyncNotifier<RegistrationState> {
  SupabaseClient get _supabase => Supabase.instance.client;

  /// Realtime channel for listening to license activation events.
  RealtimeChannel? _realtimeChannel;

  @override
  Future<RegistrationState> build() async {
    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    });
    return const RegistrationState();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setLoading(bool loading) {
    final current = state.value ?? const RegistrationState();
    state = AsyncValue.data(current.copyWith(isLoading: loading));
  }

  void _setError(String? message) {
    final current = state.value ?? const RegistrationState();
    state = AsyncValue.data(
      current.copyWith(isLoading: false, errorMessage: message),
    );
  }

  void _update(RegistrationState Function(RegistrationState) updater) {
    final current = state.value ?? const RegistrationState();
    state = AsyncValue.data(updater(current));
  }

  String _parseAuthError(String message) {
    if (message.contains('User already registered')) {
      return 'Email sudah terdaftar. Silakan login.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox Anda.';
    }
    if (message.contains('Password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (message.contains('Unable to validate email address')) {
      return 'Format email tidak valid.';
    }
    return message;
  }

  // ── Step 1: Submit Data Akun & Toko ──────────────────────────────────────

  /// Registers a new user via Supabase Auth, inserts store_profile, and
  /// advances to Step 2.
  ///
  /// Requirements: 1.10, 1.11, 1.12, 1.13, 1.14
  Future<void> submitStep1({
    required String storeName,
    required String businessType,
    required String phone,
    required String email,
    required String password,
  }) async {
    _update(
      (s) => s.copyWith(
        isLoading: true,
        errorMessage: null,
        storeName: storeName,
        businessType: businessType,
        phone: phone,
        email: email,
        password: password,
      ),
    );

    try {
      // Call Supabase signUp with 30-second timeout (Requirement 1.10)
      final response = await _supabase.auth
          .signUp(
            email: email,
            password: password,
            data: {
              'store_name': storeName,
              'phone': phone,
              'business_type': businessType,
            },
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () =>
                throw TimeoutException('Koneksi timeout. Coba lagi.'),
          );

      // signUp must return a user; otherwise treat as failure (Requirement 1.13)
      if (response.user == null) {
        _setError('Registrasi gagal. Coba lagi.');
        return;
      }

      final userId = response.user!.id;
      final accessToken = response.session?.accessToken;

      // Insert store_profile — continue even if this fails (Requirement 1.12)
      try {
        await _supabase.from('store_profile').insert({
          'name': storeName,
          'phone': phone,
          'business_type': businessType,
          'user_id': userId,
        });
      } catch (_) {
        // Intentionally swallowed — store_profile insert failure is non-blocking
      }

      // Save userId + accessToken, advance to Step 2 (Requirement 1.14)
      _update(
        (s) => s.copyWith(
          isLoading: false,
          errorMessage: null,
          userId: userId,
          accessToken: accessToken,
          currentStep: 1,
        ),
      );
    } on TimeoutException catch (e) {
      _setError(e.message ?? 'Koneksi timeout. Coba lagi.');
    } on AuthException catch (e) {
      _setError(_parseAuthError(e.message));
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('SocketException') ||
          msg.contains('NetworkException') ||
          msg.contains('Failed host lookup')) {
        _setError('Tidak ada koneksi internet. Periksa jaringan Anda.');
      } else {
        _setError(msg);
      }
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────

  /// Navigates to a specific step without triggering any async operations.
  /// Used by the UI for back-button handling.
  void goToStep(int step) {
    _update((s) => s.copyWith(currentStep: step, errorMessage: null));
  }

  // ── Step 2: Fetch Packages ────────────────────────────────────────────────

  /// Fetches active subscription packages from Supabase.
  /// Falls back to [SubscriptionPackage.fallbackPackages] on error/timeout.
  ///
  /// Requirements: 2.1, 2.5
  Future<void> fetchPackages() async {
    _setLoading(true);

    try {
      final response = await _supabase
          .from('subscription_packages')
          .select()
          .eq('is_active', true)
          .timeout(const Duration(seconds: 10));

      final packages = (response as List<dynamic>)
          .map((e) => SubscriptionPackage.fromJson(e as Map<String, dynamic>))
          .toList();

      // Default selection: prefer 'pro', otherwise first package
      final defaultSlug = packages.any((p) => p.slug == 'pro')
          ? 'pro'
          : (packages.isNotEmpty ? packages.first.slug : 'pro');

      _update(
        (s) => s.copyWith(
          isLoading: false,
          packages: packages,
          selectedPackageSlug: defaultSlug,
        ),
      );
    } catch (_) {
      // Fallback to hardcoded packages on any error or timeout
      final fallback = SubscriptionPackage.fallbackPackages;
      _update(
        (s) => s.copyWith(
          isLoading: false,
          packages: fallback,
          selectedPackageSlug: 'pro',
        ),
      );
    }
  }

  // ── Step 2: Select Package ────────────────────────────────────────────────

  /// Updates the selected package slug in state.
  ///
  /// Requirements: 2.4
  void selectPackage(String slug) {
    _update((s) => s.copyWith(selectedPackageSlug: slug));
  }

  // ── Step 2: Initiate Checkout ─────────────────────────────────────────────

  /// Calls the Checkout_API with Bearer token auth and advances to Step 3.
  ///
  /// Requirements: 2.6, 2.7, 2.8
  Future<void> initiateCheckout(String packageSlug) async {
    final current = state.value ?? const RegistrationState();
    final userId = current.userId;
    final accessToken = current.accessToken;

    if (userId == null) {
      _setError('Sesi tidak valid. Silakan ulangi dari awal.');
      return;
    }

    _setLoading(true);

    try {
      final dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.webBaseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          headers: {
            'Content-Type': 'application/json',
            if (accessToken != null)
              'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      final response = await dio.post(
        '/api/subscription/checkout',
        data: {
          'userId': userId,
          'packageSlug': packageSlug,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final invoiceNumber = data['invoiceNumber'] as String?;
      final paymentUrl = data['paymentUrl'] as String?;
      final expiredAtRaw = data['expiredAt'];
      final expiredAt = expiredAtRaw != null
          ? DateTime.tryParse(expiredAtRaw.toString())
          : null;

      // All three fields must be present before advancing to Step 3
      // (Requirement 2.7 / Property 7)
      if (invoiceNumber == null || paymentUrl == null || expiredAt == null) {
        _setError('Respons server tidak lengkap. Coba lagi.');
        return;
      }

      _update(
        (s) => s.copyWith(
          isLoading: false,
          errorMessage: null,
          invoiceNumber: invoiceNumber,
          paymentUrl: paymentUrl,
          expiredAt: expiredAt,
          currentStep: 2,
        ),
      );
    } on DioException catch (e) {
      _setError(_parseCheckoutError(e));
    } catch (e) {
      _setError('Terjadi kesalahan. Coba lagi.');
    }
  }

  /// Parses Checkout_API error responses into user-friendly Indonesian messages.
  String _parseCheckoutError(DioException e) {
    final statusCode = e.response?.statusCode;
    String? serverMessage;

    try {
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        serverMessage = data['error'] as String?;
      }
    } catch (_) {}

    if (statusCode == 400) {
      if (serverMessage != null &&
          serverMessage.contains('User already has an active subscription')) {
        return 'Akun ini sudah memiliki lisensi aktif.';
      }
      return serverMessage ?? 'Permintaan tidak valid. Coba lagi.';
    }
    if (statusCode == 404) {
      return 'Paket tidak tersedia saat ini. Coba lagi nanti.';
    }
    if (statusCode != null && statusCode >= 500) {
      return 'Terjadi kesalahan server. Coba lagi dalam beberapa saat.';
    }
    if (serverMessage != null) {
      return serverMessage;
    }
    return 'Terjadi kesalahan. Coba lagi.';
  }

  // ── Step 2: Renew Checkout ────────────────────────────────────────────────

  /// Re-calls the Checkout_API with the same data (for expired invoices).
  ///
  /// Requirements: 3.5
  Future<void> renewCheckout() async {
    final current = state.value ?? const RegistrationState();
    await initiateCheckout(current.selectedPackageSlug);
  }

  // ── Step 2: Create Trial License ─────────────────────────────────────────

  /// Delegates trial license creation to [LicenseNotifier.createTrialLicense],
  /// then invalidates [licenseProvider] to trigger re-read.
  ///
  /// Requirements: 4.1, 4.2
  Future<(bool, String?)> createTrialLicense() async {
    final current = state.value ?? const RegistrationState();
    final userId = current.userId;

    if (userId == null) {
      return (false, 'Sesi tidak valid. Silakan ulangi dari awal.');
    }

    _setLoading(true);

    final result = await ref
        .read(licenseProvider.notifier)
        .createTrialLicense(userId);

    _setLoading(false);

    if (result.$1) {
      ref.invalidate(licenseProvider);
    }

    return result;
  }

  // ── Step 3: Realtime Subscription ────────────────────────────────────────

  /// Subscribes to Supabase Realtime on the `licenses` table filtered by
  /// `user_id=eq.{userId}`. Calls [onLicenseActivated] when `is_active = true`
  /// is received.
  ///
  /// Requirements: 3.6, 3.7, 3.8
  void startRealtimeSubscription(
    String userId, {
    void Function()? onLicenseActivated,
    void Function()? onSubscribeFailed,
    void Function()? onDisconnected,
    void Function()? onReconnected,
  }) {
    // Cancel any existing subscription first
    cancelRealtimeSubscription();

    final channelName = 'registration-license-$userId';

    _realtimeChannel = _supabase
        .channel(channelName)
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'licenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final newRecord = payload.newRecord;
            final isActive = newRecord['is_active'];
            if (isActive == true) {
              ref.invalidate(licenseProvider);
              onLicenseActivated?.call();
            }
          },
        )
        .subscribe((status, [error]) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            onReconnected?.call();
          } else if (status == RealtimeSubscribeStatus.channelError ||
              status == RealtimeSubscribeStatus.timedOut) {
            onSubscribeFailed?.call();
          } else if (status == RealtimeSubscribeStatus.closed) {
            onDisconnected?.call();
          }
        });
  }

  /// Cancels the active Supabase Realtime subscription.
  ///
  /// Requirements: 3.8
  void cancelRealtimeSubscription() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }
}

// ==========================================
// PROVIDER REGISTRATION
// ==========================================

final registrationProvider =
    AsyncNotifierProvider<RegistrationNotifier, RegistrationState>(
  RegistrationNotifier.new,
);
