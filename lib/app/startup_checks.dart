import '../core/errors/config_exception.dart';
import 'app_config.dart';

class StartupChecks {
  const StartupChecks._();

  static ConfigException? validate(AppConfig config) {
    if (config.requiresSupabase && !config.isSupabaseConfigured) {
      return ConfigException(
        userMessage: '서버 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
        developerMessage:
            'staging/production 모드에서는 Supabase URL과 anon key가 필요합니다.',
        missingKeys: [
          _scopedKey(config, 'SUPABASE_URL'),
          _scopedKey(config, 'SUPABASE_ANON_KEY'),
        ],
      );
    }

    if (config.isSupabaseConfigured && !config.hasValidSupabaseUrl) {
      return ConfigException(
        userMessage: '서버 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
        developerMessage:
            'SUPABASE_URL 형식이 올바르지 않습니다. production에서는 https URL이 필요합니다.',
        missingKeys: [_scopedKey(config, 'SUPABASE_URL')],
      );
    }

    if ((config.isProduction && !config.hasProductionGoogleOAuthConfig) ||
        (config.isStaging && !config.hasProductionGoogleOAuthConfig)) {
      return ConfigException(
        userMessage: '로그인 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
        developerMessage:
            'staging/production 모드에서는 Web/Android/iOS/Server Google OAuth 클라이언트, iOS reversed client ID, fuelarena://login-callback 설정이 모두 필요합니다.',
        missingKeys: [
          _scopedKey(config, 'GOOGLE_WEB_CLIENT_ID'),
          _scopedKey(config, 'GOOGLE_ANDROID_CLIENT_ID'),
          _scopedKey(config, 'GOOGLE_IOS_CLIENT_ID'),
          _scopedKey(config, 'GOOGLE_SERVER_CLIENT_ID'),
          _scopedKey(config, 'GOOGLE_REVERSED_IOS_CLIENT_ID'),
          'AUTH_REDIRECT_SCHEME',
          'AUTH_REDIRECT_HOST',
        ],
      );
    }

    if (!config.isDev && !config.hasLegalUrls) {
      return ConfigException(
        userMessage: '필수 고지 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
        developerMessage:
            'staging/production 모드에서는 약관, 개인정보 처리방침, 위치정보 고지 URL이 필요합니다.',
        missingKeys: const [
          'TERMS_OF_SERVICE_URL',
          'PRIVACY_POLICY_URL',
          'LOCATION_POLICY_URL',
        ],
      );
    }

    return null;
  }

  static String _scopedKey(AppConfig config, String baseKey) {
    return '${baseKey}_${config.environment.envSuffix}';
  }
}
