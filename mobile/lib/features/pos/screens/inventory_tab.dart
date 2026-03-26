import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:drift/drift.dart' show Value;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/pos/screens/barcode_scanner_modal.dart';
import 'package:image_picker/image_picker.dart';
import 'inventory/stock_opname_screen.dart';
import 'inventory/import_product_screen.dart';
import 'inventory/global_stock_history_screen.dart';
import 'inventory/product_list_screen.dart';
import 'inventory/ingredient_list_screen.dart';
import 'inventory/ingredient_opname_screen.dart';
import 'inventory/select_product_transaction_screen.dart';


class InventoryTab extends ConsumerStatefulWidget {
  final bool showBackButton;
  const InventoryTab({super.key, this.showBackButton = false});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productWithVariantsProvider);
    final isCashier = ref.watch(sessionProvider.select((s) => s.value?.role)) == 'cashier';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ===== Hero Header =====
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppTheme.primaryColor, Color(0xFF1E2EB0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Manajemen Stok', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
                            Text('Kelola inventori bisnis Anda', style: GoogleFonts.poppins(fontSize: 13, color: Colors.white60)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), shape: BoxShape.circle),
                          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 26),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Stats Row
                    productsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (products) {
                        final totalProducts = products.length;
                        final lowStock = products.where((pwv) => pwv.product.lowStockThreshold > 0 && pwv.totalStock <= pwv.product.lowStockThreshold).length;
                        final outOfStock = products.where((pwv) => pwv.totalStock <= 0).length;
                        return Row(
                          children: [
                            _buildStatChip(Icons.category_outlined, '$totalProducts', 'Produk', Colors.white),
                            const SizedBox(width: 10),
                            _buildStatChip(Icons.warning_amber_rounded, '$lowStock', 'Stok Rendah', AppTheme.secondaryColor),
                            const SizedBox(width: 10),
                            _buildStatChip(Icons.block_rounded, '$outOfStock', 'Habis', Colors.red.shade300),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // ===== Primary Actions (Large Cards) =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Transaksi Stok', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildPrimaryActionCard(
                            context,
                            icon: Icons.add_shopping_cart_rounded,
                            label: 'Stock In',
                            sublabel: 'Terima barang masuk',
                            color: const Color(0xFF16A34A),
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const SelectProductTransactionScreen(type: TransactionType.in_),
                            )),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildPrimaryActionCard(
                            context,
                            icon: Icons.remove_shopping_cart_rounded,
                            label: 'Stock Out',
                            sublabel: 'Catat barang keluar',
                            color: AppTheme.errorColor,
                            onTap: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => const SelectProductTransactionScreen(type: TransactionType.out),
                            )),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== Secondary Menu Grid =====
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Menu Lainnya', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.0,
                      children: [
                        _buildMenuCard(
                          context,
                          icon: Icons.store_rounded,
                          label: 'Produk',
                          color: AppTheme.primaryColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.kitchen_rounded,
                          label: 'Bahan Baku',
                          color: const Color(0xFF0D9488),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IngredientListScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.inventory_2_outlined,
                          label: 'Stock Opname',
                          color: AppTheme.tertiaryColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StockOpnameScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.fact_check_outlined,
                          label: 'Opname Bahan',
                          color: AppTheme.errorColor,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const IngredientOpnameScreen())),
                        ),
                        _buildMenuCard(
                          context,
                          icon: Icons.history_rounded,
                          label: 'Riwayat Stok',
                          color: const Color(0xFF0891B2),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalStockHistoryScreen())),
                        ),
                        if (!isCashier)
                          _buildMenuCard(
                            context,
                            icon: Icons.file_upload_outlined,
                            label: 'Import CSV',
                            color: AppTheme.secondaryColor,
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImportProductScreen())),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ===== Low Stock Alert =====
            SliverToBoxAdapter(
              child: productsAsync.when(
                data: (products) {
                  final lowStockItems = products.where((pwv) => pwv.product.lowStockThreshold > 0 && pwv.totalStock <= pwv.product.lowStockThreshold).toList();
                  if (lowStockItems.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('⚠️ Perlu Perhatian', style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textSecondary, letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.secondaryColor, AppTheme.secondaryColor.withValues(alpha: 0.8)]),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: AppTheme.secondaryColor.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
                          ),
                          child: Column(
                            children: lowStockItems.take(3).map((pwv) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.inventory_2_outlined, color: AppTheme.primaryColor, size: 16),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(pwv.product.name, style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 13))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                                  child: Text('Sisa ${pwv.totalStock}', style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w800, fontSize: 12)),
                                ),
                              ]),
                            )).toList()
                            ..addAll(lowStockItems.length > 3 ? [
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductListScreen())),
                                  child: Center(child: Text('+${lowStockItems.length - 3} produk lainnya →',
                                    style: GoogleFonts.poppins(color: AppTheme.primaryColor, fontWeight: FontWeight.w700, fontSize: 12, decoration: TextDecoration.underline))),
                                ),
                              )
                            ] : []),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),

            // Bottom spacing
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(value, style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
            Text(label, style: GoogleFonts.poppins(fontSize: 10, color: Colors.white60)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrimaryActionCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 14),
            Text(label, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
            const SizedBox(height: 2),
            Text(sublabel, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textPrimary), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


// ===== Variant input form model =====
class _VariantInput {
  final nameController = TextEditingController();
  final optionController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final skuController = TextEditingController();

  void dispose() {
    nameController.dispose();
    optionController.dispose();
    priceController.dispose();
    stockController.dispose();
    skuController.dispose();
  }
}

// ===== Recipe input form model =====
class _RecipeInput {
  int? ingredientId;
  final quantityController = TextEditingController();

  void dispose() {
    quantityController.dispose();
  }
}

// ===== Add / Edit Product Sheet =====

class AddProductSheet extends ConsumerStatefulWidget {
  final Product? product;

  const AddProductSheet({super.key, this.product});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _minStockController = TextEditingController(text: '0');
  int? _selectedCategoryId;
  bool _isLoading = false;

  // Variant mode
  bool _hasVariants = false;
  final List<_VariantInput> _variantInputs = [];
  
  // Recipe mapping
  final List<_RecipeInput> _recipeInputs = [];

  // Image
  String? _imagePath;
  final _imagePicker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1000,
        maxHeight: 1000,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil gambar: $e')),
        );
      }
    }
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pilih Sumber Foto',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildPickerOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Kamera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.camera);
                  },
                ),
                const SizedBox(width: 24),
                _buildPickerOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Galeri',
                  color: AppTheme.tertiaryColor,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      final p = widget.product!;
      _nameController.text = p.name;
      _priceController.text = p.price.toString();
      _stockController.text = p.stock.toString();
      _skuController.text = p.sku;
      _minStockController.text = p.lowStockThreshold.toString();
      _selectedCategoryId = p.categoryId;
      _hasVariants = p.hasVariants;
      _imagePath = p.imageUri;

      // Load existing variants if editing
      if (_hasVariants) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingVariants());
      }

      WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingRecipes());
    } else {
      _addVariantInput(); // Start with one blank variant row
    }
  }

  Future<void> _loadExistingRecipes() async {
    final db = ref.read(databaseProvider);
    final existing = await db.getRecipesByProductId(widget.product!.id);
    if (!mounted) return;
    setState(() {
      _recipeInputs.clear();
      for (final r in existing) {
        final rInput = _RecipeInput();
        rInput.ingredientId = r.ingredientId;
        rInput.quantityController.text = r.quantityNeeded.toString();
        _recipeInputs.add(rInput);
      }
    });
  }

  Future<void> _loadExistingVariants() async {
    final db = ref.read(databaseProvider);
    final existing = await db.getVariantsByProduct(widget.product!.id);
    if (!mounted) return;
    setState(() {
      _variantInputs.clear();
      for (final v in existing) {
        final vi = _VariantInput();
        vi.nameController.text = v.name;
        vi.optionController.text = v.optionValue;
        vi.priceController.text = v.price?.toString() ?? '';
        vi.stockController.text = v.stock.toString();
        vi.skuController.text = v.sku ?? '';
        _variantInputs.add(vi);
      }
    });
  }

  void _addVariantInput() {
    setState(() => _variantInputs.add(_VariantInput()));
  }

  void _addRecipeInput() {
    setState(() => _recipeInputs.add(_RecipeInput()));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _minStockController.dispose();
    for (final vi in _variantInputs) {
      vi.dispose();
    }
    for (final ri in _recipeInputs) {
      ri.dispose();
    }
    super.dispose();
  }

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: Text('Tambah Kategori', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16)),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: ctrl,
              decoration: _inputDecoration('Nama Kategori'),
              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          actionsPadding: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (!formKey.currentState!.validate()) return;
                setStateDialog(() => isSaving = true);
                final db = ref.read(databaseProvider);
                try {
                  final id = await db.insertCategory(CategoriesCompanion.insert(
                    name: ctrl.text.trim(),
                  ));
                  ref.invalidate(categoryProvider);
                  setState(() => _selectedCategoryId = id);
                  if (context.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: isSaving 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, {String? hint, String? prefixText, String? suffixText, Widget? prefixIcon, Widget? suffixIcon, Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      suffixText: suffixText,
      suffixStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 13),
      prefixStyle: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: AppTheme.textPrimary, fontSize: 15),
      labelStyle: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey.shade400),
      filled: true,
      fillColor: fillColor ?? Colors.grey.shade50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.errorColor, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      maxChildSize: 0.95,
      minChildSize: 0.6,
      expand: false,
      builder: (_, scrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Handle & Title fixed at top
              Container(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 48,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.product == null ? 'Tambah Produk Baru' : 'Edit Produk',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondary),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Scrollable Form
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.of(context).viewInsets.bottom + 100),
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image Picker
                          Center(
                            child: GestureDetector(
                              onTap: _showImagePicker,
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(32),
                                  border: Border.all(
                                    color: AppTheme.infoColor.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  image: _imagePath != null
                                      ? DecorationImage(
                                          image: _imagePath!.startsWith('http')
                                              ? NetworkImage(_imagePath!) as ImageProvider
                                              : FileImage(File(_imagePath!)),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                ),
                                child: _imagePath == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withValues(alpha: 0.05),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(Icons.camera_alt_rounded, color: AppTheme.infoColor, size: 24),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Upload Foto',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.infoColor,
                                            ),
                                          ),
                                        ],
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Basic Info Section
                          Text(
                            'Informasi Dasar',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          TextFormField(
                            controller: _nameController,
                            decoration: _inputDecoration('Nama Produk'),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ref.watch(categoryProvider).when(
                                  data: (categories) => DropdownButtonFormField<int>(
                                    initialValue: _selectedCategoryId,
                                    decoration: _inputDecoration('Kategori'),
                                    icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                                    items: categories.map((c) {
                                      return DropdownMenuItem(value: c.id, child: Text(c.name));
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedCategoryId = val),
                                    validator: (v) => v == null ? 'Pilih kategori' : null,
                                  ),
                                  loading: () => const LinearProgressIndicator(),
                                  error: (err, stack) => const Text('Gagal memuat kategori'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 52, // Match text field height approximately
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  onPressed: () => _showAddCategoryDialog(context),
                                  icon: const Icon(Icons.add_rounded),
                                  color: AppTheme.primaryColor,
                                  tooltip: 'Tambah Kategori Baru',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _skuController,
                                  decoration: _inputDecoration('SKU (Opsional)', hint: 'Barcode / Kode'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                height: 52, // Match text field height approximately
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final res = await BarcodeScannerModal.show(context, returnResult: true);
                                    if (res != null) _skuController.text = res;
                                  },
                                  icon: const Icon(Icons.qr_code_scanner_rounded),
                                  color: AppTheme.primaryColor,
                                  tooltip: 'Scan Barcode',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Price & Stock
                          Text(
                            'Harga & Stok',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                              _hasVariants ? 'Harga Dasar' : 'Harga Jual',
                              prefixText: 'Rp  ',
                            ),
                            validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                          ),
                          if (_hasVariants)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 4),
                              child: Text(
                                'Digunakan jika varian tidak memiliki harga khusus.',
                                style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                            ),
                          const SizedBox(height: 16),

                          if (!_hasVariants) ...[
                            TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              decoration: _inputDecoration('Stok Awal'),
                              validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                            ),
                            const SizedBox(height: 16),
                          ] else ...[
                            const SizedBox(height: 16),
                          ],

                          // Low Stock Alert Threshold
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.notifications_active_outlined, color: Colors.orange.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Alert Stok Minimum',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Sistem akan memperingatkan jika stok di bawah angka ini. Isi 0 untuk menonaktifkan.',
                                  style: GoogleFonts.poppins(fontSize: 11, color: Colors.orange.shade700),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _minStockController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    'Batas Stok Minimum',
                                    hint: 'Contoh: 5',
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Variants Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Produk memiliki varian',
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Cth: Ukuran, Level Pedas, Rasa',
                                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: _hasVariants,
                                      onChanged: (val) {
                                        setState(() {
                                          _hasVariants = val;
                                          if (val && _variantInputs.isEmpty) _addVariantInput();
                                        });
                                      },
                                      activeThumbColor: Colors.white,
                                      activeTrackColor: AppTheme.primaryColor,
                                      inactiveThumbColor: Colors.white,
                                    ),
                                  ],
                                ),
                                
                                if (_hasVariants) ...[
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 20),
                                    child: Divider(height: 1),
                                  ),
                                  ..._variantInputs.asMap().entries.map((entry) {
                                    final idx = entry.key;
                                    final vi = entry.value;
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 20),
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: AppTheme.primaryColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: Text(
                                                  'Varian ${idx + 1}',
                                                  style: GoogleFonts.poppins(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 12,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                              if (_variantInputs.length > 1)
                                                InkWell(
                                                  onTap: () {
                                                    setState(() {
                                                      vi.dispose();
                                                      _variantInputs.removeAt(idx);
                                                    });
                                                  },
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(6.0),
                                                    decoration: BoxDecoration(
                                                      color: AppTheme.errorColor.withValues(alpha: 0.1),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor, size: 20),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  controller: vi.nameController,
                                                  decoration: _inputDecoration('Grup', hint: 'Cth: Ukuran', fillColor: Colors.white),
                                                  validator: (v) => _hasVariants && (v == null || v.isEmpty) ? 'Wajib' : null,
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: TextFormField(
                                                  controller: vi.optionController,
                                                  decoration: _inputDecoration('Opsi', hint: 'Cth: Besar', fillColor: Colors.white),
                                                  validator: (v) => _hasVariants && (v == null || v.isEmpty) ? 'Wajib' : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                flex: 3,
                                                child: TextFormField(
                                                  controller: vi.priceController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: _inputDecoration('Harga', hint: 'Ikut Dasar', prefixText: 'Rp  ', fillColor: Colors.white),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                flex: 2,
                                                child: TextFormField(
                                                  controller: vi.stockController,
                                                  keyboardType: TextInputType.number,
                                                  decoration: _inputDecoration('Stok', fillColor: Colors.white),
                                                  validator: (v) => _hasVariants && (v == null || v.isEmpty) ? 'Wajib' : null,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          TextFormField(
                                            controller: vi.skuController,
                                            decoration: _inputDecoration('SKU Varian (Opsional)', hint: 'Barcode varian', fillColor: Colors.white),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: _addVariantInput,
                                      icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                      label: Text('Tambah Varian Lagi', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: AppTheme.primaryColor,
                                        side: BorderSide(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.05),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Recipe Builder Section
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.restaurant_menu_rounded, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Resep / Komposisi (Opsional)',
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Pilih bahan baku dan jumlah yang dikurangkan otomatis setiap produk terjual.',
                                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                                const SizedBox(height: 16),
                                
                                ..._recipeInputs.asMap().entries.map((entry) {
                                  final idx = entry.key;
                                  final ri = entry.value;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.shade200),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: ref.watch(ingredientProvider).when(
                                            data: (ingredients) => DropdownButtonFormField<int>(
                                              isExpanded: true,
                                              value: ri.ingredientId,
                                              decoration: _inputDecoration('Bahan Baku', fillColor: Colors.white),
                                              icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
                                              items: ingredients.map((ing) {
                                                return DropdownMenuItem<int>(
                                                  value: ing.id,
                                                  child: Text('${ing.name} (${ing.unit})'),
                                                );
                                              }).toList(),
                                              onChanged: (val) => setState(() => ri.ingredientId = val),
                                              validator: (v) => v == null ? 'Pilih' : null,
                                              selectedItemBuilder: (BuildContext context) {
                                                return ingredients.map<Widget>((ing) {
                                                  return Text(
                                                    ing.name,
                                                    style: GoogleFonts.poppins(color: AppTheme.textPrimary, fontSize: 13),
                                                    overflow: TextOverflow.ellipsis,
                                                  );
                                                }).toList();
                                              },
                                            ),
                                            loading: () => const LinearProgressIndicator(),
                                            error: (_, __) => const Text('Gagal memuat bahan baku'),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 1,
                                          child: TextFormField(
                                            controller: ri.quantityController,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            decoration: _inputDecoration(
                                              'Jumlah',
                                              fillColor: Colors.white,
                                              suffixText: ri.ingredientId == null
                                                  ? null
                                                  : ref.watch(ingredientProvider).when(
                                                        data: (ings) {
                                                          final ing = ings.firstWhere(
                                                            (i) => i.id == ri.ingredientId,
                                                            orElse: () => ings.first,
                                                          );
                                                          return ing.unit;
                                                        },
                                                        loading: () => null,
                                                        error: (_, __) => null,
                                                      ),
                                            ),
                                            validator: (v) => v == null || v.isEmpty ? 'Wajib' : null,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
                                              ri.dispose();
                                              _recipeInputs.removeAt(idx);
                                            });
                                          },
                                          icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.errorColor),
                                          padding: const EdgeInsets.only(top: 12),
                                        ),
                                      ],
                                    ),
                                  );
                                }),

                                SizedBox(
                                  width: double.infinity,
                                  child: TextButton.icon(
                                    onPressed: _addRecipeInput,
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                    label: Text('Tambah Bahan Baku', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                                    style: TextButton.styleFrom(
                                      foregroundColor: AppTheme.primaryColor,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              _buildBottomStickyButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStickyButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -5),
            blurRadius: 15,
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProduct,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  'Simpan Produk',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final db = ref.read(databaseProvider);
    final catId = _selectedCategoryId;
    if (catId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final enteredSku = _skuController.text.trim();
    final sku = enteredSku.isNotEmpty
        ? enteredSku
        : 'SKU-${DateTime.now().millisecondsSinceEpoch}';
    final priceVal =
        int.tryParse(
          _priceController.text.replaceAll('.', '').replaceAll(',', ''),
        ) ??
        0;
    final stockVal = int.tryParse(_stockController.text) ?? 0;

    int productId;

    final minStockVal = int.tryParse(_minStockController.text) ?? 0;

    if (widget.product == null) {
      productId = await db.insertProduct(
        ProductsCompanion.insert(
          categoryId: catId,
          sku: sku,
          name: _nameController.text.trim(),
          price: priceVal,
          hasVariants: Value(_hasVariants),
          stock: Value(_hasVariants ? 0 : stockVal),
          lowStockThreshold: Value(minStockVal),
          imageUri: Value(_imagePath),
        ),
      );
    } else {
      productId = widget.product!.id;
      await db.updateProduct(
        widget.product!.copyWith(
          sku: sku,
          name: _nameController.text.trim(),
          price: priceVal,
          hasVariants: _hasVariants,
          stock: _hasVariants ? 0 : stockVal,
          lowStockThreshold: minStockVal,
          categoryId: catId,
          imageUri: Value(_imagePath),
        ),
      );
    }

    // Save variants if applicable
    if (_hasVariants) {
      final variantRows = _variantInputs.map((vi) {
        final vPrice = int.tryParse(
          vi.priceController.text.replaceAll('.', '').replaceAll(',', ''),
        );
        final vStock = int.tryParse(vi.stockController.text) ?? 0;
        final vSku = vi.skuController.text.trim();

        return ProductVariantsCompanion.insert(
          productId: productId,
          name: vi.nameController.text.trim(),
          optionValue: vi.optionController.text.trim(),
          price: Value(vPrice == null || vPrice == 0 ? null : vPrice),
          stock: Value(vStock),
          sku: Value(vSku.isEmpty ? null : vSku),
        );
      }).toList();

      await db.replaceVariants(productId, variantRows);
    } else {
      // If toggled off, remove all existing variants
      await db.deleteVariantsByProduct(productId);
    }

    if (!mounted) return;

    // Save recipes
    final validRecipes = _recipeInputs
        .where((ri) => ri.ingredientId != null && ri.quantityController.text.isNotEmpty)
        .map((ri) {
      final qStr = ri.quantityController.text.replaceAll(',', '.');
      final quantity = double.tryParse(qStr) ?? 0.0;
      return ProductRecipesCompanion.insert(
        productId: productId,
        ingredientId: ri.ingredientId!,
        quantityNeeded: quantity,
      );
    }).toList();

    await db.replaceProductRecipes(productId, validRecipes);

    if (!mounted) return;
    ref.invalidate(productProvider);
    Navigator.pop(context);
  }
}
