import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/services/backup_service.dart';

final shiftTransactionsProvider = StreamProvider.family<List, int>((
  ref,
  shiftId,
) {
  final db = ref.watch(databaseProvider);
  return db.watchTransactionsByShift(shiftId);
});

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class ShiftReportModal extends ConsumerStatefulWidget {
  final String cashierName;

  const ShiftReportModal({super.key, required this.cashierName});

  @override
  ConsumerState<ShiftReportModal> createState() => _ShiftReportModalState();
}

class _ShiftReportModalState extends ConsumerState<ShiftReportModal> {
  bool _isSubmitting = false;
  final _actualCashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _actualCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 768;

    final shiftAsync = ref.watch(openShiftProvider);
    final activeShift = shiftAsync.value;

    if (activeShift == null) {
      return const SizedBox.shrink();
    }

    final transactionsAsync = ref.watch(
      shiftTransactionsProvider(activeShift.id),
    );

    double startCash = activeShift.startingCash.toDouble();
    double cashSales = 0;
    double qrisSales = 0;
    double voidSales = 0;

    if (transactionsAsync.hasValue) {
      for (final t in transactionsAsync.value!) {
        if (t.paymentStatus == 'paid') {
          if (t.paymentMethod == 'tunai') {
            cashSales += t.totalAmount;
          } else {
            qrisSales += t.totalAmount;
          }
        } else if (t.paymentStatus == 'void') {
          voidSales += t.totalAmount;
        }
      }
    }

    final double expectedDrawer = startCash + cashSales;

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
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kasir: ${widget.cashierName}',
                      style: GoogleFonts.poppins(
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
                          style: GoogleFonts.poppins(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _currency.format(expectedDrawer),
                          style: GoogleFonts.poppins(
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

                  _buildDetailRow(
                    'Void/Pengembalian',
                    voidSales,
                    isNegative: true,
                  ),

                  const SizedBox(height: 24),

                  // Cash Reconciliation Section
                  _buildSectionTitle('Rekonsiliasi Kas'),
                  const SizedBox(height: 12),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _actualCashController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Uang Tunai Fisik di Laci',
                        hintText: 'Masukkan jumlah uang tunai...',
                        prefixText: 'Rp ',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      onChanged: (value) {
                        setState(() {}); // Refresh for discrepancy calc
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Wajib diisi';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Masukkan angka valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Discrepancy Display
                  _buildDiscrepancyDisplay(expectedDrawer),

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
                                style: GoogleFonts.poppins(
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
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    if (_formKey.currentState!.validate()) {
                                      final actualCash =
                                          int.parse(_actualCashController.text);
                                      _showEndShiftConfirmation(
                                        context,
                                        activeShift.id,
                                        actualCash,
                                        expectedDrawer.toInt(),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.dangerColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Kalkulasi & Tutup Shift',
                                    style: GoogleFonts.poppins(
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
      style: GoogleFonts.poppins(
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
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            _currency.format(amount),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: amountColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiscrepancyDisplay(double expected) {
    final actual = double.tryParse(_actualCashController.text) ?? 0;
    final diff = actual - expected;
    final isWarning = diff != 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning
            ? AppTheme.dangerColor.withValues(alpha: 0.05)
            : AppTheme.successColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWarning
              ? AppTheme.dangerColor.withValues(alpha: 0.2)
              : AppTheme.successColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Selisih Kas',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: isWarning ? AppTheme.dangerColor : AppTheme.successColor,
            ),
          ),
          Text(
            _currency.format(diff),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w800,
              color: isWarning ? AppTheme.dangerColor : AppTheme.successColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showEndShiftConfirmation(
    BuildContext context,
    int shiftId,
    int actualCash,
    int expectedCash,
  ) {
    final diff = actualCash - expectedCash;
    final diffText = diff == 0
        ? 'Kas imbang (Balance).'
        : 'Terdapat selisih ${_currency.format(diff)}.';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Konfirmasi Tutup Shift',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Sesi kasir akan diakhiri. $diffText Apakah Anda yakin uang fisik di laci telah sesuai dengan input Anda?',
          style: GoogleFonts.poppins(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Batal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isSubmitting = true);

              final success = await ref
                  .read(shiftControllerProvider.notifier)
                  .closeShift(shiftId, actualCash);
              if (success) {
                // Trigger auto-backup after successful close shift
                await BackupService().performAutoBackup();
              }

              if (!mounted) return;
              setState(() => _isSubmitting = false);

              if (success) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Shift Ditutup, laporan tercetak! ✅',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: AppTheme.successColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Gagal menutup shift. Silakan coba lagi.',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    backgroundColor: AppTheme.dangerColor,
                  ),
                );
              }
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
