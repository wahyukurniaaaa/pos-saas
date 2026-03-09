import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:posify_app/features/settings/screens/employee_list_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
import 'package:posify_app/features/reports/screens/sales_analytics_screen.dart';
import 'package:posify_app/features/settings/screens/category_management_screen.dart';
import 'package:posify_app/features/settings/screens/tax_service_settings_screen.dart';
import 'package:posify_app/features/settings/screens/database_settings_screen.dart';

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Toko & Karyawan
          _buildSettingsTile(
            Icons.people_rounded,
            'Kelola Karyawan',
            'Tambah & kelola akses karyawan',
            onTap: () => _navigate(context, const EmployeeListScreen()),
          ),
          _buildSettingsTile(
            Icons.label_rounded,
            'Kelola Kategori Produk',
            'Tambah, edit, hapus kategori',
            onTap: () => _navigate(context, const CategoryManagementScreen()),
          ),
          const Divider(height: 32),

          // Riwayat & Laporan
          _buildSettingsTile(
            Icons.analytics_rounded,
            'Analitik Penjualan',
            'Dashboard dan tren penjualan',
            onTap: () => _navigate(context, const SalesAnalyticsScreen()),
          ),
          _buildSettingsTile(
            Icons.receipt_long_rounded,
            'Riwayat Transaksi',
            'Nota & void transaksi',
            onTap: () => _navigate(context, const TransactionHistoryScreen()),
          ),
          _buildSettingsTile(
            Icons.access_time_rounded,
            'Riwayat Sesi Shift',
            'Daftar shift karyawan',
            onTap: () => _navigate(context, const ShiftHistoryScreen()),
          ),
          _buildSettingsTile(
            Icons.print_rounded,
            'Pengaturan Printer',
            'Bluetooth thermal printer',
            onTap: () => _navigate(context, const PrinterSettingsScreen()),
          ),
          _buildSettingsTile(
            Icons.calculate_rounded,
            'Pajak & Service Charge',
            'PPN, service, diskon default',
            onTap: () => _navigate(context, const TaxServiceSettingsScreen()),
          ),
          _buildSettingsTile(
            Icons.storage_rounded,
            'Manajemen Database',
            'Backup & Restore data (AES-256)',
            onTap: () => _navigate(context, const DatabaseSettingsScreen()),
          ),
          const Divider(height: 32),

          // Akun
          _buildSettingsTile(
            Icons.lock_rounded,
            'Ganti PIN',
            'Ubah PIN owner atau karyawan',
          ),
          _buildSettingsTile(
            Icons.logout_rounded,
            'Keluar / Ganti User',
            'Kembali ke halaman login PIN',
            isDestructive: true,
            onTap: () {
              ref.read(sessionProvider.notifier).logout();
              Navigator.pushReplacementNamed(context, '/pin-login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    IconData icon,
    String title,
    String subtitle, {
    bool isDestructive = false,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppTheme.errorColor.withValues(alpha: 0.1)
                : AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDestructive ? AppTheme.errorColor : AppTheme.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDestructive ? AppTheme.errorColor : AppTheme.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondary),
        ),
        trailing: Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
        ),
        onTap: onTap,
      ),
    );
  }
}
