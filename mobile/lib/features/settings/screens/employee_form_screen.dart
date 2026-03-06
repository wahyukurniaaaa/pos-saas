import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:drift/drift.dart' hide Column;

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
    {'value': 'inactive', 'label': 'Nonaktif'},
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
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Karyawan' : 'Tambah Karyawan Baru',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Photo placeholder
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withValues(
                      alpha: 0.1,
                    ),
                    child: const Icon(
                      Icons.person,
                      size: 50,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Name
            _buildLabel('👤 Nama Karyawan'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: _inputDecoration('Masukkan nama karyawan'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
            ),
            const SizedBox(height: 20),

            // Role
            _buildLabel('🎖️ Level Akses (Role)'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: _inputDecoration(''),
              items: _roles.map((r) {
                return DropdownMenuItem(
                  value: r['value'],
                  child: Text(r['label']!, style: GoogleFonts.inter()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRole = v!),
            ),
            const SizedBox(height: 20),

            // PIN
            _buildLabel('🔐 PIN Login (6 Digit)'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _pinController,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: _inputDecoration('Masukkan 6 digit PIN'),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'PIN wajib diisi';
                if (v.length != 6) return 'PIN harus 6 digit';
                if (int.tryParse(v) == null) return 'PIN harus berupa angka';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Status
            _buildLabel('🛑 Status Akun'),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedStatus,
              decoration: _inputDecoration(''),
              items: _statuses.map((s) {
                return DropdownMenuItem(
                  value: s['value'],
                  child: Text(s['label']!, style: GoogleFonts.inter()),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedStatus = v!),
            ),
            const SizedBox(height: 40),

            // Save button
            ElevatedButton(
              onPressed: _isLoading ? null : _saveEmployee,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      '💾 SIMPAN KARYAWAN',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(color: AppTheme.textSecondary),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
      ),
    );
  }
}
