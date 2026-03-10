import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/dio_provider.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Notifier for license activation and status check.
class LicenseNotifier extends AsyncNotifier<License?> {
  final _deviceInfo = DeviceInfoPlugin();
  final _storage = const FlutterSecureStorage();
  static const String _deviceIdKey = 'posify_device_id_stable';

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

    // Hash it to make it uniform + adding some salt
    final hashedId = sha256.convert(utf8.encode('salt_$baseId')).toString();
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

      // 1. Lazy Fingerprint Validation
      // If mismatch, we STILL allow entry but trigger background verification.
      // This solves the 'kicked out' issue if Build.ID changes slightly.
      if (license.deviceFingerprint != currentDeviceId) {
        _verifyWithServer(license.licenseCode, currentDeviceId);
        // We don't return null here yet. Let the user use the app.
        // If server says NO later, then we'll invalidate state.
      }

      // 2. 7-Day Hard Offline Block - This is a business rule, we keep it.
      final now = DateTime.now();
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
        '/license/verify',
        data: {'license_code': code, 'device_fingerprint': deviceId},
      );

      if (response.data['status'] == 'success' &&
          response.data['data'] != null &&
          response.data['data']['is_active'] == true) {
        // Success! Update local timestamp
        await db.updateLicenseVerification(code);
      } else {
        // License is no longer valid for this device!
        await db.deleteLicense(code);
        ref.invalidateSelf();
      }
    } catch (e) {
      // Offline-First: Keep local state if server unreachable
    }
  }

  Future<bool> activate(String code) async {
    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);
    final dio = ref.read(dioProvider);

    try {
      final deviceId = await _getDeviceId();
      final model = await _getDeviceModel();

      // 1. Call Backend Go API
      final response = await dio.post(
        '/license/activate',
        data: {
          'license_code': code,
          'device_fingerprint': deviceId,
          'device_model': model,
          'os_version': Platform.operatingSystemVersion,
        },
      );

      if (!ref.mounted) return false;

      if (response.data['status'] == 'success') {
        // 2. Save to Local SQLite
        try {
          await db.insertLicense(
            LicensesCompanion.insert(
              licenseCode: code,
              deviceFingerprint: Value(deviceId),
              activationDate: Value(DateTime.now()),
              status: const Value('active'),
            ),
          );
        } catch (insertErr) {
          // Duplicate license code — already exists in local DB, continue
        }

        // 3. Read back dari DB dan update state
        final newLicense = await db.getLocalLicense();
        if (ref.mounted) state = AsyncValue.data(newLicense);
        return true;
      }

      state = AsyncValue.error(
        response.data['message'] ?? 'Aktivasi gagal',
        StackTrace.current,
      );
      return false;
    } on DioException catch (e) {
      if (!ref.mounted) return false;
      final msg = e.response?.data?['message'] ?? 'Gagal menghubungi server';
      state = AsyncValue.error(msg, StackTrace.current);
      return false;
    } catch (e, st) {
      if (!ref.mounted) return false;
      state = AsyncValue.error(e.toString(), st);
      return false;
    }
  }
}

final licenseProvider = AsyncNotifierProvider<LicenseNotifier, License?>(
  LicenseNotifier.new,
);
