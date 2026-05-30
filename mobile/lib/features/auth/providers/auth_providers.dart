import 'dart:async';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:lumio/core/constants/app_constants.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/providers/dio_provider.dart';
import 'package:lumio/core/providers/license_tier_provider.dart';
import 'package:lumio/core/providers/supabase_provider.dart';

class DeviceLimitException implements Exception {
  final String message;
  DeviceLimitException(this.message);
  
  @override
  String toString() => message;
}

final localLicenseProvider = FutureProvider.autoDispose<License?>((ref) async {
  final db = ref.watch(databaseProvider);
  return db.getLocalLicense();
});

// ==========================================
// LICENSE NOTIFIER (Tetap via Go Backend)
// ==========================================

/// Notifier for license activation and status check.
class LicenseNotifier extends AsyncNotifier<License?> {
  final _deviceInfo = DeviceInfoPlugin();
  final _storage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'lumio_device_id_stable';
  static const String _serverTimeKey = 'lumio_last_server_time';

  Future<String> _getDeviceId() async {
    final cachedId = await _storage.read(key: _deviceIdKey);
    if (cachedId != null) return cachedId;

    String baseId = 'lumio';
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      baseId = '${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      baseId = iosInfo.identifierForVendor ?? 'IOS-UNKNOWN';
    }

    // Use a deterministic hash based on stable device properties
    final hashedId = sha256.convert(utf8.encode('lumio_stable_$baseId')).toString();
    await _storage.write(key: _deviceIdKey, value: hashedId);
    return hashedId;
  }

  Future<String> _getDeviceModel() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.utsname.machine;
    }
    return 'Generic';
  }

  @override
  Future<License?> build() async {
    // IMPORTANT: This build() method has NO dependency on authProvider.
    // Invalidation is triggered externally by AuthNotifier after sign-in/sign-out.
    // This breaks the circular dependency chain:
    // appTierProvider → licenseProvider → authProvider → licenseProvider (CYCLE)
    final db = ref.watch(databaseProvider);
    // Watch supabaseUserProvider reactively so that when auth state changes (login/logout),
    // licenseProvider is automatically marked as dirty/reloading, preventing UI flash of UnlicensedScreen.
    final authUser = ref.watch(supabaseUserProvider);

    var license = await db.getLocalLicense();

    if (license == null) {
      // If no local license, check if the current Supabase user has one in cloud metadata.
      if (authUser != null && authUser.email != null) {
        final syncedLicense = await _verifyAccountSilently(authUser.email!);
        if (syncedLicense != null) {
          license = syncedLicense;
        }
      }
    }

    if (license != null) {
      final currentDeviceId = await _getDeviceId();
      final now = DateTime.now();

      // Time Manipulation Check
      final lastServerTimeString = await _storage.read(key: _serverTimeKey);
      if (lastServerTimeString != null) {
        final lastServerTime = DateTime.tryParse(lastServerTimeString);
        if (lastServerTime != null && now.isBefore(lastServerTime)) {
          await db.deleteLicense(license.licenseCode);
          return null;
        }
      }

      // Lazy Fingerprint Validation
      if (license.deviceFingerprint != currentDeviceId) {
        _verifyWithServer(license.licenseCode, currentDeviceId);
      }

      // 7-Day Hard Offline Block
      final lastCheck = license.lastVerified ?? license.activationDate ?? now;
      final diff = now.difference(lastCheck);

      if (diff.inDays >= 7) {
        _verifyWithServer(license.licenseCode, currentDeviceId);
        return null;
      }

      // Heartbeat Validation (Every 24h)
      if (diff.inHours >= 24) {
        _verifyWithServer(license.licenseCode, currentDeviceId);
      }
    }

    return license;
  }

  Future<void> _verifyWithServer(String code, String deviceId) async {
    final db = ref.read(databaseProvider);

    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return;
      
      final response = await Supabase.instance.client
          .from('licenses')
          .select()
          .eq('user_id', authUser.id)
          .eq('is_active', true)
          .maybeSingle();

      if (response != null) {
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        await db.updateLicenseFingerprint(code, deviceId);
      } else {
        await db.deleteLicense(code);
        ref.invalidateSelf();
      }
    } catch (e) {
      // Offline or error
    }
  }

  /// Creates a local trial license for the given [userId].
  ///
  /// Returns `(true, null)` on success.
  /// Returns `(false, 'Trial sudah pernah digunakan.')` if a trial already exists.
  /// Returns `(false, 'Gagal mengaktifkan trial. Coba lagi.')` on SQLite error.
  Future<(bool, String?)> createTrialLicense(String userId) async {
    final db = ref.read(databaseProvider);

    // Check if a trial license already exists
    final existing = await db.getLocalLicense();
    if (existing != null && existing.licenseCode.startsWith('TRIAL-')) {
      return (false, 'Trial sudah pernah digunakan.');
    }

    try {
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
      return (true, null);
    } catch (e) {
      return (false, 'Gagal mengaktifkan trial. Coba lagi.');
    }
  }

  Future<(bool, String?)> verifyAccount(String email) async {
    try {
      final license = await _verifyAccountSilently(email);
      if (!ref.mounted) return (false, null);

      if (license != null) {
        state = AsyncValue.data(license);
        return (true, null);
      }
      return (false, 'Akun belum berlangganan atau masa aktif telah habis.');
    } on DeviceLimitException catch (e) {
      if (ref.mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
      return (false, e.message);
    } catch (e) {
      if (ref.mounted) {
        state = const AsyncValue.data(null);
      }
      return (false, 'Gagal memverifikasi lisensi: ${e.toString()}');
    }
  }

  /// Internal helper to activate a license without modifying the Notifier state directly.
  /// Useful for the build() method sync logic.
  Future<License?> _verifyAccountSilently(String email) async {
    final db = ref.read(databaseProvider);

    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) return null;

      // 1. Query Supabase licenses
      final response = await Supabase.instance.client
          .from('licenses')
          .select()
          .eq('user_id', authUser.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      final deviceId = await _getDeviceId();

      // 2. Jika tidak ada lisensi sama sekali di Supabase -> AUTO-TRIAL
      if (response == null) {
        final expiredAt = DateTime.now().add(const Duration(days: 7));
        final licenseCode = 'TRIAL-${authUser.id}';

        // A. Insert ke Supabase (pencatatan anti-abuse server-side)
        await Supabase.instance.client.from('licenses').insert({
          'license_code': licenseCode,
          'tier_level': 'trial',
          'max_devices': 1,
          'max_outlets': 1,
          'is_active': true,
          'activation_date': DateTime.now().toIso8601String(),
          'expired_at': expiredAt.toIso8601String(),
          'user_id': authUser.id,
          'customer_email': email,
        });

        // B. Insert ke SQLite lokal
        await db.into(db.licenses).insert(
          LicensesCompanion.insert(
            licenseCode: licenseCode,
            deviceFingerprint: Value(deviceId),
            activationDate: Value(DateTime.now()),
            status: const Value('active'),
            tierLevel: const Value('trial'),
            maxDevices: const Value(1),
            maxOutlets: const Value(1),
            expiredAt: Value(expiredAt),
          ),
        );

        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        return await db.getLocalLicense();
      }

      // 3. Jika ada lisensi
      final tier = (response['tier_level'] as String?)?.toLowerCase();
      final expiredAtStr = response['expired_at'] as String?;
      final expiredAt = expiredAtStr != null ? DateTime.parse(expiredAtStr) : null;
      final isActive = response['is_active'] as bool? ?? false;

      // A. Jika Trial Expired atau Lisensi Tidak Aktif
      if (!isActive || (tier == 'trial' && expiredAt != null && expiredAt.isBefore(DateTime.now()))) {
        await (db.delete(db.licenses)).go();
        await db.into(db.licenses).insert(
          LicensesCompanion.insert(
            licenseCode: response['license_code'] as String? ?? 'ACCOUNT-BOUND',
            deviceFingerprint: Value(deviceId),
            activationDate: Value(DateTime.now()),
            status: const Value('expired'),
            tierLevel: Value(tier),
            maxDevices: Value(response['max_devices'] as int? ?? 1),
            maxOutlets: Value(response['max_outlets'] as int? ?? 1),
            expiredAt: Value(expiredAt),
          ),
        );
        return await db.getLocalLicense();
      }

      // B. Jika Lisensi Berbayar Aktif (pro atau lite) -> Check Device Limit di Go Server
      if (tier == 'pro' || tier == 'lite') {
        final dio = ref.read(dioProvider);
        final deviceModel = await _getDeviceModel();
        final osVersion = Platform.isAndroid ? 'Android' : 'iOS';

        try {
          final verifyResponse = await dio.post(
            'license/verify-account',
            data: {
              'user_id': authUser.id,
              'email': email,
              'device_fingerprint': deviceId,
              'device_model': deviceModel,
              'os_version': osVersion,
            },
          );

          final verifyData = verifyResponse.data;
          final isVerifySuccess = (verifyData is Map && verifyData['status'] == 'success') ||
                                  (verifyData is Map && verifyData['success'] == true) ||
                                  verifyResponse.statusCode == 200;

          if (isVerifySuccess && verifyData is Map && verifyData['data'] != null) {
            final resData = verifyData['data'];
            await (db.delete(db.licenses)).go();
            await db.into(db.licenses).insert(
              LicensesCompanion.insert(
                licenseCode: resData['license_code'] as String? ?? 'ACCOUNT-BOUND',
                deviceFingerprint: Value(deviceId),
                activationDate: Value(DateTime.now()),
                status: const Value('active'),
                tierLevel: Value(resData['tier_level'] as String?),
                maxDevices: Value(resData['max_devices'] as int? ?? 1),
                maxOutlets: Value(resData['max_outlets'] as int? ?? 1),
                expiredAt: resData['expired_at'] != null ? Value(DateTime.parse(resData['expired_at'] as String)) : const Value(null),
              ),
            );
            await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
            return await db.getLocalLicense();
          }
        } on DioException catch (e) {
          final statusCode = e.response?.statusCode;
          final responseData = e.response?.data;
          final hasLimitMessage = responseData is Map && responseData['message'] != null &&
                                  responseData['message'].toString().contains('Batas maksimum perangkat');
          if (statusCode == 403 || hasLimitMessage) {
            throw DeviceLimitException('Batas maksimum perangkat terlampaui. Silakan lepas perangkat lama Anda.');
          }
          rethrow;
        }
      }

      // Default fallback (misalnya trial masih aktif)
      await (db.delete(db.licenses)).go();
      await db.into(db.licenses).insert(
        LicensesCompanion.insert(
          licenseCode: response['license_code'] as String? ?? 'ACCOUNT-BOUND',
          deviceFingerprint: Value(deviceId),
          activationDate: Value(DateTime.now()),
          status: const Value('active'),
          tierLevel: Value(tier),
          maxDevices: Value(response['max_devices'] as int? ?? 1),
          maxOutlets: Value(response['max_outlets'] as int? ?? 1),
          expiredAt: Value(expiredAt),
        ),
      );
      await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
      return await db.getLocalLicense();

    } catch (e) {
      if (e is DeviceLimitException) rethrow;
      return null;
    }
  }
}

final licenseProvider = AsyncNotifierProvider<LicenseNotifier, License?>(
  LicenseNotifier.new,
);

// ==========================================
// AUTH NOTIFIER (Supabase-based)
// ==========================================

class AuthNotifier extends AsyncNotifier<User?> {
  SupabaseClient get _supabase => Supabase.instance.client;

  @override
  Future<User?> build() async {
    // Use the existing supabaseAuthStateProvider (NOT an anonymous StreamProvider).
    // Creating a new StreamProvider inside build() would create a new listener
    // on every rebuild, causing both memory leaks and cascading rebuilds.
    ref.listen(supabaseAuthStateProvider, (_, next) {
      if (ref.mounted) ref.invalidateSelf();
    });
    return _supabase.auth.currentUser;
  }

  /// Register with email and password via Supabase.
  /// Optionally activates a license code via the Go backend after registration.
  Future<(bool, String?)> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: data,
      );

      if (response.user == null) {
        return (false, 'Registrasi gagal. Coba lagi.');
      }

      if (ref.mounted) state = AsyncValue.data(response.user);
      return (true, null);
    } on AuthException catch (e) {
      return (false, _parseAuthError(e.message));
    } catch (e) {
      return (false, e.toString());
    }
  }

  /// Sign in with email and password via Supabase.
  Future<(bool, String?)> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return (false, 'Login gagal. Periksa email dan password Anda.');
      }

      // Trigger license sync check
      ref.invalidate(licenseProvider);

      if (ref.mounted) state = AsyncValue.data(response.user);
      return (true, null);
    } on AuthException catch (e) {
      return (false, _parseAuthError(e.message));
    } catch (e) {
      return (false, e.toString());
    }
  }

  /// Sign in with Google (native flow using google_sign_in package).
  Future<(bool, String?)> signInWithGoogle() async {
    try {
      final webClientId = AppConstants.googleWebClientId;
      final iosClientId = AppConstants.googleIosClientId;

      final googleSignIn = GoogleSignIn(
        clientId: Platform.isIOS ? iosClientId : null,
        serverClientId: webClientId,
        scopes: ['email', 'profile'],
      );

      final googleAccount = await googleSignIn.signIn();
      if (googleAccount == null) {
        return (false, 'Login Google dibatalkan.');
      }

      final googleAuth = await googleAccount.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;

      if (idToken == null) {
        return (false, 'Gagal mendapatkan token Google. Coba lagi.');
      }

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user == null) {
        return (false, 'Login Google gagal. Coba lagi.');
      }

      // Trigger license sync check
      ref.invalidate(licenseProvider);

      if (ref.mounted) state = AsyncValue.data(response.user);
      return (true, null);
    } on AuthException catch (e) {
      return (false, _parseAuthError(e.message));
    } catch (e) {
      return (false, e.toString());
    }
  }

  /// Sign out from Supabase.
  Future<void> signOut() async {
    await _supabase.auth.signOut();
    ref.invalidate(licenseProvider);
    if (ref.mounted) state = const AsyncValue.data(null);
  }

  String _parseAuthError(String message) {
    // Friendly Indonesian error messages
    if (message.contains('Invalid login credentials')) {
      return 'Email atau password salah.';
    }
    if (message.contains('Email not confirmed')) {
      return 'Email belum dikonfirmasi. Cek inbox Anda.';
    }
    if (message.contains('User already registered')) {
      return 'Email sudah terdaftar. Silakan login.';
    }
    if (message.contains('Password should be at least')) {
      return 'Password minimal 6 karakter.';
    }
    if (message.contains('Unable to validate email address')) {
      return 'Format email tidak valid.';
    }
    return message;
  }
}

final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);
