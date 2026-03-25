import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const _storage = FlutterSecureStorage();
  
  // MENGGUNAKAN NAMA KUNCI YANG SAMA DENGAN DATABASE.DART
  // Inilah inti dari unified-key SQLCipher
  static const _keyName = 'db_encryption_key';

  /// Mengambil Master Recovery Key SQLCipher untuk ditampilkan ke pengguna
  Future<String> getRecoveryKey() async {
    String? key = await _storage.read(key: _keyName);
    if (key == null || key.isEmpty) {
      return 'Kunci belum ter-generate (Login Terlebih Dahulu)';
    }
    return key; // Teks Password ~44 karakter (Base64)
  }

  /// Mem-backup Database (Hanya menyalin karena otomatis terenkripsi oleh SQLCipher)
  Future<String> performAutoBackup() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      // File ini SUDAH merupakan brankas AES-256 yang aman buatan Drift SQLCipher
      final dbFile = File(p.join(dbFolder.path, 'posify.db'));

      if (!await dbFile.exists()) return 'Database tidak ditemukan';

      final appSupportDir = await getApplicationSupportDirectory();
      final backupsDir = Directory(p.join(appSupportDir.path, 'backups'));

      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      // Disimpan dengan format eksklusif .posifybak agar mudah di-filter FilePicker
      final backupPath = p.join(
        backupsDir.path,
        'posify_backup_$timestamp.posifybak',
      );

      // LANGSUNG Salin file! Tidak perlu encrypt lagi.
      await dbFile.copy(backupPath);

      return 'Auto-backup berhasil disimpan';
    } catch (e) {
      return 'Auto-backup gagal: $e';
    }
  }

  /// Membaca daftar file backup di penyimpanan internal aplikasi
  Future<List<File>> getBackupList() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final backupsDir = Directory(p.join(appSupportDir.path, 'backups'));

    if (!await backupsDir.exists()) return [];

    // Bisa disaring berdasarkan ekstensi .posifybak jika diperlukan
    final files = backupsDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // Terbaru di atas
    return files;
  }

  /// Me-restore file backup ke direktori utama aplikasi Drift
  Future<void> restoreBackup(File backupFile, {String? recoveryKey}) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'posify.db');

    // JIKA RESTORE DARI HP LAIN & KUNCI (PASSWORD) DIMASUKKAN OLEH PENGGUNA
    if (recoveryKey != null && recoveryKey.isNotEmpty) {
      // TIMPA Master Key di HP Baru ini dengan Key dari HP Lama!
      // Agar Drift/SQLCipher bisa membaca file backup HP lama ini tanpa mendeteksi "corrupted error".
      await _storage.write(key: _keyName, value: recoveryKey);
    }

    final currentDbFile = File(dbPath);
    if (await currentDbFile.exists()) {
      await currentDbFile.delete(); // Kosongkan database saat ini
    }

    // Salin file backup untuk menjadi database primer
    await backupFile.copy(dbPath);
  }

  /// Fungsi antarmuka: Impor file (misal dari Google Drive/USB) lalu jadikan backup baru
  Future<void> importAndRestore(File externalFile, String recoveryKey) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final backupsDir = Directory(p.join(appSupportDir.path, 'backups'));
    if (!await backupsDir.exists()) await backupsDir.create(recursive: true);

    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final internalPath = p.join(
      backupsDir.path,
      'imported_backup_$timestamp.posifybak',
    );
    
    // 1. Amankan salinan backup dari file picker ke direktori internal aplikasi
    await externalFile.copy(internalPath);

    // 2. Langsung timpa database utama, BERSAMAAN DENGAN kunci pemulihannya
    await restoreBackup(File(internalPath), recoveryKey: recoveryKey);
  }
}
