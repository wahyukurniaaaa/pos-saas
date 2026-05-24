import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumio/core/theme/app_theme.dart';
import 'package:lumio/features/auth/providers/owner_provider.dart';
import 'package:lumio/features/pos/screens/pos_tab.dart';
import 'package:lumio/features/pos/screens/inventory_tab.dart';
import 'package:lumio/features/reports/screens/report_menu_screen.dart';
import 'package:lumio/features/settings/screens/employee_list_screen.dart';
import 'package:lumio/features/settings/screens/store_profile_screen.dart';
import 'package:lumio/features/settings/screens/transaction_history_screen.dart';
import 'package:lumio/features/settings/screens/shift_history_screen.dart';
import 'package:lumio/features/settings/screens/category_management_screen.dart';
import 'package:lumio/features/settings/screens/tax_service_settings_screen.dart';
import 'package:lumio/features/settings/screens/database_settings_screen.dart';
import 'package:lumio/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:lumio/features/settings/screens/customers/customer_list_screen.dart';
import 'package:lumio/features/settings/screens/suppliers/supplier_list_screen.dart';
import 'package:lumio/features/pos/screens/inventory/global_stock_history_screen.dart';
import 'package:lumio/features/pos/screens/settings/discount_management_screen.dart';
import 'package:lumio/features/pos/screens/settings/expense_management_screen.dart';
import 'package:lumio/features/auth/screens/device_management_screen.dart';
import 'package:lumio/features/dashboard/screens/cashflow_screen.dart';
import 'package:intl/intl.dart';
import 'package:lumio/features/dashboard/widgets/low_stock_widget.dart';
import 'package:lumio/features/inventory/screens/po/po_list_screen.dart';
import 'package:lumio/core/widgets/responsive_layout.dart';
import 'package:lumio/features/dashboard/providers/dashboard_kpi_provider.dart';

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
class OwnerDashboardScreen extends ConsumerWidget {
  const OwnerDashboardScreen({super.key});

  // ─── Static text styles ────────────────────────────────────────────────────
  static final _menuTileLabelStyle = GoogleFonts.poppins(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );
  static final _menuTileSubtitleStyle = GoogleFonts.poppins(
    fontSize: 11,
    color: AppTheme.textSecondary,
  );
  static final _heroNameStyle = GoogleFonts.poppins(
    fontSize: 24,
    color: Colors.white,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );
  static final _roleBadgeStyle = GoogleFonts.poppins(
    fontSize: 11,
    color: AppTheme.primaryColor,
    fontWeight: FontWeight.w700,
  );

  void _nav(BuildContext context, Widget screen) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => screen));

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi 👋';
    if (h < 15) return 'Selamat Siang ☀️';
    if (h < 18) return 'Selamat Sore 🌤️';
    return 'Selamat Malam 🌙';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).value;
    final isOwner = session?.role == 'owner';
    final kpiAsync = ref.watch(dashboardKpiProvider);

    // Attach onTap for 'Transaksi' KPI card after receiving data (Option a)
    final kpiAsyncWithTap = kpiAsync.whenData((data) {
      final kpisWithTap = data.kpis.map((kpi) {
        if (kpi.label == 'Transaksi') {
          return KpiItem(
            label: kpi.label,
            value: kpi.value,
            subtitle: kpi.subtitle,
            delta: kpi.delta,
            deltaPositive: kpi.deltaPositive,
            icon: kpi.icon,
            color: kpi.color,
            onTap: () => _nav(context, const TransactionHistoryScreen()),
          );
        }
        return kpi;
      }).toList();
      return DashboardKpiData(
        kpis: kpisWithTap,
        lowStockSummary: data.lowStockSummary,
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardKpiProvider.notifier).refresh(),
        color: AppTheme.primaryColor,
        displacement: 100,
        child: ResponsiveCenter(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── Hero with KPI cards embedded ──────────────────────────────
              SliverToBoxAdapter(
                child: _buildHero(
                  context,
                  ref,
                  session?.name ?? 'Owner',
                  isOwner,
                  kpiAsyncWithTap,
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // ── Low Stock Warning ──────────────────────────────────────────
              if (kpiAsync.value?.lowStockSummary.totalCount != null &&
                  kpiAsync.value!.lowStockSummary.totalCount > 0)
                SliverToBoxAdapter(
                  child: LowStockWidget(
                    summary: kpiAsync.value!.lowStockSummary,
                  ),
                ),

              // ── Quick Action Grid ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('AKSI CEPAT'),
                      const SizedBox(height: 12),
                      _buildActionGrid(context, isOwner),
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
                          label: 'Semua Laporan',
                          subtitle: 'Pusat laporan bisnis terpadu',
                          color: AppTheme.primaryColor,
                          onTap: () => _nav(context, const ReportMenuScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.account_balance_wallet_rounded,
                          label: 'Arus Kas',
                          subtitle: 'Laporan margin & pengeluaran',
                          color: Colors.green,
                          onTap: () => _nav(context, const CashFlowScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.receipt_long_rounded,
                          label: 'Riwayat Transaksi',
                          subtitle: 'Nota & void transaksi',
                          color: AppTheme.tertiaryColor,
                          onTap: () =>
                              _nav(context, const TransactionHistoryScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.history_rounded,
                          label: 'Histori Mutasi Stok',
                          subtitle: 'Kartu stok masuk, keluar & opname',
                          color: Colors.green,
                          onTap: () =>
                              _nav(context, const GlobalStockHistoryScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.access_time_rounded,
                          label: 'Riwayat Shift',
                          subtitle: 'Daftar sesi shift karyawan',
                          color: AppTheme.infoColor,
                          onTap: () =>
                              _nav(context, const ShiftHistoryScreen()),
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
                        _label('MASTER DATA & KARYAWAN'),
                        const SizedBox(height: 12),
                        _menuCard([
                          _MenuTile(
                            icon: Icons.store_mall_directory_rounded,
                            label: 'Profil Toko',
                            subtitle: 'Nama, alamat & logo',
                            color: AppTheme.primaryColor,
                            onTap: () =>
                                _nav(context, const StoreProfileScreen()),
                          ),
                          _MenuTile(
                            icon: Icons.people_outline_rounded,
                            label: 'Kelola Pelanggan (Member)',
                            subtitle: 'Database & program loyalitas',
                            color: AppTheme.tertiaryColor,
                            onTap: () =>
                                _nav(context, const CustomerListScreen()),
                          ),
                          _MenuTile(
                            icon: Icons.business_rounded,
                            label: 'Kelola Supplier',
                            subtitle: 'Daftar pemasok barang',
                            color: Colors.amber,
                            onTap: () =>
                                _nav(context, const SupplierListScreen()),
                          ),
                          _MenuTile(
                            icon: Icons.receipt_long_rounded,
                            label: 'Purchase Order',
                            subtitle: 'Buat & kelola PO ke supplier',
                            color: Colors.teal,
                            onTap: () => _nav(context, const PoListScreen()),
                          ),
                          _MenuTile(
                            icon: Icons.people_rounded,
                            label: 'Kelola Karyawan',
                            subtitle: 'Tambah & kelola akses karyawan',
                            color: Colors.orange,
                            onTap: () =>
                                _nav(context, const EmployeeListScreen()),
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
                          onTap: () =>
                              _nav(context, const CategoryManagementScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.print_rounded,
                          label: 'Pengaturan Printer',
                          subtitle: 'Bluetooth thermal printer',
                          color: AppTheme.primaryColor,
                          onTap: () =>
                              _nav(context, const PrinterSettingsScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.calculate_rounded,
                          label: 'Pajak & Service Charge',
                          subtitle: 'PPN, service, diskon default',
                          color: AppTheme.infoColor,
                          onTap: () =>
                              _nav(context, const TaxServiceSettingsScreen()),
                        ),
                        _MenuTile(
                          icon: Icons.local_offer_rounded,
                          label: 'Diskon & Promo',
                          subtitle: 'Kelola voucher & program promo',
                          color: AppTheme.secondaryColor,
                          onTap: () =>
                              _nav(context, const DiscountManagementScreen()),
                          isLast: !isOwner,
                        ),
                        if (isOwner)
                          _MenuTile(
                            icon: Icons.storage_rounded,
                            label: 'Manajemen Database',
                            subtitle: 'Backup & restore data',
                            color: Colors.deepOrange,
                            onTap: () =>
                                _nav(context, const DatabaseSettingsScreen()),
                          ),
                        if (isOwner)
                          _MenuTile(
                            icon: Icons.devices_other_rounded,
                            label: 'Manajemen Perangkat',
                            subtitle: 'Kelola & unbind perangkat',
                            color: AppTheme.tertiaryColor,
                            onTap: () =>
                                _nav(context, const DeviceManagementScreen()),
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
      ),
    );
  }

  // ─── Hero widget ─────────────────────────────────────────────────────────────
  Widget _buildHero(
    BuildContext context,
    WidgetRef ref,
    String name,
    bool isOwner,
    AsyncValue<DashboardKpiData> kpiAsync,
  ) {
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
                          style: _heroNameStyle,
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
                          style: _roleBadgeStyle,
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

            // KPI scroll — Req 10.3: loading indicator only in KPI section
            SizedBox(
              height: 120,
              child: kpiAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                error: (e, _) => const SizedBox(),
                data: (data) => ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.kpis.length,
                  itemBuilder: (ctx, i) => _KpiCard(
                    data: data.kpis[i],
                    isFirst: i == 0,
                  ),
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
  Widget _buildActionGrid(BuildContext context, bool isOwner) {
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
        label: 'Stok & Produk',
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
        onTap: () => _nav(context, const ReportMenuScreen()),
      ),
      _ActionItem(
        icon: Icons.outbond_rounded,
        label: 'Kas Keluar',
        color: Colors.deepOrange,
        onTap: () => _nav(context, const ExpenseManagementScreen()),
      ),
      _ActionItem(
        icon: Icons.people_outline_rounded,
        label: 'Pelanggan',
        color: AppTheme.tertiaryColor,
        onTap: () => _nav(context, const CustomerListScreen()),
      ),
      _ActionItem(
        icon: Icons.access_time_rounded,
        label: 'Shift',
        color: Colors.deepPurple,
        onTap: () => _nav(context, const ShiftHistoryScreen()),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
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
                    topLeft:
                        isFirst ? const Radius.circular(20) : Radius.zero,
                    topRight:
                        isFirst ? const Radius.circular(20) : Radius.zero,
                    bottomLeft:
                        tile.isLast ? const Radius.circular(20) : Radius.zero,
                    bottomRight:
                        tile.isLast ? const Radius.circular(20) : Radius.zero,
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
                                style: _menuTileLabelStyle,
                              ),
                              Text(
                                tile.subtitle,
                                style: _menuTileSubtitleStyle,
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
  final KpiItem data; // ← KpiItem from dashboard_kpi_provider.dart
  final bool isFirst;
  const _KpiCard({required this.data, this.isFirst = false});

  static final _labelStyle = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppTheme.textSecondary,
  );
  static final _valueStyle = GoogleFonts.poppins(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    color: AppTheme.textPrimary,
  );
  static final _subtitleStyle = GoogleFonts.poppins(
    fontSize: 9,
    color: AppTheme.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: data.onTap,
      child: Container(
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
                      color: (data.deltaPositive! ? Colors.green : Colors.red)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      data.delta!,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color:
                            data.deltaPositive! ? Colors.green : Colors.red,
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
                  style: _labelStyle,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    data.value,
                    style: _valueStyle,
                  ),
                ),
                if (data.subtitle != null)
                  Text(
                    data.subtitle!,
                    style: _subtitleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action Tile ───────────────────────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final _ActionItem data;
  const _ActionTile({required this.data});

  static final _labelStyle = GoogleFonts.poppins(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppTheme.textPrimary,
  );

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
                style: _labelStyle,
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
