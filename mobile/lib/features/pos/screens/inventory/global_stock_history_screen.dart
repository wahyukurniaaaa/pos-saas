import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';

class GlobalStockHistoryScreen extends ConsumerWidget {
  const GlobalStockHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockHistoryProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Riwayat Mutasi Stok',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 16),
              ),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF1E2EB0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            foregroundColor: Colors.white,
          ),
          
          historyAsync.when(
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, s) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
            data: (logs) {
              if (logs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade200),
                        const SizedBox(height: 16),
                        Text(
                          'Belum ada mutasi stok',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = logs[index];
                      final log = item.transaction;
                      final product = item.product;
                      final variant = item.variant;
                      
                      final date = DateTime.tryParse(log.createdAt) ?? DateTime.now();
                      
                      Color typeColor;
                      IconData typeIcon;
                      String typeLabel;

                      switch (log.type) {
                        case 'IN':
                          typeColor = const Color(0xFF16A34A);
                          typeIcon = Icons.add_circle_outline_rounded;
                          typeLabel = 'Stok Masuk';
                          break;
                        case 'OUT':
                          typeColor = AppTheme.errorColor;
                          typeIcon = Icons.remove_circle_outline_rounded;
                          typeLabel = 'Stok Keluar';
                          break;
                        case 'ADJUST':
                          typeColor = AppTheme.tertiaryColor;
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
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(typeIcon, color: typeColor, size: 24),
                            ),
                            const SizedBox(width: 16),
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
                                          fontSize: 12,
                                          color: typeColor,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                      Text(
                                        DateFormat('dd MMM, HH:mm').format(date),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  if (variant != null)
                                    Text(
                                      '${variant.name}: ${variant.optionValue}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  if (log.reason != null && log.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: ${log.reason!}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        color: AppTheme.textSecondary.withValues(alpha: 0.8),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Stok: ${log.newStock}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                    childCount: logs.length,
                  ),
                ),
              );
            },
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
