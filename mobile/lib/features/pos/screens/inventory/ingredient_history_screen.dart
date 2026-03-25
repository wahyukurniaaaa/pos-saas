import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';

class IngredientHistoryScreen extends ConsumerWidget {
  final Ingredient ingredient;

  const IngredientHistoryScreen({super.key, required this.ingredient});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final historyAsync = ref.watch(StreamProvider((ref) => db.watchIngredientHistory(ingredient.id)));
    final suppliersAsync = ref.watch(supplierProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Riwayat Stok', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(ingredient.name, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: historyAsync.when(
        data: (history) {
          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                    child: Icon(Icons.history_rounded, size: 64, color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat transaksi', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          }

          return suppliersAsync.when(
            data: (suppliers) {
              final supplierMap = {for (var s in suppliers) s.id: s.name};
              
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: history.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = history[index];
                  final isIncrease = item.quantityChange > 0;
                  final date = item.createdAt;
                  final supplierName = item.supplierId != null ? supplierMap[item.supplierId] : null;

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        _buildTypeIcon(item.type, isIncrease),
                        const SizedBox(width: 14),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _formatType(item.type),
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: AppTheme.textPrimary),
                                  ),
                                  if (supplierName != null) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(4)),
                                      child: Text(supplierName, style: GoogleFonts.poppins(fontSize: 10, color: Colors.blue.shade700, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ],
                              ),
                              if (item.reason != null && item.reason!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(item.reason!, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                                ),
                              const SizedBox(height: 4),
                              Text(
                                DateFormat('dd MMM yyyy, HH:mm').format(date),
                                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                              ),
                            ],
                          ),
                        ),

                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isIncrease ? "+" : ""}${item.quantityChange % 1 == 0 ? item.quantityChange.toInt() : item.quantityChange.toStringAsFixed(1)} ${ingredient.unit}',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: isIncrease ? const Color(0xFF0D9488) : AppTheme.errorColor,
                              ),
                            ),
                            Text(
                              'Sisa: ${item.newBalance % 1 == 0 ? item.newBalance.toInt() : item.newBalance.toStringAsFixed(1)} ${ingredient.unit}',
                              style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Gagal memuat supplier')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTypeIcon(String type, bool isIncrease) {
    Color color;
    IconData icon;

    switch (type) {
      case 'SALE':
        color = Colors.blue;
        icon = Icons.shopping_cart_outlined;
        break;
      case 'PURCHASE':
      case 'ADD':
        color = const Color(0xFF0D9488);
        icon = Icons.add_business_outlined;
        break;
      case 'ADJUST':
        color = Colors.orange;
        icon = Icons.edit_note_rounded;
        break;
      case 'WASTE':
        color = AppTheme.errorColor;
        icon = Icons.delete_sweep_outlined;
        break;
      case 'RETURN':
        color = Colors.indigo;
        icon = Icons.assignment_return_outlined;
        break;
      default:
        color = Colors.grey;
        icon = Icons.receipt_long_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  String _formatType(String type) {
    switch (type) {
      case 'SALE': return 'Penjualan';
      case 'PURCHASE':
      case 'ADD': return 'Stok Masuk';
      case 'ADJUST': return 'Penyesuaian';
      case 'WASTE': return 'Barang Rusak';
      case 'RETURN': return 'Retur Supplier';
      default: return 'Lainnya';
    }
  }
}
