import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/services/backup_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/auth_providers.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class LicenseActivationScreen extends ConsumerStatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  ConsumerState<LicenseActivationScreen> createState() =>
      _LicenseActivationScreenState();
}

class _LicenseActivationScreenState
    extends ConsumerState<LicenseActivationScreen>
    with SingleTickerProviderStateMixin {
  final _licenseController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastLicense();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveCenter(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryDark,
                AppTheme.primaryColor,
                AppTheme.primaryColor.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Icon
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'POSify',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Lisensi Seumur Hidup',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Card Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 30,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Masukkan Kode Lisensi',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Kode dikirim ke email saat pembelian',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // License Input
                              TextFormField(
                                controller: _licenseController,
                                textCapitalization:
                                    TextCapitalization.characters,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(
                                    RegExp(r'[A-Za-z0-9\-]'),
                                  ),
                                  UpperCaseTextFormatter(),
                                ],
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 1.5,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'POS-L1-XXXXX-XXXXX',
                                  hintStyle: GoogleFonts.jetBrainsMono(
                                    color: AppTheme.textSecondary.withValues(
                                      alpha: 0.4,
                                    ),
                                    fontSize: 16,
                                    letterSpacing: 1.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.vpn_key_rounded,
                                    color: AppTheme.primaryColor,
                                  ),
                                  filled: true,
                                  fillColor: AppTheme.scaffoldBg,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: AppTheme.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Kode lisensi wajib diisi';
                                  }
                                  if (value.length < 10) {
                                    return 'Format kode lisensi tidak valid';
                                  }
                                  return null;
                                },
                              ),
                                if (_errorMessage != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          AppTheme.errorColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppTheme.errorColor.withValues(
                                          alpha: 0.3,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.error_outline_rounded,
                                          color: AppTheme.errorColor,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: GoogleFonts.inter(
                                              fontSize: 13,
                                              color: AppTheme.errorColor,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),

                              // Activate Button
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading
                                      ? null
                                      : _activateLicense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(
                                              Icons.verified_user_rounded,
                                              size: 20,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'AKTIFKAN PERANGKAT INI',
                                              style: GoogleFonts.inter(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Restore Option
                      TextButton.icon(
                        onPressed: _isLoading ? null : _handleRestore,
                        icon: const Icon(Icons.settings_backup_restore_rounded),
                        label: const Text(
                          'Sudah punya backup? Pulihkan di sini',
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Info Text
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.wifi_rounded,
                                size: 16,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Butuh internet saat Aktivasi & Verifikasi (7 hari)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.7),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Maksimal offline 7 hari sebelum verifikasi ulang',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: Colors.white.withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _activateLicense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ref
        .read(licenseProvider.notifier)
        .activate(_licenseController.text.trim());

    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = result.$1;
    final String? serverError = result.$2;

    debugPrint('Activation Success: $success');
    debugPrint('Activation Error: $serverError');

    if (success) {
      // AppBootstrap akan otomatis navigate ke screen berikutnya
      return;
    } else {
      final msg = serverError ?? 'Aktivasi gagal. Periksa kode atau koneksi Anda.';

      setState(() => _errorMessage = msg);

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(child: Text(msg)),
            ],
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _handleRestore() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final keyController = TextEditingController();

    if (!mounted) return;

    final recoveryKey = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan Kunci Pemulihan (Recovery Key) dari HP lama untuk membuka file backup ini.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Recovery Key',
                border: OutlineInputBorder(),
                hintText: 'Masukkan kunci base64...',
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, keyController.text),
            child: const Text('Mulai Restore'),
          ),
        ],
      ),
    );

    if (recoveryKey == null || recoveryKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await BackupService().importAndRestore(file, recoveryKey);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Data Berhasil Dipulihkan'),
          content: const Text(
            'Data dari HP lama berhasil masuk. Aplikasi akan ditutup. Silakan buka kembali untuk me-load data Anda.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => exit(0),
              child: const Text('Tutup Aplikasi'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal: Pastikan Kunci Pemulihan benar.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadLastLicense() async {
    // We can't use ref here easily if it's not a ConsumerState,
    // but it is a ConsumerState, so we can use ref.read
    final db = ref.read(databaseProvider);
    final license = await db.getLocalLicense();
    if (license != null && mounted) {
      _licenseController.text = license.licenseCode;
    }
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
