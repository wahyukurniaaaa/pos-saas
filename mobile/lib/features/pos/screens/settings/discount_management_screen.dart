import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' show Value;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/providers/discount_provider.dart';

final _currency =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class DiscountManagementScreen extends ConsumerWidget {
  const DiscountManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discountsAsync = ref.watch(discountProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Manajemen Diskon & Promo',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDiscountForm(context, ref, null),
        backgroundColor: AppTheme.secondaryColor,
        foregroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded),
        label: Text('Tambah Promo',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
      ),
      body: ResponsiveCenter(
        child: discountsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (discounts) {
            if (discounts.isEmpty) return _buildEmpty(context, ref);
            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: discounts.length,
              itemBuilder: (_, i) =>
                  _buildDiscountCard(context, ref, discounts[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration:
                BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
            child:
                Icon(Icons.local_offer_outlined, size: 80, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 24),
          Text('Belum ada promo aktif',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 8),
          Text('Buat promo untuk meningkatkan penjualan.',
              style: GoogleFonts.poppins(fontSize: 14, color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildDiscountCard(BuildContext context, WidgetRef ref, Discount d) {
    final isExpired = d.endDate != null &&
        d.endDate!.isBefore(DateTime.now());
    final statusColor = !d.isActive
        ? Colors.grey
        : isExpired
            ? AppTheme.errorColor
            : AppTheme.successColor;
    final statusLabel = !d.isActive ? 'Nonaktif' : isExpired ? 'Kedaluwarsa' : 'Aktif';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              d.scope == 'item'
                  ? Icons.shopping_bag_rounded
                  : Icons.receipt_long_rounded,
              color: AppTheme.primaryColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name,
                    style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                // Value Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        d.type == 'fixed'
                            ? _currency.format(d.value)
                            : '${d.value.toStringAsFixed(0)}%',
                        style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (d.scope == 'item'
                                ? AppTheme.infoColor
                                : AppTheme.tertiaryColor)
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        d.scope == 'item' ? 'Per Item' : 'Per Transaksi',
                        style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: d.scope == 'item'
                                ? AppTheme.infoColor
                                : AppTheme.tertiaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Wrap(spacing: 8, children: [
                  if (d.minSpend > 0)
                    Text('Min. ${_currency.format(d.minSpend)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textSecondary)),
                  if (d.isAutomatic)
                    Text('• Auto',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.secondaryColor, fontWeight: FontWeight.w700)),
                  if (!d.isStackable)
                    Text('• Eksklusif',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.errorColor)),
                  if (d.endDate != null)
                    Text('• Sampai ${DateFormat('dd/MM/yy').format(d.endDate!)}',
                        style: GoogleFonts.poppins(
                            fontSize: 11, color: AppTheme.textSecondary)),
                ]),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(statusLabel,
                    style: GoogleFonts.poppins(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: statusColor)),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _showDiscountForm(context, ref, d),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: AppTheme.infoColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.edit_rounded,
                          size: 15, color: AppTheme.infoColor),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref, d),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.delete_outline_rounded,
                          size: 15, color: AppTheme.errorColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Discount d) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Promo', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text(
            'Apakah Anda yakin ingin menghapus promo "${d.name}"?',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Batal',
                  style: GoogleFonts.poppins(color: AppTheme.textSecondary))),
          TextButton(
            onPressed: () async {
              await ref.read(discountProvider.notifier).remove(d.id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Hapus',
                style: GoogleFonts.poppins(
                    color: AppTheme.errorColor, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDiscountForm(BuildContext context, WidgetRef ref, Discount? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _DiscountFormSheet(existing: existing),
    );
  }
}

// ─── Form Sheet ──────────────────────────────────────────────────────────────

class _DiscountFormSheet extends ConsumerStatefulWidget {
  final Discount? existing;
  const _DiscountFormSheet({this.existing});

  @override
  ConsumerState<_DiscountFormSheet> createState() => _DiscountFormSheetState();
}

class _DiscountFormSheetState extends ConsumerState<_DiscountFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _valueCtrl = TextEditingController();
  final _minSpendCtrl = TextEditingController();
  final _minQtyCtrl = TextEditingController();

  String _scope = 'transaction';
  String _type = 'percentage';
  bool _isAutomatic = false;
  bool _isStackable = true;
  bool _isActive = true;
  DateTime? _startDate;
  DateTime? _endDate;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final d = widget.existing;
    if (d != null) {
      _nameCtrl.text = d.name;
      _valueCtrl.text = d.value.toString();
      _minSpendCtrl.text = d.minSpend > 0 ? d.minSpend.toString() : '';
      _minQtyCtrl.text = d.minQty > 1 ? d.minQty.toString() : '';
      _scope = d.scope;
      _type = d.type;
      _isAutomatic = d.isAutomatic;
      _isStackable = d.isStackable;
      _isActive = d.isActive;
      _startDate = d.startDate;
      _endDate = d.endDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    _minSpendCtrl.dispose();
    _minQtyCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final session = ref.read(sessionProvider).value;
    final outletId = session?.outletId;

    final entry = DiscountsCompanion(
      id: widget.existing != null ? Value(widget.existing!.id) : const Value.absent(),
      name: Value(_nameCtrl.text.trim()),
      scope: Value(_scope),
      type: Value(_type),
      value: Value(double.parse(_valueCtrl.text.trim())),
      minSpend: Value(int.tryParse(_minSpendCtrl.text.trim()) ?? 0),
      minQty: Value(int.tryParse(_minQtyCtrl.text.trim()) ?? 1),
      isAutomatic: Value(_isAutomatic),
      isStackable: Value(_isStackable),
      isActive: Value(_isActive),
      startDate: Value(_startDate ?? DateTime.now()),
      endDate: Value(_endDate),
      outletId: outletId != null ? Value(outletId) : const Value.absent(),
    );
    await ref.read(discountProvider.notifier).save(entry);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.primaryColor),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.existing == null ? 'Tambah Promo' : 'Edit Promo';
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),

              // Name
              _sectionLabel('Nama Promo'),
              TextFormField(
                controller: _nameCtrl,
                decoration: _inputDeco('Contoh: Diskon Akhir Tahun', Icons.local_offer_rounded),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 16),

              // Scope
              _sectionLabel('Berlaku Untuk'),
              Row(children: [
                _segmentBtn('Transaksi', 'transaction', Icons.receipt_long_rounded),
                const SizedBox(width: 8),
                _segmentBtn('Per Item', 'item', Icons.shopping_bag_rounded),
              ]),
              const SizedBox(height: 16),

              // Type + Value
              _sectionLabel('Tipe Diskon'),
              Row(children: [
                _segmentBtn('Persentase (%)', 'percentage', Icons.percent_rounded),
                const SizedBox(width: 8),
                _segmentBtn('Nominal (Rp)', 'fixed', Icons.attach_money_rounded),
              ]),
              const SizedBox(height: 12),
              TextFormField(
                controller: _valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: _inputDeco(
                    _type == 'percentage' ? 'Contoh: 10 (10%)' : 'Contoh: 5000',
                    Icons.discount_rounded),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Nilai wajib diisi';
                  final n = double.tryParse(v.trim());
                  if (n == null || n <= 0) return 'Masukkan angka valid';
                  if (_type == 'percentage' && n > 100) return 'Max 100%';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Min Spend
              _sectionLabel('Minimal Belanja (Rp)'),
              TextFormField(
                controller: _minSpendCtrl,
                keyboardType: TextInputType.number,
                decoration:
                    _inputDeco('0 = tidak ada syarat', Icons.shopping_cart_rounded),
              ),
              if (_scope == 'item') ...[
                const SizedBox(height: 16),
                _sectionLabel('Minimal Quantity'),
                TextFormField(
                  controller: _minQtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: _inputDeco('Contoh: 3 (beli 3 dapat diskon)', Icons.format_list_numbered_rounded),
                ),
              ],
              const SizedBox(height: 16),

              // Periods
              _sectionLabel('Periode Promo'),
              Row(children: [
                Expanded(
                  child: _datePicker(
                      label: 'Mulai', date: _startDate, onTap: () => _pickDate(true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _datePicker(
                      label: 'Selesai', date: _endDate, onTap: () => _pickDate(false)),
                ),
              ]),
              const SizedBox(height: 16),

              // Toggles
              _toggleRow('Terapkan Otomatis', 'Aktif jika syarat terpenuhi tanpa pilih manual.', _isAutomatic,
                  (v) => setState(() => _isAutomatic = v)),
              _toggleRow('Dapat Digabung', 'Bisa dipakai bersamaan dengan diskon lain.', _isStackable,
                  (v) => setState(() => _isStackable = v)),
              _toggleRow('Status Aktif', 'Promo bisa tampil & dipilih kasir.', _isActive,
                  (v) => setState(() => _isActive = v)),

              const SizedBox(height: 24),

              // Save
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                    foregroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text('Simpan Promo',
                          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppTheme.textPrimary)),
      );

  Widget _segmentBtn(String label, String value, IconData icon) {
    final active = (_scope == value) || (_type == value);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (value == 'transaction' || value == 'item') {
              _scope = value;
            } else {
              _type = value;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? AppTheme.primaryColor : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker({required String label, required DateTime? date, required VoidCallback onTap}) {
    final fmt = DateFormat('dd MMM yyyy');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary)),
                Text(date != null ? fmt.format(date) : 'Pilih Tanggal',
                    style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: date != null ? AppTheme.textPrimary : AppTheme.textSecondary)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleRow(String label, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textPrimary)),
                  Text(subtitle,
                      style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.5),
              activeThumbColor: AppTheme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5)),
      );
}
