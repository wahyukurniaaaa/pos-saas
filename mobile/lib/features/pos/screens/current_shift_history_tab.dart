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

class CurrentShiftHistoryTab extends ConsumerWidget {
  const CurrentShiftHistoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final currentFilter = ref.watch(historyFilterProvider);
    
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Riwayat',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textPrimary),
            onPressed: () {
              ref.invalidate(databaseProvider);
              ref.invalidate(historyFilterProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(context, ref),
          Expanded(
            child: StreamBuilder<StoreProfileData?>(
              stream: db.watchStoreProfile(),
              builder: (context, profileSnapshot) {
                final profile = profileSnapshot.data;
                
                return StreamBuilder<Shift?>(
                  stream: db.watchOpenShift(),
                  builder: (context, shiftSnapshot) {
                    final openShift = shiftSnapshot.data;
                    
                    if (shiftSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    // Handle Stream for Transactions based on filter
                    return StreamBuilder<List<Transaction>>(
                      stream: _getTransactionStream(db, currentFilter, openShift),
                      builder: (context, txnSnapshot) {
                        if (txnSnapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final txns = txnSnapshot.data ?? [];

                        if (currentFilter.type == HistoryFilterType.currentShift && openShift == null) {
                          return _buildNoShiftState();
                        }

                        return ListView(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          children: [
                            _buildSummaryCard(txns, currency, openShift, profile, currentFilter),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _getListTitle(currentFilter),
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${txns.length}',
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (txns.isEmpty)
                              _buildEmptyState()
                            else
                              ...txns.map((txn) => _buildTransactionCard(context, ref, txn, currency)),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Transaction>> _getTransactionStream(
    PosifyDatabase db, 
    HistoryFilter filter, 
    Shift? openShift
  ) {
    if (filter.type == HistoryFilterType.currentShift) {
      if (openShift == null) return Stream.value([]);
      return db.watchTransactionsByShift(openShift.id);
    }

    final range = _getDateRange(filter);
    if (range == null) return db.watchAllTransactions();
    
    return db.watchTransactionsByRange(range.start, range.end);
  }

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

  String _getListTitle(HistoryFilter filter) {
    if (filter.type == HistoryFilterType.currentShift) return 'Transaksi Shift Ini';
    return 'Daftar Transaksi';
  }

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(historyFilterProvider);
    final filters = HistoryFilterType.values;

    return Container(
      height: 60,
      color: Colors.white,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final type = filters[index];
          final filter = HistoryFilter(type: type);
          final isSelected = currentFilter.type == type;

          return FilterChip(
            label: Text(
              filter.label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : AppTheme.textSecondary,
              ),
            ),
            selected: isSelected,
            onSelected: (selected) async {
              if (type == HistoryFilterType.custom) {
                final range = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2023),
                  lastDate: DateTime.now(),
                  builder: (context, child) {
                    return Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.light(
                          primary: AppTheme.primaryColor,
                          onPrimary: Colors.white,
                          onSurface: AppTheme.textPrimary,
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
            backgroundColor: AppTheme.backgroundLight,
            selectedColor: AppTheme.primaryColor,
            checkmarkColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          );
        },
      ),
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
            style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondary),
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
              style: GoogleFonts.inter(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    List<Transaction> txns, 
    NumberFormat currency, 
    Shift? openShift, 
    StoreProfileData? profile,
    HistoryFilter filter
  ) {
    int totalSale = txns.where((t) => t.paymentStatus != 'void').fold(0, (sum, t) => sum + t.totalAmount);
    
    // Omzet is total sales - voids
    // In this view, Omzet and total are handled similarly but showing both for clarity
    
    Map<String, int> paymentTotals = {};
    for (var txn in txns.where((t) => t.paymentStatus != 'void')) {
      paymentTotals[txn.paymentMethod] = (paymentTotals[txn.paymentMethod] ?? 0) + txn.totalAmount;
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
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    dateRangeVisible,
                    style: GoogleFonts.inter(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Text(
                  filter.label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Omzet',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            currency.format(totalSale),
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Metode Pembayaran',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (paymentTotals.isEmpty)
             Text(
              'Belum ada pembayaran',
              style: GoogleFonts.inter(
                fontSize: 13, 
                color: AppTheme.textSecondary, 
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  Text(
                    currency.format(e.value),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
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
                      Text(
                        txn.receiptNumber,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFmt.format(txn.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
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
                              style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Text(
                  currency.format(txn.totalAmount),
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isVoid ? AppTheme.errorColor : AppTheme.textPrimary,
                    decoration: isVoid ? TextDecoration.lineThrough : null,
                  ),
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
                    label: Text('Print', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                      side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
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
                    label: Text('Refund', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
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
        title: Text('Refund Transaksi?', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
        content: Text('Apakah Anda yakin ingin membatalkan transaksi ${txn.receiptNumber}? Stok akan dikembalikan.', style: GoogleFonts.inter()),
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
        actionDescription: 'Otorisasi refund (VOID) transaksi ${txn.receiptNumber}?',
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
