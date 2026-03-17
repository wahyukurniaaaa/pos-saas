import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/core/widgets/product_image.dart';

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class InventoryTab extends ConsumerStatefulWidget {
  final bool showBackButton;
  const InventoryTab({super.key, this.showBackButton = false});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final session = ref.watch(sessionProvider).value;
    final isCashier = session?.role == 'cashier';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header with Search
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (widget.showBackButton)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.arrow_back_ios_new_rounded,
                                    size: 18,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          Text(
                            'Manajemen Stok',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (!isCashier)
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.secondaryColor.withValues(alpha: 0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => _showAddProductSheet(context),
                              child: const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: Icon(Icons.add_rounded, color: AppTheme.primaryColor, size: 28),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (v) {
                      setState(() {});
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
                      fillColor: Colors.grey.shade50,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                        borderSide: const BorderSide(color: AppTheme.tertiaryColor, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ResponsiveCenter(
                child: productsAsync.when(
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
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada produk',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isCashier) ...[
                      SizedBox(
                        width: 200,
                        child: ElevatedButton.icon(
                          onPressed: () => _showAddProductSheet(context),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Tambah Produk'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: 200,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ImportProductScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.file_upload_outlined, size: 18),
                          label: const Text('Import CSV'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.textSecondary,
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.grey.shade100, width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppTheme.infoColor.withValues(alpha: 0.1),
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
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: AppTheme.textPrimary,
                                      height: 1.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          p.sku.isEmpty ? 'Umum' : p.sku,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                            color: AppTheme.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Colors.grey,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Stok: ${p.stock}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: p.stock > 0
                                              ? AppTheme.textSecondary
                                              : AppTheme.errorColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (p.hasVariants)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade600,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'Punya Varian',
                                          style: GoogleFonts.poppins(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _currency.format(p.price),
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                if (!isCashier)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      InkWell(
                                        onTap: () {
                                          _confirmDelete(context, p);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.errorColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.delete_outline,
                                            size: 16,
                                            color: AppTheme.errorColor,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      InkWell(
                                        onTap: () {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (ctx) => Container(
                                              margin: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
                                              decoration: const BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                              ),
                                              child: AddProductSheet(product: p),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            'Edit',
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.primaryColor,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                if (!isCashier)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const ImportProductScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.file_upload_outlined,
                                  size: 18,
                                ),
                                label: const Text('Import CSV'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const StockOpnameScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.inventory_2_outlined,
                                  size: 18,
                                ),
                                label: const Text('Opname'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.textSecondary,
                                  side: BorderSide(
                                    color: Colors.grey.shade300,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _showAddProductSheet(context),
                              icon: const Icon(Icons.add_rounded),
                              label: Text(
                                'Tambah Produk Baru',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        content: Text('Yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteProduct(product);
              ref.invalidate(productProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  void _showAddProductSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => const AddProductSheet(),
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
  int? _selectedCategoryId;
  bool _isLoading = false;

  // Variant mode
  bool _hasVariants = false;
  final List<_VariantInput> _variantInputs = [];
  
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
                  color: Colors.purple,
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
      _selectedCategoryId = p.categoryId;
      _hasVariants = p.hasVariants;
      _imagePath = p.imageUri;

      // Load existing variants if editing
      if (_hasVariants) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadExistingVariants());
      }
    } else {
      _addVariantInput(); // Start with one blank variant row
    }
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

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    for (final vi in _variantInputs) {
      vi.dispose();
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
                  if (mounted) Navigator.pop(ctx);
                } catch (e) {
                  setStateDialog(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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

  InputDecoration _inputDecoration(String label, {String? hint, String? prefixText, Widget? prefixIcon, Widget? suffixIcon, Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
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
                            const SizedBox(height: 32),
                          ] else ...[
                            const SizedBox(height: 16),
                          ],

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
                                      activeColor: Colors.white,
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

    if (widget.product == null) {
      productId = await db.insertProduct(
        ProductsCompanion.insert(
          categoryId: catId,
          sku: sku,
          name: _nameController.text.trim(),
          price: priceVal,
          hasVariants: Value(_hasVariants),
          stock: Value(_hasVariants ? 0 : stockVal),
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
    ref.invalidate(productProvider);
    Navigator.pop(context);
  }
}
