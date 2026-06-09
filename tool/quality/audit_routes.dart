// ignore_for_file: avoid_print, avoid_relative_lib_imports, unused_local_variable, unused_import
import 'dart:io';

void main() {
  print('=== GoRouter Route Audit Started ===');
  final routerFile = File('lib/app/router.dart');
  if (!routerFile.existsSync()) {
    print('Error: lib/app/router.dart not found.');
    exit(1);
  }

  final content = routerFile.readAsStringSync();

  // Find all GoRoute(...) blocks by scanning the string and matching matching parentheses
  int index = 0;
  final List<Map<String, String>> routes = [];
  while (true) {
    index = content.indexOf('GoRoute(', index);
    if (index == -1) break;

    int parenCount = 0;
    int end = -1;
    for (int i = index + 8; i < content.length; i++) {
      if (content[i] == '(') {
        parenCount++;
      } else if (content[i] == ')') {
        if (parenCount == 0) {
          end = i;
          break;
        }
        parenCount--;
      }
    }

    if (end != -1) {
      final block = content.substring(index, end + 1);
      final pathMatch = RegExp(r'''path:\s*['"]([^'"]*)['"]''').firstMatch(block);
      if (pathMatch != null && !block.contains('redirect:')) {
        final path = pathMatch.group(1)!;
        final screenMatch = RegExp(r'''(\w+Screen)\b''').firstMatch(block);
        if (screenMatch != null) {
          routes.add({'path': path, 'className': screenMatch.group(1)!});
        }
      }
      index = end + 1;
    } else {
      index += 8;
    }
  }

  int totalRoutes = 0;
  int emptyRoutes = 0;
  final List<String> issues = [];

  for (final route in routes) {
    totalRoutes++;
    final path = route['path']!;
    final className = route['className']!;

    // Find the file defining the class name
    final file = _findFileForClass('lib', className);
    if (file == null) {
      issues.add('Route "$path" maps to "$className", but its definition file could not be found.');
      emptyRoutes++;
      continue;
    }

    final fileContent = file.readAsStringSync();
    
    // Check if the file content looks like an empty mock template or placeholder
    bool isEmptyTemplate = false;
    final lines = fileContent.split('\n');

    if (lines.length < 15) {
      isEmptyTemplate = true;
    } else if (fileContent.contains('// TODO: 구현 필요') ||
        fileContent.contains('// TODO: 임시') ||
        (fileContent.contains('EmptyStateView') && lines.length < 35)) {
      isEmptyTemplate = true;
    }

    if (isEmptyTemplate) {
      issues.add('Route "$path" maps to "$className" at ${file.path}, which appears to be an empty or unimplemented template.');
      emptyRoutes++;
    }
  }

  print('Total routes checked: $totalRoutes');
  if (issues.isNotEmpty) {
    print('\n[WARNING] Found $emptyRoutes empty or unimplemented route target screens:');
    for (final issue in issues) {
      print(' - $issue');
    }
    // We exit with 0 to warn, or 1 to block build. 
    // Since this is a warning report, we print warning but allow build for local dev.
    print('\nAudit finished with warnings.');
  } else {
    print('\n[SUCCESS] All $totalRoutes routes are successfully mapped to implemented screen files.');
  }
}

File? _findFileForClass(String dirPath, String className) {
  final dir = Directory(dirPath);
  if (!dir.existsSync()) return null;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final content = entity.readAsStringSync();
      if (content.contains('class $className ')) {
        return entity;
      }
    }
  }
  return null;
}
