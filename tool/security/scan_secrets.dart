// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

final _secretPatterns = <String, RegExp>{
  'Supabase secret key': RegExp(r'\bsb_secret_[A-Za-z0-9_-]{20,}\b'),
  'Google OAuth client secret': RegExp(r'\bGOCSPX-[A-Za-z0-9_-]{20,}\b'),
  'private key block': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
  'service role assignment': RegExp(
    r'\b(SUPABASE_)?SERVICE_ROLE(_KEY)?\s*=\s*\S+',
    caseSensitive: false,
  ),
  'raw JWT literal': RegExp(r'\beyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.'),
};

final _tokenLogPattern = RegExp(
  r'\b(print|log|logger\.[A-Za-z]+)\s*\([^)]*\b(idToken|accessToken|refreshToken|clientSecret|serviceRole)\b',
  caseSensitive: false,
);

const _allowedTrackedEnvExamples = {
  '.env.example',
  '.env.production.example',
  '.env.staging.example',
  '.env.edge.production.example',
};

const _allowedFixtureFiles = {
  'test/unit/auth_security_test.dart',
  'tool/validate_product_invariants.dart',
  'tool/validate_release_environment_selftest.py',
};

void main() {
  final files = <String>{
    ..._gitFiles(['ls-files', '-z']),
    ..._gitFiles(['ls-files', '--others', '--exclude-standard', '-z']),
  }.where(_shouldScan).toList()
    ..sort();

  final findings = <String>[];
  for (final path in files) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    final lines =
        utf8.decode(file.readAsBytesSync(), allowMalformed: true).split('\n');
    for (var index = 0; index < lines.length; index++) {
      final line = lines[index];
      final trimmed = line.trimLeft();
      if (trimmed.startsWith('//') || trimmed.startsWith('#')) {
        continue;
      }
      for (final entry in _secretPatterns.entries) {
        if (entry.value.hasMatch(line)) {
          findings.add('$path:${index + 1} ${entry.key}');
        }
      }
      if (path.startsWith('lib/') && _tokenLogPattern.hasMatch(line)) {
        findings.add('$path:${index + 1} raw token logging');
      }
    }
  }

  if (findings.isNotEmpty) {
    print('[ERROR] Secret scan failed. Locations only:');
    for (final finding in findings) {
      print('- $finding');
    }
    exit(1);
  }

  print('[SUCCESS] Secret scan passed.');
}

List<String> _gitFiles(List<String> args) {
  final result = Process.runSync(
    'git',
    args,
    stdoutEncoding: null,
    stderrEncoding: utf8,
  );
  if (result.exitCode != 0) {
    print('[ERROR] git ${args.join(' ')} failed.');
    if ((result.stderr as String).isNotEmpty) {
      print(result.stderr);
    }
    exit(1);
  }
  final output = result.stdout as List<int>;
  return utf8
      .decode(output, allowMalformed: true)
      .split('\u0000')
      .where((path) => path.isNotEmpty)
      .map((path) => path.replaceAll('\\', '/'))
      .toList();
}

bool _shouldScan(String path) {
  if (_allowedFixtureFiles.contains(path)) {
    return false;
  }
  final name = path.split('/').last;
  if (name.startsWith('.env')) {
    return _allowedTrackedEnvExamples.contains(path);
  }
  if (path.startsWith('build/') ||
      path.startsWith('.dart_tool/') ||
      path.startsWith('android/.gradle/') ||
      path.startsWith('ios/Pods/')) {
    return false;
  }
  final lower = path.toLowerCase();
  return lower.endsWith('.dart') ||
      lower.endsWith('.py') ||
      lower.endsWith('.md') ||
      lower.endsWith('.yaml') ||
      lower.endsWith('.yml') ||
      lower.endsWith('.json') ||
      lower.endsWith('.xml') ||
      lower.endsWith('.plist') ||
      lower.endsWith('.gradle') ||
      lower.endsWith('.kts') ||
      lower.endsWith('.sql') ||
      lower.endsWith('.txt');
}
