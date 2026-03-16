import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:posify_app/core/widgets/responsive_layout.dart';

class EmployeeFormScreen extends ConsumerStatefulWidget {
  final Employee? employee;

  const EmployeeFormScreen({super.key, this.employee});

  @override
  ConsumerState<EmployeeFormScreen> createState() => _EmployeeFormScreenState();
}

class _EmployeeFormScreenState extends ConsumerState<EmployeeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  String _selectedRole = 'cashier';
  String _selectedStatus = 'active';
  bool _isLoading = false;

  bool get _isEditing => widget.employee != null;

  final _roles = [
    {'value': 'owner', 'label': 'Owner (Level 1)'},
    {'value': 'supervisor', 'label': 'Supervisor (Level 2)'},
    {'value': 'cashier', 'label': 'Kasir (Level 3)'},
  ];

  final _statuses = [
    {'value': 'active', 'label': 'Aktif (Bisa Login)'},
    {'value': 'inactive', 'label': 'Nonaktif (Diblokir)'},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      _nameController.text = widget.employee!.name;
      _pinController.text = widget.employee!.pin;
      _selectedRole = widget.employee!.role;
      _selectedStatus = widget.employee!.status;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _saveEmployee() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = ref.read(databaseProvider);
    final name = _nameController.text.trim();
    final pin = _pinController.text.trim();

    try {
      if (_isEditing) {
        await db.updateEmployee(
          widget.employee!.copyWith(
            name: name,
            pin: pin,
            role: _selectedRole,
            status: _selectedStatus,
          ),
        );
      } else {
        await db.insertEmployee(
          EmployeesCompanion.insert(
            name: name,
            pin: pin,
            role: _selectedRole,
            status: Value(_selectedStatus),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Karyawan berhasil disimpan'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('UNIQUE')
                ? 'PIN sudah digunakan oleh karyawan lain'
                : 'Gagal menyimpan: ${e.toString()}',
          ),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
           _isEditing ? 'Edit Karyawan' : 'Tambah Karyawan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: ResponsiveCenter(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              // Photo placeholder
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.2),
                          width: 4,
                        ),
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        size: 48,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppTheme.primaryColor,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // Fields Area
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('DATA DIRI'),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      decoration: _inputDecoration('Nama Lengkap', 'Misal: Budi Santoso', Icons.badge_rounded),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('AKSES & KEAMANAN'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _inputDecoration('Level Akses', '', Icons.security_rounded),
                      items: _roles.map((r) {
                        return DropdownMenuItem(
                          value: r['value'],
                          child: Text(
                            r['label']!, 
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600)
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedRole = v!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _pinController,
                      obscureText: true,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, letterSpacing: 4),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: _inputDecoration('PIN Login', 'Masukkan 6 digit angka', Icons.dialpad_rounded).copyWith(
                        counterText: "",
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'PIN wajib diisi';
                        final pin = v.trim();
                        if (pin.length != 6) {
                          return 'PIN harus tepat 6 digit';
                        }
                        if (int.tryParse(pin) == null) {
                          return 'PIN harus berupa angka';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    _buildLabel('STATUS AKUN'),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: _inputDecoration('Status', '', Icons.power_settings_new_rounded),
                      items: _statuses.map((s) {
                        return DropdownMenuItem(
                          value: s['value'],
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: s['value'] == 'active' ? AppTheme.successColor : AppTheme.errorColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                s['label']!, 
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: s['value'] == 'active' ? AppTheme.textPrimary : AppTheme.errorColor,
                                )
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveEmployee,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Simpan Karyawan',
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
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
        color: AppTheme.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  InputDecoration _inputDecoration(String labelText, String hintText, IconData icon) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, letterSpacing: 0),
      filled: true,
      fillColor: Colors.grey.shade50,
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
}
