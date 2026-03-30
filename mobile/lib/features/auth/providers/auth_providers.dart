import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/dio_provider.dart';

/// Notifier for license activation and status check.
class LicenseNotifier extends AsyncNotifier<License?> {
  final _deviceInfo = DeviceInfoPlugin();
  final _storage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'posify_device_id_stable';
  static const String _serverTimeKey = 'posify_last_server_time';

  Future<String> _getDeviceId() async {
    // 1. Check persistent cache (Secure Storage)
    final cachedId = await _storage.read(key: _deviceIdKey);
    if (cachedId != null) return cachedId;

    // 2. If not exist, generate a stable-ish ID based on hardware info
    String baseId = 'posify';
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      // Using combination of several hardware IDs to be more persistent
      baseId = '${androidInfo.brand}-${androidInfo.model}-${androidInfo.id}';
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      baseId = iosInfo.identifierForVendor ?? 'IOS-UNKNOWN';
    }

    // Hash it to make it uniform + adding some dynamic salt
    final salt = DateTime.now().millisecondsSinceEpoch.toString();
    final hashedId = sha256.convert(utf8.encode('${salt}_$baseId')).toString();
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
    final license = await db.getLocalLicense();

    if (license != null) {
      final currentDeviceId = await _getDeviceId();
      final now = DateTime.now();

      // 0. Time Manipulation Check
      final lastServerTimeString = await _storage.read(key: _serverTimeKey);
      if (lastServerTimeString != null) {
        final lastServerTime = DateTime.tryParse(lastServerTimeString);
        // If current device time is BEFORE the last known verified time, clock was manipulated backwards.
        if (lastServerTime != null && now.isBefore(lastServerTime)) {
          await db.deleteLicense(license.licenseCode);
          return null;
        }
      }

      // 1. Lazy Fingerprint Validation
      // If mismatch, we STILL allow entry but trigger background verification.
      // This solves the 'kicked out' issue if Build.ID changes slightly.
      if (license.deviceFingerprint != currentDeviceId) {
        _verifyWithServer(license.licenseCode, currentDeviceId);
        // We don't return null here yet. Let the user use the app.
        // If server says NO later, then we'll invalidate state.
      }

      // 2. 7-Day Hard Offline Block - This is a business rule, we keep it.
      final lastCheck = license.lastVerified ?? license.activationDate ?? now;
      final diff = now.difference(lastCheck);

      if (diff.inDays >= 7) {
        // Return null triggers the activation screen (Lock Mode) if expired.
        // Background verification must update lastVerified to reset this.
        _verifyWithServer(license.licenseCode, currentDeviceId);
        return null;
      }

      // 3. Heartbeat Validation (Every 24h background check)
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
          (data is Map &&
              data['data'] is Map &&
              data['data']['is_active'] == true);

      if (isSuccess) {
        // Success! Update local timestamp AND ensure fingerprint is synced locally
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        await db.updateLicenseFingerprint(code, deviceId);
      } else {
        // Verification failed. Could be a fingerprint mismatch after emulator update.
        // Try a "Silent Re-activation" instead of immediate deletion.
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
          // Silent re-activation worked! Update local DB with new fingerprint.
          await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
          await db.updateLicenseFingerprint(code, deviceId);
        } else {
          // Truly invalid or device limit reached.
          await db.deleteLicense(code);
          ref.invalidateSelf();
        }
      }
    } catch (e) {
      // Offline-First: Keep local state if server unreachable
      // Network Blackhole Exploit Mitigation
      try {
        // Cek koneksi ke server stabil (tanpa memicu request yang berat)
        await dio.head('https://1.1.1.1', options: Options(receiveTimeout: const Duration(seconds: 3)));
        // Jika kode sampai sini, berarti ada internet AKTIF namun `/verify` sengaja diblokir / mati.
        throw Exception('Akses API terblokir. Harap periksa jaringan / matikan VPN.');
      } catch (_) {
        // Jika ping ke 1.1.1.1 juga Error/Timeout = perangkat ini benar-benar OFFLINE murni.
        // Kita izinkan grace-period lisensi berjalan normal.
      }
    }
  }


  Future<(bool, String?)> activate(String code) async {
    // NOTE: Do NOT set state = AsyncValue.loading() here.
    // AppBootstrap watches licenseProvider, so setting loading state would
    // cause it to rebuild a fresh LicenseActivationScreen (unmounting the
    // current one) → setState would never run → error message never shows.
    // Loading state is handled locally in the screen via _isLoading flag.
    final db = ref.read(databaseProvider);
    final dio = ref.read(dioProvider);

    try {
      final deviceId = await _getDeviceId();
      final model = await _getDeviceModel();

      // 1. Call Backend Go API
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
        // Save the server time
        await _storage.write(key: _serverTimeKey, value: DateTime.now().toIso8601String());
        
        // 2. Clear existing licenses first to avoid UNIQUE constraint violation on licenseCode
        // This is a robust approach for a Single-License POS application.
        await (db.delete(db.licenses)).go();

        // 3. Save new activation to Local SQLite
        await db.into(db.licenses).insert(
              LicensesCompanion.insert(
                licenseCode: code,
                deviceFingerprint: Value(deviceId),
                activationDate: Value(DateTime.now()),
                status: const Value('active'),
              ),
            );

        // 4. Read back from DB and update state
        final newLicense = await db.getLocalLicense();

        if (ref.mounted) state = AsyncValue.data(newLicense);
        return (true, null);
      }

      final errorMsg = (data is Map)
          ? (data['message']?.toString() ?? 'Aktivasi gagal')
          : 'Aktivasi gagal: Server mengembalikan status ${response.statusCode}';

      // Keep state as data(null) – do NOT set error state.
      // AppBootstrap watches this provider, and setting error would
      // rebuild a fresh LicenseActivationScreen, wiping local error state.
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
      // Keep state as data(null) – avoid triggering AppBootstrap rebuild.
      if (ref.mounted) state = const AsyncValue.data(null);
      return (false, msg);
    } catch (e) {
      if (!ref.mounted) return (false, null);
      // Keep state as data(null) – avoid triggering AppBootstrap rebuild.
      state = const AsyncValue.data(null);
      return (false, e.toString());
    }
  }
}

final licenseProvider = AsyncNotifierProvider<LicenseNotifier, License?>(
  LicenseNotifier.new,
);

class AuthNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<(bool, String?)> registerWithLicense({
    required String email,
    required String password,
    String? licenseCode,
  }) async {
    final dio = ref.read(dioProvider);
    final lNotifier = ref.read(licenseProvider.notifier);

    try {
      final deviceId = await lNotifier._getDeviceId();
      // Call backend
      final response = await dio.post(
        'auth/register-with-license',
        data: {
          'email': email,
          'password': password,
          if (licenseCode != null && licenseCode.isNotEmpty)
            'license_code': licenseCode,
          'device_fingerprint': deviceId,
        },
      );

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          response.statusCode == 201;

      if (isSuccess && data is Map) {
        final resData = data['data'];
        if (resData is Map && resData['license'] != null) {
            // License was activated as part of registration. Hydrate it to DB!
            final db = ref.read(databaseProvider);
            // Save the server time
            await lNotifier._storage.write(
              key: LicenseNotifier._serverTimeKey, 
              value: DateTime.now().toIso8601String()
            );

            // Clear old if any
            await (db.delete(db.licenses)).go();

            // Insert new license snippet
            final lData = resData['license'];
            final tierLevel = lData['tier_level']?.toString();

            await db.into(db.licenses).insert(
              LicensesCompanion.insert(
                licenseCode: licenseCode ?? lData['license_code'] ?? '',
                deviceFingerprint: Value(deviceId),
                activationDate: Value(DateTime.now()),
                status: const Value('active'),
              ),
            );

            // Trigger app reload
            ref.invalidate(licenseProvider);
        }
        return (true, null);
      }

      final errorMsg = (data is Map && data['message'] != null)
          ? data['message']!.toString()
          : 'Registrasi gagal: Status ${response.statusCode}';
      return (false, errorMsg);
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final msg = (e.response!.data as Map)['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
           return (false, msg);
        }
      }
      return (false, 'Network error. Pastikan tersambung internet.');
    } catch (e) {
      return (false, e.toString());
    }
  }
}

final authProvider = AsyncNotifierProvider.autoDispose<AuthNotifier, void>(
  AuthNotifier.new,
);

