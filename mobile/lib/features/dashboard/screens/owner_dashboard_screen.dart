import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/pos_tab.dart';
import 'package:posify_app/features/pos/screens/inventory_tab.dart';
import 'package:posify_app/features/reports/screens/sales_analytics_screen.dart';
import 'package:posify_app/features/settings/screens/employee_list_screen.dart';
import 'package:posify_app/features/settings/screens/store_profile_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
import 'package:posify_app/features/settings/screens/category_management_screen.dart';
import 'package:posify_app/features/settings/screens/tax_service_settings_screen.dart';
import 'package:posify_app/features/settings/screens/database_settings_screen.dart';
import 'package:posify_app/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:intl/intl.dart';

// ─── KPI data ──────────────────────────────────────────────────────────────────
class _KpiData {
  final String label;
  final String value;
  final String? subtitle;
  final String? delta;
  final bool? deltaPositive;
  final IconData icon;
  final Color color;
  const _KpiData({
    required this.label,
    required this.value,
    this.subtitle,
    this.delta,
    this.deltaPositive,
    required this.icon,
    required this.color,
  });
}

// ─── Quick action ──────────────────────────────────────────────────────────────
class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

// ─── Menu tile ─────────────────────────────────────────────────────────────────
class _MenuTile {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() =>
      _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  final _currency = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  List<_KpiData> _kpis = [];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    final db = ref.read(databaseProvider);
    final now = DateTime.now();

    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final yestStart = todayStart.subtract(const Duration(days: 1));
    final yestEnd = DateTime(
      yestStart.year, yestStart.month, yestStart.day, 23, 59, 59,
    );

    final results = await Future.wait([
      db.getTotalRevenue(todayStart, todayEnd),
      db.getTotalRevenue(yestStart, yestEnd),
      db.getTotalTransactions(todayStart, todayEnd),
      db.getTotalTransactions(yestStart, yestEnd),
      db.getTopProducts(todayStart, todayEnd),
      db.getHourlySales(todayStart, todayEnd),
    ]);

    final todayRev = results[0] as int;
    final yestRev = results[1] as int;
    final todayTrx = results[2] as int;
    final yestTrx = results[3] as int;
    final topProds = results[4] as dynamic;
    final hourly = results[5] as dynamic;

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

    if (mounted) {
      setState(() {
        _kpis = [
          _KpiData(
            label: 'Pendapatan',
            value: _currency.format(todayRev),
            subtitle: 'Kemarin: ${_currency.format(yestRev)}',
            delta: '${revD >= 0 ? '+' : ''}${revD.toStringAsFixed(1)}%',
            deltaPositive: revD >= 0,
            icon: Icons.payments_rounded,
            color: AppTheme.primaryColor,
          ),
          _KpiData(
            label: 'Transaksi',
            value: '$todayTrx Trx',
            subtitle: 'Kemarin: $yestTrx Trx',
            delta: '${trxD >= 0 ? '+' : ''}${trxD.toStringAsFixed(1)}%',
            deltaPositive: trxD >= 0,
            icon: Icons.receipt_long_rounded,
            color: AppTheme.tertiaryColor,
          ),
          _KpiData(
            label: 'Rata-rata/Trx',
            value: _currency.format(aov),
            subtitle: 'Avg. Order Value',
            icon: Icons.shopping_cart_rounded,
            color: Colors.orange,
          ),
          _KpiData(
            label: 'Jam Tersibuk',
            value: peakHour,
            subtitle: 'Transaksi terbanyak',
            icon: Icons.access_time_rounded,
            color: AppTheme.infoColor,
          ),
          _KpiData(
            label: 'Terlaris',
            value: topProduct,
            subtitle: 'Produk top hari ini',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFE67E22),
          ),
        ];
        _isLoading = false;
      });
    }
  }

  void _nav(Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi 👋';
    if (h < 15) return 'Selamat Siang ☀️';
    if (h < 18) return 'Selamat Sore 🌤️';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final isOwner = session?.role == 'owner';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primaryColor,
        displacement: 100,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Hero with KPI cards embedded ──────────────────────────────
            SliverToBoxAdapter(
              child: _buildHero(session?.name ?? 'Owner', isOwner),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Quick Action Grid ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('AKSI CEPAT'),
                    const SizedBox(height: 12),
                    _buildActionGrid(isOwner),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // ── Laporan & Riwayat ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('LAPORAN & RIWAYAT'),
                    const SizedBox(height: 12),
                    _menuCard([
                      _MenuTile(
                        icon: Icons.analytics_rounded,
                        label: 'Analitik Penjualan',
                        subtitle: 'Grafik tren & top produk',
                        color: AppTheme.primaryColor,
                        onTap: () => _nav(const SalesAnalyticsScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.receipt_long_rounded,
                        label: 'Riwayat Transaksi',
                        subtitle: 'Nota & void transaksi',
                        color: AppTheme.tertiaryColor,
                        onTap: () => _nav(const TransactionHistoryScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.access_time_rounded,
                        label: 'Riwayat Shift',
                        subtitle: 'Daftar sesi shift karyawan',
                        color: AppTheme.infoColor,
                        onTap: () => _nav(const ShiftHistoryScreen()),
                        isLast: true,
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            if (isOwner) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('TOKO & KARYAWAN'),
                      const SizedBox(height: 12),
                      _menuCard([
                        _MenuTile(
                          icon: Icons.store_mall_directory_rounded,
                          label: 'Profil Toko',
                          subtitle: 'Nama, alamat & logo',
                          color: AppTheme.primaryColor,
                          onTap: () => _nav(const StoreProfileScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.people_rounded,
                          label: 'Kelola Karyawan',
                          subtitle: 'Tambah & kelola akses karyawan',
                          color: Colors.orange,
                          onTap: () => _nav(const EmployeeListScreen()),
                          isLast: true,
                        ),
                      ]),
                    ],
                  ),
                ),
              ),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('KONFIGURASI SISTEM'),
                    const SizedBox(height: 12),
                    _menuCard([
                      _MenuTile(
                        icon: Icons.label_rounded,
                        label: 'Kelola Kategori',
                        subtitle: 'Tambah, edit, hapus kategori produk',
                        color: AppTheme.tertiaryColor,
                        onTap: () => _nav(const CategoryManagementScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.print_rounded,
                        label: 'Pengaturan Printer',
                        subtitle: 'Bluetooth thermal printer',
                        color: AppTheme.primaryColor,
                        onTap: () => _nav(const PrinterSettingsScreen()),
                      ),
                      _MenuTile(
                        icon: Icons.calculate_rounded,
                        label: 'Pajak & Service Charge',
                        subtitle: 'PPN, service, diskon default',
                        color: AppTheme.infoColor,
                        onTap: () => _nav(const TaxServiceSettingsScreen()),
                        isLast: !isOwner,
                      ),
                      if (isOwner)
                        _MenuTile(
                          icon: Icons.storage_rounded,
                          label: 'Manajemen Database',
                          subtitle: 'Backup & restore data',
                          color: Colors.deepOrange,
                          onTap: () => _nav(const DatabaseSettingsScreen()),
                          isLast: true,
                        ),
                    ]),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── Hero widget ─────────────────────────────────────────────────────────────
  Widget _buildHero(String name, bool isOwner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.tertiaryColor],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting row
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _greeting(),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          name,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(DateTime.now()),
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryColor,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isOwner ? 'Owner' : 'Supervisor',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () {
                            ref.read(sessionProvider.notifier).logout();
                            Navigator.pushReplacementNamed(
                              context,
                              '/employee-selection',
                            );
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.logout_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // KPI scroll
            SizedBox(
              height: 120,
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _kpis.length,
                      itemBuilder: (ctx, i) => _KpiCard(
                        data: _kpis[i],
                        isFirst: i == 0,
                      ),
                    ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ─── Quick action grid ────────────────────────────────────────────────────────
  Widget _buildActionGrid(bool isOwner) {
    final actions = <_ActionItem>[
      _ActionItem(
        icon: Icons.point_of_sale_rounded,
        label: 'Kasir',
        color: AppTheme.primaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const Scaffold(body: PosTab(showBackButton: true)),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.inventory_2_rounded,
        label: 'Produk',
        color: AppTheme.tertiaryColor,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const InventoryTab(showBackButton: true),
          ),
        ),
      ),
      _ActionItem(
        icon: Icons.analytics_rounded,
        label: 'Laporan',
        color: AppTheme.infoColor,
        onTap: () => _nav(const SalesAnalyticsScreen()),
      ),
      _ActionItem(
        icon: Icons.receipt_long_rounded,
        label: 'Transaksi',
        color: Colors.orange,
        onTap: () => _nav(const TransactionHistoryScreen()),
      ),
      if (isOwner)
        _ActionItem(
          icon: Icons.people_rounded,
          label: 'Karyawan',
          color: Colors.teal,
          onTap: () => _nav(const EmployeeListScreen()),
        ),
      if (isOwner)
        _ActionItem(
          icon: Icons.store_mall_directory_rounded,
          label: 'Profil Toko',
          color: Colors.indigo,
          onTap: () => _nav(const StoreProfileScreen()),
        ),
      _ActionItem(
        icon: Icons.access_time_rounded,
        label: 'Shift',
        color: Colors.deepPurple,
        onTap: () => _nav(const ShiftHistoryScreen()),
      ),
      _ActionItem(
        icon: Icons.print_rounded,
        label: 'Printer',
        color: Colors.blueGrey,
        onTap: () => _nav(const PrinterSettingsScreen()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: actions.length,
      itemBuilder: (ctx, i) => _ActionTile(data: actions[i]),
    );
  }

  // ─── Menu card ────────────────────────────────────────────────────────────────
  Widget _menuCard(List<_MenuTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: tiles.asMap().entries.map((e) {
          final tile = e.value;
          final isFirst = e.key == 0;
          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: tile.onTap,
                  borderRadius: BorderRadius.only(
                    topLeft: isFirst ? const Radius.circular(20) : Radius.zero,
                    topRight: isFirst ? const Radius.circular(20) : Radius.zero,
                    bottomLeft: tile.isLast ? const Radius.circular(20) : Radius.zero,
                    bottomRight: tile.isLast ? const Radius.circular(20) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: tile.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(tile.icon, color: tile.color, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tile.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              Text(
                                tile.subtitle,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.grey.shade300,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!tile.isLast)
                Divider(height: 1, indent: 74, color: Colors.grey.shade100),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: AppTheme.textSecondary.withValues(alpha: 0.6),
        ),
      );
}

// ─── KPI Card ──────────────────────────────────────────────────────────────────
class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool isFirst;
  const _KpiCard({required this.data, this.isFirst = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 155,
      margin: EdgeInsets.only(left: isFirst ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(data.icon, size: 16, color: data.color),
              ),
              if (data.delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (data.deltaPositive! ? Colors.green : Colors.red)
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data.delta!,
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: data.deltaPositive! ? Colors.green : Colors.red,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  data.value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              if (data.subtitle != null)
                Text(
                  data.subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 9,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Action Tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final _ActionItem data;
  const _ActionTile({required this.data});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      data.color.withValues(alpha: 0.15),
                      data.color.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                data.label,
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
