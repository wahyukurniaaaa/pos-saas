import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/inventory/providers/po_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class PoDetailScreen extends ConsumerStatefulWidget {
  final int poId;
  const PoDetailScreen({super.key, required this.poId});

  @override
  ConsumerState<PoDetailScreen> createState() => _PoDetailScreenState();
}

class _PoDetailScreenState extends ConsumerState<PoDetailScreen> {
  bool _isProcessing = false;

  // Map of itemId → received qty controller
  final Map<int, TextEditingController> _receiveControllers = {};

  @override
  void dispose() {
    for (final c in _receiveControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Color _statusColor(String status) => switch (status) {
        'draft' => Colors.grey.shade600,
        'sent' => Colors.blue.shade700,
        'received' => Colors.green.shade700,
        'cancelled' => Colors.red.shade600,
        _ => Colors.grey,
      };

  String _statusLabel(String status) => switch (status) {
        'draft' => 'Draft',
        'sent' => 'Dikirim ke Supplier',
        'received' => 'Diterima',
        'cancelled' => 'Dibatalkan',
        _ => status,
      };

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await ref
          .read(purchaseOrdersProvider.notifier)
          .updateStatus(widget.poId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status PO berhasil diubah ke "${_statusLabel(newStatus)}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _receiveAll(List<PurchaseOrderItem> items) async {
    final receivedItems = items.map((item) {
      final qty = double.tryParse(
              _receiveControllers[item.id]?.text ?? '${item.quantity}') ??
          item.quantity;
      return (itemId: item.id, receivedQty: qty);
    }).toList();

    setState(() => _isProcessing = true);
    try {
      await ref.read(purchaseOrdersProvider.notifier).receivePO(
            poId: widget.poId,
            receivedItems: receivedItems,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Stok berhasil diperbarui'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // Refresh item list
      ref.invalidate(poItemsProvider(widget.poId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final posAsync = ref.watch(purchaseOrdersProvider);
    final itemsAsync = ref.watch(poItemsProvider(widget.poId));

    final po = posAsync.value
        ?.firstWhere((p) => p.id == widget.poId, orElse: () => throw Exception());

    if (po == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final statusColor = _statusColor(po.status);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text(
          'PO #${po.id}',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (items) {
          // Initialize controllers
          for (final item in items) {
            _receiveControllers.putIfAbsent(
                item.id,
                () => TextEditingController(
                    text: '${item.quantity}'));
          }

          return ResponsiveCenter(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.receipt_long_rounded,
                              color: statusColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'PO #${po.id}',
                                style: GoogleFonts.poppins(
                                    fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                po.orderedAt.substring(0, 10),
                                style: GoogleFonts.poppins(
                                    fontSize: 11, color: AppTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 5),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _statusLabel(po.status),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  _sectionLabel('ITEM PESANAN'),
                  const SizedBox(height: 10),

                  // Items list
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: items.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(child: Text('Tidak ada item')),
                          )
                        : Column(
                            children: items.asMap().entries.map((e) {
                              final item = e.value;
                              final isLast = e.key == items.length - 1;
                              return Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(14),
                                    child: Row(
                                      children: [
                                        Icon(
                                          item.productId != null
                                              ? Icons.inventory_2_rounded
                                              : Icons.kitchen_rounded,
                                          color: AppTheme.primaryColor,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                item.itemName,
                                                style: GoogleFonts.poppins(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600),
                                              ),
                                              Text(
                                                'Dipesan: ${item.quantity} ${item.unit}',
                                                style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color:
                                                        AppTheme.textSecondary),
                                              ),
                                              if (po.status == 'received')
                                                Text(
                                                  'Diterima: ${item.receivedQuantity} ${item.unit}',
                                                  style: GoogleFonts.poppins(
                                                    fontSize: 11,
                                                    color: Colors.green.shade700,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        // Receive qty input (only for 'sent' status)
                                        if (po.status == 'sent')
                                          SizedBox(
                                            width: 70,
                                            child: TextFormField(
                                              controller:
                                                  _receiveControllers[item.id],
                                              keyboardType: TextInputType.number,
                                              decoration: InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(8)),
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 8),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (!isLast)
                                    Divider(
                                        height: 1,
                                        indent: 44,
                                        color: Colors.grey.shade100),
                                ],
                              );
                            }).toList(),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  if (_isProcessing)
                    const Center(child: CircularProgressIndicator())
                  else ...[
                    if (po.status == 'draft') ...[
                      _actionButton(
                        label: 'Kirim ke Supplier',
                        icon: Icons.send_rounded,
                        color: AppTheme.secondaryColor,
                        fgColor: AppTheme.primaryColor,
                        onTap: () => _updateStatus('sent'),
                      ),
                      const SizedBox(height: 10),
                      _actionButton(
                        label: 'Batalkan PO',
                        icon: Icons.cancel_outlined,
                        color: Colors.red.shade600,
                        onTap: () => _updateStatus('cancelled'),
                        outlined: true,
                      ),
                    ],
                    if (po.status == 'sent')
                      _actionButton(
                        label: 'Tandai Diterima & Update Stok',
                        icon: Icons.check_circle_rounded,
                        color: Colors.green.shade700,
                        onTap: () => _receiveAll(items),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      );

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    Color? fgColor,
    required VoidCallback onTap,
    bool outlined = false,
  }) {
    final textColor = fgColor ?? Colors.white;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18),
              label: Text(label,
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(
                foregroundColor: color,
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              icon: Icon(icon, size: 18, color: textColor),
              label: Text(label,
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w700, color: textColor)),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
            ),
    );
  }
}
