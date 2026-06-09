// ignore_for_file: avoid_print
import 'dart:io';

void main() async {
  print('========================================================');
  print('Android Google Sign-In & OAuth Checklist Generator');
  print('========================================================');

  final androidDir = Directory('android');
  if (!androidDir.existsSync()) {
    print(
        '[ERROR] android/ directory not found. Are you in the root of the Flutter project?');
    exit(1);
  }

  print(
      '[INFO] Running gradle signingReport to retrieve SHA-1 and SHA-256 fingerprints...');

  final isWindows = Platform.isWindows;
  final gradlewPath = isWindows ? 'android\\gradlew.bat' : 'android/gradlew';

  if (!File(gradlewPath).existsSync()) {
    print('[WARNING] gradlew wrapper not found at $gradlewPath.');
    print('Manual fallback instructions will be printed at the end.');
  } else {
    try {
      final result = await Process.run(
        isWindows ? 'cmd.exe' : '/bin/sh',
        isWindows
            ? ['/c', gradlewPath, 'signingReport']
            : ['-c', '$gradlewPath signingReport'],
        workingDirectory: Directory.current.path,
      );

      if (result.exitCode == 0) {
        print('[SUCCESS] gradlew signingReport executed successfully.');
        final output = result.stdout as String;

        // Simple parser to extract variant, SHA1, and SHA256
        final lines = output.split('\n');
        String currentVariant = '';
        for (final line in lines) {
          final trimmed = line.trim();
          if (trimmed.startsWith('Variant:')) {
            currentVariant = trimmed.split(':').last.trim();
          } else if (trimmed.startsWith('SHA1:') ||
              trimmed.startsWith('SHA-1:')) {
            final sha1 = trimmed.split(':').sublist(1).join(':').trim();
            if (currentVariant.isNotEmpty) {
              print('Variant [$currentVariant] SHA-1: $sha1');
            }
          } else if (trimmed.startsWith('SHA256:') ||
              trimmed.startsWith('SHA-256:')) {
            final sha256 = trimmed.split(':').sublist(1).join(':').trim();
            if (currentVariant.isNotEmpty) {
              print('Variant [$currentVariant] SHA-256: $sha256');
            }
          }
        }
      } else {
        print(
            '[WARNING] gradle signingReport failed with exit code: ${result.exitCode}');
        print('Error output: ${result.stderr}');
      }
    } catch (e) {
      print('[WARNING] Failed to run gradle signingReport: $e');
    }
  }

  print('\n========================================================');
  print('MANUAL CHECKLIST & COMMANDS FOR ANDROID OAUTH');
  print('========================================================');
  print('1. Find applicationId:');
  print('   Check android/app/build.gradle -> defaultConfig -> applicationId');
  print('\n2. Extract Debug Key SHA-1 & SHA-256 manually:');
  print('   Command (Windows):');
  print(
      '     keytool -list -v -alias androiddebugkey -keystore %USERPROFILE%\\.android\\debug.keystore -storepass android');
  print('   Command (Mac/Linux):');
  print(
      '     keytool -list -v -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android');
  print('\n3. Extract Release Key SHA-1 & SHA-256 manually:');
  print('   Command:');
  print(
      '     keytool -list -v -alias <your-release-key-alias> -keystore <path-to-production-keystore>');
  print('\n4. Google Play App Signing SHA-1:');
  print(
      '   If you use Google Play App Signing, you must retrieve the SHA-1 fingerprint');
  print(
      '   from the Google Play Console (Setup -> App Integrity) and register it');
  print('   in both Google Cloud Console OAuth Client and Supabase.');
  print('========================================================');
}
