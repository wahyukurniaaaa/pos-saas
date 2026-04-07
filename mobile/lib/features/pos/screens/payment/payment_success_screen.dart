import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/receipt_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class PaymentSuccessScreen extends ConsumerStatefulWidget {
  final int transactionId;
  final double totalAmount;
  final double cashReceived;
  final double changeAmount;
  final String paymentMethod;

  const PaymentSuccessScreen({
    super.key,
    required this.transactionId,
    required this.totalAmount,
    required this.cashReceived,
    required this.changeAmount,
    required this.paymentMethod,
    this.pointsEarned = 0,
    this.customerPointsAfter,
  });

  final int pointsEarned;
  final int? customerPointsAfter;

  @override
  ConsumerState<PaymentSuccessScreen> createState() => _PaymentSuccessScreenState();
}

class _PaymentSuccessScreenState extends ConsumerState<PaymentSuccessScreen> {
  bool _hasAutoPrinted = false;

  @override
  void initState() {
    super.initState();
    _checkAndAutoPrint();
  }

  Future<void> _checkAndAutoPrint() async {
    if (_hasAutoPrinted) return;
    
    try {
      final db = ref.read(databaseProvider);
      final settings = await (db.select(db.printerSettings)..limit(1)).getSingleOrNull();
      
      if (settings != null && settings.autoPrint) {
        _hasAutoPrinted = true;
        _doPrintReceipt();
      }
    } catch (e) {
      debugPrint('Auto-print error: $e');
    }
  }

  Future<void> _doPrintReceipt() async {
    try {
      final db = ref.read(databaseProvider);
      final receiptService = ref.read(receiptServiceProvider);

      final profile = await db.getStoreProfile();
      final txnData = await db.getTransactionWithItems(widget.transactionId);

      Customer? customer;
      if (txnData?.transaction.customerId != null) {
        customer = await (db.select(db.customers)
          ..where((c) => c.id.equals(txnData!.transaction.customerId!)))
          .getSingleOrNull();
      }

      if (txnData != null) {
        await receiptService.printReceipt(
          profile: profile,
          transaction: txnData.transaction,
          items: txnData.items,
          payments: txnData.payments,
          customer: customer,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mencetak: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatCurrency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      body: ResponsiveCenter(
        child: SafeArea(
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
                  style: GoogleFonts.poppins(
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
                        formatCurrency.format(widget.totalAmount),
                      ),
                      _buildDataRow(
                        'Dibayar (${widget.paymentMethod.toUpperCase()})',
                        formatCurrency.format(widget.cashReceived),
                      ),
                      const Divider(height: 24),
                      _buildDataRow(
                        'Kembalian',
                        formatCurrency.format(widget.changeAmount),
                        isTotal: true,
                      ),
                      if (widget.pointsEarned > 0 && widget.customerPointsAfter != null) ...[
                        const Divider(height: 24),
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: Colors.amber, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Poin Diperoleh',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              '+${widget.pointsEarned} Poin',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (widget.customerPointsAfter != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Total poin: ${widget.customerPointsAfter}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ],
                  ),
                ),

                const Spacer(),

                // Print Receipt Button
                OutlinedButton.icon(
                  onPressed: () => _doPrintReceipt(),
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
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Share to WhatsApp Button
                ElevatedButton.icon(
                  onPressed: () async {
                    try {
                      final db = ref.read(databaseProvider);
                      final receiptService = ref.read(receiptServiceProvider);

                      final profile = await db.getStoreProfile();
                      final txnData = await db.getTransactionWithItems(widget.transactionId);

                      // Fetch customer if linked
                      Customer? customer;
                      if (txnData?.transaction.customerId != null) {
                        customer = await (db.select(db.customers)
                          ..where((c) => c.id.equals(txnData!.transaction.customerId!)))
                          .getSingleOrNull();
                      }

                      if (txnData != null) {
                        await receiptService.shareToWhatsApp(
                          profile: profile,
                          data: txnData,
                          customer: customer,
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Gagal membagikan: $e'),
                            backgroundColor: AppTheme.errorColor,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.share_rounded, color: Colors.white),
                  label: const Text('BAGIKAN KE WHATSAPP'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: GoogleFonts.poppins(
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
                    textStyle: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('LANJUT TRANSAKSI BARU'),
                ),
              ],
            ),
          ),
        ),
      ),
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
            style: GoogleFonts.poppins(
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? AppTheme.textPrimary : AppTheme.textSecondary,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
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
