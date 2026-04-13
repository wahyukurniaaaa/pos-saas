import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/providers/receipt_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/settings/screens/receipt_detail_screen.dart';
import 'package:posify_app/features/auth/widgets/supervisor_auth_dialog.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/pos/screens/shift/shift_report_modal.dart';

/// Payment totals for a date-range history filter, sourced from transaction_payments.
final historyPaymentTotalsProvider =
    FutureProvider.family<Map<String, int>, DateTimeRange?>((ref, range) async {
  final db = ref.watch(databaseProvider);
  if (range == null) {
    // All-time: use a very wide range
    final results = await db.getPaymentMethodBreakdown(
      DateTime(2000),
      DateTime(2100),
    );
    return <String, int>{for (final r in results) r.method: r.totalAmount};
  }
  final results = await db.getPaymentMethodBreakdown(range.start, range.end);
  return <String, int>{for (final r in results) r.method: r.totalAmount};
});

class CurrentShiftHistoryTab extends ConsumerWidget {
  const CurrentShiftHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(historyFilterProvider);
    final historyAsync = ref.watch(historyDataProvider);
    
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Riwayat',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: Theme.of(context).colorScheme.onSurface),
            onPressed: () {
              ref.invalidate(historyDataProvider);
              ref.invalidate(historyFilterProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, ref),
          Expanded(
            child: historyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (data) {
                final txns = data.transactions;
                final openShift = data.openShift;
                final profile = data.profile;

                if (currentFilter.type == HistoryFilterType.currentShift && openShift == null) {
                  return _buildNoShiftState();
                }

                return CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildSummaryCard(
                              context, ref, txns, currency, openShift, profile, currentFilter,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                  Text(
                                    _getListTitle(currentFilter),
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                Text(
                                  '${txns.length}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (txns.isEmpty) _buildEmptyState(),
                          ],
                        ),
                      ),
                    ),
                    if (txns.isNotEmpty)
                      SliverPadding(
                        padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
                        sliver: SliverList.builder(
                          itemCount: txns.length,
                          itemBuilder: (context, index) {
                            return _buildTransactionCard(context, ref, txns[index], currency);
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getListTitle(HistoryFilter filter) {
    if (filter.type == HistoryFilterType.currentShift) return 'Transaksi Shift Ini';
    return 'Daftar Transaksi';
  }

  // Display-only helper for date range label in summary card
  DateTimeRange? _getDateRange(HistoryFilter filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (filter.type) {
      case HistoryFilterType.today:
        return DateTimeRange(start: today, end: now);
      case HistoryFilterType.thisWeek:
        final startOfWeek = today.subtract(Duration(days: now.weekday - 1));
        return DateTimeRange(start: startOfWeek, end: now);
      case HistoryFilterType.thisMonth:
        return DateTimeRange(start: DateTime(now.year, now.month, 1), end: now);
      case HistoryFilterType.thisYear:
        return DateTimeRange(start: DateTime(now.year, 1, 1), end: now);
      case HistoryFilterType.custom:
        return filter.range;
      case HistoryFilterType.currentShift:
        return null;
    }
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(historyFilterProvider);

    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: () => _showFilterModal(context, ref, currentFilter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode: ${currentFilter.label}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterModal(BuildContext context, WidgetRef ref, HistoryFilter currentFilter) {
    final filters = HistoryFilterType.values;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Pilih Rentang Waktu',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...filters.map((type) {
                  final filter = HistoryFilter(type: type);
                  final isSelected = currentFilter.type == type;
                  return ListTile(
                    title: Text(
                      filter.label,
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () async {
                      Navigator.pop(modalContext);
                      if (type == HistoryFilterType.custom) {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime(2023),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: ColorScheme.light(
                                  primary: Theme.of(context).colorScheme.primary,
                                  onPrimary: Colors.white,
                                  onSurface: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              child: child!,
                            );
                          },
                        );
                        if (range != null) {
                          ref.read(historyFilterProvider.notifier).setFilter(
                              HistoryFilter(type: type, range: range));
                        }
                      } else {
                        ref.read(historyFilterProvider.notifier).setFilter(filter);
                      }
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoShiftState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_clock_rounded, size: 80, color: AppTheme.borderColor),
          const SizedBox(height: 16),
          Text(
            'Belum ada shift aktif',
            style: GoogleFonts.poppins(fontSize: 16, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Column(
          children: [
            Icon(Icons.receipt_long_rounded, size: 64, color: AppTheme.borderColor.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'Belum ada transaksi di shift ini',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> txns,
    NumberFormat currency,
    Shift? openShift,
    StoreProfileData? profile,
    HistoryFilter filter,
  ) {
    int totalSale = txns
        .where((t) => t.paymentStatus != 'void')
        .fold(0, (sum, t) => sum + t.totalAmount);

    // Resolve accurate payment totals from transaction_payments table
    // to eliminate 'mixed' from the breakdown display.
    Map<String, int> paymentTotals = {};
    if (filter.type == HistoryFilterType.currentShift && openShift != null) {
      // For current shift: use the accurate per-method provider
      final totalsAsync = ref.watch(shiftPaymentTotalsProvider(openShift.id));
      if (totalsAsync.hasValue) paymentTotals = totalsAsync.value!;
    } else {
      // For date-range filters: use getPaymentMethodBreakdown (already rewritten)
      final range = _getDateRange(filter);
      final totalsAsync = ref.watch(historyPaymentTotalsProvider(range));
      if (totalsAsync.hasValue) paymentTotals = totalsAsync.value!;
    }

    final dateFmt = DateFormat('dd MMM yyyy');
    String dateRangeVisible = '';
    if (filter.type == HistoryFilterType.currentShift && openShift != null) {
      dateRangeVisible = 'Mulai ${DateFormat('HH:mm').format(openShift.startTime)}';
    } else {
      final range = _getDateRange(filter);
      if (range != null) {
        dateRangeVisible = '${dateFmt.format(range.start)} - ${dateFmt.format(range.end)}';
      } else {
        dateRangeVisible = 'Semua Transaksi';
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile?.name ?? 'Toko Saya',
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dateRangeVisible,
                    style: GoogleFonts.poppins(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                ),
                child: Text(
                  filter.label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Omzet',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(totalSale),
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          if (paymentTotals.isEmpty)
             Text(
              'Belum ada pembayaran',
              style: GoogleFonts.poppins(
                fontSize: 13, 
                color: Theme.of(context).colorScheme.onSurfaceVariant, 
                fontStyle: FontStyle.italic
              ),
            )
          else
            ...paymentTotals.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    e.key.toUpperCase(),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    currency.format(e.value),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(BuildContext context, WidgetRef ref, Transaction txn, NumberFormat currency) {
    final isVoid = txn.paymentStatus == 'void';
    final dateFmt = DateFormat('d MMM yyyy, HH:mm');
    final session = ref.watch(sessionProvider).value;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              txn.receiptNumber ?? 'DRAFT',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isVoid ? AppTheme.errorColor.withValues(alpha: 0.1) : AppTheme.successColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isVoid ? 'VOID' : 'BERHASIL',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isVoid ? AppTheme.errorColor : AppTheme.successColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateFmt.format(txn.createdAt),
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(Icons.person_outline, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Pegawai: ${session?.name ?? 'User'}',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.history_toggle_off_rounded, size: 14, color: AppTheme.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'Shift: #${txn.shiftId}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      if (txn.customerName != null || txn.customerPhone != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.card_membership_rounded, size: 14, color: Color(0xFF0D9488)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Member: ${txn.customerName ?? txn.customerPhone ?? "-"}',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF0D9488),
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (txn.notes != null && txn.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.note_rounded, size: 14, color: AppTheme.primaryColor),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                txn.notes!,
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppTheme.primaryColor,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Total Belanja',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currency.format(txn.totalAmount),
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: isVoid ? AppTheme.errorColor : Theme.of(context).colorScheme.primary,
                        decoration: isVoid ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.borderColor),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: isVoid ? null : () => _handlePrint(ref, txn),
                    icon: const Icon(Icons.print_outlined, size: 18),
                    label: Text('Print', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isVoid ? null : () => _handleRefund(context, ref, txn),
                    icon: const Icon(Icons.undo_rounded, size: 18),
                    label: Text('Refund', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ReceiptDetailScreen(transactionId: txn.id),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrint(WidgetRef ref, Transaction txn) async {
    try {
      final db = ref.read(databaseProvider);
      final profile = await db.getStoreProfile();
      final items = await db.getTransactionWithItems(txn.id);
      
      if (items != null) {
        await ref.read(receiptServiceProvider).printReceipt(
          profile: profile,
          transaction: txn,
          items: items.items,
        );
      }
    } catch (e) {
      // Handle error (printer connection, etc.)
    }
  }

  Future<void> _handleRefund(BuildContext context, WidgetRef ref, Transaction txn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Refund Transaksi?', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin membatalkan transaksi ${txn.receiptNumber ?? 'DRAFT'}? Stok akan dikembalikan.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Ya, Refund'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;
      
      // Use the established SupervisorAuthDialog for authorization
      final supervisorId = await SupervisorAuthDialog.show(
        context,
        actionDescription: 'Otorisasi refund (VOID) transaksi ${txn.receiptNumber ?? 'DRAFT'}?',
      );

      if (supervisorId != null) {
        final success = await ref.read(databaseProvider).voidTransaction(txn.id, supervisorId);
        if (success && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaksi berhasil di-refund'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    }
  }
}
