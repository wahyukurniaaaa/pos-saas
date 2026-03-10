import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/core/theme/app_theme.dart';

class WhatsAppReceiptWidget extends StatelessWidget {
  final TransactionWithItems data;
  final StoreProfileData? storeProfile;

  const WhatsAppReceiptWidget({
    super.key,
    required this.data,
    this.storeProfile,
  });

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final date = DateFormat(
      'dd/MM/yyyy HH:mm',
    ).format(data.transaction.createdAt);

    return Container(
      width: 400, // Fixed width for consistent screenshot quality
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(color: Colors.white),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo & Store Info
          if (storeProfile?.name != null)
            Text(
              storeProfile!.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          if (storeProfile?.address != null)
            Text(
              storeProfile!.address!,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          const SizedBox(height: 24),
          const Divider(thickness: 1, color: AppTheme.borderColor),
          const SizedBox(height: 16),

          // Transaction Info
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NO. STRUK:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                data.transaction.receiptNumber,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TANGGAL:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                date,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(thickness: 1, color: AppTheme.borderColor),
          const SizedBox(height: 16),

          // Items
          ...data.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          item.product.name,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${item.item.quantity} x ${currency.format(item.item.priceAtTransaction)}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    currency.format(item.item.subtotal),
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          const Divider(thickness: 1, color: AppTheme.borderColor),
          const SizedBox(height: 24),

          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimary,
                ),
              ),
              Text(
                currency.format(data.transaction.totalAmount),
                style: GoogleFonts.inter(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PEMBAYARAN:',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Text(
                data.transaction.paymentMethod.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 48),
          Text(
            'Terima kasih telah berbelanja!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'POSIFY - Solusi POS Pintar',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
