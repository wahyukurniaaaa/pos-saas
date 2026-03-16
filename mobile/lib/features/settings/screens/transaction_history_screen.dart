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

class TransactionHistoryScreen extends ConsumerWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final currentFilter = ref.watch(historyFilterProvider);
    
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
                stream: db.watchOpenShift(),
                builder: (context, shiftSnapshot) {
                  final openShift = shiftSnapshot.data;
                  
                  return StreamBuilder<List<Transaction>>(
                    stream: _getTransactionStream(db, currentFilter, openShift),
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
                                txn.receiptNumber,
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
                                    '${dateFmt.format(txn.createdAt)} | ${currency.format(txn.totalAmount)} (${txn.paymentMethod})',
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
              style: GoogleFonts.poppins(
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
}
