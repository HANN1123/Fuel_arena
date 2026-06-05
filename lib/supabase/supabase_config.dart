import '../app/app_config.dart';

class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig({
    required this.url,
    required this.anonKey,
    required this.environment,
  });

  factory SupabaseRuntimeConfig.fromAppConfig(AppConfig config) {
    return SupabaseRuntimeConfig(
      url: config.supabaseUrl,
      anonKey: config.supabaseAnonKey,
      environment: config.modeLabel,
    );
  }

  final String url;
  final String anonKey;
  final String environment;

  bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}

