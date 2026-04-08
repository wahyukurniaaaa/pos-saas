import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';

class StockOpnameHistoryScreen extends ConsumerWidget {
  final String type; // 'PRODUCT' or 'INGREDIENT'

  const StockOpnameHistoryScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(stockOpnameHistoryProvider(type));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          type == 'PRODUCT' ? 'Riwayat Opname Produk' : 'Riwayat Opname Bahan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
      ),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_turned_in_outlined, 
                      size: 80, color: Colors.grey.shade200),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada riwayat opname',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final date = DateTime.tryParse(session.createdAt) ?? DateTime.now();

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_rounded, 
                        color: AppTheme.primaryColor),
                  ),
                  title: Text(
                    session.opnameNumber,
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    DateFormat('dd MMM yyyy, HH:mm').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showOpnameDetails(context, ref, session),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showOpnameDetails(BuildContext context, WidgetRef ref, StockOpnameData session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OpnameDetailsSheet(session: session),
    );
  }
}

class _OpnameDetailsSheet extends ConsumerWidget {
  final StockOpnameData session;

  const _OpnameDetailsSheet({required this.session});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(stockOpnameItemsProvider(session.id));

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Detail Opname',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    Text(
                      session.opnameNumber,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),
          
          // Items List
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
              data: (items) {
                if (items.isEmpty) {
                  return const Center(child: Text('Tidak ada item'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _OpnameItemTile(item: item, type: session.type);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OpnameItemTile extends ConsumerWidget {
  final StockOpnameItem item;
  final String type;

  const _OpnameItemTile({required this.item, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.read(databaseProvider);

    return FutureBuilder(
      future: _getName(db),
      builder: (context, snapshot) {
        final name = snapshot.data ?? 'Memuat...';
        final isLoss = item.variance < 0;
        final isGain = item.variance > 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _tileInfo('Sistem', item.systemStock.toStringAsFixed(0)),
                  _tileInfo('Fisik', item.physicalStock.toStringAsFixed(0)),
                  _tileInfo(
                    'Selisih',
                    (item.variance > 0 ? '+' : '') + item.variance.toStringAsFixed(0),
                    color: isLoss ? AppTheme.errorColor : (isGain ? AppTheme.successColor : AppTheme.textSecondary),
                  ),
                ],
              ),
              if (item.varianceReason != null && item.varianceReason!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Ket: ${item.varianceReason}',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: AppTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _tileInfo(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14, 
            fontWeight: FontWeight.w800,
            color: color ?? AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<String> _getName(PosifyDatabase db) async {
    if (type == 'INGREDIENT') {
      final ing = await db.getIngredientById(item.ingredientId!);
      return ing?.name ?? 'Unknown';
    } else {
      final prod = await db.getProduct(item.productId!);
      String name = prod?.name ?? 'Unknown';
      if (item.variantId != null) {
        final variant = await db.getVariant(item.variantId!);
        if (variant != null) {
          name += ' (${variant.name}: ${variant.optionValue})';
        }
      }
      return name;
    }
  }
}
