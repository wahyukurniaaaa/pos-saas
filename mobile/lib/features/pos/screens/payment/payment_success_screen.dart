import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final double totalAmount;
  final double cashReceived;
  final double changeAmount;
  final String paymentMethod;

  const PaymentSuccessScreen({
    super.key,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    required this.paymentMethod,
  });

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Success Icon
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.successColor,
                  size: 60,
                ),
              ),
              const SizedBox(height: 32),

              // Success Text
              Text(
                'TRANSAKSI BERHASIL',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    _buildDataRow(
                      'Total Belanja',
                      formatCurrency.format(totalAmount),
                    ),
                    _buildDataRow(
                      'Dibayar (${paymentMethod.toUpperCase()})',
                      formatCurrency.format(cashReceived),
                    ),
                    const Divider(height: 24),
                    _buildDataRow(
                      'Kembalian',
                      formatCurrency.format(changeAmount),
                      isTotal: true,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Print Receipt Button
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Implement actual printing logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mencetak struk...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.print_rounded),
                label: const Text('CETAK ULANG STRUK'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(
                    color: AppTheme.primaryColor,
                    width: 2,
                  ),
                  foregroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // New Transaction Button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('LANJUT TRANSAKSI BARU'),
              ),
            ],
          ),
        ),
      )),
    );
  }

  Widget _buildDataRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isTotal ? 20 : 14,
              color: isTotal ? AppTheme.primaryColor : AppTheme.textPrimary,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
