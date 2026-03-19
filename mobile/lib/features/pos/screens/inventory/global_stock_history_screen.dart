import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

class GlobalStockHistoryScreen extends ConsumerWidget {
  const GlobalStockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final historyAsync = ref.watch(StreamProvider<List<StockTransaction>>((ref) {
      return (db.select(db.stockTransactions)
            ..orderBy([(t) => drift.OrderingTerm(expression: t.createdAt, mode: drift.OrderingMode.desc)]))
          .watch();
    }));

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Riwayat Mutasi Stok',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (logs) {
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada mutasi stok',
                    style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16).copyWith(bottom: 100),
            itemCount: logs.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final log = logs[index];
              final date = DateTime.tryParse(log.createdAt) ?? DateTime.now();
              
              Color typeColor;
              IconData typeIcon;
              String typeLabel;

              switch (log.type) {
                case 'IN':
                  typeColor = Colors.green;
                  typeIcon = Icons.add_circle_outline_rounded;
                  typeLabel = 'Stok Masuk';
                  break;
                case 'OUT':
                  typeColor = Colors.red;
                  typeIcon = Icons.remove_circle_outline_rounded;
                  typeLabel = 'Stok Keluar';
                  break;
                case 'ADJUST':
                  typeColor = Colors.orange;
                  typeIcon = Icons.settings_backup_restore_rounded;
                  typeLabel = 'Penyesuaian';
                  break;
                case 'SALE':
                  typeColor = AppTheme.primaryColor;
                  typeIcon = Icons.shopping_bag_outlined;
                  typeLabel = 'Penjualan';
                  break;
                case 'VOID':
                  typeColor = Colors.grey;
                  typeIcon = Icons.cancel_outlined;
                  typeLabel = 'Pembatalan';
                  break;
                default:
                  typeColor = Colors.blue;
                  typeIcon = Icons.swap_horiz_rounded;
                  typeLabel = log.type;
              }

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(typeIcon, color: typeColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                typeLabel,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: typeColor,
                                ),
                              ),
                              Text(
                                DateFormat('dd MMM, HH:mm').format(date),
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          FutureBuilder<Product?>(
                            future: (db.select(db.products)..where((p) => p.id.equals(log.productId))).getSingleOrNull(),
                            builder: (context, snapshot) {
                              final productName = snapshot.data?.name ?? 'Memuat...';
                              return Text(
                                productName,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                  color: AppTheme.textPrimary,
                                ),
                              );
                            }
                          ),
                          if (log.reason != null && log.reason!.isNotEmpty)
                            Text(
                              log.reason!,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${log.quantity > 0 && log.type != 'SALE' && log.type != 'OUT' ? '+' : ''}${log.quantity}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: typeColor,
                          ),
                        ),
                        Text(
                          'Sisa: ${log.newStock}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
