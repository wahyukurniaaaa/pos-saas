import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:posify_app/core/theme/app_theme.dart';
import 'package:posify_app/core/services/backup_service.dart';
import 'package:path/path.dart' as p;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Manajemen Database',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textPrimary,
      ),
      body: _isLoading
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
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _handleBackup,
        label: const Text('Backup Sekarang'),
        icon: const Icon(Icons.backup_rounded),
        backgroundColor: AppTheme.primaryColor,
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
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Data Anda dienkripsi dengan AES-256 dan disimpan secara lokal di perangkat ini.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
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
            style: GoogleFonts.inter(color: AppTheme.textSecondary),
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
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '$date • $size KB',
              style: GoogleFonts.inter(fontSize: 12),
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
