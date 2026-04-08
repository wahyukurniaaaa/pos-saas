import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

class ChangePinDialog extends ConsumerStatefulWidget {
  final Employee employee;
  final bool isSelfChange;

  const ChangePinDialog({
    super.key,
    required this.employee,
    this.isSelfChange = true,
  });

  @override
  ConsumerState<ChangePinDialog> createState() => _ChangePinDialogState();
}

class _ChangePinDialogState extends ConsumerState<ChangePinDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _isLoading = false;
  bool _showOldPin = false;
  bool _showNewPin = false;
  bool _showConfirmPin = false;

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);

    try {
      // 1. Verify old PIN if it's a self-change
      if (widget.isSelfChange) {
        if (_oldPinController.text != widget.employee.pin) {
          throw 'PIN lama yang Anda masukkan salah';
        }
      }

      // 2. Update the PIN
      await db.updateEmployeePin(widget.employee.id, _newPinController.text);

      if (!mounted) return;
      
      Navigator.pop(context, true); // Success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PIN berhasil diperbarui'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.vpn_key_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isSelfChange ? 'Ubah PIN Saya' : 'Ubah PIN Karyawan',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          widget.isSelfChange 
                            ? 'Amankan akun Anda'
                            : 'Reset PIN untuk ${widget.employee.name}',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    if (widget.isSelfChange) ...[
                      _buildPinField(
                        controller: _oldPinController,
                        label: 'PIN Saat Ini',
                        obscure: !_showOldPin,
                        onToggle: () => setState(() => _showOldPin = !_showOldPin),

                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Masukkan PIN lama';
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                    _buildPinField(
                      controller: _newPinController,
                      label: widget.isSelfChange ? 'PIN Baru' : 'Masukkan PIN Baru',
                      obscure: !_showNewPin,
                      onToggle: () => setState(() => _showNewPin = !_showNewPin),
                      validator: (v) {
                        if (v == null || v.length != 6) return 'PIN harus 6 digit';
                        if (widget.isSelfChange && v == _oldPinController.text) {
                          return 'PIN baru tidak boleh sama dengan PIN lama';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildPinField(
                      controller: _confirmPinController,
                      label: 'Konfirmasi PIN Baru',
                      obscure: !_showConfirmPin,
                      onToggle: () => setState(() => _showConfirmPin = !_showConfirmPin),
                      validator: (v) {
                        if (v != _newPinController.text) return 'PIN tidak cocok';
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                children: [
                   Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondaryColor,
                        foregroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.primaryColor,
                              ),
                            )
                          : Text(
                              'Simpan PIN',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPinField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: TextInputType.number,
      maxLength: 6,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w800,
        letterSpacing: 8,
        fontSize: 18,
        color: AppTheme.textPrimary,
      ),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        counterText: '',
        labelStyle: GoogleFonts.poppins(
          fontWeight: FontWeight.w500,
          color: AppTheme.textSecondary,
          letterSpacing: 0,
          fontSize: 14,
        ),
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
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(
            obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }
}
