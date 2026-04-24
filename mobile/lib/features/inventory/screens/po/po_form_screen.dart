import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/inventory/providers/po_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';

class PoFormScreen extends ConsumerStatefulWidget {
  const PoFormScreen({super.key});

  @override
  ConsumerState<PoFormScreen> createState() => _PoFormScreenState();
}

class _PoFormScreenState extends ConsumerState<PoFormScreen> {
  final _notesController = TextEditingController();
  Supplier? _selectedSupplier;
  final List<_PoItemRow> _items = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final companions = _items
          .where((i) => i.qty > 0)
          .map(
            (i) => PurchaseOrderItemsCompanion.insert(
              purchaseOrderId: '', 
              itemName: i.name,
              unit: i.unit,
              quantity: i.qty,
              productId:
                  i.type == 'product' ? Value(i.refId) : const Value.absent(),
              ingredientId:
                  i.type == 'ingredient' ? Value(i.refId) : const Value.absent(),
              purchasePrice: Value(i.price),
            ),
          )
          .toList();

      await ref.read(purchaseOrdersProvider.notifier).createPO(
            supplierId: _selectedSupplier?.id,
            notes: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            items: companions,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addItem() async {
    final db = ref.read(databaseProvider);
    final session = ref.read(sessionProvider).value;
    if (session == null || session.outletId == null) return;
    final outletId = session.outletId!;

    final products = await db.getAllProducts(outletId);
    final ingredients = await db.getAllIngredients(outletId);

    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(
        products: products,
        ingredients: ingredients,
        onAdd: (item) => setState(() => _items.add(item)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final outletId = session?.outletId;
    
    final suppliersAsync =
        ref.watch(FutureProvider((r) {
          if (outletId == null) return Future.value(<Supplier>[]);
          return r.read(databaseProvider).getAllSuppliers(outletId);
        }).future);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'Buat Purchase Order',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                color: AppTheme.secondaryColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ResponsiveCenter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('INFORMASI PESANAN'),
                    const SizedBox(height: 10),
                    _card([
                      FutureBuilder<List<Supplier>>(
                        future: suppliersAsync,
                        builder: (ctx, snap) {
                          final supplierList = snap.data ?? [];
                          return DropdownButtonFormField<Supplier>(
                            value: _selectedSupplier,
                            decoration: _inputDecoration('Supplier (Opsional)'),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('— Tanpa Supplier —'),
                              ),
                              ...supplierList.map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.name),
                                  )),
                            ],
                            onChanged: (v) =>
                                setState(() => _selectedSupplier = v),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _notesController,
                        decoration: _inputDecoration('Catatan (Opsional)'),
                        maxLines: 2,
                      ),
                    ]),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        _sectionLabel('ITEM PESANAN'),
                        const Spacer(),
                        ElevatedButton.icon(
                          onPressed: _addItem,
                          icon: const Icon(Icons.add_rounded, size: 16),
                          label: const Text('Tambah'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.secondaryColor,
                              foregroundColor: AppTheme.primaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_items.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(24),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'Belum ada item',
                          style: GoogleFonts.poppins(
                              fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((e) {
                        final item = e.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          color: Colors.white,
                          child: ListTile(
                            leading: Icon(
                              item.type == 'product'
                                  ? Icons.inventory_2_rounded
                                  : Icons.kitchen_rounded,
                              color: AppTheme.primaryColor,
                            ),
                            title: Text(item.name,
                                style: GoogleFonts.poppins(
                                    fontSize: 13, fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              '${item.qty} ${item.unit}  •  Rp ${item.price}',
                              style: GoogleFonts.poppins(fontSize: 11),
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: Colors.red, size: 18),
                              onPressed: () =>
                                  setState(() => _items.removeAt(e.key)),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _card(List<Widget> children) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: children),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      );

  InputDecoration _inputDecoration(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      );
}

class _PoItemRow {
  final String refId;
  final String type; 
  final String name;
  final String unit;
  final double qty;
  final int price;

  const _PoItemRow({
    required this.refId,
    required this.type,
    required this.name,
    required this.unit,
    required this.qty,
    required this.price,
  });
}

class _AddItemSheet extends StatefulWidget {
  final List<Product> products;
  final List<Ingredient> ingredients;
  final void Function(_PoItemRow) onAdd;

  const _AddItemSheet({
    required this.products,
    required this.ingredients,
    required this.onAdd,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _tab = 'product';
  Product? _selectedProduct;
  Ingredient? _selectedIngredient;
  final _qtyCtrl = TextEditingController(text: '1');
  final _priceCtrl = TextEditingController(text: '0');

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final qty = double.tryParse(_qtyCtrl.text) ?? 0;
    final price = int.tryParse(_priceCtrl.text) ?? 0;
    if (_tab == 'product' && _selectedProduct != null) {
      widget.onAdd(_PoItemRow(
        refId: _selectedProduct!.id,
        type: 'product',
        name: _selectedProduct!.name,
        unit: 'pcs',
        qty: qty,
        price: price,
      ));
      Navigator.pop(context);
    } else if (_tab == 'ingredient' && _selectedIngredient != null) {
      widget.onAdd(_PoItemRow(
        refId: _selectedIngredient!.id,
        type: 'ingredient',
        name: _selectedIngredient!.name,
        unit: _selectedIngredient!.unit,
        qty: qty,
        price: price,
      ));
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Pilih item terlebih dahulu')));
    }
  }

  InputDecoration _decor(String label) => InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      );

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4))),
          ),
          const SizedBox(height: 16),
          Text('Tambah Item PO',
              style: GoogleFonts.poppins(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'product', label: Text('Produk')),
              ButtonSegment(value: 'ingredient', label: Text('Bahan Baku')),
            ],
            selected: {_tab},
            onSelectionChanged: (v) =>
                setState(() => _tab = v.first),
          ),
          const SizedBox(height: 14),
          if (_tab == 'product')
            DropdownButtonFormField<Product>(
              value: _selectedProduct,
              decoration: _decor('Pilih Produk'),
              items: widget.products
                  .map((p) =>
                      DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedProduct = v),
            )
          else
            DropdownButtonFormField<Ingredient>(
              value: _selectedIngredient,
              decoration: _decor('Pilih Bahan Baku'),
              items: widget.ingredients
                  .map((i) =>
                      DropdownMenuItem(value: i, child: Text(i.name)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedIngredient = v),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  decoration: _decor('Qty'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: _decor('Harga Beli'),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondaryColor,
                foregroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              child: Text('Tambahkan',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
            ),
          ),
        ],
      ),
    );
  }
}
