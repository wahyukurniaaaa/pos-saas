import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/dio_provider.dart';
import 'package:posify_app/core/database/database.dart';

/// Notifier for license activation and status check.
class LicenseNotifier extends AsyncNotifier<License?> {
  final _deviceInfo = DeviceInfoPlugin();

  Future<String> _getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id; // Unique ID for Android
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'UNKNOWN-IOS';
    }
    return 'UNKNOWN-DEVICE';
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

      // 1. Local Fingerprint Validation (Migration Check)
      if (license.deviceFingerprint != currentDeviceId) {
        // Device mismatch detected. Verification required.
        // Since it's a new device, we don't allow access until activated/verified.
        return null;
      }

      // 2. 7-Day Hard Offline Block
      final now = DateTime.now();
      final lastCheck = license.lastVerified ?? license.activationDate ?? now;
      final diff = now.difference(lastCheck);

      if (diff.inDays >= 7) {
        // 7 days without any successful verification. Hard block access.
        // Returning null triggers the activation screen (Lock Mode).
        return null;
      }

      // 3. 24-Hour Heartbeat Validation (Background check if online)
      // If 24 hours have passed, trigger a background verification
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
