import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/widgets/supervisor_auth_dialog.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final int transactionId;

  const ReceiptDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  TransactionWithItems? _txnData;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final data = await db.getTransactionWithItems(widget.transactionId);
    if (mounted) {
      setState(() {
        _txnData = data;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleVoid() async {
    final supervisorId = await SupervisorAuthDialog.show(
      context,
      actionDescription:
          'Otorisasi pembatalan (VOID) transaksi ini? Stok akan dikembalikan.',
    );

    if (supervisorId != null && mounted) {
      final db = ref.read(databaseProvider);
      final success = await db.voidTransaction(
        widget.transactionId,
        supervisorId,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaksi berhasil dibatalkan (VOID)'),
            backgroundColor: AppTheme.successColor,
          ),
        );
        _loadData(); // Reload to show VOID status
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal membatalkan transaksi'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: ResponsiveCenter(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_txnData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Transaksi')),
        body: const ResponsiveCenter(
          child: Center(child: Text('Transaksi tidak ditemukan')),
        ),
      );
    }

    final txn = _txnData!.transaction;
    final items = _txnData!.items;
    final isVoid = txn.paymentStatus == 'void';

    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('dd MMM yyyy HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Transaksi',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isVoid ? AppTheme.errorColor : AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      if (isVoid) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'TRANSAKSI DIBATALKAN (VOID)',
                            style: GoogleFonts.inter(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        txn.receiptNumber,
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFmt.format(txn.createdAt),
                        style: GoogleFonts.inter(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Metode Bayar:',
                            style: GoogleFonts.inter(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            txn.paymentMethod.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Items List
              Text(
                'Rincian Pembelian',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (c, i) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final e = items[index];
                    return ListTile(
                      title: Text(
                        e.product.name,
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        '${e.item.quantity} x ${currency.format(e.item.priceAtTransaction)}',
                        style: GoogleFonts.inter(fontSize: 12),
                      ),
                      trailing: Text(
                        currency.format(e.item.subtotal),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Summary
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow('Subtotal', txn.subtotal, currency),
                      if (txn.taxAmount > 0)
                        _buildSummaryRow('Pajak', txn.taxAmount, currency),
                      if (txn.serviceChargeAmount > 0)
                        _buildSummaryRow(
                          'Service Charge',
                          txn.serviceChargeAmount,
                          currency,
                        ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            currency.format(txn.totalAmount),
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Action Buttons
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mencetak ulang struk...')),
                  );
                },
                icon: const Icon(Icons.print),
                label: const Text('CETAK ULANG STRUK'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              if (!isVoid) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _handleVoid,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('BATALKAN TRANSAKSI (VOID)'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppTheme.errorColor,
                    side: const BorderSide(color: AppTheme.errorColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int amount, NumberFormat currency) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(color: AppTheme.textSecondary)),
          Text(
            currency.format(amount),
            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
