import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateChecker {
  static const String _updateUrl = 'https://raw.githubusercontent.com/wahyukurniaaaa/lumio-apk/main/releases/latest.json';

  static Future<void> check(BuildContext context) async {
    try {
      final response = await http.get(Uri.parse(_updateUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latestVersion = data['latest_version'] as String;
        final downloadUrl = data['download_url'] as String;
        final releaseNotes = data['release_notes'] as String;
        final forceUpdate = data['force_update'] as bool? ?? false;
        final minimumVersion = data['minimum_version'] as String;

        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = packageInfo.version;

        if (_isLowerVersion(currentVersion, minimumVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(
            context,
            latestVersion,
            releaseNotes,
            downloadUrl,
            true, // Force update because it's below minimum
          );
        } else if (_isLowerVersion(currentVersion, latestVersion)) {
          if (!context.mounted) return;
          _showUpdateDialog(
            context,
            latestVersion,
            releaseNotes,
            downloadUrl,
            forceUpdate,
          );
        }
      }
    } catch (e) {
      // Silent fail on error (no internet, timeout, JSON error, dll)
    }
  }

  static bool _isLowerVersion(String current, String target) {
    List<int> currentParts = current.split('.').map((s) => int.tryParse(s) ?? 0).toList();
    List<int> targetParts = target.split('.').map((s) => int.tryParse(s) ?? 0).toList();

    for (int i = 0; i < 3; i++) {
      int c = i < currentParts.length ? currentParts[i] : 0;
      int t = i < targetParts.length ? targetParts[i] : 0;
      if (c < t) return true;
      if (c > t) return false;
    }
    return false;
  }

  static void _showUpdateDialog(
    BuildContext context,
    String latestVersion,
    String releaseNotes,
    String downloadUrl,
    bool forceUpdate,
  ) {
    showDialog(
      context: context,
      barrierDismissible: !forceUpdate,
      builder: (context) {
        return PopScope(
          canPop: !forceUpdate,
          child: AlertDialog(
            title: Text('🔄 Update Tersedia v$latestVersion'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Yang baru:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(releaseNotes),
                ],
              ),
            ),
            actions: [
              if (!forceUpdate)
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Nanti'),
                ),
              ElevatedButton(
                onPressed: () async {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: const Text('Update Sekarang'),
              ),
            ],
          ),
        );
      },
    );
  }
}
