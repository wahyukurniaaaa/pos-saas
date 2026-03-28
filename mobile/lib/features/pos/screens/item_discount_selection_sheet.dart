import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/pos/providers/discount_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';

final _currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

class ItemDiscountSelectionSheet extends ConsumerWidget {
  final CartItem cartItem;

  const ItemDiscountSelectionSheet({super.key, required this.cartItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemTotal = (cartItem.effectivePrice * cartItem.quantity).toDouble();
    final validAsync = ref.watch(validItemDiscountsProvider(itemTotal));
    final selectedDiscount = cartItem.appliedDiscount;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
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
                Text('Diskon Item',
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
          // List
          Flexible(
            child: validAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (discounts) {
                // Filter by minQty
                final eligibleDiscounts = discounts.where((d) => d.minQty <= cartItem.quantity).toList();

                if (eligibleDiscounts.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.local_offer_outlined,
                            size: 60, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Tidak ada diskon item',
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: AppTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(
                            'Belum ada diskon produk yang berlaku.',
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
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: eligibleDiscounts.length,
                  itemBuilder: (_, i) => _buildDiscountTile(
                      context, ref, eligibleDiscounts[i], selectedDiscount, itemTotal.toInt()),
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
                  ref.read(cartProvider.notifier).updateItemDiscount(cartItem.cartKey, null);
                  Navigator.pop(context);
                },
                child: Text('Hapus Diskon Item',
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
      Discount discount, Discount? selected, int itemTotal) {
    final isSelected = selected?.id == discount.id;
    final discountDisplay = discount.type == 'fixed'
        ? _currency.format(discount.value)
        : '${discount.value.toStringAsFixed(0)}%';
    final discountAmount = calculateDiscountAmount(discount, itemTotal);

    return GestureDetector(
      onTap: () {
        ref.read(cartProvider.notifier).updateItemDiscount(
            cartItem.cartKey, isSelected ? null : discount);
        Navigator.pop(context);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.06)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.secondaryColor.withValues(alpha: 0.15),
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(6)),
                        child: Text(discountDisplay,
                            style: GoogleFonts.poppins(
                                fontSize: 10, fontWeight: FontWeight.w600, color: Colors.white)),
                      ),
                    ],
                  )
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
          ],
        ),
      ),
    );
  }
}
