import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../providers/owner_provider.dart';

class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
            stops: [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    const Icon(
                      Icons.store_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Pengaturan Pemilik & Toko',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lengkapi data untuk memulai',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),

              // Form Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppTheme.scaffoldBg,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionLabel('👤', 'Nama Pemilik'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Bapak Budi',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Nama wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel('🏪', 'Nama Toko'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _storeNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              hintText: 'Contoh: Toko Budi Jaya',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Nama toko wajib diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          _buildSectionLabel('🔒', 'Buat PIN Akses (6 Digit)'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _pinController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: _obscurePin,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: '• • • • • •',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePin
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => _obscurePin = !_obscurePin),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.length != 6) {
                                return 'PIN harus 6 digit';
                              }
                              if (v == '123456' || v == '000000') {
                                return 'Pola PIN terlalu umum';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          _buildSectionLabel('🔒', 'Konfirmasi PIN'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _confirmPinController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            obscureText: _obscureConfirm,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 18,
                              letterSpacing: 8,
                            ),
                            decoration: InputDecoration(
                              hintText: '• • • • • •',
                              counterText: '',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v != _pinController.text) {
                                return 'PIN tidak cocok';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 32),

                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveOwnerSetup,
                              icon: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.rocket_launch_rounded,
                                      size: 20,
                                    ),
                              label: Text(
                                _isLoading
                                    ? 'MENYIMPAN...'
                                    : 'MULAI GUNAKAN POSIFY',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String emoji, String label) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _saveOwnerSetup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final success = await ref
        .read(ownerProvider.notifier)
        .setupOwner(
          name: _nameController.text.trim(),
          storeName: _storeNameController.text.trim(),
          pin: _pinController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/pin-login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan data. Coba lagi.'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
