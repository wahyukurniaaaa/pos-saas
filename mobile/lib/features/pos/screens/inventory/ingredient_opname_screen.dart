import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'stock_opname_history_screen.dart';

class IngredientOpnameScreen extends ConsumerStatefulWidget {
  const IngredientOpnameScreen({super.key});

  @override
  ConsumerState<IngredientOpnameScreen> createState() => _IngredientOpnameScreenState();
}

class _IngredientOpnameScreenState extends ConsumerState<IngredientOpnameScreen> {
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  final Map<int, double> _physicalStock = {}; // ingredientId -> physical qty
  final Map<int, TextEditingController> _inputControllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _controllerFor(Ingredient ingredient) {
    return _inputControllers.putIfAbsent(
      ingredient.id,
      () => TextEditingController(text: ingredient.stockQuantity.toStringAsFixed(2)),
    );
  }

  Future<void> _saveOpname() async {
    if (_physicalStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Tidak ada perubahan stok untuk disimpan'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Harap isi alasan perubahan stok'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = ref.read(databaseProvider);
      final employee = ref.read(sessionProvider).value;
      if (employee == null) {
        throw Exception('Sesi kasir tidak valid');
      }

      final ingredients = ref.read(ingredientProvider).value ?? [];

      await db.transaction(() async {
        final headerId = await db.createDraftOpname(
          StockOpnameCompanion.insert(
            opnameNumber: 'OP-${DateTime.now().millisecondsSinceEpoch}',
            type: 'INGREDIENT',
            status: 'DRAFT',
            createdBy: employee.id,
            notes: drift.Value(reason),
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        for (final entry in _physicalStock.entries) {
          final id = entry.key;
          final physical = entry.value;

          final index = ingredients.indexWhere((i) => i.id == id);
          if (index == -1) continue;
          final ingredient = ingredients[index];

          final diff = physical - ingredient.stockQuantity;
          if (diff == 0.0) continue;

          await db.addOpnameItem(
            StockOpnameItemsCompanion.insert(
              stockOpnameId: headerId,
              ingredientId: drift.Value(id),
              systemStock: ingredient.stockQuantity,
              physicalStock: physical,
              variance: diff,
              varianceReason: drift.Value(reason),
            ),
          );
        }

        await db.submitOpname(headerId);
      });

      if (!mounted) return;
      ref.invalidate(ingredientProvider);

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Penyesuaian stok bahan baku berhasil disimpan'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Gagal menyimpan: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ingredientsAsync = ref.watch(ingredientProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Opname Bahan Baku',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const StockOpnameHistoryScreen(type: 'INGREDIENT'),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Opname',
          ),
          TextButton(
            onPressed:
                (_isSaving || _physicalStock.isEmpty) ? null : _saveOpname,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                color: (_isSaving || _physicalStock.isEmpty)
                    ? Colors.white60
                    : Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            // Search bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Cari Bahan Baku...',
                  hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            // Summary chips
            if (_physicalStock.isNotEmpty)
              Container(
                color: AppTheme.primaryColor.withValues(alpha: 0.07),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    Icon(Icons.pending_actions_rounded, size: 16, color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      '${_physicalStock.length} item diubah — ingat isi alasan di bawah!',
                      style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

            // Ingredient list
            Expanded(
              child: ingredientsAsync.when(
                data: (ingredients) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = ingredients
                      .where((i) => i.name.toLowerCase().contains(query))
                      .toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text('Tidak ada bahan baku ditemukan',
                          style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (ctx, index) {
                      final ingredient = filtered[index];
                      final controller = _controllerFor(ingredient);
                      final physical = _physicalStock[ingredient.id] ?? ingredient.stockQuantity;
                      final diff = physical - ingredient.stockQuantity;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: diff != 0 ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.grey.shade200,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(Icons.kitchen_rounded, size: 18, color: AppTheme.primaryColor),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(ingredient.name,
                                            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15)),
                                        Text('Satuan: ${ingredient.unit}',
                                            style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary)),
                                      ],
                                    ),
                                  ),
                                  if (diff != 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: diff > 0 ? AppTheme.successColor.withValues(alpha: 0.1) : AppTheme.errorColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        diff > 0 ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1),
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: diff > 0 ? AppTheme.successColor : AppTheme.errorColor,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  // System stock (read-only)
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Stok Sistem', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                                        Text(
                                          ingredient.stockQuantity % 1 == 0
                                              ? ingredient.stockQuantity.toInt().toString()
                                              : ingredient.stockQuantity.toStringAsFixed(2),
                                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.east_rounded, color: AppTheme.textSecondary),
                                  const SizedBox(width: 12),
                                  // Physical stock input
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Stok Fisik', style: GoogleFonts.poppins(fontSize: 11, color: AppTheme.textSecondary)),
                                        SizedBox(
                                          height: 44,
                                          child: TextFormField(
                                            controller: controller,
                                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                                            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w700),
                                            decoration: InputDecoration(
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                              filled: true,
                                              fillColor: Colors.grey.shade100,
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              enabledBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: Colors.grey.shade300),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(8),
                                                borderSide: BorderSide(color: AppTheme.primaryColor, width: 1.5),
                                              ),
                                            ),
                                            onChanged: (val) {
                                              final parsed = double.tryParse(val);
                                              if (parsed != null) {
                                                setState(() => _physicalStock[ingredient.id] = parsed);
                                              } else {
                                                setState(() => _physicalStock.remove(ingredient.id));
                                              }
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
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

            // Reason input (sticky bottom)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Alasan Penyesuaian',
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.textSecondary)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Stok Opname Bulanan, Barang rusak',
                      hintStyle: GoogleFonts.poppins(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
