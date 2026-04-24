import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:intl/intl.dart';
import 'receipt_detail_screen.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final currentFilter = ref.watch(historyFilterProvider);
    final session = ref.watch(sessionProvider).value;
    final outletId = session?.outletId ?? '';
    
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final dateFmt = DateFormat('d MMM yyyy, HH:mm', 'id_ID');

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: Navigator.canPop(context),
        title: Text(
          'Riwayat Transaksi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterBar(context, ref),
          Expanded(
            child: ResponsiveCenter(
              child: StreamBuilder<Shift?>(
                stream: db.watchOpenShift(outletId),
                builder: (context, shiftSnapshot) {
                  final openShift = shiftSnapshot.data;
                  
                  return StreamBuilder<List<Transaction>>(
                    stream: _getTransactionStream(db, currentFilter, openShift, outletId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final txns = snapshot.data ?? [];

                      if (txns.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: AppTheme.textSecondary.withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Belum ada transaksi',
                                style: GoogleFonts.poppins(
                                  color: AppTheme.textSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: txns.length,
                        itemBuilder: (context, index) {
                          final txn = txns[index];
                          final isVoid = txn.paymentStatus == 'void';

                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isVoid
                                    ? AppTheme.errorColor.withValues(alpha: 0.3)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isVoid
                                      ? AppTheme.errorColor.withValues(alpha: 0.1)
                                      : AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  color: isVoid
                                      ? AppTheme.errorColor
                                      : AppTheme.primaryColor,
                                ),
                              ),
                              title: Text(
                                txn.receiptNumber ?? 'DRAFT',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    '${dateFmt.format(txn.createdAt)} | ${currency.format(txn.totalAmount)} (${txn.paymentMethod ?? 'Draft'})',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isVoid
                                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                                          : AppTheme.successColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isVoid ? 'VOID' : 'LUNAS',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: isVoid
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ReceiptDetailScreen(transactionId: txn.id),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Detail',
                                  style: GoogleFonts.poppins(
                                    color: AppTheme.primaryColor,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Transaction>> _getTransactionStream(
    PosifyDatabase db, 
    HistoryFilter filter, 
    Shift? openShift,
    String outletId,
  ) {
    if (filter.type == HistoryFilterType.currentShift) {
      if (openShift == null) return Stream.value([]);
      return db.watchTransactionsByShift(openShift.id);
    }

    final range = _getDateRange(filter);
    if (range == null) return db.watchAllTransactions(outletId);
    
    return db.watchTransactionsByRange(range.start, range.end, outletId);
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

  Widget _buildFilterBar(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(historyFilterProvider);

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: InkWell(
        onTap: () => _showFilterModal(context, ref, currentFilter),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Periode: ${currentFilter.label}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
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
                        color: isSelected ? AppTheme.primaryColor : AppTheme.textPrimary,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppTheme.primaryColor)
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
}
