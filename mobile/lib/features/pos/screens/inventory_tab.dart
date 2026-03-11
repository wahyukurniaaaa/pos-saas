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

final _currency = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class InventoryTab extends ConsumerStatefulWidget {
  const InventoryTab({super.key});

  @override
  ConsumerState<InventoryTab> createState() => _InventoryTabState();
}

class _InventoryTabState extends ConsumerState<InventoryTab> {
  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productProvider);
    final session = ref.watch(sessionProvider).value;
    final isCashier = session?.role == 'cashier';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manajemen Stok',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isCashier)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => _showAddProductSheet(context),
            ),
        ],
      ),
      body: ResponsiveCenter(
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
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isCashier)
                      ElevatedButton.icon(
                        onPressed: () => _showAddProductSheet(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Produk'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              image: p.imageUri != null 
                                ? DecorationImage(
                                    image: FileImage(File(p.imageUri!)),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            ),
                            child: p.imageUri != null 
                                ? null 
                                : const Icon(
                                    Icons.fastfood_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 22,
                                  ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              if (p.hasVariants)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Varian',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Text(
                            p.hasVariants
                                ? '${p.sku}  •  Harga dasar: ${_currency.format(p.price)}'
                                : '${p.sku}  •  ${_currency.format(p.price)}',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!p.hasVariants)
                                Chip(
                                  label: Text(
                                    'Stok: ${p.stock}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: p.stock > 0
                                          ? AppTheme.successColor
                                          : AppTheme.errorColor,
                                    ),
                                  ),
                                  backgroundColor: p.stock > 0
                                      ? AppTheme.successColor.withValues(
                                          alpha: 0.1,
                                        )
                                      : AppTheme.errorColor.withValues(
                                          alpha: 0.1,
                                        ),
                                  side: BorderSide.none,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              if (!isCashier)
                                PopupMenuButton<String>(
                                  onSelected: (val) {
                                    if (val == 'edit') {
                                      showModalBottomSheet(
                                        context: context,
                                        isScrollControlled: true,
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        builder: (ctx) =>
                                            AddProductSheet(product: p),
                                      );
                                    } else if (val == 'delete') {
                                      _confirmDelete(context, p);
                                    }
                                  },
                                  itemBuilder: (ctx) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Text('Edit'),
                                    ),
                                    const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (!isCashier)
                  Container(
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
                    ),
                    child: Column(
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
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
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
                                  foregroundColor: AppTheme.primaryColor,
                                  side: const BorderSide(
                                    color: AppTheme.primaryColor,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProductSheet(context),
                          icon: const Icon(Icons.add),
                          label: const Text('TAMBAH PRODUK'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
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
    );
  }

  void _confirmDelete(BuildContext context, Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Hapus Produk',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
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

  Future<void> _pickImage() async {
    final pickedFile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (_, scrollController) => ResponsiveCenter(
        maxWidth: 640,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 20,
          ),
          child: Form(
            key: _formKey,
            child: ListView(
              controller: scrollController,
              children: [
              Text(
                widget.product == null ? 'Tambah Produk' : 'Edit Produk',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),

              // Image Picker
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                      image: _imagePath != null
                          ? DecorationImage(
                              image: FileImage(File(_imagePath!)),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _imagePath == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                'Foto',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // === Basic Info ===
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Base price (used when no variant or as fallback)
              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: _hasVariants
                      ? 'Harga Dasar (Rp) — fallback'
                      : 'Harga (Rp)',
                  prefixText: 'Rp ',
                  helperText: _hasVariants
                      ? 'Digunakan jika varian tidak punya harga khusus'
                      : null,
                ),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 12),

              // Stock only for simple product
              if (!_hasVariants)
                TextFormField(
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Stok Awal'),
                  validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                ),
              if (!_hasVariants) const SizedBox(height: 12),

              // Category
              ref.watch(categoryProvider).when(
                data: (categories) => DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(labelText: 'Kategori'),
                  items: categories.map((c) {
                    return DropdownMenuItem(value: c.id, child: Text(c.name));
                  }).toList(),
                  onChanged: (val) =>
                      setState(() => _selectedCategoryId = val),
                  validator: (v) => v == null ? 'Wajib diisi' : null,
                ),
                loading: () => const LinearProgressIndicator(),
                error: (err, stack) => const Text('Gagal memuat kategori'),
              ),
              const SizedBox(height: 12),

              // SKU
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _skuController,
                      decoration: const InputDecoration(
                        labelText: 'SKU (Opsional)',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () async {
                      final res = await BarcodeScannerModal.show(
                        context,
                        returnResult: true,
                      );
                      if (res != null) _skuController.text = res;
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    color: AppTheme.primaryColor,
                    tooltip: 'Scan Barcode',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // === Variant toggle ===
              SwitchListTile(
                value: _hasVariants,
                onChanged: (val) {
                  setState(() {
                    _hasVariants = val;
                    if (val && _variantInputs.isEmpty) _addVariantInput();
                  });
                },
                title: Text(
                  'Produk ini memiliki varian',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  'Contoh: Ukuran (S/M/L), Rasa (Coklat/Vanilla)',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                activeColor: AppTheme.primaryColor,
                contentPadding: EdgeInsets.zero,
              ),

              // === Variant inputs ===
              if (_hasVariants) ...[
                const Divider(),
                Text(
                  'Daftar Varian',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                ..._variantInputs.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final vi = entry.value;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.shade200),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Text(
                                'Varian ${idx + 1}',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              if (_variantInputs.length > 1)
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      vi.dispose();
                                      _variantInputs.removeAt(idx);
                                    });
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppTheme.errorColor,
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: vi.nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nama',
                                    hintText: 'Ukuran',
                                    isDense: true,
                                  ),
                                  validator: (v) =>
                                      _hasVariants && (v == null || v.isEmpty)
                                          ? 'Wajib'
                                          : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: vi.optionController,
                                  decoration: const InputDecoration(
                                    labelText: 'Opsi',
                                    hintText: 'L',
                                    isDense: true,
                                  ),
                                  validator: (v) =>
                                      _hasVariants && (v == null || v.isEmpty)
                                          ? 'Wajib'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: vi.priceController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Harga Varian (Rp)',
                                    hintText: 'Kosongkan = pakai harga dasar',
                                    isDense: true,
                                    prefixText: 'Rp ',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: vi.stockController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Stok',
                                    isDense: true,
                                  ),
                                  validator: (v) =>
                                      _hasVariants && (v == null || v.isEmpty)
                                          ? 'Wajib'
                                          : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: vi.skuController,
                            decoration: const InputDecoration(
                              labelText: 'SKU Varian (Opsional)',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addVariantInput,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah Varian'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Simpan Produk',
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
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
