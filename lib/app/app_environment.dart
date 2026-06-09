enum AppEnvironment {
  dev,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.trim().toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }

  String get label => switch (this) {
        AppEnvironment.dev => 'dev',
        AppEnvironment.staging => 'staging',
        AppEnvironment.production => 'production',
      };

  String get envSuffix => switch (this) {
        AppEnvironment.dev => 'DEV',
        AppEnvironment.staging => 'STAGING',
        AppEnvironment.production => 'PRODUCTION',
      };
}
