import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:drift/drift.dart' as drift;
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';
import 'package:intl/intl.dart';
import 'stock_opname_history_screen.dart';

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
    if (_physicalStock.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada perubahan stok untuk disimpan'),
          backgroundColor: Colors.blue,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

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
    final employee = ref.read(sessionProvider).value;

    if (employee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi kasir tidak valid'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() => _isSaving = false);
      return;
    }

    try {
      await db.transaction(() async {
        final headerId = await db.createDraftOpname(
          StockOpnameCompanion.insert(
            opnameNumber: 'OP-${DateTime.now().millisecondsSinceEpoch}',
            type: 'PRODUCT',
            status: 'DRAFT',
            createdBy: employee.id,
            notes: drift.Value(reason),
            createdAt: DateTime.now().toIso8601String(),
          ),
        );

        for (final entry in _physicalStock.entries) {
          final key = entry.key;
          final physicalValue = entry.value;

          if (key.startsWith('p_')) {
            final id = key.replaceFirst('p_', '');
            // Use specific getter for efficiency
            final product = await db.getProduct(id);

            if (product != null && physicalValue != product.stock) {
              await db.addOpnameItem(
                StockOpnameItemsCompanion.insert(
                  stockOpnameId: headerId,
                  productId: drift.Value(product.id),
                  systemStock: product.stock.toDouble(),
                  physicalStock: physicalValue.toDouble(),
                  variance: (physicalValue - product.stock).toDouble(),
                  varianceReason: drift.Value(reason),
                ),
              );
            }
          } else if (key.startsWith('v_')) {
            final id = key.replaceFirst('v_', '');
            // Use specific getter for efficiency
            final variant = await db.getVariant(id);

            if (variant != null && physicalValue != variant.stock) {
              await db.addOpnameItem(
                StockOpnameItemsCompanion.insert(
                  stockOpnameId: headerId,
                  productId: drift.Value(variant.productId),
                  variantId: drift.Value(variant.id),
                  systemStock: variant.stock.toDouble(),
                  physicalStock: physicalValue.toDouble(),
                  variance: (physicalValue - variant.stock).toDouble(),
                  varianceReason: drift.Value(reason),
                ),
              );
            }
          }
        }

        await db.submitOpname(headerId);
      });

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
            behavior: SnackBarBehavior.floating,
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
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const StockOpnameHistoryScreen(type: 'PRODUCT'),
              ),
            ),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Opname',
          ),
          TextButton(
            onPressed: (_isSaving || _physicalStock.isEmpty) ? null : _saveOpname,
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
                                      child: _StockAdjusterItem(
                                        label: '${v.name}: ${v.optionValue}',
                                        itemKey: 'v_${v.id}',
                                        systemStock: v.stock,
                                        physicalStock: _physicalStock['v_${v.id}'] ?? v.stock,
                                        onChanged: (val) {
                                          setState(() {
                                            _physicalStock['v_${v.id}'] = val;
                                          });
                                        },
                                      ),
                                    )),
                              ] else ...[
                                const Divider(height: 32),
                                _StockAdjusterItem(
                                  label: 'Stok Unit',
                                  itemKey: 'p_${product.id}',
                                  systemStock: product.stock,
                                  physicalStock: _physicalStock['p_${product.id}'] ?? product.stock,
                                  onChanged: (val) {
                                    setState(() {
                                      _physicalStock['p_${product.id}'] = val;
                                    });
                                  },
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
}

class _StockAdjusterItem extends ConsumerStatefulWidget {
  final String label;
  final String itemKey;
  final int systemStock;
  final int physicalStock;
  final ValueChanged<int> onChanged;

  const _StockAdjusterItem({
    required this.label,
    required this.itemKey,
    required this.systemStock,
    required this.physicalStock,
    required this.onChanged,
  });

  @override
  ConsumerState<_StockAdjusterItem> createState() => _StockAdjusterItemState();
}

class _StockAdjusterItemState extends ConsumerState<_StockAdjusterItem> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.physicalStock.toString());
  }

  @override
  void didUpdateWidget(_StockAdjusterItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.physicalStock != widget.physicalStock) {
      final currentPos = _controller.selection;
      _controller.text = widget.physicalStock.toString();
      _controller.selection = currentPos;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    final diff = widget.physicalStock - widget.systemStock;
    final isVariant = widget.itemKey.startsWith('v_');
    final id = widget.itemKey.replaceFirst(isVariant ? 'v_' : 'p_', '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            FutureBuilder<String?>(
              future: ref.read(databaseProvider).getLastAdjustDate(
                    isVariant ? '' : id,
                    variantId: isVariant ? id : null,
                  ),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    final date = DateTime.parse(snapshot.data!);
                    final formatted = DateFormat('dd MMM yyyy').format(date);
                    return Text(
                      'Opname Terakhir: $formatted',
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: AppTheme.primaryColor.withValues(alpha: 0.7),
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  } catch (_) {
                    return const SizedBox.shrink();
                  }
                }
                return const SizedBox.shrink();
              },
            ),
          ],
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
                    '${widget.systemStock}',
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
                    final newVal = (widget.physicalStock - 1).clamp(0, 99999);
                    widget.onChanged(newVal);
                  },
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppTheme.errorColor,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                Container(
                  width: 70,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _controller,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    onChanged: (v) {
                      final val = int.tryParse(v) ?? 0;
                      widget.onChanged(val);
                    },
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final newVal = widget.physicalStock + 1;
                    widget.onChanged(newVal);
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
