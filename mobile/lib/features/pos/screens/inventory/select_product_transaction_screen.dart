import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/product_image.dart';

import 'stock_in_screen.dart';
import 'stock_out_screen.dart';

enum TransactionType { in_, out }

class SelectProductTransactionScreen extends ConsumerStatefulWidget {
  final TransactionType type;

  const SelectProductTransactionScreen({super.key, required this.type});

  @override
  ConsumerState<SelectProductTransactionScreen> createState() => _SelectProductTransactionScreenState();
}

class _SelectProductTransactionScreenState extends ConsumerState<SelectProductTransactionScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onProductSelected(Product p, [ProductVariant? v]) async {
    final route = MaterialPageRoute<bool>(
      builder: (_) => widget.type == TransactionType.in_
          ? StockInScreen(args: StockInArgs(product: p, variant: v))
          : StockOutScreen(args: StockOutArgs(product: p, variant: v)),
    );
    
    final saved = await Navigator.push<bool>(context, route);
    if (saved == true && mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsWithVariantsAsync = ref.watch(productWithVariantsProvider);
    final isStockIn = widget.type == TransactionType.in_;
    final accentColor = isStockIn ? AppTheme.successColor : AppTheme.dangerColor;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(isStockIn, accentColor),
          _buildSearchOverlay(accentColor),
          productsWithVariantsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
            error: (e, _) => SliverFillRemaining(child: _buildErrorState(e)),
            data: (pwvList) {
              final filtered = pwvList.where((pwv) {
                if (_searchQuery.isEmpty) return true;
                final q = _searchQuery.toLowerCase();
                if (pwv.product.name.toLowerCase().contains(q)) return true;
                if (pwv.product.sku.toLowerCase().contains(q)) return true;
                return pwv.variants.any((v) =>
                    v.name.toLowerCase().contains(q) ||
                    v.optionValue.toLowerCase().contains(q) ||
                    (v.sku?.toLowerCase().contains(q) ?? false));
              }).toList();

              if (filtered.isEmpty) {
                return SliverFillRemaining(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final pwv = filtered[i];
                      if (pwv.product.hasVariants && pwv.variants.isNotEmpty) {
                        return _buildVariantProduct(pwv.product, pwv.variants, isStockIn, accentColor);
                      } else {
                        return _buildSingleProduct(pwv.product, isStockIn, accentColor);
                      }
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(bool isStockIn, Color accentColor) {
    return SliverAppBar(
      expandedHeight: 40,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: accentColor,
      foregroundColor: Colors.white,
      title: Text(
        isStockIn ? 'Pilih Produk Masuk' : 'Pilih Produk Keluar',
        style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchOverlay(Color accentColor) {
    return SliverToBoxAdapter(
      child: Container(
        color: accentColor,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Cari nama produk atau SKU...',
              hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: accentColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              suffixIcon: _searchQuery.isNotEmpty 
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey.shade400, size: 20),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(Object e) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: AppTheme.dangerColor),
            const SizedBox(height: 16),
            Text('Gagal memuat: $e', 
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _searchQuery.isEmpty ? Icons.inventory_2_outlined : Icons.search_off_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 20),
          Text(
            _searchQuery.isEmpty ? 'Belum Ada Produk' : 'Produk Tidak Ditemukan',
            style: GoogleFonts.poppins(
              fontSize: 18, 
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              _searchQuery.isEmpty 
                ? 'Tambahkan produk di menu Produk terlebih dahulu.'
                : 'Coba masukkan kata kunci pencarian yang berbeda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleProduct(Product p, bool isStockIn, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onProductSelected(p),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ProductImage(
                  imageUri: p.imageUri, 
                  productName: p.name, 
                  categoryId: p.categoryId,
                  borderRadius: 12,
                  width: 54,
                  height: 54,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Stok: ${p.stock}',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                          if (p.sku.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Text(
                              'SKU: ${p.sku}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 11,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariantProduct(Product p, List<ProductVariant> variants, bool isStockIn, Color accentColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          collapsedShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: ProductImage(
            imageUri: p.imageUri, 
            productName: p.name, 
            categoryId: p.categoryId,
            borderRadius: 12,
            width: 54,
            height: 54,
          ),
          title: Text(
            p.name,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            '${variants.length} Varian • Total: ${p.stock}',
            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w500),
          ),
          children: variants.map((v) => _buildVariantItem(p, v, isStockIn, accentColor)).toList(),
        ),
      ),
    );
  }

  Widget _buildVariantItem(Product p, ProductVariant v, bool isStockIn, Color accentColor) {
    return InkWell(
      onTap: () => _onProductSelected(p, v),
      child: Container(
        padding: const EdgeInsets.fromLTRB(80, 10, 16, 10),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade100)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${v.name}: ${v.optionValue}',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Stok: ${v.stock} • SKU: ${v.sku ?? "-"}',
                    style: GoogleFonts.poppins(
                      fontSize: 12, 
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: accentColor, size: 20),
          ],
        ),
      ),
    );
  }
}
