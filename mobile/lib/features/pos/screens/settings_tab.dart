import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/features/auth/providers/owner_provider.dart';
import 'package:posify_app/features/pos/screens/settings/printer_settings_screen.dart';
import 'package:posify_app/features/settings/screens/transaction_history_screen.dart';
import 'package:posify_app/features/settings/screens/shift_history_screen.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Pengaturan',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        shape: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 1)),
      ),
      body: ResponsiveCenter(
        child: Consumer(
          builder: (context, ref, child) {
            final session = ref.watch(sessionProvider).value;
            final isOwner = session?.role == 'owner';
            final isSupervisor = session?.role == 'supervisor';
            final canAccessDashboard = isOwner || isSupervisor;

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              children: [
                // Navigasi Backoffice
                if (canAccessDashboard)
                  _buildSection(
                    context: context,
                    title: 'Manajemen Data',
                    items: [
                      _SettingsItem(
                        icon: Icons.dashboard_rounded,
                        title: 'Masuk ke Backoffice',
                        subtitle: 'Pindah ke modul Manajemen (Dashboard)',
                        onTap: () => Navigator.pushReplacementNamed(context, '/dashboard'),
                        isLast: true,
                      ),
                    ],
                  ),
                // Laporan & Riwayat
                _buildSection(
                  context: context,
                  title: 'Laporan & Riwayat',
                  items: [
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
                  context: context,
                  title: 'Konfigurasi Sistem',
                  items: [
                    _SettingsItem(
                      icon: Icons.print_rounded,
                      title: 'Pengaturan Printer',
                      subtitle: 'Bluetooth thermal printer',
                      onTap: () => _navigate(context, const PrinterSettingsScreen()),
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
                  context: context,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

  Widget _buildSection({required BuildContext context, required String title, required List<_SettingsItem> items}) {
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
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1), width: 1),
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
                      Divider(height: 1, indent: 64, color: Theme.of(context).dividerColor.withValues(alpha: 0.05)),
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
  final VoidCallback? onTap;
  final bool isLast;

  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isDestructive = false,
    this.onTap,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(isLast ? 16 : 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDestructive
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 20,
                  color: isDestructive
                          ? AppTheme.errorColor
                          : Theme.of(context).colorScheme.primary,
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
                        color: isDestructive
                                ? AppTheme.errorColor
                                : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
