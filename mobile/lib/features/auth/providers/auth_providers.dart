import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/dio_provider.dart';
import 'package:posify_app/core/database/database.dart';

/// Notifier for license activation and status check.
/// Uses non-autoDispose so license state persists throughout app lifecycle.
class LicenseNotifier extends AsyncNotifier<License?> {
  @override
  Future<License?> build() async {
    final db = ref.watch(databaseProvider);
    return db.getLocalLicense();
  }

  Future<bool> activate(String code) async {
    state = const AsyncValue.loading();
    final db = ref.read(databaseProvider);
    final dio = ref.read(dioProvider);

    try {
      final deviceId = 'DEVICE-${DateTime.now().millisecondsSinceEpoch}';

      // 1. Call Backend Go API
      final response = await dio.post(
        '/license/activate',
        data: {'license_code': code, 'device_fingerprint': deviceId},
      );

      // Check if provider is still mounted after async operation
      if (!ref.mounted) return false;

      if (response.data['status'] == 'success') {
        // 2. Save to Local SQLite
        await db.insertLicense(
          LicensesCompanion.insert(
            licenseCode: code,
            deviceFingerprint: Value(deviceId),
            activationDate: Value(DateTime.now()),
            status: const Value('active'),
          ),
        );

        // 3. Refresh state
        ref.invalidateSelf();
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
