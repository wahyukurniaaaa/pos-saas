import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/core/providers/dio_provider.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';

// Model to represent a device from backend
class LicenseDevice {
  final String deviceFingerprint;
  final String deviceModel;
  final String osVersion;
  final String activationDate;

  LicenseDevice({
    required this.deviceFingerprint,
    required this.deviceModel,
    required this.osVersion,
    required this.activationDate,
  });

  factory LicenseDevice.fromJson(Map<String, dynamic> json) {
    return LicenseDevice(
      deviceFingerprint: json['device_fingerprint'] ?? '',
      deviceModel: json['device_model'] ?? 'Unknown',
      osVersion: json['os_version'] ?? 'Unknown',
      activationDate: json['activation_date'] ?? '',
    );
  }
}

// State class for device management screen
class DeviceManagementState {
  final bool isLoading;
  final String? error;
  final List<LicenseDevice> devices;

  DeviceManagementState({
    this.isLoading = false,
    this.error,
    this.devices = const [],
  });

  DeviceManagementState copyWith({
    bool? isLoading,
    String? error,
    List<LicenseDevice>? devices,
    bool clearError = false,
  }) {
    return DeviceManagementState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      devices: devices ?? this.devices,
    );
  }
}

// Provider for managing device fetch and unbind
final deviceManagementProvider =
    NotifierProvider<DeviceManagementNotifier, DeviceManagementState>(
  DeviceManagementNotifier.new,
);

class DeviceManagementNotifier extends Notifier<DeviceManagementState> {
  @override
  DeviceManagementState build() {
    return DeviceManagementState();
  }

  Future<bool> fetchDevices(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final licenseAsync = ref.read(licenseProvider);
      final license = licenseAsync.value;
      if (license == null) {
        state = state.copyWith(
            isLoading: false, error: "Lisensi tidak ditemukan.");
        return false;
      }

      final dio = ref.read(dioProvider);
      final response = await dio.post(
        'license/devices',
        data: {
          'license_code': license.licenseCode,
          'customer_email': email,
        },
      );

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          (data is Map && data['success'] == true) ||
          response.statusCode == 200;

      if (isSuccess && data is Map && data['data'] != null) {
        final List<dynamic> devicesData = data['data'];
        final devices = devicesData
            .map((e) => LicenseDevice.fromJson(e as Map<String, dynamic>))
            .toList();

        state = state.copyWith(isLoading: false, devices: devices);
        return true;
      }

      final errorMsg = (data is Map)
          ? (data['message']?.toString() ?? 'Gagal mengambil daftar perangkat')
          : 'Server mengembalikan status ${response.statusCode}';
          
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;

    } on DioException catch (e) {
      String msg = 'Gagal menghubungi server';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Terjadi kesalahan: $e");
      return false;
    }
  }

  Future<bool> unbindDevice(String email, String fingerprint) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final licenseAsync = ref.read(licenseProvider);
      final license = licenseAsync.value;
      if (license == null) {
        state = state.copyWith(
            isLoading: false, error: "Lisensi tidak ditemukan.");
        return false;
      }

      final dio = ref.read(dioProvider);
      final response = await dio.post(
        'license/reset',
        data: {
          'license_code': license.licenseCode,
          'customer_email': email,
          'device_fingerprint': fingerprint,
        },
      );

      final data = response.data;
      final isSuccess = (data is Map && data['status'] == 'success') ||
          (data is Map && data['success'] == true) ||
          response.statusCode == 200;

      if (isSuccess) {
        // Refetch to get updated list
        await fetchDevices(email);
        return true;
      }

      final errorMsg = (data is Map)
          ? (data['message']?.toString() ?? 'Gagal melepas perangkat')
          : 'Server mengembalikan status ${response.statusCode}';
          
      state = state.copyWith(isLoading: false, error: errorMsg);
      return false;

    } on DioException catch (e) {
      String msg = 'Gagal menghubungi server';
      if (e.response?.data is Map && e.response?.data['message'] != null) {
        msg = e.response?.data['message'].toString() ?? msg;
      }
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: "Terjadi kesalahan: $e");
      return false;
    }
  }
}
