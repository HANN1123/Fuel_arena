// ignore_for_file: avoid_print
import 'dart:io';

void main(List<String> args) {
  String envMode = 'dev';
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--env' && i + 1 < args.length) {
      envMode = args[i + 1];
    }
  }

  print('Checking auth environment validation for mode: $envMode');

  final envMap = _loadEnvFiles(envMode);
  if (envMap.isEmpty) {
    print('[ERROR] No environment values found in .env or .env.$envMode.');
    exit(1);
  }

  for (final key in envMap.keys) {
    final lowerKey = key.toLowerCase();
    if (lowerKey.contains('secret') || lowerKey.contains('private_key')) {
      print(
          '[ERROR] Sensitive Client Secret or Private Key found in env key: $key');
      exit(1);
    }
    if (lowerKey.contains('service_role') || lowerKey.contains('service_key')) {
      print('[ERROR] Sensitive service_role key found in env key: $key');
      exit(1);
    }
  }

  for (final entry in envMap.entries) {
    final value = entry.value;
    if (value.toLowerCase().contains('service_role')) {
      print(
          '[ERROR] Value containing "service_role" found under key: ${entry.key}');
      exit(1);
    }
  }

  final bool allowStagingMock = envMap['STAGING_ALLOW_MOCK_AUTH'] == 'true';

  if (envMode == 'production') {
    if (envMap['STAGING_ALLOW_MOCK_AUTH'] == 'true') {
      print('[ERROR] STAGING_ALLOW_MOCK_AUTH must not be true for production.');
      exit(1);
    }
    final prodKeys = [
      'APP_ENV',
      'SUPABASE_URL_PRODUCTION',
      'SUPABASE_ANON_KEY_PRODUCTION',
      'GOOGLE_WEB_CLIENT_ID_PRODUCTION',
      'GOOGLE_ANDROID_CLIENT_ID_PRODUCTION',
      'GOOGLE_IOS_CLIENT_ID_PRODUCTION',
      'GOOGLE_SERVER_CLIENT_ID_PRODUCTION',
      'GOOGLE_REVERSED_IOS_CLIENT_ID_PRODUCTION',
      'AUTH_REDIRECT_SCHEME',
      'AUTH_REDIRECT_HOST',
      'TERMS_OF_SERVICE_URL',
      'PRIVACY_POLICY_URL',
      'LOCATION_POLICY_URL',
    ];
    for (final key in prodKeys) {
      final val = envMap[key];
      if (val == null || val.isEmpty) {
        print('[ERROR] Missing required production key in env files: $key');
        exit(1);
      }
    }
    _validateEnvironmentName(envMap, 'production');
    _validateSupabaseUrl(envMap, 'PRODUCTION');
    _validateRedirect(envMap);
    _validateClientIds(envMap, 'PRODUCTION');
  } else if (envMode == 'staging') {
    if (!allowStagingMock) {
      final stagingKeys = [
        'APP_ENV',
        'STAGING_ALLOW_MOCK_AUTH',
        'SUPABASE_URL_STAGING',
        'SUPABASE_ANON_KEY_STAGING',
        'GOOGLE_WEB_CLIENT_ID_STAGING',
        'GOOGLE_ANDROID_CLIENT_ID_STAGING',
        'GOOGLE_IOS_CLIENT_ID_STAGING',
        'GOOGLE_SERVER_CLIENT_ID_STAGING',
        'GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING',
        'AUTH_REDIRECT_SCHEME',
        'AUTH_REDIRECT_HOST',
        'TERMS_OF_SERVICE_URL',
        'PRIVACY_POLICY_URL',
        'LOCATION_POLICY_URL',
      ];
      for (final key in stagingKeys) {
        final val = envMap[key];
        if (val == null || val.isEmpty) {
          print('[ERROR] Missing required staging key in env files: $key');
          exit(1);
        }
      }
      _validateEnvironmentName(envMap, 'staging');
      _validateSupabaseUrl(envMap, 'STAGING');
      _validateRedirect(envMap);
      _validateClientIds(envMap, 'STAGING');
    } else {
      print(
          '[INFO] Staging mock auth is allowed, skipping strict missing keys checks.');
      _validateClientIds(envMap, 'STAGING', allowEmpty: true);
    }
  } else {
    print(
        '[INFO] Dev environment validation passed (missing configs are allowed for dev fallback).');
    _validateClientIds(envMap, 'DEV', allowEmpty: true);
  }

  print('[SUCCESS] Environment variables validation check passed.');
}

Map<String, String> _loadEnvFiles(String envMode) {
  final values = <String, String>{};
  void readFile(String path) {
    final envFile = File(path);
    if (!envFile.existsSync()) {
      return;
    }
    for (final line in envFile.readAsLinesSync()) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) {
        continue;
      }
      final parts = trimmed.split('=');
      if (parts.length >= 2) {
        final key = parts[0].trim();
        final value = parts.sublist(1).join('=').trim();
        values[key] = value;
      }
    }
  }

  readFile('.env');
  if (envMode == 'staging' || envMode == 'production') {
    readFile('.env.$envMode');
  }
  return values;
}

void _validateEnvironmentName(Map<String, String> envMap, String expected) {
  if ((envMap['APP_ENV'] ?? '').trim().toLowerCase() != expected) {
    print('[ERROR] APP_ENV must be $expected.');
    exit(1);
  }
}

void _validateSupabaseUrl(Map<String, String> envMap, String suffix) {
  final key = 'SUPABASE_URL_$suffix';
  final url = envMap[key] ?? '';
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
    print('[ERROR] $key must be a valid https Supabase URL.');
    exit(1);
  }
  if (!uri.host.endsWith('.supabase.co')) {
    print('[ERROR] $key must point to a supabase.co project host.');
    exit(1);
  }
}

void _validateRedirect(Map<String, String> envMap) {
  if (envMap['AUTH_REDIRECT_SCHEME'] != 'fuelarena' ||
      envMap['AUTH_REDIRECT_HOST'] != 'login-callback') {
    print(
        '[ERROR] AUTH_REDIRECT_SCHEME/HOST must resolve to fuelarena://login-callback.');
    exit(1);
  }
}

void _validateClientIds(Map<String, String> envMap, String suffix,
    {bool allowEmpty = false}) {
  final webKey = 'GOOGLE_WEB_CLIENT_ID_$suffix';
  final androidKey = 'GOOGLE_ANDROID_CLIENT_ID_$suffix';
  final iosKey = 'GOOGLE_IOS_CLIENT_ID_$suffix';
  final serverKey = 'GOOGLE_SERVER_CLIENT_ID_$suffix';
  final revIosKey = 'GOOGLE_REVERSED_IOS_CLIENT_ID_$suffix';

  const googleSuffix = '.apps.googleusercontent.com';

  void checkGoogleSuffix(String key) {
    final val = envMap[key];
    if (val == null || val.isEmpty) {
      if (allowEmpty) return;
      print('[ERROR] Key $key is empty.');
      exit(1);
    }
    if (!val.endsWith(googleSuffix)) {
      print('[ERROR] $key must end with "$googleSuffix"');
      exit(1);
    }
  }

  checkGoogleSuffix(webKey);
  checkGoogleSuffix(androidKey);
  checkGoogleSuffix(iosKey);
  checkGoogleSuffix(serverKey);

  final revIos = envMap[revIosKey];
  if (revIos != null && revIos.isNotEmpty) {
    if (!revIos.startsWith('com.googleusercontent.apps.')) {
      print('[ERROR] $revIosKey must start with "com.googleusercontent.apps."');
      exit(1);
    }
  } else if (!allowEmpty) {
    print('[ERROR] Key $revIosKey is empty.');
    exit(1);
  }
}
