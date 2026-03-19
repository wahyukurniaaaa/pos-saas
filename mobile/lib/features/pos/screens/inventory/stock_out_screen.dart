import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

// Args to pass to StockOutScreen
class StockOutArgs {
  final Product product;
  final ProductVariant? variant;

  const StockOutArgs({required this.product, this.variant});
}

class StockOutScreen extends ConsumerStatefulWidget {
  final StockOutArgs args;

  const StockOutScreen({super.key, required this.args});

  @override
  ConsumerState<StockOutScreen> createState() => _StockOutScreenState();
}

class _StockOutScreenState extends ConsumerState<StockOutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController(text: '1');
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

      await db.processStockOut(
        productId: product.id,
        variantId: variant?.id,
        quantity: qty,
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
                  'Stok keluar -$qty berhasil dicatat',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            backgroundColor: AppTheme.dangerColor,
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
            backgroundColor: AppTheme.dangerColor,
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
    final newStockPreview = currentStock - qty;

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Stock Out — Stok Keluar',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.dangerColor, AppTheme.dangerColor.withValues(alpha: 0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ResponsiveCenter(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            children: [
              // Product info card with subtle glassmorphism effect
              _buildProductCard(),
              const SizedBox(height: 24),

              // Stock preview chip with dynamic design
              _buildStockPreview(newStockPreview),
              const SizedBox(height: 32),

              // Form Sections
              _buildSectionLabel('Daftar Pengurangan'),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18),
                decoration: _inputDecoration(
                  hint: 'Contoh: 10',
                  label: 'Jumlah Barang Keluar *',
                  prefix: const Icon(Icons.remove_circle_outline_rounded, color: AppTheme.dangerColor),
                ),
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Masukkan jumlah valid';
                  if (n > currentStock) return 'Stok tidak cukup';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _buildSectionLabel('Informasi Tambahan'),
              const SizedBox(height: 12),

              DropdownButtonFormField<Supplier?>(
                isExpanded: true,
                decoration: _inputDecoration(
                  hint: 'Pilih supplier...',
                  label: 'Supplier (Opsional - untuk Retur)',
                  prefix: const Icon(Icons.local_shipping_outlined, color: AppTheme.tertiaryColor),
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                items: [
                  const DropdownMenuItem<Supplier?>(
                    value: null,
                    child: Text('Tanpa Supplier'),
                  ),
                  ...suppliersAsync.maybeWhen(
                    data: (list) => list.map((s) => DropdownMenuItem<Supplier?>(
                          value: s,
                          child: Text(s.name, overflow: TextOverflow.ellipsis),
                        )),
                    orElse: () => [],
                  ),
                ],
                onChanged: (s) => setState(() => _selectedSupplier = s),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _invoiceController,
                decoration: _inputDecoration(
                  hint: 'Contoh: RETUR-024',
                  label: 'Referensi / No. Dokumen (Opsional)',
                  prefix: const Icon(Icons.receipt_long_outlined, color: AppTheme.tertiaryColor),
                ),
              ),
              const SizedBox(height: 20),

              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: _inputDecoration(
                  hint: 'Jelaskan alasan (Barang Rusak, Kadaluarsa, dll)',
                  label: 'Alasan Keluar *',
                  prefix: const Icon(Icons.chat_bubble_outline_rounded, color: AppTheme.textSecondary),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Harap isi alasan';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.dangerColor.withValues(alpha: 0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.dangerColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    _isSaving ? 'MEMPROSES...' : 'SIMPAN STOK KELUAR',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 1),
                  ),
                ),
              ),
              const SizedBox(height: 50),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.dangerColor.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppTheme.dangerColor.withValues(alpha: 0.1), AppTheme.dangerColor.withValues(alpha: 0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(Icons.inventory_2_rounded, color: AppTheme.dangerColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    color: AppTheme.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (variant != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      '${variant!.name}: ${variant!.optionValue}',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.dangerColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Stok saat ini: $currentStock unit',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppTheme.dangerColor,
                      fontWeight: FontWeight.w700,
                    ),
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.dangerColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.dangerColor.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.trending_down_rounded, color: AppTheme.dangerColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estimasi Stok Akhir',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$newStock unit',
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.dangerColor,
                    letterSpacing: -1,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.dangerColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '-${_qtyController.text.isEmpty ? 0 : (int.tryParse(_qtyController.text) ?? 0)}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w900,
                color: Colors.white,
                fontSize: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w800,
          fontSize: 12,
          color: AppTheme.textSecondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, String? label, Widget? prefix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14),
      hintText: hint,
      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 14),
      prefixIcon: prefix,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppTheme.dangerColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: AppTheme.dangerColor, width: 1),
      ),
    );
  }
}
