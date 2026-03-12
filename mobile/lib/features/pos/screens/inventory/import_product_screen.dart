import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import '../../providers/import_product_provider.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class ImportProductScreen extends ConsumerWidget {
  const ImportProductScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importProductProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Impor Produk',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: AppTheme.textOnPrimary,
      ),
      body: ResponsiveCenter(child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(
              Icons.upload_file_rounded,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Impor Produk dari CSV',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gunakan file CSV dengan format berikut:\n'
              'Nama, SKU, Harga, Stok, ID Kategori',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            if (state.isLoading)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Sedang memproses...'),
                ],
              )
            else ...[
              ElevatedButton.icon(
                onPressed: () =>
                    ref.read(importProductProvider.notifier).importCsv(),
                icon: const Icon(Icons.file_open_rounded),
                label: const Text('PILIH FILE CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.textOnPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              if (state.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  state.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.errorColor),
                ),
              ],
              if (state.importedCount > 0) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '✅ Berhasil mengimpor ${state.importedCount} produk!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppTheme.successColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      )),
    );
  }
}
