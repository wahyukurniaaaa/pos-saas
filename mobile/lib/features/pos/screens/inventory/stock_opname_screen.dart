import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class StockOpnameScreen extends ConsumerStatefulWidget {
  const StockOpnameScreen({super.key});

  @override
  ConsumerState<StockOpnameScreen> createState() => _StockOpnameScreenState();
}

class _StockOpnameScreenState extends ConsumerState<StockOpnameScreen> {
  final _searchController = TextEditingController();
  final _reasonController = TextEditingController();
  final Map<String, int> _physicalStock = {};
  bool _isSaving = false;

  @override
  void dispose() {
    _searchController.dispose();
    _reasonController.dispose();
    super.dispose();
  }
  Future<void> _saveOpname() async {
    if (_physicalStock.isEmpty) return;

    final reason = _reasonController.text.trim();
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi alasan perubahan stok'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    final db = ref.read(databaseProvider);
    final session = ref.read(sessionProvider).value;
    final currentEmployeeId = session?.id ?? 1;

    try {
      for (final entry in _physicalStock.entries) {
        final key = entry.key;
        final physicalValue = entry.value;

        if (key.startsWith('p_')) {
          final id = int.parse(key.replaceFirst('p_', ''));
          final productWithV = (await db.getAllProducts())
              .where((p) => p.id == id)
              .firstOrNull;

          if (productWithV != null && physicalValue != productWithV.stock) {
            await db.insertStockAdjustment(
              StockAdjustmentsCompanion.insert(
                productId: productWithV.id,
                employeeId: currentEmployeeId,
                previousStock: productWithV.stock,
                newStock: physicalValue,
                reason: reason,
              ),
            );
            await db.updateProduct(
              productWithV.copyWith(stock: physicalValue),
            );
          }
        } else if (key.startsWith('v_')) {
          final id = int.parse(key.replaceFirst('v_', ''));
          // Get variant and its product
          final allVariants = await db.getAllVariants();
          final variant = allVariants.where((v) => v.id == id).firstOrNull;

          if (variant != null && physicalValue != variant.stock) {
            await db.insertStockAdjustment(
              StockAdjustmentsCompanion.insert(
                productId: variant.productId,
                variantId: drift.Value(variant.id),
                employeeId: currentEmployeeId,
                previousStock: variant.stock,
                newStock: physicalValue,
                reason: reason,
              ),
            );
            await db.updateVariant(variant.copyWith(stock: physicalValue));
          }
        }
      }

      if (!mounted) return;
      ref.invalidate(productWithVariantsProvider);
      ref.invalidate(productProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penyesuaian stok berhasil disimpan'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan: $e'),
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
    final productsAsync = ref.watch(productWithVariantsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Penyesuaian Stok (Opname)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveOpname,
            child: Text(
              'Simpan',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: ResponsiveCenter(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Cari Produk / SKU',
                      hintStyle:
                          GoogleFonts.poppins(color: AppTheme.textSecondary),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppTheme.textSecondary,
                      ),
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
            Expanded(
              child: productsAsync.when(
                data: (list) {
                  final query = _searchController.text.toLowerCase();
                  final filtered = list.where((p) {
                    return p.product.name.toLowerCase().contains(query) ||
                        p.product.sku.toLowerCase().contains(query);
                  }).toList();

                  if (filtered.isEmpty) {
                    return Center(
                      child: Text(
                        'Tidak ada produk ditemukan',
                        style: GoogleFonts.poppins(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final product = item.product;
                      final variants = item.variants;

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
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
                                      color: product.hasVariants
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      product.hasVariants
                                          ? Icons.layers_outlined
                                          : Icons.inventory_2_outlined,
                                      size: 20,
                                      color: product.hasVariants
                                          ? Colors.blue
                                          : AppTheme.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'SKU: ${product.sku}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (product.hasVariants) ...[
                                const Divider(height: 32),
                                ...variants.map((v) => Padding(
                                      padding: const EdgeInsets.only(bottom: 16),
                                      child: _buildStockAdjuster(
                                        label: '${v.name}: ${v.optionValue}',
                                        key: 'v_${v.id}',
                                        systemStock: v.stock,
                                      ),
                                    )),
                              ] else ...[
                                const Divider(height: 32),
                                _buildStockAdjuster(
                                  label: 'Stok Unit',
                                  key: 'p_${product.id}',
                                  systemStock: product.stock,
                                ),
                              ],
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Alasan Perubahan (Untuk Log Audit)',
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _reasonController,
                    decoration: InputDecoration(
                      hintText: 'Contoh: Barang rusak/hilang',
                      hintStyle:
                          GoogleFonts.poppins(color: AppTheme.textSecondary),
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

  Widget _buildStockAdjuster({
    required String label,
    required String key,
    required int systemStock,
  }) {
    final physical = _physicalStock[key] ?? systemStock;
    final diff = physical - systemStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Di Sistem',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '$systemStock',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() {
                      _physicalStock[key] = (physical - 1).clamp(0, 99999);
                    });
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.errorColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 50,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(8),
                    color: Colors.white,
                  ),
                  child: Text(
                    '$physical',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _physicalStock[key] = physical + 1;
                    });
                  },
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppTheme.successColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Selisih',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    diff > 0 ? '+$diff' : '$diff',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: diff == 0
                          ? AppTheme.textSecondary
                          : diff > 0
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
