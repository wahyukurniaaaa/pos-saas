import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lumio/core/database/database.dart';
import 'package:lumio/core/providers/database_provider.dart';
import 'package:lumio/core/theme/app_theme.dart';
import 'package:lumio/features/auth/providers/owner_provider.dart';
import 'package:lumio/features/dashboard/widgets/low_stock_widget.dart';

// ─── KPI item model (public mirror of _KpiData in OwnerDashboardScreen) ────────
class KpiItem {
  final String label;
  final String value;
  final String? subtitle;
  final String? delta;
  final bool? deltaPositive;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const KpiItem({
    required this.label,
    required this.value,
    this.subtitle,
    this.delta,
    this.deltaPositive,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

// ─── Dashboard KPI data model ───────────────────────────────────────────────────
class DashboardKpiData {
  final List<KpiItem> kpis;
  final LowStockSummary lowStockSummary;

  const DashboardKpiData({
    required this.kpis,
    required this.lowStockSummary,
  });
}

// ─── DashboardKpiNotifier ───────────────────────────────────────────────────────
class DashboardKpiNotifier extends AsyncNotifier<DashboardKpiData> {
  Timer? _debounceTimer;
  StreamSubscription? _txnSubscription;

  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  Future<DashboardKpiData> build() async {
    // Req 10.5: use ref.select() to avoid rebuilds when other session fields change
    final outletId = ref.watch(
      sessionProvider.select((s) => s.value?.outletId),
    );

    if (outletId == null) {
      return const DashboardKpiData(
        kpis: [],
        lowStockSummary: LowStockSummary(products: [], ingredients: []),
      );
    }

    final db = ref.read(databaseProvider);

    // Req 10.7: watch transactions stream with 2000ms debounce
    _txnSubscription?.cancel();
    _txnSubscription = db.watchAllTransactions(outletId).listen((_) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 2000), () {
        if (ref.mounted) ref.invalidateSelf();
      });
    });

    // Req 10.8 & 15.4: cancel timer and subscription on dispose
    ref.onDispose(() {
      _debounceTimer?.cancel();
      _txnSubscription?.cancel();
    });

    return _fetchKpiData(outletId, db);
  }

  /// Runs the same 8 queries as _loadStats() in OwnerDashboardScreen via Future.wait()
  Future<DashboardKpiData> _fetchKpiData(
      String outletId, LumioDatabase db) async {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final yestStart = todayStart.subtract(const Duration(days: 1));
    final yestEnd = DateTime(
      yestStart.year,
      yestStart.month,
      yestStart.day,
      23,
      59,
      59,
    );

    // Req 10.2: all 8 queries in parallel
    final results = await Future.wait([
      db.getTotalRevenue(todayStart, todayEnd, outletId),       // 0
      db.getTotalRevenue(yestStart, yestEnd, outletId),         // 1
      db.getTotalTransactions(todayStart, todayEnd, outletId),  // 2
      db.getTotalTransactions(yestStart, yestEnd, outletId),    // 3
      db.getTopProducts(todayStart, todayEnd, outletId),        // 4
      db.getHourlySales(todayStart, todayEnd, outletId),        // 5
      db.getLowStockProductsFiltered(outletId: outletId),       // 6
      db.getLowStockIngredients(outletId: outletId),            // 7
    ]);

    final todayRev = results[0] as int;
    final yestRev = results[1] as int;
    final todayTrx = results[2] as int;
    final yestTrx = results[3] as int;
    final topProds = results[4] as dynamic;
    final hourly = results[5] as dynamic;
    final lowStockProds = results[6] as List<Product>;
    final lowStockIngs = results[7] as List<Ingredient>;

    final aov = todayTrx > 0 ? (todayRev / todayTrx).round() : 0;

    String peakHour = '-';
    if ((hourly as List).isNotEmpty) {
      final sorted = [...hourly]
        ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      peakHour = 'Pukul ${sorted.first.dateStr}';
    }

    String topProduct = '-';
    if ((topProds as List).isNotEmpty) {
      topProduct = topProds.first.productName;
    }

    double delta(int cur, int prev) =>
        prev == 0 ? (cur > 0 ? 100.0 : 0.0) : ((cur - prev) / prev) * 100;

    final revD = delta(todayRev, yestRev);
    final trxD = delta(todayTrx, yestTrx);

    final kpis = [
      KpiItem(
        label: 'Pendapatan',
        value: _currency.format(todayRev),
        subtitle: 'Kemarin: ${_currency.format(yestRev)}',
        delta: '${revD >= 0 ? '+' : ''}${revD.toStringAsFixed(1)}%',
        deltaPositive: revD >= 0,
        icon: Icons.payments_rounded,
        color: AppTheme.primaryColor,
      ),
      KpiItem(
        label: 'Transaksi',
        value: '$todayTrx Trx',
        subtitle: 'Kemarin: $yestTrx Trx',
        delta: '${trxD >= 0 ? '+' : ''}${trxD.toStringAsFixed(1)}%',
        deltaPositive: trxD >= 0,
        icon: Icons.receipt_long_rounded,
        color: AppTheme.tertiaryColor,
        // Note: onTap navigation is handled by the screen layer
      ),
      KpiItem(
        label: 'Rata-rata/Trx',
        value: _currency.format(aov),
        subtitle: 'Avg. Order Value',
        icon: Icons.shopping_cart_rounded,
        color: Colors.orange,
      ),
      KpiItem(
        label: 'Jam Tersibuk',
        value: peakHour,
        subtitle: 'Transaksi terbanyak',
        icon: Icons.access_time_rounded,
        color: AppTheme.infoColor,
      ),
      KpiItem(
        label: 'Terlaris',
        value: topProduct,
        subtitle: 'Produk top hari ini',
        icon: Icons.emoji_events_rounded,
        color: AppTheme.secondaryColor,
      ),
    ];

    final lowStockSummary = LowStockSummary(
      products: lowStockProds,
      ingredients: lowStockIngs,
    );

    return DashboardKpiData(kpis: kpis, lowStockSummary: lowStockSummary);
  }

  /// Req 10.6 & 15.3: Manual refresh — immediate, no debounce
  Future<void> refresh() async {
    _debounceTimer?.cancel();
    ref.invalidateSelf();
  }
}

// ─── Provider registration ──────────────────────────────────────────────────────
final dashboardKpiProvider =
    AsyncNotifierProvider<DashboardKpiNotifier, DashboardKpiData>(
  DashboardKpiNotifier.new,
);
