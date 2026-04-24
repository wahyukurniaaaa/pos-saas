import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'ingredient_form_screen.dart';
import 'ingredient_history_screen.dart';
import 'ingredient_opname_screen.dart';

class IngredientListScreen extends ConsumerStatefulWidget {
  const IngredientListScreen({super.key});

  @override
  ConsumerState<IngredientListScreen> createState() => _IngredientListScreenState();
}

class _IngredientListScreenState extends ConsumerState<IngredientListScreen> {
  final _searchController = TextEditingController();
  final _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Bahan Baku',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Opname Stok Bahan Baku',
            icon: const Icon(Icons.fact_check_outlined, color: Colors.white),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IngredientOpnameScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Container(
            color: AppTheme.primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildSearchBar(),
          ),
        ),
      ),
      body: ingredientsAsync.when(
        data: (ingredients) {
          if (ingredients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.kitchen_rounded, size: 56, color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                  ),
                  const SizedBox(height: 20),
                  Text('Belum Ada Bahan Baku',
                      style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Tap tombol + untuk menambahkan\nbahan baku pertama Anda.',
                      style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center),
                ],
              ),
            );
          }

          final lowStockItems = ingredients.where((i) => i.stockQuantity <= i.minStockThreshold && i.minStockThreshold > 0).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (lowStockItems > 0)
                _buildLowStockBanner(lowStockItems),

              ...ingredients.map((item) => _buildIngredientCard(item)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Terjadi kesalahan: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Tambah Bahan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildLowStockBanner(int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.orange.shade700, Colors.orange.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.orange.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$count bahan baku stok menipis! Segera tambah stok.',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientCard(Ingredient item) {
    final isLowStock = item.minStockThreshold > 0 && item.stockQuantity <= item.minStockThreshold;

    return GestureDetector(
      onTap: () => _showActionSheet(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLowStock ? Colors.orange.shade200 : Colors.grey.shade100,
            width: isLowStock ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isLowStock
                    ? Colors.orange.shade50
                    : AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.kitchen_rounded,
                color: isLowStock ? Colors.orange.shade600 : AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'HPP: ${_currencyFormatter.format(item.averageCost)} / ${item.unit}',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatStock(item.stockQuantity, item.unit),
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: isLowStock ? Colors.orange.shade700 : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isLowStock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Menipis',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  )
                else
                  Text(
                    'Min: ${_formatStock(item.minStockThreshold, item.unit)}',
                    style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary),
                  ),
              ],
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatStock(double qty, String unit) {
    final formatted = qty % 1 == 0 ? qty.toInt().toString() : qty.toStringAsFixed(1);
    return '$formatted $unit';
  }

  void _showActionSheet(Ingredient item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _IngredientActionSheet(
        item: item,
        onAddStock: () => _showAddStockModal(item),
        onRemoveStock: () => _showRemoveStockModal(item),
        onHistory: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => IngredientHistoryScreen(ingredient: item)),
          );
        },
        onEdit: () {
          Navigator.pop(ctx);
          _openForm(ingredientId: item.id);
        },
        onDelete: () {
          Navigator.pop(ctx);
          _confirmDelete(item);
        },
      ),
    );
  }

  void _showAddStockModal(Ingredient item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddStockModal(ingredient: item),
    ).then((_) => ref.invalidate(ingredientProvider));
  }

  void _showRemoveStockModal(Ingredient item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _RemoveStockBottomSheet(ingredient: item),
    ).then((_) => ref.invalidate(ingredientProvider));
  }

  Future<void> _confirmDelete(Ingredient item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Bahan Baku', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
          'Apakah Anda yakin ingin menghapus "${item.name}"? Tindakan ini tidak dapat dibatalkan.',
          style: GoogleFonts.poppins(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Batal', style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor, foregroundColor: Colors.white),
            child: Text('Hapus', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final db = ref.read(databaseProvider);
      await db.deleteIngredient(item);
      ref.invalidate(ingredientProvider);
    }
  }

  Widget _buildSearchBar() {
    return TextField(
      controller: _searchController,
      onChanged: (val) => ref.read(ingredientProvider.notifier).setSearch(val),
      style: GoogleFonts.poppins(color: Colors.white),
      decoration: InputDecoration(
        hintText: 'Cari bahan baku...',
        hintStyle: GoogleFonts.poppins(color: Colors.white60, fontSize: 14),
        prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70, size: 20),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.15),
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

  void _openForm({String? ingredientId}) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => IngredientFormScreen(ingredientId: ingredientId)),
    ).then((_) => ref.invalidate(ingredientProvider));
  }
}

class _IngredientActionSheet extends StatelessWidget {
  final Ingredient item;
  final VoidCallback onAddStock;
  final VoidCallback onRemoveStock;
  final VoidCallback onHistory;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _IngredientActionSheet({
    required this.item,
    required this.onAddStock,
    required this.onRemoveStock,
    required this.onHistory,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Text(item.name,
              style: GoogleFonts.poppins(fontSize: 17, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          Text('Stok: ${item.stockQuantity} ${item.unit}',
              style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          _ActionItem(
            icon: Icons.add_circle_outline_rounded,
            label: 'Tambah Stok',
            subtitle: 'Catat pembelian bahan baku baru',
            color: const Color(0xFF0D9488),
            onTap: onAddStock,
          ),
          const SizedBox(height: 12),
          _ActionItem(
             icon: Icons.remove_circle_outline_rounded,
             label: 'Stok Keluar (Waste)',
             subtitle: 'Catat bahan rusak atau kedaluwarsa',
             color: Colors.orange.shade800,
             onTap: onRemoveStock,
          ),
          const SizedBox(height: 12),
          _ActionItem(
            icon: Icons.history_rounded,
            label: 'Lihat Riwayat',
            subtitle: 'Audit keluar masuk stok bahan',
            color: Colors.blue.shade700,
            onTap: onHistory,
          ),
          const SizedBox(height: 12),
          _ActionItem(
            icon: Icons.edit_rounded,
            label: 'Edit Bahan Baku',
            subtitle: 'Ubah nama, satuan, atau HPP',
            color: AppTheme.primaryColor,
            onTap: onEdit,
          ),
          const SizedBox(height: 12),
          _ActionItem(
            icon: Icons.delete_outline_rounded,
            label: 'Hapus Bahan Baku',
            subtitle: 'Hapus permanen dari sistem',
            color: AppTheme.errorColor,
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 14, color: color)),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddStockModal extends ConsumerStatefulWidget {
  final Ingredient ingredient;
  const _AddStockModal({required this.ingredient});

  @override
  ConsumerState<_AddStockModal> createState() => _AddStockModalState();
}

class _AddStockModalState extends ConsumerState<_AddStockModal> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _costController = TextEditingController();
  final _reasonController = TextEditingController();
  String? _selectedSupplierId;
  bool _isLoading = false;

  late String _selectedInputUnit;

  static const Map<String, Map<String, double>> _conversions = {
    'gr': {'gr': 1.0, 'kg': 1000.0},
    'ml': {'ml': 1.0, 'liter': 1000.0, 'l': 1000.0},
    'pcs': {'pcs': 1.0},
  };

  List<String> get _availableUnits {
    final base = widget.ingredient.unit;
    return _conversions[base]?.keys.toList() ?? [base];
  }

  double get _conversionMultiplier {
    final base = widget.ingredient.unit;
    return _conversions[base]?[_selectedInputUnit] ?? 1.0;
  }

  @override
  void initState() {
    super.initState();
    _selectedInputUnit = widget.ingredient.unit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _costController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: const Color(0xFF0D9488).withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0D9488), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tambah Stok', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
                        Text(widget.ingredient.name, style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                      decoration: _inputStyle('Jumlah'),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedInputUnit,
                      decoration: _inputStyle('Satuan'),
                      items: _availableUnits.map((u) => DropdownMenuItem(value: u, child: Text(u.toUpperCase()))).toList(),
                      onChanged: (val) => setState(() => _selectedInputUnit = val!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, _) {
                final suppliers = ref.watch(supplierProvider);
                return suppliers.when(
                  data: (list) => list.isEmpty ? const SizedBox.shrink() : DropdownButtonFormField<String>(
                    decoration: _inputStyle('Supplier (Opsional)', icon: Icons.store_rounded),
                    items: list.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (v) => _selectedSupplierId = v,
                  ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, ___) => const SizedBox.shrink(),
                );
              }),
              const SizedBox(height: 16),
              TextFormField(
                controller: _costController,
                keyboardType: TextInputType.number,
                decoration: _inputStyle('Harga Beli per ${widget.ingredient.unit}', prefixText: 'Rp '),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: _inputStyle('Keterangan'),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D9488),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, {String? prefixText, IconData? icon}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefixText,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final qty = double.parse(_quantityController.text.replaceAll(',', '.'));
      final outletId = ref.read(sessionProvider).value?.outletId;
      await ref.read(databaseProvider).addIngredientStock(
        ingredientId: widget.ingredient.id,
        quantityInBaseUnit: qty * _conversionMultiplier,
        supplierId: _selectedSupplierId,
        newCostPerUnit: double.tryParse(_costController.text),
        reason: _reasonController.text.trim(),
        outletId: outletId,
      );
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _RemoveStockBottomSheet extends ConsumerStatefulWidget {
  final Ingredient ingredient;
  const _RemoveStockBottomSheet({required this.ingredient});

  @override
  ConsumerState<_RemoveStockBottomSheet> createState() => _RemoveStockBottomSheetState();
}

class _RemoveStockBottomSheetState extends ConsumerState<_RemoveStockBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _qtyController = TextEditingController();
  final _reasonController = TextEditingController();
  String _selectedReason = 'WASTE';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Stok Keluar (Waste)', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _selectedReason,
                decoration: InputDecoration(labelText: 'Alasan', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                items: [
                  const DropdownMenuItem(value: 'WASTE', child: Text('Rusak / Basi')),
                  const DropdownMenuItem(value: 'RETURN', child: Text('Retur ke Supplier')),
                  const DropdownMenuItem(value: 'ADJUST', child: Text('Penyesuaian Manual')),
                ],
                onChanged: (v) => setState(() => _selectedReason = v!),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _qtyController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Jumlah Keluar (${widget.ingredient.unit})', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14))),
                validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _reasonController, decoration: InputDecoration(labelText: 'Catatan tambahan', filled: true, fillColor: Colors.grey.shade50, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)))),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setState(() => _isLoading = true);
                    final qty = double.parse(_qtyController.text.replaceAll(',', '.'));
                    final outletId = ref.read(sessionProvider).value?.outletId;
                    await ref.read(databaseProvider).deductIngredientStock(
                      ingredientId: widget.ingredient.id,
                      quantityInBaseUnit: qty,
                      type: _selectedReason,
                      reason: _reasonController.text.trim(),
                      outletId: outletId,
                    );
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade800, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Simpan Pengeluaran Stok'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
