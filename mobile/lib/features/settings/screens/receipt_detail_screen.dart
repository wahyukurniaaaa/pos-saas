import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/receipt_provider.dart';
import 'package:posify_app/features/auth/widgets/supervisor_auth_dialog.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class ReceiptDetailScreen extends ConsumerStatefulWidget {
  final String transactionId;

  const ReceiptDetailScreen({super.key, required this.transactionId});

  @override
  ConsumerState<ReceiptDetailScreen> createState() =>
      _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends ConsumerState<ReceiptDetailScreen> {
  TransactionWithItems? _txnData;
  List<TransactionPayment> _payments = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = ref.read(databaseProvider);
    final data = await db.getTransactionWithItems(widget.transactionId);
    final payments = await db.getTransactionPayments(widget.transactionId);
    if (mounted) {
      setState(() {
        _txnData = data;
        _payments = payments;
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
        _loadData();
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
    final cs = Theme.of(context).colorScheme;

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
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: isVoid ? AppTheme.errorColor : cs.primary,
        foregroundColor: isVoid ? Colors.white : cs.onPrimary,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Info Card
              Card(
                color: cs.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            style: GoogleFonts.poppins(
                              color: AppTheme.errorColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      Text(
                        txn.receiptNumber ?? 'DRAFT',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        dateFmt.format(txn.createdAt),
                        style: GoogleFonts.poppins(
                          color: cs.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Metode Bayar:',
                            style: GoogleFonts.poppins(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          // Display all payment methods from transaction_payments.
                          // For split payments this shows each method & amount.
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: _payments.isNotEmpty
                                ? _payments.map((p) => Text(
                                    _payments.length > 1
                                        ? '${p.method.toUpperCase()}: ${currency.format(p.amount)}'
                                        : p.method.toUpperCase(),
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      color: cs.onSurface,
                                    ),
                                  )).toList()
                                : [
                                    Text(
                                      (txn.paymentMethod ?? 'Draft').toUpperCase(),
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600,
                                        color: cs.onSurface,
                                      ),
                                    ),
                                  ],
                          ),
                        ],
                      ),
                      if (txn.notes != null && txn.notes!.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Catatan:',
                              style: GoogleFonts.poppins(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                txn.notes!,
                                textAlign: TextAlign.right,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w500,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Items List
              Text(
                'Rincian Pembelian',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                color: cs.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
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
                        e.item.variantName != null
                            ? '${e.product.name} - ${e.item.variantName}'
                            : e.product.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        '${e.item.quantity} x ${currency.format(e.item.priceAtTransaction)}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        currency.format(e.item.subtotal),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Summary Card
              Card(
                color: cs.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildSummaryRow(context, 'Subtotal', txn.subtotal, currency),
                      if (txn.taxAmount > 0)
                        _buildSummaryRow(context, 'Pajak', txn.taxAmount, currency),
                      if (txn.serviceChargeAmount > 0)
                        _buildSummaryRow(
                          context,
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                          Text(
                            currency.format(txn.totalAmount),
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: cs.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Print Button
              OutlinedButton.icon(
                onPressed: () async {
                  try {
                    final db = ref.read(databaseProvider);
                    final receiptService = ref.read(receiptServiceProvider);
                    final profile = await db.getStoreProfile();

                    if (_txnData != null) {
                      await receiptService.printReceipt(
                        profile: profile,
                        transaction: _txnData!.transaction,
                        items: _txnData!.items,
                        payments: _txnData!.payments,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Gagal mencetak: $e'),
                          backgroundColor: AppTheme.errorColor,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.print),
                label: const Text('CETAK ULANG STRUK'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: cs.primary,
                  side: BorderSide(color: cs.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

                    if (_txnData != null) {
                      await receiptService.shareToWhatsApp(
                        profile: profile,
                        data: _txnData!,
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
                  backgroundColor: const Color(0xFF25D366),
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

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    int amount,
    NumberFormat currency,
  ) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(color: cs.onSurfaceVariant),
          ),
          Text(
            currency.format(amount),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
