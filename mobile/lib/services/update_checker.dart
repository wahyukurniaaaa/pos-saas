import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Mengecek versi terbaru dari GitHub dan menampilkan dialog update jika perlu.
///
/// URL latest.json: https://raw.githubusercontent.com/wahyukurniaaaa/lumio-apk/main/releases/latest.json
///
/// Format latest.json:
/// ```json
/// {
///   "latest_version": "1.2.0",
///   "download_url": "https://github.com/wahyukurniaaaa/lumio-apk/releases/latest/download/lumio.apk",
///   "release_notes": "- Tambah fitur diskon\n- Fix bug struk printer",
///   "force_update": false,
///   "minimum_version": "1.0.0"
/// }
/// ```
class UpdateChecker {
  static const String _latestJsonUrl =
      'https://raw.githubusercontent.com/wahyukurniaaaa/lumio-apk/main/releases/latest.json';

  /// Panggil dari initState() splash/bootstrap screen.
  /// Silent fail jika tidak ada internet, timeout, atau JSON tidak valid.
  static Future<void> check(BuildContext context) async {
    try {
      final response = await http
          .get(Uri.parse(_latestJsonUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) return;

      final Map<String, dynamic> data =
          json.decode(response.body) as Map<String, dynamic>;

      final latestVersion = data['latest_version'] as String? ?? '';
      final downloadUrl = data['download_url'] as String? ?? '';
      final releaseNotes = data['release_notes'] as String? ?? '';
      final forceUpdate = data['force_update'] as bool? ?? false;
      final minimumVersion = data['minimum_version'] as String? ?? '0.0.0';

      if (latestVersion.isEmpty || downloadUrl.isEmpty) return;

      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      if (!context.mounted) return;

      // Cek minimum_version dulu — lebih ketat dari force_update
      if (_isLowerThan(currentVersion, minimumVersion)) {
        _showUpdateDialog(
          context: context,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          forceUpdate: true, // Wajib update, tidak bisa skip
          isBelowMinimum: true,
        );
        return;
      }

      // Cek apakah ada versi baru
      if (_isLowerThan(currentVersion, latestVersion)) {
        _showUpdateDialog(
          context: context,
          latestVersion: latestVersion,
          releaseNotes: releaseNotes,
          downloadUrl: downloadUrl,
          forceUpdate: forceUpdate,
          isBelowMinimum: false,
        );
      }
    } catch (_) {
      // Silent fail: no internet, timeout, JSON parse error, dll
    }
  }

  /// Membandingkan dua versi semantic (MAJOR.MINOR.PATCH).
  /// Mengembalikan true jika [current] lebih rendah dari [target].
  static bool _isLowerThan(String current, String target) {
    final currentParts = _parseSemver(current);
    final targetParts = _parseSemver(target);

    for (int i = 0; i < 3; i++) {
      final c = currentParts[i];
      final t = targetParts[i];
      if (c < t) return true;
      if (c > t) return false;
    }
    return false; // Sama persis
  }

  static List<int> _parseSemver(String version) {
    final parts = version.split('.');
    return List.generate(3, (i) => i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0);
  }

  static void _showUpdateDialog({
    required BuildContext context,
    required String latestVersion,
    required String releaseNotes,
    required String downloadUrl,
    required bool forceUpdate,
    required bool isBelowMinimum,
  }) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (dialogContext) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Text('🔄 ', style: TextStyle(fontSize: 20)),
                Expanded(
                  child: Text(
                    'Update Tersedia v$latestVersion',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isBelowMinimum) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Versi kamu sudah tidak didukung. Update wajib dilakukan.',
                              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'Yang baru:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    releaseNotes,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Nanti'),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('Update Sekarang'),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
