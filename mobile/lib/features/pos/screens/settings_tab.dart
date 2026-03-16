import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:posify_app/features/settings/screens/employee_list_screen.dart';
import 'package:posify_app/features/settings/screens/store_profile_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
import 'package:posify_app/features/reports/screens/sales_analytics_screen.dart';
import 'package:posify_app/features/settings/screens/category_management_screen.dart';
import 'package:posify_app/features/settings/screens/tax_service_settings_screen.dart';
import 'package:posify_app/features/settings/screens/database_settings_screen.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      body: ResponsiveCenter(
        child: Consumer(
          builder: (context, ref, child) {
            final session = ref.watch(sessionProvider).value;
            final isOwner = session?.role == 'owner';
            final isSupervisor = session?.role == 'supervisor';
            final isAtLeastSupervisor = isOwner || isSupervisor;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // Toko & Karyawan
                if (isOwner)
                  _buildSection(
                    title: 'Toko & Karyawan',
                    items: [
                      _SettingsItem(
                        icon: Icons.store_mall_directory_rounded,
                        title: 'Profil Toko',
                        subtitle: 'Nama toko, alamat, logo & struk',
                        onTap: () => _navigate(context, const StoreProfileScreen()),
                      ),
                      _SettingsItem(
                        icon: Icons.people_rounded,
                        title: 'Kelola Karyawan',
                        subtitle: 'Tambah & kelola akses karyawan',
                        onTap: () => _navigate(context, const EmployeeListScreen()),
                        isLast: true,
                      ),
                    ],
                  ),

                // Produk
                _buildSection(
                  title: 'Produk',
                  items: [
                    _SettingsItem(
                      icon: Icons.label_rounded,
                      title: 'Kelola Kategori Produk',
                      subtitle: 'Tambah, edit, hapus kategori',
                      isEnabled: isAtLeastSupervisor,
                      onTap: () => _navigate(context, const CategoryManagementScreen()),
                      isLast: true,
                    ),
                  ],
                ),

                // Laporan & Riwayat
                _buildSection(
                  title: 'Laporan & Riwayat',
                  items: [
                    if (isAtLeastSupervisor)
                      _SettingsItem(
                        icon: Icons.analytics_rounded,
                        title: 'Analitik Penjualan',
                        subtitle: 'Dashboard dan tren penjualan',
                        onTap: () => _navigate(context, const SalesAnalyticsScreen()),
                      ),
                    _SettingsItem(
                      icon: Icons.receipt_long_rounded,
                      title: 'Riwayat Transaksi',
                      subtitle: 'Nota & void transaksi',
                      onTap: () => _navigate(context, const TransactionHistoryScreen()),
                    ),
                    _SettingsItem(
                      icon: Icons.access_time_rounded,
                      title: 'Riwayat Sesi Shift',
                      subtitle: 'Daftar shift karyawan',
                      onTap: () => _navigate(context, const ShiftHistoryScreen()),
                      isLast: true,
                    ),
                  ],
                ),

                // Konfigurasi Sistem
                _buildSection(
                  title: 'Konfigurasi Sistem',
                  items: [
                    _SettingsItem(
                      icon: Icons.print_rounded,
                      title: 'Pengaturan Printer',
                      subtitle: 'Bluetooth thermal printer',
                      onTap: () => _navigate(context, const PrinterSettingsScreen()),
                    ),
                    if (isAtLeastSupervisor)
                      _SettingsItem(
                        icon: Icons.calculate_rounded,
                        title: 'Pajak & Service Charge',
                        subtitle: 'PPN, service, diskon default',
                        onTap: () => _navigate(context, const TaxServiceSettingsScreen()),
                        isLast: !isOwner,
                      ),
                    if (isOwner)
                      _SettingsItem(
                        icon: Icons.storage_rounded,
                        title: 'Manajemen Database',
                        subtitle: 'Backup & Restore data',
                        onTap: () => _navigate(context, const DatabaseSettingsScreen()),
                        isLast: true,
                      ),
                  ],
                ),

                // Akun
                _buildSection(
                  title: 'Keamanan & Akun',
                  items: [
                    _SettingsItem(
                      icon: Icons.lock_rounded,
                      title: 'Ganti PIN',
                      subtitle: 'Ubah PIN pribadi',
                      onTap: () {
                        // Implement Ganti PIN
                      },
                    ),
                    _SettingsItem(
                      icon: Icons.logout_rounded,
                      title: 'Keluar / Ganti User',
                      subtitle: 'Kembali ke halaman utama',
                      isDestructive: true,
                      onTap: () {
                        ref.read(sessionProvider.notifier).logout();
                        Navigator.pushReplacementNamed(context, '/employee-selection');
                      },
                      isLast: true,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Posify App v1.0.0',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<_SettingsItem> items}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 8),
            child: Text(
              title.toUpperCase(),
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: items.map((item) {
                return Column(
                  children: [
                    item,
                    if (!item.isLast)
                      Divider(height: 1, indent: 64, color: Colors.grey.shade100),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDestructive;
  final bool isEnabled;
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.isEnabled = true,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(isLast ? 16 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: !isEnabled
                      ? Colors.grey.shade100
                      : isDestructive
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: !isEnabled
                      ? Colors.grey.shade400
                      : isDestructive
                          ? AppTheme.errorColor
                          : AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: !isEnabled
                            ? Colors.grey.shade400
                            : isDestructive
                                ? AppTheme.errorColor
                                : AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: isEnabled ? AppTheme.textSecondary : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isEnabled ? Colors.grey.shade400 : Colors.grey.shade200,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
