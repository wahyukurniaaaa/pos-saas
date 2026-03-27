import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/pos/screens/barcode_scanner_modal.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/core/widgets/product_image.dart';
import 'package:posify_app/features/pos/screens/inventory_tab.dart' show AddProductSheet;
import 'stock_card_screen.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

// ===== Product List Screen =====
class ProductListScreen extends ConsumerStatefulWidget {
  const ProductListScreen({super.key});

  @override
  ConsumerState<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends ConsumerState<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productWithVariantsProvider);
    final isCashier = ref.watch(sessionProvider.select((s) => s.value?.role)) == 'cashier';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Manajemen Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: ResponsiveCenter(
        child: productsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (products) {
            if (products.isEmpty) return _buildEmpty(context, isCashier);
            return Column(
              children: [
                _buildLowStockBanner(products),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: products.length,
                    itemBuilder: (_, i) => _buildProductCard(context, products[i], isCashier),
                  ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: !isCashier && (productsAsync.value?.isNotEmpty ?? false) ? Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _showAddProductSheet(context),
          backgroundColor: AppTheme.primaryColor,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: Text('Tambah Produk Baru', 
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white, fontSize: 13)),
        ),
      ) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (v) => ref.read(productWithVariantsProvider.notifier).setSearch(v.isEmpty ? null : v),
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Cari produk atau SKU...',
        hintStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: _searchController,
          builder: (context, value, _) {
            return value.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      ref.read(productWithVariantsProvider.notifier).setSearch(null);
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white70, size: 20),
                    onPressed: () => BarcodeScannerModal.show(context),
                  );
          },
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.secondaryColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildLowStockBanner(List<ProductWithVariants> products) {
    final lowStockItems = products.where((pwv) => pwv.product.lowStockThreshold > 0 && pwv.totalStock <= pwv.product.lowStockThreshold).toList();
    if (lowStockItems.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${lowStockItems.length} Produk Stok Rendah!',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.white)),
                Text(
                  lowStockItems.map((pwv) => pwv.product.name).take(2).join(', ') +
                      (lowStockItems.length > 2 ? ', +${lowStockItems.length - 2} lainnya' : ''),
                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.white.withOpacity(0.85)),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, ProductWithVariants pwv, bool isCashier) {
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
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
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StockCardScreen(product: p))),
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
                    _buildActionButton(Icons.edit_rounded, Colors.blue, () => _showEditProductSheet(context, p)),
                    const SizedBox(width: 8),
                    _buildActionButton(Icons.delete_outline_rounded, Colors.red, () => _showDeleteDialog(context, p)),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, bool isCashier) {
    return SizedBox.expand(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada produk',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai tambahkan produk jualan Anda.',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          if (!isCashier) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showAddProductSheet(context),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                'Tambah Produk Pertama',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: const StadiumBorder(),
                elevation: 2,
              ),
            ),
          ],
        ],
      ),
    ),
  ),
);
}



  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: const AddProductSheet(),
      ),
    );
  }

  void _showEditProductSheet(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: AddProductSheet(product: product),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Produk', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"? Semua varian juga akan terhapus.', style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteProduct(product);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('Hapus', style: GoogleFonts.poppins(color: AppTheme.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
