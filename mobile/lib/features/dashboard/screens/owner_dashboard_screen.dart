import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/pos_tab.dart';
import 'package:posify_app/features/reports/screens/sales_analytics_screen.dart';
import 'package:posify_app/features/settings/screens/employee_list_screen.dart';
import 'package:posify_app/features/settings/screens/store_profile_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
import 'package:posify_app/features/settings/screens/category_management_screen.dart';
import 'package:posify_app/features/settings/screens/tax_service_settings_screen.dart';
import 'package:posify_app/features/settings/screens/database_settings_screen.dart';
import 'package:posify_app/features/pos/screens/inventory_tab.dart';
import 'package:posify_app/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:intl/intl.dart';

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
  int _todayRevenue = 0;
  int _yesterdayRevenue = 0;
  int _todayTransactions = 0;
  int _yesterdayTransactions = 0;

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

    final yesterdayStart = todayStart.subtract(const Duration(days: 1));
    final yesterdayEnd = DateTime(
      yesterdayStart.year,
      yesterdayStart.month,
      yesterdayStart.day,
      23,
      59,
      59,
    );

    final todayRev = await db.getTotalRevenue(todayStart, todayEnd);
    final todayTrx = await db.getTotalTransactions(todayStart, todayEnd);
    final yestRev = await db.getTotalRevenue(yesterdayStart, yesterdayEnd);
    final yestTrx = await db.getTotalTransactions(
      yesterdayStart,
      yesterdayEnd,
    );

    if (mounted) {
      setState(() {
        _todayRevenue = todayRev;
        _yesterdayRevenue = yestRev;
        _todayTransactions = todayTrx;
        _yesterdayTransactions = yestTrx;
        _isLoading = false;
      });
    }
  }

  void _navigate(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider).value;
    final isOwner = session?.role == 'owner';
    final greeting = _getGreeting();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        color: AppTheme.primaryColor,
        child: CustomScrollView(
          slivers: [
            // --- App Bar ---
            SliverAppBar(
              expandedHeight: 180,
              floating: false,
              pinned: true,
              backgroundColor: AppTheme.primaryColor,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Keluar',
                  onPressed: () {
                    ref.read(sessionProvider.notifier).logout();
                    Navigator.pushReplacementNamed(
                      context,
                      '/employee-selection',
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppTheme.primaryColor, AppTheme.tertiaryColor],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            greeting,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: Colors.white.withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session?.name ?? 'Owner',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Scorecards ---
                    _buildSectionTitle('Ringkasan Hari Ini'),
                    const SizedBox(height: 12),
                    _isLoading
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(24),
                              child: CircularProgressIndicator(
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: _buildScoreCard(
                                  title: 'Pendapatan',
                                  value: _currency.format(_todayRevenue),
                                  previousValue: _currency.format(
                                    _yesterdayRevenue,
                                  ),
                                  current: _todayRevenue.toDouble(),
                                  previous: _yesterdayRevenue.toDouble(),
                                  icon: Icons.payments_rounded,
                                  iconColor: AppTheme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildScoreCard(
                                  title: 'Transaksi',
                                  value: '$_todayTransactions Trx',
                                  previousValue: '$_yesterdayTransactions Trx',
                                  current: _todayTransactions.toDouble(),
                                  previous: _yesterdayTransactions.toDouble(),
                                  icon: Icons.receipt_long_rounded,
                                  iconColor: AppTheme.tertiaryColor,
                                ),
                              ),
                            ],
                          ),

                    const SizedBox(height: 28),

                    // --- Quick Actions ---
                    _buildSectionTitle('Aksi Cepat'),
                    const SizedBox(height: 12),
                    _buildQuickActions(),

                    const SizedBox(height: 28),

                    // --- Laporan Section ---
                    if (true) ...[
                      _buildSectionTitle('Laporan & Riwayat'),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        items: [
                          _MenuItem(
                            icon: Icons.analytics_rounded,
                            label: 'Analitik Penjualan',
                            subtitle: 'Grafik tren & top produk',
                            color: AppTheme.primaryColor,
                            onTap:
                                () => _navigate(const SalesAnalyticsScreen()),
                          ),
                          _MenuItem(
                            icon: Icons.receipt_long_rounded,
                            label: 'Riwayat Transaksi',
                            subtitle: 'Nota & void transaksi',
                            color: AppTheme.tertiaryColor,
                            onTap:
                                () =>
                                    _navigate(const TransactionHistoryScreen()),
                          ),
                          _MenuItem(
                            icon: Icons.access_time_rounded,
                            label: 'Riwayat Shift',
                            subtitle: 'Daftar sesi shift karyawan',
                            color: AppTheme.infoColor,
                            onTap: () => _navigate(const ShiftHistoryScreen()),
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- Toko & Karyawan (Owner only) ---
                    if (isOwner) ...[
                      _buildSectionTitle('Toko & Karyawan'),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        items: [
                          _MenuItem(
                            icon: Icons.store_mall_directory_rounded,
                            label: 'Profil Toko',
                            subtitle: 'Nama toko, alamat, logo & struk',
                            color: AppTheme.primaryColor,
                            onTap: () => _navigate(const StoreProfileScreen()),
                          ),
                          _MenuItem(
                            icon: Icons.people_rounded,
                            label: 'Kelola Karyawan',
                            subtitle: 'Tambah & kelola akses karyawan',
                            color: Colors.orange,
                            onTap: () => _navigate(const EmployeeListScreen()),
                            isLast: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],

                    // --- Produk Section ---
                    _buildSectionTitle('Produk'),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      items: [
                        _MenuItem(
                          icon: Icons.label_rounded,
                          label: 'Kelola Kategori',
                          subtitle: 'Tambah, edit, hapus kategori produk',
                          color: AppTheme.tertiaryColor,
                          onTap:
                              () => _navigate(const CategoryManagementScreen()),
                          isLast: true,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- Sistem Section ---
                    _buildSectionTitle('Konfigurasi Sistem'),
                    const SizedBox(height: 12),
                    _buildMenuCard(
                      items: [
                        _MenuItem(
                          icon: Icons.print_rounded,
                          label: 'Pengaturan Printer',
                          subtitle: 'Bluetooth thermal printer',
                          color: AppTheme.primaryColor,
                          onTap: () => _navigate(const PrinterSettingsScreen()),
                        ),
                        _MenuItem(
                          icon: Icons.calculate_rounded,
                          label: 'Pajak & Service Charge',
                          subtitle: 'PPN, service, diskon default',
                          color: AppTheme.tertiaryColor,
                          onTap:
                              () =>
                                  _navigate(const TaxServiceSettingsScreen()),
                          isLast: !isOwner,
                        ),
                        if (isOwner)
                          _MenuItem(
                            icon: Icons.storage_rounded,
                            label: 'Manajemen Database',
                            subtitle: 'Backup & Restore data',
                            color: Colors.deepOrange,
                            onTap:
                                () => _navigate(const DatabaseSettingsScreen()),
                            isLast: true,
                          ),
                      ],
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppTheme.textSecondary.withValues(alpha: 0.7),
      ),
    );
  }

  Widget _buildScoreCard({
    required String title,
    required String value,
    required String previousValue,
    required double current,
    required double previous,
    required IconData icon,
    required Color iconColor,
  }) {
    final double change = previous > 0
        ? ((current - previous) / previous) * 100
        : current > 0
        ? 100.0
        : 0.0;
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: (isPositive ? Colors.green : Colors.red).withValues(
                    alpha: 0.1,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Kemarin: $previousValue',
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.point_of_sale_rounded,
        label: 'Kasir',
        color: AppTheme.primaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const Scaffold(body: PosTab(showBackButton: true)),
            ),
          );
        },
      ),
      _QuickAction(
        icon: Icons.inventory_2_rounded,
        label: 'Produk',
        color: AppTheme.tertiaryColor,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const _ProductShell()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.analytics_rounded,
        label: 'Laporan',
        color: AppTheme.infoColor,
        onTap: () => _navigate(const SalesAnalyticsScreen()),
      ),
      _QuickAction(
        icon: Icons.receipt_long_rounded,
        label: 'Transaksi',
        color: Colors.orange,
        onTap: () => _navigate(const TransactionHistoryScreen()),
      ),
    ];

    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      children: actions.map((a) {
        return InkWell(
          onTap: a.onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(a.icon, color: a.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  a.label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMenuCard({required List<_MenuItem> items}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final item = e.value;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.only(
                  topLeft: e.key == 0
                      ? const Radius.circular(20)
                      : Radius.zero,
                  topRight: e.key == 0
                      ? const Radius.circular(20)
                      : Radius.zero,
                  bottomLeft: item.isLast
                      ? const Radius.circular(20)
                      : Radius.zero,
                  bottomRight: item.isLast
                      ? const Radius.circular(20)
                      : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.label,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              item.subtitle,
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
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              if (!item.isLast)
                Divider(
                  height: 1,
                  indent: 70,
                  color: Colors.grey.shade100,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi 👋';
    if (hour < 15) return 'Selamat Siang 👋';
    if (hour < 18) return 'Selamat Sore 👋';
    return 'Selamat Malam 👋';
  }
}

// Wrapper to show InventoryTab as a standalone screen
class _ProductShell extends ConsumerWidget {
  const _ProductShell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(body: InventoryTab());
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  final bool isLast;
  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.isLast = false,
  });
}
