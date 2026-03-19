import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';


// Args to pass to StockInScreen
class StockInArgs {
  final Product product;
  final ProductVariant? variant;

  const StockInArgs({required this.product, this.variant});
}

class StockInScreen extends ConsumerStatefulWidget {
  final StockInArgs args;

  const StockInScreen({super.key, required this.args});

  @override
  ConsumerState<StockInScreen> createState() => _StockInScreenState();
}

class _StockInScreenState extends ConsumerState<StockInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
  final _costController = TextEditingController(text: '0');
  final _noteController = TextEditingController();
  final _invoiceController = TextEditingController();
  Supplier? _selectedSupplier;
  bool _isSaving = false;

  Product get product => widget.args.product;
  ProductVariant? get variant => widget.args.variant;

  int get currentStock => variant?.stock ?? product.stock;

  @override
  void dispose() {
    _qtyController.dispose();
    _costController.dispose();
    _noteController.dispose();
    _invoiceController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final qty = int.tryParse(_qtyController.text.replaceAll('.', '')) ?? 0;
      final cost = int.tryParse(_costController.text.replaceAll('.', '')) ?? 0;

      await db.processStockIn(
        productId: product.id,
        variantId: variant?.id,
        quantity: qty,
        unitCost: cost,
        supplierId: _selectedSupplier?.id,
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
        invoiceRef: _invoiceController.text.trim().isEmpty ? null : _invoiceController.text.trim(),
      );

      ref.invalidate(productProvider);
      ref.invalidate(productWithVariantsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Stok masuk +$qty berhasil dicatat',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(supplierProvider);
    final qty = int.tryParse(_qtyController.text) ?? 0;
    final newStockPreview = currentStock + qty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Stock In — Stok Masuk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Product info card
              _buildProductCard(),
              const SizedBox(height: 20),

              // Stock preview chip
              _buildStockPreview(newStockPreview),
              const SizedBox(height: 24),

              // Quantity
              _buildSectionLabel('Jumlah Barang Masuk *'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                decoration: _inputDecoration(
                  hint: 'e.g. 50',
                  prefix: const Icon(Icons.add_box_rounded, color: AppTheme.primaryColor),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Masukkan jumlah valid';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Cost
              _buildSectionLabel('Harga Beli / Satuan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration(
                  hint: 'Rp 0',
                  prefix: const Icon(Icons.payments_outlined, color: AppTheme.secondaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // Supplier
              _buildSectionLabel('Supplier (Opsional)'),
              const SizedBox(height: 8),
              suppliersAsync.when(
                loading: () => const CircularProgressIndicator(),
                error: (e, _) => Text('$e'),
                data: (supplierList) => DropdownButtonFormField<Supplier?>(
                  initialValue: _selectedSupplier,
                  isExpanded: true,
                  decoration: _inputDecoration(
                    hint: 'Pilih supplier...',
                    prefix: const Icon(Icons.local_shipping_outlined, color: AppTheme.secondaryColor),
                  ),
                  items: [
                    const DropdownMenuItem<Supplier?>(
                      value: null,
                      child: Text('Tanpa Supplier'),
                    ),
                    ...supplierList.map((s) => DropdownMenuItem<Supplier?>(
                          value: s,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (s) => setState(() => _selectedSupplier = s),
                ),
              ),
              const SizedBox(height: 16),

              // Invoice ref
              _buildSectionLabel('Nomor Faktur / Referensi (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _invoiceController,
                decoration: _inputDecoration(
                  hint: 'e.g. INV-2025-001',
                  prefix: const Icon(Icons.receipt_long_outlined, color: AppTheme.tertiaryColor),
                ),
              ),
              const SizedBox(height: 16),

              // Note
              _buildSectionLabel('Catatan (Opsional)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: _inputDecoration(
                  hint: 'Catatan tambahan...',
                  prefix: const Icon(Icons.notes_rounded, color: AppTheme.textSecondary),
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(
                  _isSaving ? 'Menyimpan...' : 'Simpan Stock In',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant != null)
                  Text(
                    '${variant!.name}: ${variant!.optionValue}',
                    style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                Text(
                  'Stok saat ini: $currentStock unit',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: currentStock <= 0 ? AppTheme.errorColor : AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockPreview(int newStock) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.successColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.successColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.trending_up_rounded, color: AppTheme.successColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stok sesudah input:',
                  style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                ),
                Text(
                  '$newStock unit',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '+${_qtyController.text.isEmpty ? 0 : (int.tryParse(_qtyController.text) ?? 0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w800,
                color: AppTheme.successColor,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 13,
        color: AppTheme.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
      ),
    );
  }
}
