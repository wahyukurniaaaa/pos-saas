import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/services/backup_service.dart';
import 'package:path/path.dart' as p;
import 'package:posify_app/core/providers/database_provider.dart';
import 'package:posify_app/features/pos/providers/pos_providers.dart';
import 'package:posify_app/core/widgets/responsive_layout.dart';

class DatabaseSettingsScreen extends ConsumerStatefulWidget {
  const DatabaseSettingsScreen({super.key});

  @override
  ConsumerState<DatabaseSettingsScreen> createState() =>
      _DatabaseSettingsScreenState();
}

class _DatabaseSettingsScreenState
    extends ConsumerState<DatabaseSettingsScreen> {
  List<File> _backups = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoading = true);
    final list = await BackupService().getBackupList();
    setState(() {
      _backups = list;
      _isLoading = false;
    });
  }

  Future<void> _handleBackup() async {
    setState(() => _isLoading = true);
    final result = await BackupService().performAutoBackup();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));

    _loadBackups();
  }

  Future<void> _handleRestore(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Restore'),
        content: const Text(
          'Seluruh data saat ini akan digantikan dengan data dari backup ini. Aplikasi akan ditutup setelah proses selesai. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Ya, Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await BackupService().restoreBackup(file);

      if (!mounted) return;

      // Since we replaced the DB file, the app needs to restart or re-init.
      // We show a final message.
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Restore Berhasil'),
          content: const Text(
            'Data telah dipulihkan. Silakan buka ulang aplikasi untuk memuat data terbaru.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => exit(0), // Crude but effective for this context
              child: const Text('Tutup Aplikasi'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Restore gagal: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showRecoveryKey() async {
    final key = await BackupService().getRecoveryKey();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kunci Pemulihan (Recovery Key)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gunakan kunci ini untuk memulihkan data jika Anda pindah ke HP baru. JANGAN BERIKAN KUNCI INI KEPADA SIAPAPUN!',
              style: TextStyle(fontSize: 12, color: AppTheme.dangerColor),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                key,
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: key));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Kunci disalin ke clipboard')),
              );
            },
            child: const Text('Salin Kunci'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any, // .enc files are treated as any or binary
    );

    if (result == null || result.files.single.path == null) return;

    final file = File(result.files.single.path!);
    final keyController = TextEditingController();

    if (!mounted) return;

    final recoveryKey = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masukkan Kunci Pemulihan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan Kunci Pemulihan dari HP lama untuk membuka file ini.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: keyController,
              decoration: const InputDecoration(
                labelText: 'Recovery Key',
                border: OutlineInputBorder(),
                hintText: 'Masukkan kunci base64...',
              ),
              style: GoogleFonts.robotoMono(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, keyController.text),
            child: const Text('Lanjutkan Restore'),
          ),
        ],
      ),
    );

    if (recoveryKey == null || recoveryKey.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await BackupService().importAndRestore(file, recoveryKey);

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Import & Restore Berhasil'),
          content: const Text(
            'Data dari HP lama berhasil dipulihkan. Silakan buka ulang aplikasi. \n\nCatatan: Anda mungkin perlu melakukan Aktivasi Ulang lisensi di HP baru ini.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => exit(0),
              child: const Text('Tutup Aplikasi'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import gagal. Pastikan Recovery Key benar. Error: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Data Transaksi?'),
        content: const Text(
          'Seluruh data Produk, Stok, Shift, dan Transaksi akan dihapus permanen. Kategori dan Akun Karyawan akan dipertahankan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerColor,
            ),
            child: const Text('Ya, Hapus Data'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      final db = ref.read(databaseProvider);
      await db.clearTransactionalData();

      // Invalidate providers to refresh UI
      ref.invalidate(productProvider);
      ref.invalidate(categoryProvider); // Although preserved, refresh just in case

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data transaksi berhasil dibersihkan! ✅'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menghapus data: $e'),
          backgroundColor: AppTheme.dangerColor,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Manajemen Database',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: ResponsiveCenter(child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: _backups.isEmpty
                      ? _buildEmptyState()
                      : _buildBackupList(),
                ),
              ],
            )),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'import',
            onPressed: _handleImport,
            label: const Text('Import dari HP Lain'),
            icon: const Icon(Icons.file_download_rounded),
            backgroundColor: Colors.orange[700],
          ),
          const SizedBox(height: 16),
          FloatingActionButton.extended(
            heroTag: 'backup',
            onPressed: _handleBackup,
            label: const Text('Backup Sekarang'),
            icon: const Icon(Icons.backup_rounded),
            backgroundColor: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Backup Lokal',
            style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Data Anda dienkripsi dengan AES-256 dan disimpan secara lokal di perangkat ini.',
            style: GoogleFonts.poppins(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          _buildRecoveryKeyButton(),
          const SizedBox(height: 16),
          _buildResetDataButton(),
        ],
      ),
    );
  }

  Widget _buildResetDataButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _handleResetData,
        icon: const Icon(Icons.delete_sweep_rounded, color: AppTheme.dangerColor),
        label: const Text(
          'Bersihkan Data Transaksi & Produk',
          style: TextStyle(color: AppTheme.dangerColor),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.all(16),
          side: BorderSide(color: AppTheme.dangerColor.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildRecoveryKeyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _showRecoveryKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.vignette_rounded, color: Colors.purple),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Kunci Pemulihan (Recovery Key)',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[900],
                        ),
                      ),
                      Text(
                        'Penting untuk pindah ke HP baru',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.purple[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.purple),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.storage_rounded,
            size: 64,
            color: AppTheme.textSecondary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada backup',
            style: GoogleFonts.poppins(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBackupList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _backups.length,
      itemBuilder: (context, index) {
        final file = _backups[index];
        final filename = p.basename(file.path);
        final stats = file.statSync();
        final size = (stats.size / 1024).toStringAsFixed(1);
        final date = DateFormat('dd MMM yyyy, HH:mm').format(stats.modified);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE8F5E9),
              child: Icon(Icons.description_rounded, color: Colors.green),
            ),
            title: Text(
              filename,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$date • $size KB',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.settings_backup_restore_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Restore Datanya'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('Bagikan/Kirim File'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppTheme.dangerColor,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Hapus',
                        style: TextStyle(color: AppTheme.dangerColor),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (val) {
                if (val == 'restore') _handleRestore(file);
                if (val == 'share') {
                  Share.shareXFiles([
                    XFile(file.path),
                  ], text: 'Backup Database Posify');
                }
                if (val == 'delete') {
                  file.deleteSync();
                  _loadBackups();
                }
              },
            ),
          ),
        );
      },
    );
  }
}
