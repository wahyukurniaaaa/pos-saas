import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'stock_in_screen.dart';
import 'stock_out_screen.dart';

final _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

// Provider to load stock card data
final stockCardProvider = FutureProvider.family<List<StockTransaction>, ({int productId, int? variantId})>(
  (ref, arg) {
    final db = ref.watch(databaseProvider);
    return db.getStockCard(arg.productId, variantId: arg.variantId);
  },
);

class StockCardScreen extends ConsumerWidget {
  final Product product;
  final ProductVariant? variant;

  const StockCardScreen({super.key, required this.product, this.variant});

  int get currentStock => variant?.stock ?? product.stock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = (productId: product.id, variantId: variant?.id);
    final stockCardAsync = ref.watch(stockCardProvider(key));

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Kartu Stok',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: Colors.white.withOpacity(0.1)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'stock_out_btn',
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockOutScreen(
                        args: StockOutArgs(product: product, variant: variant),
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(stockCardProvider(key));
                  }
                },
                backgroundColor: AppTheme.errorColor,
                icon: const Icon(Icons.remove_shopping_cart_rounded, color: Colors.white),
                label: Text(
                  'Stock Out',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'stock_in_btn',
                onPressed: () async {
                  final result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StockInScreen(
                        args: StockInArgs(product: product, variant: variant),
                      ),
                    ),
                  );
                  if (result == true) {
                    ref.invalidate(stockCardProvider(key));
                  }
                },
                backgroundColor: const Color(0xFF22C55E), // Green for Stock In
                icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
                label: Text(
                  'Stock In',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Product Info Header
            _buildHeader(context, product, variant),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  _buildLegendChip('IN', const Color(0xFF22C55E)),
                  const SizedBox(width: 8),
                  _buildLegendChip('SALE', AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  _buildLegendChip('ADJUST', AppTheme.tertiaryColor),
                  const SizedBox(width: 8),
                  _buildLegendChip('VOID', AppTheme.errorColor),
                ],
              ),
            ),

            // Transaction list
            Expanded(
              child: stockCardAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
                data: (logs) {
                  if (logs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada histori pergerakan stok',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8).copyWith(bottom: 100),
                    itemCount: logs.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) => _buildLogTile(logs[i]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Product product, ProductVariant? variant) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant != null)
                  Text(
                    '${variant.name}: ${variant.optionValue}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Stok: $currentStock unit',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$currentStock',
                style: GoogleFonts.poppins(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              Text(
                'unit',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white.withValues(alpha: 0.8)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildLogTile(StockTransaction log) {
    final isIn = log.type == 'IN';
    final isVoid = log.type == 'VOID';
    final isAdj = log.type == 'ADJUST';
    Color typeColor;
    IconData typeIcon;
    String typeLabel;

    switch (log.type) {
      case 'IN':
        typeColor = const Color(0xFF22C55E);
        typeIcon = Icons.arrow_downward_rounded;
        typeLabel = 'Stok Masuk';
        break;
      case 'SALE':
        typeColor = AppTheme.primaryColor;
        typeIcon = Icons.point_of_sale_rounded;
        typeLabel = 'Penjualan';
        break;
      case 'VOID':
        typeColor = AppTheme.errorColor;
        typeIcon = Icons.undo_rounded;
        typeLabel = 'Void';
        break;
      case 'OUT':
        typeColor = AppTheme.errorColor;
        typeIcon = Icons.remove_circle_outline_rounded;
        typeLabel = 'Stok Keluar';
        break;
      case 'ADJUST':
        typeColor = AppTheme.tertiaryColor;
        typeIcon = Icons.tune_rounded;
        typeLabel = 'Opname';
        break;
      default:
        typeColor = AppTheme.textSecondary;
        typeIcon = Icons.swap_horiz_rounded;
        typeLabel = log.type;
    }

    final qtyDisplay = isIn || isVoid || isAdj
        ? '+${log.quantity}'
        : '${log.quantity}';

    DateTime? parsedDate;
    try {
      parsedDate = DateTime.parse(log.createdAt);
    } catch (_) {}

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
                Text(
                  typeLabel,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (log.reference != null)
                  Text(
                    'Ref: ${log.reference}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                if (log.reason != null)
                  Text(
                    log.reason!,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (parsedDate != null)
                  Text(
                    _dateFormat.format(parsedDate),
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                qtyDisplay,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: typeColor,
                ),
              ),
              Text(
                '${log.previousStock} → ${log.newStock}',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
