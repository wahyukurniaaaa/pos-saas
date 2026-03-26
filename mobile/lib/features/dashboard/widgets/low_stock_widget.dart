import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';

/// Data class combining low-stock products and low-stock ingredients
class LowStockSummary {
  final List<Product> products;
  final List<Ingredient> ingredients;
  const LowStockSummary({required this.products, required this.ingredients});
  int get totalCount => products.length + ingredients.length;
}

class LowStockWidget extends StatelessWidget {
  final LowStockSummary summary;
  const LowStockWidget({super.key, required this.summary});

  Color _stockColor(double stock, double threshold) {
    if (stock <= 0) return Colors.red.shade600;
    if (threshold > 0 && stock <= threshold) return AppTheme.secondaryColor;
    return AppTheme.primaryColor;
  }

  @override
  Widget build(BuildContext context) {
    if (summary.totalCount == 0) return const SizedBox.shrink();

    final numberFmt = NumberFormat('#,##0.##', 'id_ID');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'PERINGATAN STOK',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  '${summary.totalCount}',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Column(
              children: [
                // Product items
                ...summary.products.asMap().entries.map((e) {
                  final p = e.value;
                  final isLast = e.key == summary.totalCount - 1;
                  final stockColor = _stockColor(p.stock.toDouble(), p.lowStockThreshold.toDouble());
                  return _LowStockTile(
                    name: p.name,
                    stockLabel: '${numberFmt.format(p.stock)} pcs',
                    thresholdLabel: 'Min: ${p.lowStockThreshold} pcs',
                    stockColor: stockColor,
                    icon: Icons.inventory_2_rounded,
                    isLast: isLast,
                  );
                }),
                // Ingredient items
                ...summary.ingredients.asMap().entries.map((e) {
                  final ing = e.value;
                  final listIdx = summary.products.length + e.key;
                  final isLast = listIdx == summary.totalCount - 1;
                  final stockColor = _stockColor(ing.stockQuantity, ing.minStockThreshold);
                  return _LowStockTile(
                    name: ing.name,
                    stockLabel: '${numberFmt.format(ing.stockQuantity)} ${ing.unit}',
                    thresholdLabel: 'Min: ${numberFmt.format(ing.minStockThreshold)} ${ing.unit}',
                    stockColor: stockColor,
                    icon: Icons.kitchen_rounded,
                    isLast: isLast,
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _LowStockTile extends StatelessWidget {
  final String name;
  final String stockLabel;
  final String thresholdLabel;
  final Color stockColor;
  final IconData icon;
  final bool isLast;

  const _LowStockTile({
    required this.name,
    required this.stockLabel,
    required this.thresholdLabel,
    required this.stockColor,
    required this.icon,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: stockColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      thresholdLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 50),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  stockLabel,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: stockColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (!isLast) Divider(height: 1, indent: 64, color: Colors.grey.shade100),
      ],
    );
  }
}
