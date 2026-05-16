import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../providers/auth_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class UnifiedRegistrationScreen extends ConsumerStatefulWidget {
  const UnifiedRegistrationScreen({super.key});

  @override
  ConsumerState<UnifiedRegistrationScreen> createState() =>
      _UnifiedRegistrationScreenState();
}

class _UnifiedRegistrationScreenState extends ConsumerState<UnifiedRegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _storeNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;
  String? _selectedBusinessType;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
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
    _emailController.dispose();
    _passwordController.dispose();
    _storeNameController.dispose();
    _phoneController.dispose();
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
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo Icon
                      // Lumio Logo
                      Image.asset(
                        'assets/branding/lumio_logo_wordmark_white.png',
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 24),

                      Text(
                        'Buat Akun Lumio',
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Daftar akun untuk mencoba Lumio POS',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Card Form
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardTheme.color,
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
                              // Email Input
                              _buildLabel('Alamat Email'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: GoogleFonts.poppins(fontSize: 15),
                                decoration: _inputDecoration(
                                  hint: 'email@anda.com',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Email wajib diisi';
                                  if (!value.contains('@')) return 'Email tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Password Input
                              _buildLabel('Password Baru'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: GoogleFonts.poppins(fontSize: 15),
                                decoration: _inputDecoration(
                                  hint: 'Minimal 6 karakter',
                                  icon: Icons.lock_outline_rounded,
                                ).copyWith(
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: AppTheme.textSecondary.withValues(alpha: 0.6),
                                    ),
                                    onPressed: () {
                                      setState(() => _obscurePassword = !_obscurePassword);
                                    },
                                    splashRadius: 20,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Password wajib diisi';
                                  if (value.length < 6) return 'Password min. 6 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Nama Toko Input
                              _buildLabel('Nama Toko / Usaha'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _storeNameController,
                                keyboardType: TextInputType.text,
                                style: GoogleFonts.poppins(fontSize: 15),
                                decoration: _inputDecoration(
                                  hint: 'Kopi Nusantara, Warung Maju, dll.',
                                  icon: Icons.storefront_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Nama toko wajib diisi';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // No WhatsApp Input
                              _buildLabel('Nomor WhatsApp Aktif'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                style: GoogleFonts.poppins(fontSize: 15),
                                decoration: _inputDecoration(
                                  hint: '08xxxxxxxxxx',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Nomor WA wajib diisi';
                                  if (value.length < 9) return 'Nomor WA tidak valid';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // Kategori Usaha Dropdown
                              _buildLabel('Kategori Usaha'),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _selectedBusinessType,
                                hint: Text(
                                  'Pilih kategori usaha...',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.textSecondary.withValues(alpha: 0.4),
                                    fontSize: 14,
                                  ),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'fnb', child: Text('F&B (Makanan & Minuman)')),
                                  DropdownMenuItem(value: 'retail', child: Text('Retail / Toko')),
                                  DropdownMenuItem(value: 'jasa', child: Text('Jasa / Layanan')),
                                  DropdownMenuItem(value: 'lainnya', child: Text('Lainnya')),
                                ],
                                style: GoogleFonts.poppins(fontSize: 14),
                                decoration: InputDecoration(
                                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
                                  filled: true,
                                  fillColor: Theme.of(context).inputDecorationTheme.fillColor,
                                  contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                                onChanged: (val) => setState(() => _selectedBusinessType = val),
                              ),
                              const SizedBox(height: 16),
                              
                              if (_errorMessage != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.errorColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.error_outline_rounded, color: AppTheme.errorColor, size: 20),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: GoogleFonts.poppins(
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
                              
                              const SizedBox(height: 28),

                              // Submit Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _register,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                      : Text(
                                          'DAFTAR & LANJUTKAN',
                                          style: GoogleFonts.poppins(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).textTheme.titleMedium?.color?.withValues(alpha: 0.8),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        color: AppTheme.textSecondary.withValues(alpha: 0.4),
        fontSize: 14,
      ),
      prefixIcon: Icon(icon, color: AppTheme.primaryColor.withValues(alpha: 0.8)),
      filled: true,
      fillColor: Theme.of(context).inputDecorationTheme.fillColor,
      contentPadding: const EdgeInsets.symmetric(vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final storeName = _storeNameController.text.trim();
    final phone = _phoneController.text.trim();
    final businessType = _selectedBusinessType ?? 'lainnya';

    final result = await ref.read(authProvider.notifier).signUp(
      email: email,
      password: password,
      data: {
        'store_name': storeName,
        'phone': phone,
        'business_type': businessType,
      },
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final success = result.$1;
    final serverError = result.$2;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrasi sukses! Silakan cek email untuk verifikasi akun.'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      setState(() => _errorMessage = serverError ?? 'Gagal menghubungi server.');
    }
  }
}
