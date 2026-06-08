import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_config.dart';

class BootstrapResult {
  const BootstrapResult({
    required this.config,
    required this.supabaseInitialized,
    required this.configurationError,
  });

  final AppConfig config;
  final bool supabaseInitialized;
  final String? configurationError;

  bool get canStartApp => configurationError == null;
}

Future<BootstrapResult> bootstrapFuelArena() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb) {
    try {
      await dotenv.load();
    } catch (_) {
      // The app intentionally supports --dart-define and dev mock mode.
    }
  }

  final config = AppConfig.fromEnvironment();

  if (config.requiresSupabase && !config.hasSupabase) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError:
          'staging/production 모드에서는 SUPABASE_URL과 SUPABASE_ANON_KEY가 필요합니다.',
    );
  }

  if (config.isProduction && !config.hasProductionGoogleOAuthConfig) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError:
          'production 모드에서는 Web/Android/iOS/Server Google OAuth 클라이언트, iOS reversed client ID, 앱 callback 설정이 모두 필요합니다.',
    );
  }

  if (config.hasSupabase && !config.hasValidSupabaseUrl) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError:
          'SUPABASE_URL 형식이 올바르지 않습니다. production에서는 https URL이 필요합니다.',
    );
  }

  if (!config.hasSupabase) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError: null,
    );
  }

  try {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        detectSessionInUri: true,
      ),
    );
  } catch (_) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError:
          'Supabase 초기화에 실패했습니다. SUPABASE_URL과 SUPABASE_ANON_KEY를 확인해 주세요.',
    );
  }

  return BootstrapResult(
    config: config,
    supabaseInitialized: true,
    configurationError: null,
  );
}
