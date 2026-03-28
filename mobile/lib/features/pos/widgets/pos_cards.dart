import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/widgets/product_image.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class PosProductCard extends StatelessWidget {
  final ProductWithVariants pwv;
  final bool isCashier;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const PosProductCard({
    super.key,
    required this.pwv,
    required this.isCashier,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final p = pwv.product;
    final stock = pwv.totalStock;
    final isLowStock = p.lowStockThreshold > 0 && stock <= p.lowStockThreshold;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isLowStock ? Colors.orange.shade200 : Colors.grey.shade100, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ProductImage(
                      imageUri: p.imageUri,
                      productName: p.name,
                      categoryId: p.categoryId,
                      borderRadius: 16,
                    ),
                  ),
                  if (isLowStock)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.orange.shade600, borderRadius: BorderRadius.circular(6)),
                        child: Text('Stok Rendah', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  if (p.hasVariants)
                    Positioned(
                      bottom: 8, left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.tertiaryColor, borderRadius: BorderRadius.circular(6)),
                        child: Text('Varian', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textPrimary)),
                  const SizedBox(height: 2),
                  Text(_currency.format(p.price),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primaryColor)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 10, color: stock <= 0 ? AppTheme.errorColor : AppTheme.textSecondary),
                      const SizedBox(width: 4),
                      Text('Stok: $stock',
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600,
                              color: stock <= 0 ? AppTheme.errorColor : AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductListItemCard extends StatelessWidget {
  final ProductWithVariants pwv;
  final bool isCashier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onTap;

  const ProductListItemCard({
    super.key,
    required this.pwv,
    required this.isCashier,
    required this.onEdit,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = pwv.product;
    final stock = pwv.totalStock;
    final isLowStock = p.lowStockThreshold > 0 && stock <= p.lowStockThreshold;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isLowStock ? Colors.orange.shade200 : Colors.grey.shade100, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: ProductImage(
                imageUri: p.imageUri,
                productName: p.name,
                categoryId: p.categoryId,
                borderRadius: 16,
                iconSize: 28,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.textPrimary, height: 1.2)),
                const SizedBox(height: 5),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(p.sku.isEmpty ? 'Tanpa SKU' : p.sku, style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle)),
                    Text('Stok: $stock',
                      style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700,
                        color: stock <= 0 ? AppTheme.errorColor : isLowStock ? Colors.orange.shade600 : AppTheme.textSecondary)),
                  ],
                ),
                if (isLowStock) ...[
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.warning_amber_rounded, size: 11, color: Colors.orange.shade600),
                    const SizedBox(width: 2),
                    Text('Stok rendah!', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.orange.shade600)),
                  ]),
                ],
                if (p.hasVariants) ...[
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppTheme.tertiaryColor, borderRadius: BorderRadius.circular(4)),
                    child: Text('Punya Varian', style: GoogleFonts.poppins(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_currency.format(p.price),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 14, color: AppTheme.primaryColor)),
              const SizedBox(height: 8),
              if (onTap != null)
                GestureDetector(
                  onTap: onTap!,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                    ),
                    child: Text('📋 Kartu Stok', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  ),
                ),
              if (!isCashier) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    _ActionBtn(Icons.edit_rounded, Colors.blue, onEdit),
                    const SizedBox(width: 8),
                    _ActionBtn(Icons.delete_outline_rounded, Colors.red, onDelete),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(this.icon, this.color, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
