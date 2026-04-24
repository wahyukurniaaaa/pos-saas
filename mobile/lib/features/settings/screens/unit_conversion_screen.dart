import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;

final unitConversionProvider = StreamProvider<List<UnitConversion>>((ref) {
  return ref.read(databaseProvider).watchAllUnitConversions();
});

class UnitConversionScreen extends ConsumerStatefulWidget {
  const UnitConversionScreen({super.key});

  @override
  ConsumerState<UnitConversionScreen> createState() => _UnitConversionScreenState();
}

class _UnitConversionScreenState extends ConsumerState<UnitConversionScreen> {
  void _showFormSheet({UnitConversion? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnitConversionForm(existing: existing),
    );
  }

  Future<void> _confirmDelete(UnitConversion item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Hapus Konversi?', style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
        content: Text('Aturan "${item.fromUnit} → ${item.toUnit}" akan dihapus permanen.',
            style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(databaseProvider).deleteUnitConversion(item.id);
      ref.invalidate(unitConversionProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversionsAsync = ref.watch(unitConversionProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text('Konversi Satuan',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: Colors.white)),
        backgroundColor: AppTheme.primaryColor,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormSheet(),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Tambah Aturan',
            style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppTheme.primaryColor.withValues(alpha: 0.07),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contoh: 1 kg = 1000 gr. Saat Stok Masuk, pilih "kg" dan stok disimpan dalam "gr".',
                    style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: conversionsAsync.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horiz_rounded, size: 64,
                            color: AppTheme.textSecondary.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('Belum Ada Aturan Konversi',
                            style: GoogleFonts.poppins(
                                fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                        const SizedBox(height: 8),
                        Text('Tap tombol + untuk menambah konversi\nseperti "1 kg = 1000 gr".',
                            style: GoogleFonts.poppins(fontSize: 13, color: AppTheme.textSecondary),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final item = list[i];
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.swap_horiz_rounded, color: AppTheme.primaryColor),
                        ),
                        title: Text(
                          '1 ${item.fromUnit} = ${item.multiplier % 1 == 0 ? item.multiplier.toInt() : item.multiplier} ${item.toUnit}',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        subtitle: item.notes != null && item.notes!.isNotEmpty
                            ? Text(item.notes!, style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: AppTheme.textSecondary,
                              onPressed: () => _showFormSheet(existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              color: AppTheme.errorColor,
                              onPressed: () => _confirmDelete(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnitConversionForm extends ConsumerStatefulWidget {
  final UnitConversion? existing;
  const _UnitConversionForm({this.existing});

  @override
  ConsumerState<_UnitConversionForm> createState() => _UnitConversionFormState();
}

class _UnitConversionFormState extends ConsumerState<_UnitConversionForm> {
  final _formKey = GlobalKey<FormState>();
  final _fromUnitController = TextEditingController();
  final _toUnitController = TextEditingController();
  final _multiplierController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existing != null) {
      final e = widget.existing!;
      _fromUnitController.text = e.fromUnit;
      _toUnitController.text = e.toUnit;
      _multiplierController.text = e.multiplier % 1 == 0
          ? e.multiplier.toInt().toString()
          : e.multiplier.toString();
      _notesController.text = e.notes ?? '';
    }
  }

  @override
  void dispose() {
    _fromUnitController.dispose();
    _toUnitController.dispose();
    _multiplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    try {
      final multiplier = double.parse(_multiplierController.text);
      if (widget.existing != null) {
        await db.updateUnitConversion(widget.existing!.copyWith(
          fromUnit: _fromUnitController.text.trim().toLowerCase(),
          toUnit: _toUnitController.text.trim().toLowerCase(),
          multiplier: multiplier,
          notes: drift.Value(_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null),
        ));
      } else {
        final session = ref.read(sessionProvider).value;
        final outletId = session?.outletId;
        
        await db.insertUnitConversion(UnitConversionsCompanion.insert(
          fromUnit: _fromUnitController.text.trim().toLowerCase(),
          toUnit: _toUnitController.text.trim().toLowerCase(),
          multiplier: multiplier,
          notes: drift.Value(_notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null),
          outletId: outletId != null ? drift.Value(outletId) : const drift.Value.absent(),
        ));
      }
      ref.invalidate(unitConversionProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan: $e'), backgroundColor: AppTheme.errorColor),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  InputDecoration _inputDecoration(String label, String hint) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 14),
        hintText: hint,
        hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary.withValues(alpha: 0.5), fontSize: 14),
        filled: true,
        fillColor: Colors.grey.shade50,
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
          borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isEdit ? 'Edit Konversi Satuan' : 'Tambah Konversi Satuan',
                style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fromUnitController,
                      decoration: _inputDecoration('Satuan Input', 'misal: kg'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Icon(Icons.arrow_forward_rounded, color: AppTheme.textSecondary),
                  ),
                  Expanded(
                    child: TextFormField(
                      controller: _toUnitController,
                      decoration: _inputDecoration('Satuan Dasar', 'misal: gr'),
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _multiplierController,
                decoration: _inputDecoration('Nilai Konversi', 'misal: 1000'),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Wajib diisi';
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Masukkan angka positif';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                decoration: _inputDecoration('Keterangan (Opsional)', 'misal: 1 karton susu = 12 botol'),
                style: GoogleFonts.poppins(),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _isSaving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Simpan', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
