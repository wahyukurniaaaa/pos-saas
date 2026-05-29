import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumio/core/theme/app_theme.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnlicensedScreen extends ConsumerWidget {
  /// When [isTrialExpired] is true, the screen shows a trial-specific
  /// expired message instead of the generic unlicensed message.
  final bool isTrialExpired;
  final bool isOfflineVerificationRequired;

  const UnlicensedScreen({
    super.key,
    this.isTrialExpired = false,
    this.isOfflineVerificationRequired = false,
  });

  Future<void> _contactAdmin() async {
    const phoneNumber = '+6281234567890'; // Replace with actual number
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? 'Unknown';
    
    final message = 'Halo Admin, saya ingin mengaktifkan akun Lumio POS saya. Email: $email';
    final url = Uri.parse('https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}');
    
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = isOfflineVerificationRequired
        ? 'Verifikasi Lisensi Diperlukan'
        : (isTrialExpired ? 'Trial Telah Berakhir' : 'Akun Belum Aktif');

    final message = isOfflineVerificationRequired
        ? 'Aplikasi telah offline lebih dari 7 hari. Harap hubungkan perangkat ke internet lalu tekan \'Cek Status Lisensi\' untuk memverifikasi lisensi Anda.'
        : (isTrialExpired
            ? 'Masa trial 7 hari Anda telah berakhir. Silakan berlangganan untuk melanjutkan menggunakan Lumio POS.'
            : 'Akun Anda belum berlangganan atau masa aktif telah habis. Silakan hubungi Admin melalui WhatsApp untuk mengaktifkan lisensi Anda.');

    final icon = isOfflineVerificationRequired
        ? Icons.wifi_off_outlined
        : (isTrialExpired ? Icons.timer_off_outlined : Icons.lock_person_outlined);

    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.primaryDark, AppTheme.primaryColor],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
            if (isTrialExpired && !isOfflineVerificationRequired) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pushReplacementNamed('/register');
                },
                icon: const Icon(Icons.upgrade),
                label: const Text('Pilih Paket Berlangganan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            if (!isOfflineVerificationRequired) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _contactAdmin,
                icon: const Icon(Icons.chat_bubble_outline),
                label: const Text('Hubungi Admin (WhatsApp)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // WhatsApp Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                final user = Supabase.instance.client.auth.currentUser;
                if (user?.email != null) {
                  ref.read(licenseProvider.notifier).verifyAccount(user!.email!);
                }
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Cek Status Lisensi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                ref.read(authProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                'Keluar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
