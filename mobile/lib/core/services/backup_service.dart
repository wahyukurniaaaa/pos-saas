import 'dart:io';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';

class BackupService {
  static final BackupService _instance = BackupService._internal();
  factory BackupService() => _instance;
  BackupService._internal();

  static const _storage = FlutterSecureStorage();
  static const _keyName = 'backup_encryption_key';

  Future<String> _getOrCreateKey() async {
    String? key = await _storage.read(key: _keyName);
    if (key == null) {
      final newKey = encrypt.Key.fromSecureRandom(32).base64;
      await _storage.write(key: _keyName, value: newKey);
      key = newKey;
    }
    return key;
  }

  Future<void> encryptFile(File sourceFile, String targetPath) async {
    final keyString = await _getOrCreateKey();
    final key = encrypt.Key.fromBase64(keyString);
    final iv = encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final contents = await sourceFile.readAsBytes();
    final encrypted = encrypter.encryptBytes(contents, iv: iv);

    // Store IV (16 bytes) then encrypted data
    final result = Uint8List(16 + encrypted.bytes.length);
    result.setAll(0, iv.bytes);
    result.setAll(16, encrypted.bytes);

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(result);
  }

  Future<void> decryptFile(File encryptedFile, String targetPath) async {
    final keyString = await _getOrCreateKey();
    final key = encrypt.Key.fromBase64(keyString);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    final contents = await encryptedFile.readAsBytes();
    if (contents.length < 16) throw Exception('Invalid backup file');

    final iv = encrypt.IV(contents.sublist(0, 16));
    final encryptedData = contents.sublist(16);

    final decrypted = encrypter.decryptBytes(
      encrypt.Encrypted(encryptedData),
      iv: iv,
    );

    final targetFile = File(targetPath);
    await targetFile.writeAsBytes(decrypted);
  }

  Future<String> performAutoBackup() async {
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(dbFolder.path, 'posify.db'));

      if (!await dbFile.exists()) return 'Database tidak ditemukan';

      // For auto-backup, we store it in a internal but persistent folder
      // Users can see/export these from the Settings UI later
      final appSupportDir = await getApplicationSupportDirectory();
      final backupsDir = Directory(p.join(appSupportDir.path, 'backups'));

      if (!await backupsDir.exists()) {
        await backupsDir.create(recursive: true);
      }

      final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final backupPath = p.join(
        backupsDir.path,
        'posify_backup_$timestamp.enc',
      );

      await encryptFile(dbFile, backupPath);

      // Also try to copy to a more accessible folder if possible (Optional but good)
      // For now, internal backup is enough for the "Tutup Shift" flow

      return 'Auto-backup berhasil disimpan';
    } catch (e) {
      return 'Auto-backup gagal: $e';
    }
  }

  Future<List<File>> getBackupList() async {
    final appSupportDir = await getApplicationSupportDirectory();
    final backupsDir = Directory(p.join(appSupportDir.path, 'backups'));

    if (!await backupsDir.exists()) return [];

    final files = backupsDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.path.compareTo(a.path)); // Newest first
    return files;
  }

  Future<void> restoreBackup(File encryptedFile) async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dbFolder.path, 'posify.db');

    // Safety: Delete current DB first might be risky,
    // better decrypt to temp then rename
    final tempPath = '$dbPath.tmp';
    await decryptFile(encryptedFile, tempPath);

    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      await dbFile.delete();
    }

    await File(tempPath).rename(dbPath);
  }
}
