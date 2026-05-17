import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumio/core/theme/app_theme.dart';
import 'package:lumio/features/auth/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UnlicensedScreen extends ConsumerWidget {
  const UnlicensedScreen({super.key});

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
            const Icon(
              Icons.lock_person_outlined,
              size: 80,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            Text(
              'Akun Belum Aktif',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Akun Anda belum berlangganan atau masa aktif telah habis. Silakan hubungi Admin melalui WhatsApp untuk mengaktifkan lisensi Anda.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                final user = Supabase.instance.client.auth.currentUser;
                if (user?.email != null) {
                  ref.read(licenseProvider.notifier).verifyAccount(user!.email!);
                }
              },
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Cek Status Lisensi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
