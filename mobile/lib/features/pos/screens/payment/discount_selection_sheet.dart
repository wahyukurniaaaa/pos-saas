import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/discount_provider.dart';

final _currency =
    NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

/// Shows a bottom sheet for selecting an active transaction-level discount.
/// Pass [cartSubtotal] to filter eligible discounts (min spend check).
Future<void> showDiscountSelectionSheet(
    BuildContext context, WidgetRef ref, double cartSubtotal) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _DiscountSelectionSheet(cartSubtotal: cartSubtotal),
  );
}

class _DiscountSelectionSheet extends ConsumerWidget {
  final double cartSubtotal;
  const _DiscountSelectionSheet({required this.cartSubtotal});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final validAsync =
        ref.watch(validTransactionDiscountsProvider(cartSubtotal));
    final selectedDiscount = ref.watch(selectedDiscountProvider);

    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Pilih Promo / Voucher',
                    style: GoogleFonts.poppins(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.textSecondary,
                ),
              ],
            ),
          ),
          // Subtotal info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.shopping_cart_rounded,
                      color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 8),
                  Text('Total belanja saat ini: ',
                      style: GoogleFonts.poppins(
                          fontSize: 13, color: AppTheme.textSecondary)),
                  Text(_currency.format(cartSubtotal),
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor)),
                ],
              ),
            ),
          ),
          // List
          Flexible(
            child: validAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (discounts) {
                if (discounts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Tidak ada promo yang berlaku',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                            'Tambah belanjaan atau periksa syarat promo.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppTheme.textSecondary)),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: discounts.length,
                  itemBuilder: (_, i) => _buildDiscountTile(
                      context, ref, discounts[i], selectedDiscount),
                );
              },
            ),
          ),

          // Clear Button
          if (selectedDiscount != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: TextButton(
                onPressed: () {
                  ref.read(selectedDiscountProvider.notifier).state = null;
                  Navigator.pop(context);
                },
                child: Text('Hapus Promo yang Dipilih',
                    style: GoogleFonts.poppins(
                        color: AppTheme.errorColor, fontWeight: FontWeight.w600)),
              ),
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDiscountTile(BuildContext context, WidgetRef ref,
      Discount discount, Discount? selected) {
    final isSelected = selected?.id == discount.id;
    final discountDisplay = discount.type == 'fixed'
        ? _currency.format(discount.value)
        : '${discount.value.toStringAsFixed(0)}%';
    final discountAmount = calculateDiscountAmount(discount, cartSubtotal.toInt());

    return GestureDetector(
      onTap: () {
        ref.read(selectedDiscountProvider.notifier).state =
            isSelected ? null : discount;
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withOpacity(0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        child: Row(
          children: [
            // Tags
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.local_offer_rounded,
                  color: AppTheme.primaryColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(discount.name,
                      style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 4),
                  Wrap(spacing: 6, children: [
                    _chip(discountDisplay,
                        AppTheme.primaryColor, Colors.white),
                    if (discount.minSpend > 0)
                      _chip('Min. ${_currency.format(discount.minSpend)}',
                          Colors.grey.shade100, AppTheme.textSecondary),
                    if (discount.isAutomatic)
                      _chip('Auto', AppTheme.secondaryColor, AppTheme.primaryColor),
                  ]),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Hemat',
                    style: GoogleFonts.poppins(
                        fontSize: 11, color: AppTheme.textSecondary)),
                Text(_currency.format(discountAmount),
                    style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.successColor)),
              ],
            ),
            const SizedBox(width: 10),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                    width: 2),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
        child: Text(label,
            style: GoogleFonts.poppins(
                fontSize: 10, fontWeight: FontWeight.w600, color: fg)),
      );
}
