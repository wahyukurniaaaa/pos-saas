import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../providers/owner_provider.dart';

class PinLoginScreen extends ConsumerStatefulWidget {
  const PinLoginScreen({super.key});

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
        .loginWithPin(_pin);

    if (!mounted) return;

    if (employee != null) {
      // Success – navigate to POS dashboard
      Navigator.pushReplacementNamed(context, '/pos');
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
            stops: [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.point_of_sale_rounded,
                  size: 34,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'POSify',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan PIN Anda',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 28),

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
                      width: isFilled ? 18 : 14,
                      height: isFilled ? 18 : 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isError
                            ? AppTheme.errorColor
                            : isFilled
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        border: !isFilled
                            ? Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 1.5,
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),

              if (_isError) ...[
                const SizedBox(height: 12),
                Text(
                  'PIN salah, silakan coba lagi',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.accentLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const Spacer(flex: 1),

              // Keypad
              Container(
                padding: const EdgeInsets.fromLTRB(40, 0, 40, 16),
                child: Column(
                  children: [
                    _buildKeypadRow(['1', '2', '3']),
                    const SizedBox(height: 12),
                    _buildKeypadRow(['4', '5', '6']),
                    const SizedBox(height: 12),
                    _buildKeypadRow(['7', '8', '9']),
                    const SizedBox(height: 12),
                    _buildKeypadRow(['C', '0', '⌫']),
                  ],
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
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
        color: isAction
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(36),
        child: InkWell(
          borderRadius: BorderRadius.circular(36),
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
                    Icons.backspace_outlined,
                    color: Colors.white,
                    size: 24,
                  )
                : Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: label == 'C' ? 16 : 26,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
