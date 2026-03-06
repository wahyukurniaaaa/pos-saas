import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../../providers/pos_providers.dart';
import 'payment_success_screen.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class PaymentModal extends ConsumerStatefulWidget {
  final double totalAmount;

  const PaymentModal({super.key, required this.totalAmount});

  @override
  ConsumerState<PaymentModal> createState() => _PaymentModalState();
}

class _PaymentModalState extends ConsumerState<PaymentModal> {
  String _selectedMethod = 'Tunai';
  final List<String> _methods = ['Tunai', 'QRIS', 'Debit', 'Kasbon'];

  // Numpad state for manual entry
  String _cashReceivedString = '';

  // Quick cash options
  late List<double> _quickCashOptions;

  @override
  void initState() {
    super.initState();
    _calculateQuickCash();
  }

  void _calculateQuickCash() {
    // Generate quick cash buttons based on total, e.g., if total is 45.000
    // options might be Uang Pas (45.000), 50.000, 100.000
    _quickCashOptions = [widget.totalAmount]; // always exact amount first

    // Add next rounding up visually (simplified)
    if (widget.totalAmount < 50000) {
      _quickCashOptions.add(50000);
      _quickCashOptions.add(100000);
    } else if (widget.totalAmount < 100000) {
      _quickCashOptions.add(100000);
      _quickCashOptions.add(150000);
    } else {
      double nextHundred = ((widget.totalAmount / 100000).ceil()) * 100000;
      if (nextHundred == widget.totalAmount) nextHundred += 50000;

      _quickCashOptions.add(nextHundred);
      _quickCashOptions.add(nextHundred + 50000);
    }

    // Default to Uang Pas
    _cashReceivedString = widget.totalAmount.toStringAsFixed(0);
  }

  double get _cashReceived {
    if (_cashReceivedString.isEmpty) return 0;
    return double.tryParse(_cashReceivedString) ?? 0;
  }

  double get _change {
    double received = _cashReceived;
    if (received < widget.totalAmount) return 0;
    return received - widget.totalAmount;
  }

  void _onNumpadPress(String digit) {
    setState(() {
      if (digit == 'C') {
        _cashReceivedString = '';
      } else if (digit == '000') {
        if (_cashReceivedString.isNotEmpty) {
          _cashReceivedString += '000';
        }
      } else if (digit == 'DEL') {
        if (_cashReceivedString.isNotEmpty) {
          _cashReceivedString = _cashReceivedString.substring(
            0,
            _cashReceivedString.length - 1,
          );
        }
      } else {
        if (_cashReceivedString == '0' ||
            _cashReceivedString == widget.totalAmount.toStringAsFixed(0)) {
          // Clear if it's 0 or the exact amount (uamg pas generated value)
          _cashReceivedString = digit;
        } else {
          _cashReceivedString += digit;
        }
      }
    });
  }

  void _onQuickCashPress(double amount) {
    setState(() {
      _cashReceivedString = amount.toStringAsFixed(0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: isDesktop ? 600 : double.infinity,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pembayaran',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Total to Pay
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppTheme.primaryColor.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Total Tagihan',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currency.format(widget.totalAmount),
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Methods
                  Text(
                    'Metode Pembayaran',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _methods
                        .map((method) => _buildMethodChip(method))
                        .toList(),
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Content based on Method
                  if (_selectedMethod == 'Tunai') _buildCashSection(),
                  if (_selectedMethod != 'Tunai') _buildNonCashSection(),
                ],
              ),
            ),
          ),

          // Action Bottom
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed:
                  (_cashReceived >= widget.totalAmount ||
                      _selectedMethod != 'Tunai')
                  ? _processPayment
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
                disabledBackgroundColor: AppTheme.primaryColor.withValues(
                  alpha: 0.3,
                ),
              ),
              child: Text(
                'Konfirmasi & Cetak Struk',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodChip(String method) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          method,
          style: GoogleFonts.inter(
            color: isSelected ? Colors.white : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildCashSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Received Amount
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppTheme.borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Terima Tunai',
                style: GoogleFonts.inter(color: AppTheme.textSecondary),
              ),
              Text(
                _currency.format(_cashReceived),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Quick Cash
        Row(
          children: _quickCashOptions
              .map(
                (amt) => Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: amt == _quickCashOptions.last ? 0 : 8,
                    ),
                    child: OutlinedButton(
                      onPressed: () => _onQuickCashPress(amt),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: AppTheme.textPrimary,
                      ),
                      child: Text(
                        amt == widget.totalAmount
                            ? 'Uang Pas'
                            : _currency.format(amt).replaceAll('Rp ', ''),
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),

        // Numpad
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          childAspectRatio: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _buildKey('1'),
            _buildKey('2'),
            _buildKey('3'),
            _buildKey('4'),
            _buildKey('5'),
            _buildKey('6'),
            _buildKey('7'),
            _buildKey('8'),
            _buildKey('9'),
            _buildKey(
              'C',
              color: AppTheme.errorColor.withValues(alpha: 0.1),
              textColor: AppTheme.errorColor,
            ),
            _buildKey('0'),
            _buildKey('000'),
          ],
        ),

        const SizedBox(height: 24),

        // Change
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _change > 0
                ? AppTheme.neutralSlate.withValues(alpha: 0.1)
                : AppTheme.backgroundLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _change > 0
                  ? AppTheme.neutralSlate.withValues(alpha: 0.3)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kembalian',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: _change > 0
                      ? AppTheme.neutralSlate
                      : AppTheme.textSecondary,
                ),
              ),
              Text(
                _currency.format(_change),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _change > 0
                      ? AppTheme.neutralSlate
                      : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKey(String label, {Color? color, Color? textColor}) {
    return InkWell(
      onTap: () => _onNumpadPress(label),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          color: color ?? Colors.white,
          border: Border.all(color: AppTheme.borderColor),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor ?? AppTheme.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNonCashSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(
            _selectedMethod == 'QRIS'
                ? Icons.qr_code_2
                : _selectedMethod == 'Debit'
                ? Icons.credit_card
                : Icons.edit_document,
            size: 48,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Siapkan mesin EDC atau minta Pelanggan scan kode QR. Tekan Konfirmasi jika pembayaran berhasil.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _processPayment() {
    final changeAmount = _selectedMethod == 'Tunai' ? _change.toInt() : 0;

    // 1. Clear Cart
    ref.read(cartProvider.notifier).clearCart();

    // 2. Tampilkan Layar Sukses (Replace modal dengan screen sukses)
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentSuccessScreen(changeAmount: changeAmount),
      ),
    );
  }
}
