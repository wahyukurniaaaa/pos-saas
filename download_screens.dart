import 'dart:convert';
import 'dart:io';

void main() async {
  final jsonFile = File(r'C:\Users\wahyu\.gemini\antigravity\brain\316d0b20-59b5-43d2-a66b-8fcf1ee64048\.system_generated\steps\51\output.txt');
  final jsonString = await jsonFile.readAsString();
  final data = json.decode(jsonString);

  final outputDir = Directory(r'c:\www\pos-umkm-saas\stitch_screens');
  if (!outputDir.existsSync()) {
    outputDir.createSync();
  }

  for (final screen in data['screens']) {
    final title = screen['title'] ?? 'Unknown';
    // Clean title for file name
    final cleanTitle = title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    
    final htmlCode = screen['htmlCode'];
    final screenshot = screen['screenshot'];
    
    if (htmlCode != null) {
      final htmlUrl = htmlCode['downloadUrl'];
      if (htmlUrl != null) {
        final htmlPath = '${outputDir.path}\\$cleanTitle.html';
        print('Downloading HTML for $title...');
        await Process.run('curl', ['-L', htmlUrl, '-o', htmlPath]);
      }
    }

    if (screenshot != null) {
      final imgUrl = screenshot['downloadUrl'];
      if (imgUrl != null) {
        final imgPath = '${outputDir.path}\\$cleanTitle.png';
        print('Downloading Image for $title...');
        await Process.run('curl', ['-L', imgUrl, '-o', imgPath]);
      }
    }
  }

  print('Done downloading screens.');
}
