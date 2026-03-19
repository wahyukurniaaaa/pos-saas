import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import '../providers/owner_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  final Employee employee;
  const PinLoginScreen({super.key, required this.employee});

  @override
  ConsumerState<PinLoginScreen> createState() => _PinLoginScreenState();
}

class _PinLoginScreenState extends ConsumerState<PinLoginScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 12,
    ).chain(CurveTween(curve: Curves.elasticIn)).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += digit;
      _isError = false;
    });

    if (_pin.length == 6) {
      _verifyPin();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  void _clearPin() {
    setState(() {
      _pin = '';
      _isError = false;
    });
  }

  Future<void> _verifyPin() async {
    HapticFeedback.lightImpact();

    final employee = await ref
        .read(sessionProvider.notifier)
        .loginWithEmployeeAndPin(widget.employee, _pin);

    if (!mounted) return;

    if (employee != null) {
      // Route based on role
      final role = employee.role;
      final route = (role == 'owner' || role == 'supervisor')
          ? '/dashboard'
          : '/pos';
      Navigator.pushReplacementNamed(context, route);
    } else {
      // Failed PIN
      _shakeController.forward(from: 0);
      setState(() => _isError = true);
      await Future.delayed(const Duration(milliseconds: 800));
      _clearPin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: ResponsiveCenter(child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.point_of_sale_rounded,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'POSify',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.primaryColor,
                    letterSpacing: -1.0,
                  ),
                ),
                const SizedBox(height: 24),

                // Selected Employee Info
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                          image: widget.employee.photoUri != null
                              ? DecorationImage(
                                  image: FileImage(File(widget.employee.photoUri!)),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: widget.employee.photoUri == null
                            ? Center(
                                child: Text(
                                  widget.employee.name.substring(0, 1).toUpperCase(),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.employee.name,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              _getRoleLabel(widget.employee.role),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.logout_rounded),
                        color: AppTheme.textSecondary,
                        tooltip: 'Ganti Akun',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Main Card (Design System Component Style)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.symmetric(
                    vertical: 32,
                    horizontal: 24,
                  ),
                  constraints: const BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Enter your PIN',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // PIN Dots
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(
                              _shakeAnimation.value *
                                  (_shakeController.value < 0.5 ? 1 : -1),
                              0,
                            ),
                            child: child,
                          );
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(6, (index) {
                            final isFilled = index < _pin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: isFilled ? 16 : 12,
                              height: isFilled ? 16 : 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isError
                                    ? AppTheme.dangerColor
                                    : isFilled
                                    ? AppTheme.primaryColor
                                    : AppTheme.borderColor,
                              ),
                            );
                          }),
                        ),
                      ),
                      if (_isError) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Incorrect PIN, try again',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppTheme.dangerColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 25), // keep spacing consistent
                      ],

                      const SizedBox(height: 32),

                      // Keypad
                      _buildKeypadRow(['1', '2', '3']),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['4', '5', '6']),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['7', '8', '9']),
                      const SizedBox(height: 16),
                      _buildKeypadRow(['C', '0', '⌫']),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      )),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKey(key)).toList(),
    );
  }

  Widget _buildKey(String label) {
    final isAction = label == 'C' || label == '⌫';

    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: isAction ? AppTheme.backgroundLight : Colors.transparent,
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.05),
          onTap: () {
            HapticFeedback.selectionClick();
            if (label == 'C') {
              _clearPin();
            } else if (label == '⌫') {
              _removeDigit();
            } else {
              _addDigit(label);
            }
          },
          child: Center(
            child: label == '⌫'
                ? const Icon(
                    Icons.backspace_rounded,
                    color: AppTheme.textPrimary,
                    size: 24,
                  )
                : Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: label == 'C' ? 18 : 28,
                      fontWeight: isAction ? FontWeight.w600 : FontWeight.w500,
                      color: isAction
                          ? AppTheme.textSecondary
                          : AppTheme.textPrimary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  String _getRoleLabel(String role) {
    switch (role) {
      case 'owner':
        return 'Owner';
      case 'supervisor':
        return 'Supervisor';
      case 'cashier':
        return 'Kasir';
      default:
        return role;
    }
  }
}
