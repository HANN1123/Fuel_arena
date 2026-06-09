import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/errors/config_exception.dart';
import 'app_config.dart';
import 'startup_checks.dart';

class BootstrapResult {
  const BootstrapResult({
    required this.config,
    required this.supabaseInitialized,
    required this.configurationError,
    this.configurationException,
  });

  final AppConfig config;
  final bool supabaseInitialized;
  final String? configurationError;
  final ConfigException? configurationException;

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

  // StartupChecks covers the legacy release guards:
  // config.requiresSupabase && !config.hasSupabase
  // !config.hasValidSupabaseUrl
  // config.isProduction && !config.hasProductionGoogleOAuthConfig
  // staging/production, SUPABASE_URL 형식이 올바르지 않습니다.
  final configException = StartupChecks.validate(config);
  if (configException != null) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError: configException.developerMessage,
      configurationException: configException,
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
    const exception = ConfigException(
      userMessage: '서버 설정에 문제가 있어요. 잠시 후 다시 시도해주세요.',
      developerMessage:
          'Supabase 초기화에 실패했습니다. SUPABASE_URL과 SUPABASE_ANON_KEY를 확인해 주세요.',
      missingKeys: ['SUPABASE_URL', 'SUPABASE_ANON_KEY'],
    );
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError: exception.developerMessage,
      configurationException: exception,
    );
  }

  return BootstrapResult(
    config: config,
    supabaseInitialized: true,
    configurationError: null,
  );
}
