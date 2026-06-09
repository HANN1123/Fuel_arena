// ignore_for_file: avoid_print
import 'dart:io';

void main() {
  print(
      'Scanning lib/ codebase for raw token or session print/log statements...');

  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('[ERROR] lib/ directory does not exist.');
    exit(1);
  }

  // Regex patterns to detect raw print/log of tokens/sessions
  final rawTokenPrintRegex = RegExp(
    r'\b(print|log|logger\.[a-zA-Z]+)\(\s*[^)]*\b(idToken|accessToken|refreshToken|jwt)\b\s*[^)]*\)',
    caseSensitive: false,
  );

  int issuesCount = 0;

  final files = libDir.listSync(recursive: true);
  for (final file in files) {
    if (file is File && file.path.endsWith('.dart')) {
      final lines = file.readAsLinesSync();
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trim().startsWith('//')) {
          continue; // skip comments
        }
        if (rawTokenPrintRegex.hasMatch(line)) {
          print('[ERROR] Raw token logging detected at ${file.path}:${i + 1}');
          print('Line content: ${line.trim()}');
          issuesCount++;
        }
      }
    }
  }

  if (issuesCount > 0) {
    print(
        '[ERROR] Found $issuesCount raw token/session logging statements. Build failed.');
    exit(1);
  }

  print('[SUCCESS] Raw token and session logging check passed.');
}
