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

  if (config.isProduction && !config.hasSupabase) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError: 'production 모드에서는 SUPABASE_URL과 SUPABASE_ANON_KEY가 필요합니다.',
    );
  }

  if (!config.hasSupabase) {
    return BootstrapResult(
      config: config,
      supabaseInitialized: false,
      configurationError: null,
    );
  }

  await Supabase.initialize(
    url: config.supabaseUrl,
    anonKey: config.supabaseAnonKey,
  );

  return BootstrapResult(
    config: config,
    supabaseInitialized: true,
    configurationError: null,
  );
}
