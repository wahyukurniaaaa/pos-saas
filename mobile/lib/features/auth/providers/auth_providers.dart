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

import 'package:posify_app/core/constants/app_constants.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/dio_provider.dart';

// ==========================================
// LICENSE NOTIFIER (Tetap via Go Backend)
// ==========================================

/// Notifier for license activation and status check.
class LicenseNotifier extends AsyncNotifier<License?> {
  final _deviceInfo = DeviceInfoPlugin();
  final _storage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'posify_device_id_stable';
  static const String _serverTimeKey = 'posify_last_server_time';

  Future<String> _getDeviceId() async {
    final cachedId = await _storage.read(key: _deviceIdKey);
    if (cachedId != null) return cachedId;

    String baseId = 'posify';
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      baseId = '${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      baseId = iosInfo.identifierForVendor ?? 'IOS-UNKNOWN';
    }

    // Use a deterministic hash based on stable device properties
    final hashedId = sha256.convert(utf8.encode('posify_stable_$baseId')).toString();
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
    final db = ref.watch(databaseProvider);
    var license = await db.getLocalLicense();

    if (license == null) {
      // 1. Check if we have a Supabase session and a license in the cloud
      final user = Supabase.instance.client.auth.currentUser;
      final cloudLicenseCode = user?.userMetadata?['license_code'] as String?;

      if (cloudLicenseCode != null) {
        // 2. Automagically sync from cloud silently to avoid state update loops
        final syncedLicense = await _activateSilently(cloudLicenseCode);
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
    final dio = ref.read(dioProvider);

    try {
      final response = await dio.post(
        'license/verify',
        data: {'license_code': code, 'device_fingerprint': deviceId},
      );

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          (data is Map && data['success'] == true) ||
          (data is Map && data['data'] is Map && data['data']['is_active'] == true);

      if (isSuccess) {
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        await db.updateLicenseFingerprint(code, deviceId);
      } else {
        final model = await _getDeviceModel();
        final actResponse = await dio.post(
          'license/activate',
          data: {
            'license_code': code,
            'device_fingerprint': deviceId,
            'device_model': model,
            'os_version': Platform.operatingSystemVersion,
          },
        );

        final actData = actResponse.data;
        final isActSuccess = (actData is Map && actData['status'] == 'success') ||
            (actData is Map && actData['success'] == true);

        if (isActSuccess) {
          await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
          await db.updateLicenseFingerprint(code, deviceId);
        } else {
          await db.deleteLicense(code);
          ref.invalidateSelf();
        }
      }
    } catch (e) {
      try {
        await dio.head('https://1.1.1.1', options: Options(receiveTimeout: const Duration(seconds: 3)));
        throw Exception('Akses API terblokir. Harap periksa jaringan / matikan VPN.');
      } catch (_) {
        // Truly offline — grace period applies
      }
    }
  }

  Future<(bool, String?)> activate(String code) async {
    final db = ref.read(databaseProvider);
    final dio = ref.read(dioProvider);

    try {
      final deviceId = await _getDeviceId();
      final model = await _getDeviceModel();

      final response = await dio.post(
        'license/activate',
        data: {
          'license_code': code,
          'device_fingerprint': deviceId,
          'device_model': model,
          'os_version': Platform.operatingSystemVersion,
        },
      );

      if (!ref.mounted) return (false, null);

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          (data is Map && data['success'] == true) ||
          response.statusCode == 200;

      if (isSuccess) {
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        await (db.delete(db.licenses)).go();

        final resData = data['data'] as Map?;
        await db.into(db.licenses).insert(
          LicensesCompanion.insert(
            licenseCode: code,
            deviceFingerprint: Value(deviceId),
            activationDate: Value(DateTime.now()),
            status: const Value('active'),
            tierLevel: Value(resData?['tier_level'] as String?),
            maxDevices: Value(resData?['max_devices'] as int? ?? 1),
            maxOutlets: Value(resData?['max_outlets'] as int? ?? 1),
          ),
        );

        // Sync to Supabase Cloud Metadata
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'license_code': code}),
          );
        } catch (e) {
          debugPrint('Failed to sync license code to Supabase: $e');
        }

        final newLicense = await db.getLocalLicense();
        if (ref.mounted) state = AsyncValue.data(newLicense);
        return (true, null);
      }

      final errorMsg = (data is Map)
          ? (data['message']?.toString() ?? 'Aktivasi gagal')
          : 'Aktivasi gagal: Server mengembalikan status ${response.statusCode}';

      if (ref.mounted) state = const AsyncValue.data(null);
      return (false, errorMsg);
    } on DioException catch (e) {
      if (!ref.mounted) return (false, null);

      var responseData = e.response?.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }

      final msg = (responseData is Map && responseData['message'] != null)
          ? responseData['message'].toString()
          : 'Gagal menghubungi server (${e.response?.statusCode ?? "Unknown"})';
      if (ref.mounted) state = const AsyncValue.data(null);
      return (false, msg);
    } catch (e) {
      if (!ref.mounted) return (false, null);
      state = const AsyncValue.data(null);
      return (false, e.toString());
    }
  }

  /// Internal helper to activate a license without modifying the Notifier state directly.
  /// Useful for the build() method sync logic.
  Future<License?> _activateSilently(String code) async {
    final db = ref.read(databaseProvider);
    final dio = ref.read(dioProvider);

    try {
      final deviceId = await _getDeviceId();
      final model = await _getDeviceModel();

      final response = await dio.post(
        'license/activate',
        data: {
          'license_code': code,
          'device_fingerprint': deviceId,
          'device_model': model,
          'os_version': Platform.operatingSystemVersion,
        },
      );

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          (data is Map && data['success'] == true) ||
          response.statusCode == 200;

      if (isSuccess) {
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        await (db.delete(db.licenses)).go();
        
        final resData = data['data'] as Map?;
        await db.into(db.licenses).insert(
          LicensesCompanion.insert(
            licenseCode: code,
            deviceFingerprint: Value(deviceId),
            activationDate: Value(DateTime.now()),
            status: const Value('active'),
            tierLevel: Value(resData?['tier_level'] as String?),
            maxDevices: Value(resData?['max_devices'] as int? ?? 1),
            maxOutlets: Value(resData?['max_outlets'] as int? ?? 1),
          ),
        );

        // Sync to Supabase Cloud Metadata (even in silent mode to be sure)
        try {
          await Supabase.instance.client.auth.updateUser(
            UserAttributes(data: {'license_code': code}),
          );
        } catch (_) {}

        return await db.getLocalLicense();
      }
      return null;
    } catch (_) {
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
    // Listen to auth state changes and rebuild when they occur
    ref.listen(
      // We'll use a simple approach: just return current user
      // The AppBootstrap will handle redirecting via supabaseSessionProvider
      StreamProvider((ref) => _supabase.auth.onAuthStateChange),
      (_, next) {
        if (ref.mounted) ref.invalidateSelf();
      },
    );
    return _supabase.auth.currentUser;
  }

  /// Register with email and password via Supabase.
  /// Optionally activates a license code via the Go backend after registration.
  Future<(bool, String?)> signUp({
    required String email,
    required String password,
    String? licenseCode,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        return (false, 'Registrasi gagal. Coba lagi.');
      }

      // If license code provided, activate it via Go backend
      if (licenseCode != null && licenseCode.isNotEmpty) {
        final lNotifier = ref.read(licenseProvider.notifier);
        await lNotifier.activate(licenseCode);
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
