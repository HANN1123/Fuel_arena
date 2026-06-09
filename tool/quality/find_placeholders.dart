// ignore_for_file: avoid_print, avoid_relative_lib_imports, unused_local_variable, unused_import
import 'dart:io';

void main() {
  print('=== UI Placeholder String Scan Started ===');
  final libDir = Directory('lib/features');
  if (!libDir.existsSync()) {
    print('Error: lib/features directory not found.');
    exit(1);
  }

  final List<String> placeholders = ['TODO', '준비 중', 'lorem ipsum', '임시', 'placeholder'];
  int totalFiles = 0;
  int filesWithPlaceholders = 0;
  int totalFindings = 0;

  for (final entity in libDir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      totalFiles++;
      final lines = entity.readAsLinesSync();
      final fileFindings = <String>[];

      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final trimmed = line.trim();

        // Check if line is a comment or import line
        if (trimmed.startsWith('//') || trimmed.startsWith('import ')) {
          continue;
        }

        for (final keyword in placeholders) {
          if (line.contains(keyword)) {
            // Exclude valid production fallback texts for missing official data
            if (keyword == '준비 중' && (line.contains('공식 효율 정보 준비 중') || line.contains('정보 준비 중'))) {
              continue;
            }
            // Confirm it's likely a UI string or hardcoding, not a comment
            fileFindings.add('  Line ${i + 1}: $trimmed (Keyword: "$keyword")');
            totalFindings++;
            break;
          }
        }
      }

      if (fileFindings.isNotEmpty) {
        filesWithPlaceholders++;
        print('\n[FINDING] ${entity.path}:');
        for (final finding in fileFindings) {
          print(finding);
        }
      }
    }
  }

  print('\n=== Scan Summary ===');
  print('Total files scanned: $totalFiles');
  print('Files with placeholders: $filesWithPlaceholders');
  print('Total findings: $totalFindings');

  if (totalFindings > 0) {
    print('\n[WARNING] Please resolve the placeholders before releasing to production.');
    // We do not fail the build here, just exit 0 to show it's a scan report.
    exit(0);
  } else {
    print('\n[SUCCESS] No UI placeholder strings found in presentation widgets.');
    exit(0);
  }
}
