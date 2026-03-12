import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/payment/payment_modal.dart';
import 'package:posify_app/features/pos/screens/shift/shift_report_modal.dart';
import 'package:posify_app/features/pos/providers/shift_provider.dart';
import 'package:posify_app/features/pos/screens/shift/shift_opening_modal.dart';
import 'package:posify_app/features/pos/screens/barcode_scanner_modal.dart';
import 'package:posify_app/core/widgets/product_image.dart';
import '../providers/pos_providers.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class PosTab extends ConsumerStatefulWidget {
  const PosTab({super.key});

  @override
  ConsumerState<PosTab> createState() => _PosTabState();
}




class _PosTabState extends ConsumerState<PosTab> {
  final _searchController = TextEditingController();
  int? _selectedCategoryId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);
    final cashierName = sessionAsync.value?.name ?? 'Kasir';

    final shiftAsync = ref.watch(openShiftProvider);
    final hasOpenShift = shiftAsync.value != null;

    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return Column(
      children: [
        _buildAppBar(cashierName, hasOpenShift),
        Expanded(
          child: hasOpenShift
              ? (isDesktop ? _buildDesktopLayout() : _buildMobileLayout())
              : _buildClosedShiftLayout(),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              _buildSearchBar(),
              _buildCategoryChips(),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
        Container(width: 320, color: Colors.white, child: const CartPanel()),
      ],
    );
  }

  Widget _buildMobileLayout() {
    final cartItems = ref.watch(cartProvider);
    final hasItems = cartItems.isNotEmpty;

    return Stack(
      children: [
        Column(
          children: [
            _buildSearchBar(),
            _buildCategoryChips(),
            Expanded(child: _buildProductGrid()),
            if (hasItems) const SizedBox(height: 80), // Padding only when cart has items
          ],
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: CartBottomSticky(),
        ),
      ],
    );
  }

  Widget _buildClosedShiftLayout() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Kasir Belum Buka',
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Silakan buka shift untuk mulai bertransaksi',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ShiftOpeningModal(),
                );
              },
              icon: const Icon(Icons.point_of_sale_rounded),
              label: const Text('Buka Kasir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.textOnPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(String cashierName, bool hasOpenShift) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.secondaryColor.withValues(alpha: 0.1),
                child: Text(
                  cashierName.isNotEmpty ? cashierName[0].toUpperCase() : 'K',
                  style: const TextStyle(
                    color: AppTheme.textOnPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  cashierName,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textOnPrimary,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    if (hasOpenShift) {
                      _showShiftReport(context, cashierName);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => const ShiftOpeningModal(),
                      );
                    }
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasOpenShift
                          ? AppTheme.successColor.withValues(alpha: 0.2)
                          : AppTheme.errorColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: hasOpenShift
                            ? AppTheme.successColor.withValues(alpha: 0.5)
                            : AppTheme.errorColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: hasOpenShift
                                ? AppTheme.successColor
                                : AppTheme.errorColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          hasOpenShift ? 'Shift Buka' : 'Shift Tutup',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.textOnPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: _searchController,
        onChanged: (v) {
          setState(() {}); // Rebuild for suffix icon visibility
          ref.read(productProvider.notifier).setSearch(v.isEmpty ? null : v);
        },
        decoration: InputDecoration(
          hintText: 'Cari produk atau SKU...',
          hintStyle: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppTheme.textSecondary,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    ref.read(productProvider.notifier).setSearch(null);
                  },
                )
              : IconButton(
                  icon: const Icon(
                    Icons.qr_code_scanner_rounded,
                    size: 20,
                    color: AppTheme.textSecondary,
                  ),
                  onPressed: () => BarcodeScannerModal.show(context),
                ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categoriesAsync = ref.watch(categoryProvider);

    return SizedBox(
      height: 44,
      child: categoriesAsync.when(
        loading: () => const SizedBox(),
        error: (error, stackTrace) => const SizedBox(),
        data: (cats) => ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          children: [
            _buildChip(null, 'Semua'),
            ...cats.map((c) => _buildChip(c.id, c.name)),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(int? id, String label) {
    final isSelected = _selectedCategoryId == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() => _selectedCategoryId = id);
          ref.read(productProvider.notifier).setCategory(id);
        },
        selectedColor: AppTheme.primaryColor,
        checkmarkColor: Colors.white,
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondary,
        ),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }

  Widget _buildProductGrid() {
    final productsAsync = ref.watch(productProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 768;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 52,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 8),
                Text(
                  'Belum ada produk',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isDesktop ? 4 : 2,
            childAspectRatio: 0.9,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) => _buildProductCard(products[index]),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final hasVariants = product.hasVariants;
    final isOutOfStock = !hasVariants && product.stock <= 0;
    // For simple products, check if any cart item matches
    final inCart = hasVariants
        ? false // Variants can have multiple lines, don't highlight card
        : ref.watch(cartProvider).any((i) => i.cartKey == '${product.id}');

    return GestureDetector(
      onTap: isOutOfStock
          ? null
          : () {
              if (hasVariants) {
                _showVariantPicker(context, product);
              } else {
                ref.read(cartProvider.notifier).addToCart(product);
              }
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: inCart ? AppTheme.primaryColor : Colors.grey.shade100,
            width: inCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ProductImage(
                        imageUri: product.imageUri,
                        categoryId: product.categoryId,
                        borderRadius: 10,
                        iconSize: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasVariants ? 'Lihat Varian' : _currency.format(product.price),
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasVariants ? 'Berbagai pilihan' : 'Stok: ${product.stock}',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isOutOfStock
                          ? AppTheme.errorColor
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isOutOfStock)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                ),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.errorColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Habis',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (hasVariants)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade600,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Varian',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            else if (inCart)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showVariantPicker(BuildContext context, Product product) {
    final db = ref.read(databaseProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _VariantPickerSheet(product: product, db: db),
    );
  }
}

class CartPanel extends ConsumerWidget {
  const CartPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.shopping_cart_rounded,
                size: 20,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 8),
              Text(
                'Keranjang Belanja',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (cartItems.isNotEmpty)
                TextButton(
                  onPressed: () => ref.read(cartProvider.notifier).clearCart(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.errorColor,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 0),
                  ),
                  child: Text(
                    'Hapus Semua',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),

        // Items
        Expanded(
          child: cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 48,
                        color: Colors.grey.shade300,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Belum ada item',
                        style: GoogleFonts.poppins(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: cartItems.length,
                  separatorBuilder: (context, index) =>
                      Divider(color: Colors.grey.shade100),
                  itemBuilder: (context, index) =>
                      _buildCartItem(context, ref, cartItems[index]),
                ),
        ),

        // Summary & Checkout
        if (cartItems.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade100)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Subtotal',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      _currency.format(subtotal),
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => _showPaymentDialog(context, ref, subtotal),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Lanjut Pembayaran',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProductImage(
            imageUri: item.product.imageUri,
            categoryId: item.product.categoryId,
            width: 48,
            height: 48,
            borderRadius: 8,
            iconSize: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (item.variant != null)
                  Text(
                    '${item.variant!.name}: ${item.variant!.optionValue}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  currency.format(item.effectivePrice),
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _CartQtyAction(item: item),
        ],
      ),
    );
  }
}

class _CartQtyAction extends ConsumerStatefulWidget {
  final CartItem item;

  const _CartQtyAction({required this.item});

  @override
  ConsumerState<_CartQtyAction> createState() => _CartQtyActionState();
}

class _CartQtyActionState extends ConsumerState<_CartQtyAction> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.item.quantity}');
  }

  @override
  void didUpdateWidget(_CartQtyAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.quantity != widget.item.quantity &&
        _controller.text != '${widget.item.quantity}') {
      _controller.text = '${widget.item.quantity}';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateQty(String value) {
    final qty = int.tryParse(value) ?? 0;
    if (qty != widget.item.quantity) {
      ref.read(cartProvider.notifier).updateQuantity(widget.item.cartKey, qty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionIcon(
            Icons.remove,
            () {
              if (widget.item.quantity > 0) {
                final newQty = widget.item.quantity - 1;
                ref
                    .read(cartProvider.notifier)
                    .updateQuantity(widget.item.cartKey, newQty);
                _controller.text = '$newQty';
              }
            },
          ),
          SizedBox(
            width: 44,
            child: TextField(
              controller: _controller,
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
              onTap: () {
                _controller.selection = TextSelection(
                  baseOffset: 0,
                  extentOffset: _controller.text.length,
                );
              },
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
              ),
              onChanged: _updateQty,
            ),
          ),
          _buildActionIcon(
            Icons.add,
            () {
              final newQty = widget.item.quantity + 1;
              ref
                  .read(cartProvider.notifier)
                  .updateQuantity(widget.item.cartKey, newQty);
              _controller.text = '$newQty';
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 16, color: AppTheme.textPrimary),
      ),
    );
  }
}

class CartBottomSticky extends ConsumerWidget {
  const CartBottomSticky({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final subtotal = ref.watch(cartProvider.notifier).subtotal;

    if (cartItems.isEmpty) return const SizedBox.shrink();

    final totalItems = cartItems.fold(0, (sum, item) => sum + item.quantity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: InkWell(
          onTap: () {
            // Open Cart Bottom Sheet
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                height: MediaQuery.of(context).size.height * 0.85,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: const CartPanel(), // Reuse the CartPanel widget!
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.shopping_cart_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: AppTheme.errorColor,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$totalItems item di keranjang',
                      style: GoogleFonts.poppins(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _currency.format(subtotal),
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  'Lihat',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void _showPaymentDialog(BuildContext context, WidgetRef ref, double amount) {
  final isDesktop = MediaQuery.of(context).size.width > 800;

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: PaymentModal(totalAmount: amount),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PaymentModal(totalAmount: amount),
    );
  }
}

void _showShiftReport(BuildContext context, String cashierName) {
  final isDesktop = MediaQuery.of(context).size.width > 800;

  if (isDesktop) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ShiftReportModal(cashierName: cashierName),
      ),
    );
  } else {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ShiftReportModal(cashierName: cashierName),
    );
  }
}

/// Bottom sheet for selecting a variant before adding to cart
class _VariantPickerSheet extends ConsumerStatefulWidget {
  final Product product;
  final PosifyDatabase db;

  const _VariantPickerSheet({required this.product, required this.db});

  @override
  ConsumerState<_VariantPickerSheet> createState() =>
      _VariantPickerSheetState();
}

class _VariantPickerSheetState extends ConsumerState<_VariantPickerSheet> {
  List<ProductVariant> _variants = [];
  bool _loading = true;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    _loadVariants();
  }

  Future<void> _loadVariants() async {
    final variants = await widget.db.getVariantsByProduct(widget.product.id);
    if (mounted) setState(() { _variants = variants; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveCenter(
      maxWidth: 600,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image in Variant Picker
                ProductImage(
                  imageUri: widget.product.imageUri,
                  categoryId: widget.product.categoryId,
                  width: 80,
                  height: 80,
                  borderRadius: 12,
                  iconSize: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pilih varian produk di bawah ini',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    padding: const EdgeInsets.all(4),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 16),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_variants.isEmpty)
            Center(
              child: Text(
                'Belum ada varian untuk produk ini.',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _variants.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final v = _variants[i];
                final effectivePrice =
                    (v.price != null && v.price! > 0)
                        ? v.price!
                        : widget.product.price;
                final isOutOfStock = v.stock <= 0;

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: isOutOfStock
                        ? null
                        : () {
                            ref
                                .read(cartProvider.notifier)
                                .addToCart(widget.product, variant: v);
                            Navigator.pop(context);
                          },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isOutOfStock
                              ? Colors.grey.shade200
                              : AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: isOutOfStock
                            ? Colors.grey.shade50
                            : AppTheme.primaryColor.withValues(alpha: 0.03),
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
                                    color: isOutOfStock
                                        ? AppTheme.textSecondary
                                        : AppTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  'Stok: ${v.stock}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isOutOfStock
                                        ? AppTheme.errorColor
                                        : AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            isOutOfStock
                                ? 'Habis'
                                : _currency.format(effectivePrice),
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isOutOfStock
                                  ? AppTheme.errorColor
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    ),
  );
  }
}

