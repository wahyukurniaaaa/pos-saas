import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/auth/providers/auth_providers.dart';
import 'package:posify_app/features/auth/providers/device_management_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

class DeviceManagementScreen extends ConsumerStatefulWidget {
  const DeviceManagementScreen({super.key});

  @override
  ConsumerState<DeviceManagementScreen> createState() =>
      _DeviceManagementScreenState();
}

class _DeviceManagementScreenState
    extends ConsumerState<DeviceManagementScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isVerified = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _verifyAndFetch() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final success = await ref
        .read(deviceManagementProvider.notifier)
        .fetchDevices(email);

    if (success && mounted) {
      setState(() {
        _isVerified = true;
      });
    } else if (mounted) {
      final error = ref.read(deviceManagementProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal memverifikasi akun'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _confirmUnbind(LicenseDevice device) async {
    final currentLicense = await ref.read(licenseProvider.future);
    final isCurrentDevice =
        currentLicense?.deviceFingerprint == device.deviceFingerprint;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isCurrentDevice ? 'Lepas Perangkat Ini?' : 'Lepas Perangkat?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isCurrentDevice
              ? 'Anda akan melepas perangkat yang sedang digunakan. Anda harus login ulang (memasukkan kode lisensi) jika ingin menggunakan aplikasi kembali.'
              : 'Perangkat ${device.deviceModel} akan dilepas dari lisensi ini.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performUnbind(device, isCurrentDevice);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: Text(
              'Lepas Perangkat',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performUnbind(
      LicenseDevice device, bool isCurrentDevice) async {
    final email = _emailController.text.trim();
    final success = await ref
        .read(deviceManagementProvider.notifier)
        .unbindDevice(email, device.deviceFingerprint);

    if (success && mounted) {
      if (isCurrentDevice) {
        // Automatically logout and go to activation screen
        ref.read(sessionProvider.notifier).logout();
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/license-activation',
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perangkat berhasil dilepas'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else if (mounted) {
      final error = ref.read(deviceManagementProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Gagal melepas perangkat'),
          backgroundColor: AppTheme.dangerColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceManagementProvider);
    final licenseAsync = ref.watch(licenseProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('Manajemen Perangkat'),
        automaticallyImplyLeading: true,
      ),
      body: licenseAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (license) {
          if (license == null) {
            return const Center(child: Text('Lisensi tidak aktif'));
          }

          return ResponsiveCenter(
            child: !_isVerified
                ? _buildVerificationForm(state, license.licenseCode)
                : _buildDeviceList(state, license.deviceFingerprint!),
          );
        },
      ),
    );
  }

  Widget _buildVerificationForm(DeviceManagementState state, String code) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.shield_rounded,
                size: 80, color: AppTheme.tertiaryColor),
            const SizedBox(height: 24),
            Text(
              'Verifikasi Keamanan',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Masukkan email yang terdaftar untuk lisensi ini guna melihat dan mengelola perangkat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                  fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 32),
            TextFormField(
              initialValue: code,
              readOnly: true,
              style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
              decoration: InputDecoration(
                labelText: 'Kode Lisensi',
                prefixIcon: const Icon(Icons.key_rounded),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              decoration: const InputDecoration(
                labelText: 'Email Pembelian',
                prefixIcon: Icon(Icons.email_rounded),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email wajib diisi';
                }
                if (!value.contains('@')) {
                  return 'Format email tidak valid';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: state.isLoading ? null : _verifyAndFetch,
                child: state.isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3))
                    : const Text('Verifikasi & Lihat Perangkat'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList(DeviceManagementState state, String localDeviceId) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppTheme.infoColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perangkat yang dilepas tidak akan bisa mengakses aplikasi menggunakan lisensi ini.',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: AppTheme.primaryColor))
              : state.devices.isEmpty
                  ? const Center(child: Text('Tidak ada perangkat terhubung'))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.devices.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final device = state.devices[index];
                        final isCurrent =
                            device.deviceFingerprint == localDeviceId;

                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: isCurrent
                                ? Border.all(
                                    color: AppTheme.secondaryColor, width: 2)
                                : Border.all(
                                    color: Colors.grey.shade200, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(16),
                            leading: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundLight,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                device.osVersion.toLowerCase().contains('ios')
                                    ? Icons.phone_iphone_rounded
                                    : Icons.android_rounded,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device.deviceModel,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                ),
                                if (isCurrent)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Perangkat Ini',
                                      style: GoogleFonts.poppins(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'OS: ${device.osVersion}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Diaktifkan: ${device.activationDate}',
                                    style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            trailing: IconButton(
                              onPressed: () => _confirmUnbind(device),
                              icon: const Icon(Icons.link_off_rounded,
                                  color: AppTheme.dangerColor),
                              tooltip: 'Lepas Perangkat',
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
