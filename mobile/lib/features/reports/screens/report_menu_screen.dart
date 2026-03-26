import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/reports/screens/loyalty_analytics_screen.dart';
import 'package:posify_app/features/reports/screens/sales_analytics_screen.dart';
import 'package:posify_app/features/reports/screens/stock_loss_report_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
import 'package:posify_app/features/pos/screens/inventory/global_stock_history_screen.dart';
import 'package:posify_app/features/dashboard/screens/cashflow_screen.dart';

class ReportMenuScreen extends StatelessWidget {
  const ReportMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Text(
          'Pusat Laporan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('LAPORAN PENJUALAN'),
            _buildMenuCard(context, [
              _ReportMenuItem(
                icon: Icons.analytics_rounded,
                title: 'Analitik Penjualan',
                subtitle: 'Grafik tren, omzet & rata-rata struk',
                color: AppTheme.primaryColor,
                onTap: () => _nav(context, const SalesAnalyticsScreen()),
              ),
              _ReportMenuItem(
                icon: Icons.receipt_long_rounded,
                title: 'Riwayat Transaksi',
                subtitle: 'Daftar nota, void & detail pembayaran',
                color: AppTheme.tertiaryColor,
                onTap: () => _nav(context, const TransactionHistoryScreen()),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('LAPORAN FINANSIAL'),
            _buildMenuCard(context, [
              _ReportMenuItem(
                icon: Icons.account_balance_wallet_rounded,
                title: 'Arus Kas (Cash Flow)',
                subtitle: 'Ringkasan income vs expense operasional',
                color: Colors.green,
                onTap: () => _nav(context, const CashFlowScreen()),
              ),
              _ReportMenuItem(
                icon: Icons.money_off_csred_rounded,
                title: 'Laporan Loss & Waste',
                subtitle: 'Rekap barang rusak, expired & hilang',
                color: Colors.redAccent,
                onTap: () => _nav(context, const StockLossReportScreen()),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('LAPORAN OPERASIONAL'),
            _buildMenuCard(context, [
              _ReportMenuItem(
                icon: Icons.access_time_rounded,
                title: 'Riwayat Shift',
                subtitle: 'Rekap laci kasir per sesi kerja',
                color: AppTheme.infoColor,
                onTap: () => _nav(context, const ShiftHistoryScreen()),
              ),
              _ReportMenuItem(
                icon: Icons.history_rounded,
                title: 'Mutasi Stok Global',
                subtitle: 'Kartu stok masuk/keluar semua produk',
                color: Colors.orange,
                onTap: () => _nav(context, const GlobalStockHistoryScreen()),
                isLast: true,
              ),
            ]),
            const SizedBox(height: 24),
            _buildSectionTitle('LAPORAN MEMBER & LOYALTY'),
            _buildMenuCard(context, [
              _ReportMenuItem(
                icon: Icons.stars_rounded,
                title: 'Loyalty Analytics',
                subtitle: 'Leaderboard poin & member paling aktif',
                color: Colors.amber.shade700,
                onTap: () => _nav(context, const LoyaltyAnalyticsScreen()),
                isLast: true,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  void _nav(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: AppTheme.textSecondary.withValues(alpha: 0.7),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, List<_ReportMenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.map((item) {
          return Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                leading: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: item.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(item.icon, color: item.color),
                ),
                title: Text(
                  item.title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppTheme.textPrimary,
                  ),
                ),
                subtitle: Text(
                  item.subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
                onTap: item.onTap,
              ),
              if (!item.isLast)
                Divider(
                  height: 1,
                  indent: 72,
                  endIndent: 20,
                  color: Colors.grey.withValues(alpha: 0.1),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _ReportMenuItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;

  const _ReportMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });
}
