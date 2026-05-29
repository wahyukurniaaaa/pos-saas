import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumio/core/theme/app_theme.dart';
import '../providers/owner_provider.dart';
import 'package:lumio/core/widgets/responsive_layout.dart';

class OwnerSetupScreen extends ConsumerStatefulWidget {
  const OwnerSetupScreen({super.key});

  @override
  ConsumerState<OwnerSetupScreen> createState() => _OwnerSetupScreenState();
}

class _OwnerSetupScreenState extends ConsumerState<OwnerSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _outletNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  bool _initialized = false;
  int _currentStep = 0;

  @override
  void dispose() {
    _nameController.dispose();
    _storeNameController.dispose();
    _outletNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Widget _buildStepIndicator(bool isStoreProfileExists) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Langkah 1: Toko
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: isStoreProfileExists || _currentStep > 0
                    ? Colors.green.shade600
                    : (_currentStep == 0 ? AppTheme.primaryColor : Colors.grey.shade300),
                child: Icon(
                  isStoreProfileExists || _currentStep > 0
                      ? Icons.check_rounded
                      : Icons.store_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '1. Setup Toko',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: _currentStep == 0 ? FontWeight.w600 : FontWeight.normal,
                  color: _currentStep == 0
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          // Garis Penghubung
          Container(
            width: 50,
            height: 2,
            margin: const EdgeInsets.only(bottom: 18, left: 8, right: 8),
            color: isStoreProfileExists || _currentStep >= 1
                ? AppTheme.primaryColor
                : Colors.grey.shade300,
          ),
          // Langkah 2: Pemilik
          Column(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: _currentStep == 1
                    ? AppTheme.primaryColor
                    : Colors.grey.shade300,
                child: const Icon(
                  Icons.person_rounded,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '2. Setup Pemilik',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: _currentStep == 1 ? FontWeight.w600 : FontWeight.normal,
                  color: _currentStep == 1
                      ? AppTheme.primaryColor
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final storeProfileAsync = ref.watch(storeProfileProvider);
    final storeProfile = storeProfileAsync.value;

    // Jika storeProfile sudah ada dari cloud/sync, langsung lompat ke setup owner (Langkah 2)
    if (!_initialized) {
      if (storeProfile != null) {
        _currentStep = 1;
      }
      _initialized = true;
    }

    return Scaffold(
      body: ResponsiveCenter(
        child: Container(
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
                // Header Premium
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Column(
                    children: [
                      Icon(
                        storeProfile != null ? Icons.person_add_rounded : Icons.store_rounded,
                        size: 44,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        storeProfile != null
                            ? 'Lengkapi Data Pemilik'
                            : 'Pengaturan Toko & Pemilik',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        storeProfile != null
                            ? 'Atur profil pemilik untuk toko ${storeProfile.name}'
                            : 'Lengkapi data di bawah untuk mulai beroperasi',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),

                // Form Card
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hanya tampilkan step indicator jika storeProfile belum ada
                            if (storeProfile == null) ...[
                              _buildStepIndicator(false),
                              const SizedBox(height: 16),
                            ] else ...[
                              _buildStepIndicator(true),
                              const SizedBox(height: 16),
                            ],

                            if (_currentStep == 0) ...[
                              // LANGKAH 1: Setup Toko & Outlet
                              _buildSectionLabel('🏪', 'Nama Toko (Usaha)'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _storeNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: Kopi Senja',
                                ),
                                validator: (v) {
                                  if (_currentStep == 0 && (v == null || v.isEmpty)) {
                                    return 'Nama toko wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildSectionLabel('📍', 'Nama Outlet Pertama'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _outletNameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: Cabang Utama',
                                ),
                                validator: (v) {
                                  if (_currentStep == 0 && (v == null || v.isEmpty)) {
                                    return 'Nama outlet wajib diisi';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    if (_formKey.currentState!.validate()) {
                                      setState(() => _currentStep = 1);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'LANJUT SETUP PEMILIK',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.arrow_forward_rounded, size: 18),
                                    ],
                                  ),
                                ),
                              ),
                            ] else ...[
                              // LANGKAH 2: Setup Pemilik & PIN
                              _buildSectionLabel('👤', 'Nama Pemilik'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: const InputDecoration(
                                  hintText: 'Contoh: Bapak Budi',
                                ),
                                validator: (v) {
                                  if (_currentStep == 1 && (v == null || v.isEmpty)) {
                                    return 'Nama wajib diisi';
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
                                  if (_currentStep == 1) {
                                    if (v == null || v.length != 6) {
                                      return 'PIN harus 6 digit';
                                    }
                                    if (v == '123456' || v == '000000') {
                                      return 'Pola PIN terlalu umum';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),

                              _buildSectionLabel('🔒', 'Konfirmasi PIN Akses'),
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
                                  if (_currentStep == 1) {
                                    if (v != _pinController.text) {
                                      return 'PIN tidak cocok';
                                    }
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton.icon(
                                  onPressed: _isLoading
                                      ? null
                                      : () {
                                          HapticFeedback.lightImpact();
                                          _saveOwnerSetup(storeProfile != null);
                                        },
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
                                    _isLoading ? 'MENYIMPAN...' : 'MULAI GUNAKAN LUMIO',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 2,
                                  ),
                                ),
                              ),

                              // Tombol Kembali (hanya tampil jika storeProfile belum ada)
                              if (storeProfile == null) ...[
                                const SizedBox(height: 16),
                                Center(
                                  child: TextButton.icon(
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      setState(() => _currentStep = 0);
                                    },
                                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                                    label: Text(
                                      'Kembali ke Setup Toko',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.grey.shade600,
                                    ),
                                  ),
                                ),
                              ],
                            ],
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
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleSmall?.color,
          ),
        ),
      ],
    );
  }

  Future<void> _saveOwnerSetup(bool onlySetupOwner) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    bool success;
    if (onlySetupOwner) {
      success = await ref.read(ownerProvider.notifier).setupOwnerOnly(
            name: _nameController.text.trim(),
            pin: _pinController.text.trim(),
          );
    } else {
      success = await ref.read(ownerProvider.notifier).setupOwner(
            name: _nameController.text.trim(),
            storeName: _storeNameController.text.trim(),
            outletName: _outletNameController.text.trim(),
            pin: _pinController.text.trim(),
          );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, '/employee-selection');
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
