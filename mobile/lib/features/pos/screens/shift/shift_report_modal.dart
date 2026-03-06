import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class ShiftReportModal extends StatelessWidget {
  final String cashierName;

  const ShiftReportModal({super.key, required this.cashierName});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 800;

    // Hardcoded demo values based on wireframe constraints
    final double startCash = 50000;
    final double cashSales = 120000;
    final double qrisSales = 30000;
    final double expectedDrawer =
        startCash + cashSales; // only cash sales go into the drawer

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
        maxWidth: isDesktop ? 500 : double.infinity,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Laporan Shift Saat Ini',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kasir: $cashierName',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
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
                  // Expected Drawer Amount (Highlight)
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
                          'Estimasi Uang Dalam Laci',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currency.format(expectedDrawer),
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

                  // Detail Rows
                  _buildSectionTitle('Rincian Transaksi'),
                  const SizedBox(height: 12),

                  _buildDetailRow('Uang Modal (Awal)', startCash),
                  _buildDetailRow(
                    'Total Penjualan Tunai',
                    cashSales,
                    isPositive: true,
                  ),
                  _buildDetailRow(
                    'Total Penjualan Non-Tunai',
                    qrisSales,
                    isNonCash: true,
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),

                  _buildDetailRow('Void/Pengembalian', 0, isNegative: true),

                  const SizedBox(height: 24),

                  // End Shift Action
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.dangerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.dangerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: AppTheme.dangerColor,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tutup shift akan mengakhiri sesi penjualan dan mengirim laporan harian.',
                                style: GoogleFonts.inter(
                                  color: AppTheme.dangerColor,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              // Show confirmation or End shift logic
                              _showEndShiftConfirmation(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dangerColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text(
                              'Kalkulasi & Tutup Shift',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppTheme.textPrimary,
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    double amount, {
    bool isPositive = false,
    bool isNegative = false,
    bool isNonCash = false,
  }) {
    Color amountColor = AppTheme.textPrimary;
    if (isPositive) amountColor = AppTheme.successColor;
    if (isNegative) amountColor = AppTheme.dangerColor;
    if (isNonCash) {
      amountColor =
          AppTheme.textSecondary; // Non-cash is informative, not in drawer
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _currency.format(amount),
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showEndShiftConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Tutup Shift',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Sesi kasir akan diakhiri. Apakah Anda yakin uang fisik di laci telah sesuai dengan laporan?',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Shift Ditutup, laporan tercetak! ✅',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                  backgroundColor: AppTheme.successColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Ya, Tutup Shift'),
          ),
        ],
      ),
    );
  }
}
