import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class StoreProfileScreen extends ConsumerStatefulWidget {
  const StoreProfileScreen({super.key});

  @override
  ConsumerState<StoreProfileScreen> createState() => _StoreProfileScreenState();
}

class _StoreProfileScreenState extends ConsumerState<StoreProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _loyaltyConversionController = TextEditingController();
  final _loyaltyValueController = TextEditingController();

  String? _logoUri;
  bool _isLoading = true;
  bool _isSaving = false;
  StoreProfileData? _existingProfile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final db = ref.read(databaseProvider);
      final profile = await db.getStoreProfile();

      if (profile != null) {
        _existingProfile = profile;
        _nameController.text = profile.name;
        _addressController.text = profile.address ?? '';
        _phoneController.text = profile.phone ?? '';
        _loyaltyConversionController.text = profile.loyaltyPointConversion.toString();
        _loyaltyValueController.text = profile.loyaltyPointValue.toString();
        _logoUri = profile.logoUri;
      }
    } catch (e) {
      debugPrint('Error loading store profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _loyaltyConversionController.dispose();
    _loyaltyValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName =
            'logo_${DateTime.now().millisecondsSinceEpoch}${p.extension(pickedFile.path)}';
        final savedImage = await File(
          pickedFile.path,
        ).copy('${appDir.path}/$fileName');

        setState(() {
          _logoUri = savedImage.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengambil gambar: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Sumber Logo',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(width: 24),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);

      if (_existingProfile == null) {
        await db.insertStoreProfile(
          StoreProfileCompanion(
            name: Value(_nameController.text),
            address: Value(
              _addressController.text.isEmpty ? null : _addressController.text,
            ),
            phone: Value(
              _phoneController.text.isEmpty ? null : _phoneController.text,
            ),
            loyaltyPointConversion: Value(int.tryParse(_loyaltyConversionController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10000),
            loyaltyPointValue: Value(int.tryParse(_loyaltyValueController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100),
            logoUri: Value(_logoUri),
          ),
        );
      } else {
        await db.updateStoreProfile(
          _existingProfile!.copyWith(
            name: _nameController.text,
            address: Value(
              _addressController.text.isEmpty ? null : _addressController.text,
            ),
            phone: Value(
              _phoneController.text.isEmpty ? null : _phoneController.text,
            ),
            loyaltyPointConversion: int.tryParse(_loyaltyConversionController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 10000,
            loyaltyPointValue: int.tryParse(_loyaltyValueController.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 100,
            logoUri: Value(_logoUri),
          ),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil toko berhasil disimpan'),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  InputDecoration _inputDecoration(String labelText, String hintText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      prefixIcon: Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.7)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Profil Toko',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ResponsiveCenter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo Section Group
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10, offset: const Offset(0, 4)
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            GestureDetector(
                                onTap: _showImagePicker,
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          width: 4,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: _logoUri != null && _logoUri!.isNotEmpty
                                          ? ClipOval(
                                              child: Image.file(
                                                File(_logoUri!),
                                                fit: BoxFit.cover,
                                              ),
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.storefront_rounded,
                                                  size: 32,
                                                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  'Logo Toko',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme.primaryColor.withValues(alpha: 0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(
                                        color: AppTheme.secondaryColor,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: AppTheme.primaryColor,
                                        size: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Informasi ini akan ditampilkan pada header\ncetak nota / struk pembelanjaan.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                  height: 1.5,
                                ),
                              ),
                          ],
                        )
                      ),
                      
                      const SizedBox(height: 24),

                      // Fields
                      TextFormField(
                        controller: _nameController,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          'Nama Toko *',
                          'Misal: Warung Kopi Posify',
                          Icons.store_mall_directory_rounded,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama toko tidak boleh kosong';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          'Nomor Telepon (Opsional)',
                          'Misal: 08123456789',
                          Icons.phone_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        maxLines: 3,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 14),
                        decoration: _inputDecoration(
                          'Alamat Toko (Opsional)',
                          'Misal: Jl. Raya Posify No. 1, Jakarta',
                          Icons.location_on_rounded,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Loyalty Settings
                      Text(
                        'Pengaturan Poin Pelanggan (Loyalty)',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _loyaltyConversionController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          'Minimum Belanja untuk 1 Poin (Rp)',
                          'Misal: 10000',
                          Icons.monetization_on_rounded,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _loyaltyValueController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                        decoration: _inputDecoration(
                          'Nilai 1 Poin saat ditukar (Rp)',
                          'Misal: 100',
                          Icons.card_giftcard_rounded,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Save Button
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: AppTheme.primaryColor,
                                    strokeWidth: 3,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.save_rounded, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Simpan Pengaturan',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
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
            ),
    );
  }
}
