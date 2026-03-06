import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/providers/database_provider.dart';

class SupervisorAuthDialog extends ConsumerStatefulWidget {
  final String actionDescription;

  const SupervisorAuthDialog({super.key, required this.actionDescription});

  static Future<bool> show(
    BuildContext context, {
    required String actionDescription,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          SupervisorAuthDialog(actionDescription: actionDescription),
    );
    return result ?? false;
  }

  @override
  ConsumerState<SupervisorAuthDialog> createState() =>
      _SupervisorAuthDialogState();
}

class _SupervisorAuthDialogState extends ConsumerState<SupervisorAuthDialog> {
  final List<String> _pin = [];
  String? _errorMessage;
  bool _isVerifying = false;

  void _onKeyPress(String key) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin.add(key);
      _errorMessage = null;
    });
    if (_pin.length == 6) _verifyPin();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin.removeLast();
      _errorMessage = null;
    });
  }

  Future<void> _verifyPin() async {
    setState(() => _isVerifying = true);
    final db = ref.read(databaseProvider);
    final pin = _pin.join();

    final employee = await db.getEmployeeByPin(pin);

    if (!mounted) return;

    if (employee == null) {
      setState(() {
        _errorMessage = 'PIN tidak ditemukan';
        _pin.clear();
        _isVerifying = false;
      });
      return;
    }

    if (employee.role != 'owner' && employee.role != 'supervisor') {
      setState(() {
        _errorMessage = 'Hanya Owner / Supervisor yang boleh mengotorisasi';
        _pin.clear();
        _isVerifying = false;
      });
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.security_rounded,
                color: Colors.orange,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Otorisasi Supervisor',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.actionDescription,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),

            // PIN dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (i) {
                final filled = i < _pin.length;
                return Container(
                  width: 16,
                  height: 16,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: filled ? AppTheme.primaryColor : Colors.transparent,
                    border: Border.all(
                      color: filled
                          ? AppTheme.primaryColor
                          : AppTheme.borderColor,
                      width: 2,
                    ),
                  ),
                );
              }),
            ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                style: GoogleFonts.inter(
                  color: AppTheme.errorColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Numpad
            if (_isVerifying)
              const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )
            else
              _buildNumpad(),

            const SizedBox(height: 16),

            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.inter(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return SizedBox(
      width: 240,
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.5,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ...[1, 2, 3, 4, 5, 6, 7, 8, 9].map((n) => _buildKey('$n')),
          const SizedBox(),
          _buildKey('0'),
          _buildBackspaceKey(),
        ],
      ),
    );
  }

  Widget _buildKey(String label) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildBackspaceKey() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.backspace_outlined, size: 20),
      ),
    );
  }
}
