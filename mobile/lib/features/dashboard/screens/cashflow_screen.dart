import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/database/database.dart';
import 'package:posify_app/features/pos/providers/expense_provider.dart';

class CashFlowScreen extends ConsumerWidget {
  const CashFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashFlow = ref.watch(cashFlowProvider);
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        title: Text('Arus Kas (Cash Flow)',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(cashFlowProvider),
          ),
        ],
      ),
      body: cashFlow.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat: $e')),
        data: (data) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodHeader(),
              const SizedBox(height: 16),
              // ── 3 KPI Cards ────────────────────────────────────────
              Row(
                children: [
                  Expanded(child: _kpiCard('Pendapatan', data.totalRevenue, currency, const Color(0xFF27AE60), Icons.trending_up_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: _kpiCard('Pengeluaran', data.totalExpense, currency, AppTheme.errorColor, Icons.trending_down_rounded)),
                ],
              ),
              const SizedBox(height: 10),
              _netProfitCard(data.netProfit, currency),
              const SizedBox(height: 24),
              // ── Bar Chart ──────────────────────────────────────────────
              if (data.daily.isNotEmpty) ...[
                Text('Grafik Pengeluaran 7 Hari Terakhir',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
                const SizedBox(height: 12),
                _buildBarChart(data.daily),
                const SizedBox(height: 24),
              ],
              // ── Tips section ───────────────────────────────────────────
              _buildTips(data.netProfit),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodHeader() {
    final now = DateTime.now();
    final from = DateTime(now.year, now.month, now.day - 6);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range_rounded, size: 18, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '${DateFormat('d MMM', 'id_ID').format(from)} – ${DateFormat('d MMM yyyy', 'id_ID').format(now)}',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13, color: AppTheme.primaryColor),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String label, int value, NumberFormat fmt, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 8),
          Text(fmt.format(value),
              style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.textPrimary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _netProfitCard(int netProfit, NumberFormat fmt) {
    final isPositive = netProfit >= 0;
    final color = isPositive ? const Color(0xFF27AE60) : AppTheme.errorColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Laba Operasional Bersih',
                  style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Text(fmt.format(netProfit),
                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(isPositive ? Icons.thumb_up_rounded : Icons.warning_rounded, color: color, size: 28),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<DailyExpenseSummary> daily) {
    final max = daily.map((d) => d.total).reduce((a, b) => a > b ? a : b);
    if (max == 0) return const SizedBox.shrink();

    return Container(
      height: 180,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: daily.map((d) {
          final ratio = d.total / max;
          final isMax = d.total == max;
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isMax)
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('Tertinggi', style: GoogleFonts.poppins(fontSize: 8, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                width: 28,
                height: (ratio * 100).clamp(4.0, 100.0),
                decoration: BoxDecoration(
                  color: isMax ? AppTheme.secondaryColor : AppTheme.primaryColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 6),
              Text(DateFormat('E', 'id_ID').format(d.date),
                  style: GoogleFonts.poppins(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTips(int netProfit) {
    final isGood = netProfit > 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isGood ? const Color(0xFF27AE60).withOpacity(0.08) : AppTheme.errorColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isGood ? const Color(0xFF27AE60).withOpacity(0.2) : AppTheme.errorColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(
            isGood ? Icons.lightbulb_rounded : Icons.info_rounded,
            color: isGood ? const Color(0xFF27AE60) : AppTheme.errorColor,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isGood
                  ? 'Bisnis Anda sehat! Laba operasional positif dalam 7 hari terakhir. Pertahankan efisiensi pengeluaran.'
                  : 'Pengeluaran melebihi pendapatan dalam 7 hari terakhir. Tinjau kategori pengeluaran terbesar untuk optimasi.',
              style: GoogleFonts.poppins(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
