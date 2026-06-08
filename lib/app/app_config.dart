import 'package:flutter_dotenv/flutter_dotenv.dart';

enum AppEnvironment {
  dev,
  staging,
  production;

  static AppEnvironment parse(String value) {
    return switch (value.toLowerCase()) {
      'production' || 'prod' => AppEnvironment.production,
      'staging' || 'stage' => AppEnvironment.staging,
      _ => AppEnvironment.dev,
    };
  }
}

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.googleWebClientId,
    required this.googleAndroidClientId,
    required this.googleIosClientId,
    required this.googleServerClientId,
    required this.googleReversedIosClientId,
    required this.authRedirectScheme,
    required this.authRedirectHost,
    required this.adMobAndroidAppId,
    required this.adMobIosAppId,
    required this.rewardedAndroidUnitId,
    required this.rewardedIosUnitId,
    required this.nativeAndroidUnitId,
    required this.nativeIosUnitId,
    required this.interstitialAndroidUnitId,
    required this.interstitialIosUnitId,
    required this.iapPremiumMonthlyId,
    required this.iapPremiumYearlyId,
    required this.iapSeasonPassId,
    required this.iapPremiumBundleId,
    required this.kakaoMapKey,
    required this.googleMapsApiKey,
  });

  factory AppConfig.fromEnvironment() {
    String read(String key, [String fallback = '']) {
      final fromDefine = _dartDefineValue(key);
      if (fromDefine.isNotEmpty) {
        return fromDefine;
      }
      try {
        return dotenv.maybeGet(key) ?? fallback;
      } catch (_) {
        return fallback;
      }
    }

    return AppConfig(
      environment: AppEnvironment.parse(read('APP_ENV', 'dev')),
      supabaseUrl: read('SUPABASE_URL'),
      supabaseAnonKey: read('SUPABASE_ANON_KEY'),
      googleWebClientId: read('GOOGLE_WEB_CLIENT_ID'),
      googleAndroidClientId: read('GOOGLE_ANDROID_CLIENT_ID'),
      googleIosClientId: read('GOOGLE_IOS_CLIENT_ID'),
      googleServerClientId: read('GOOGLE_SERVER_CLIENT_ID'),
      googleReversedIosClientId: read('GOOGLE_REVERSED_IOS_CLIENT_ID'),
      authRedirectScheme: read('APP_AUTH_REDIRECT_SCHEME', 'fuelarena'),
      authRedirectHost: read('APP_AUTH_REDIRECT_HOST', 'login-callback'),
      adMobAndroidAppId: read('ADMOB_ANDROID_APP_ID'),
      adMobIosAppId: read('ADMOB_IOS_APP_ID'),
      rewardedAndroidUnitId: read('ADMOB_REWARDED_ANDROID_UNIT_ID'),
      rewardedIosUnitId: read('ADMOB_REWARDED_IOS_UNIT_ID'),
      nativeAndroidUnitId: read('ADMOB_NATIVE_ANDROID_UNIT_ID'),
      nativeIosUnitId: read('ADMOB_NATIVE_IOS_UNIT_ID'),
      interstitialAndroidUnitId: read('ADMOB_INTERSTITIAL_ANDROID_UNIT_ID'),
      interstitialIosUnitId: read('ADMOB_INTERSTITIAL_IOS_UNIT_ID'),
      iapPremiumMonthlyId: read(
        'IAP_PREMIUM_MONTHLY_ID',
        'fuel_arena_premium_monthly',
      ),
      iapPremiumYearlyId: read(
        'IAP_PREMIUM_YEARLY_ID',
        'fuel_arena_premium_yearly',
      ),
      iapSeasonPassId: read('IAP_SEASON_PASS_ID', 'fuel_arena_season_pass'),
      iapPremiumBundleId: read(
        'IAP_PREMIUM_BUNDLE_ID',
        'fuel_arena_premium_bundle',
      ),
      kakaoMapKey: read('KAKAO_MAP_KEY'),
      googleMapsApiKey: read('GOOGLE_MAPS_API_KEY'),
    );
  }

  static String _dartDefineValue(String key) {
    return switch (key) {
      'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_ANON_KEY' => const String.fromEnvironment('SUPABASE_ANON_KEY'),
      'APP_ENV' => const String.fromEnvironment('APP_ENV'),
      'GOOGLE_WEB_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      'GOOGLE_ANDROID_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID'),
      'GOOGLE_IOS_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      'GOOGLE_SERVER_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      'GOOGLE_REVERSED_IOS_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_REVERSED_IOS_CLIENT_ID'),
      'APP_AUTH_REDIRECT_SCHEME' =>
        const String.fromEnvironment('APP_AUTH_REDIRECT_SCHEME'),
      'APP_AUTH_REDIRECT_HOST' =>
        const String.fromEnvironment('APP_AUTH_REDIRECT_HOST'),
      'ADMOB_ANDROID_APP_ID' =>
        const String.fromEnvironment('ADMOB_ANDROID_APP_ID'),
      'ADMOB_IOS_APP_ID' => const String.fromEnvironment('ADMOB_IOS_APP_ID'),
      'ADMOB_REWARDED_ANDROID_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_REWARDED_ANDROID_UNIT_ID'),
      'ADMOB_REWARDED_IOS_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_REWARDED_IOS_UNIT_ID'),
      'ADMOB_NATIVE_ANDROID_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_NATIVE_ANDROID_UNIT_ID'),
      'ADMOB_NATIVE_IOS_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_NATIVE_IOS_UNIT_ID'),
      'ADMOB_INTERSTITIAL_ANDROID_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_INTERSTITIAL_ANDROID_UNIT_ID'),
      'ADMOB_INTERSTITIAL_IOS_UNIT_ID' =>
        const String.fromEnvironment('ADMOB_INTERSTITIAL_IOS_UNIT_ID'),
      'IAP_PREMIUM_MONTHLY_ID' =>
        const String.fromEnvironment('IAP_PREMIUM_MONTHLY_ID'),
      'IAP_PREMIUM_YEARLY_ID' =>
        const String.fromEnvironment('IAP_PREMIUM_YEARLY_ID'),
      'IAP_SEASON_PASS_ID' =>
        const String.fromEnvironment('IAP_SEASON_PASS_ID'),
      'IAP_PREMIUM_BUNDLE_ID' =>
        const String.fromEnvironment('IAP_PREMIUM_BUNDLE_ID'),
      'KAKAO_MAP_KEY' => const String.fromEnvironment('KAKAO_MAP_KEY'),
      'GOOGLE_MAPS_API_KEY' =>
        const String.fromEnvironment('GOOGLE_MAPS_API_KEY'),
      _ => '',
    };
  }

  const factory AppConfig.devMock() = _DevMock;

  final AppEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final String googleWebClientId;
  final String googleAndroidClientId;
  final String googleIosClientId;
  final String googleServerClientId;
  final String googleReversedIosClientId;
  final String authRedirectScheme;
  final String authRedirectHost;
  final String adMobAndroidAppId;
  final String adMobIosAppId;
  final String rewardedAndroidUnitId;
  final String rewardedIosUnitId;
  final String nativeAndroidUnitId;
  final String nativeIosUnitId;
  final String interstitialAndroidUnitId;
  final String interstitialIosUnitId;
  final String iapPremiumMonthlyId;
  final String iapPremiumYearlyId;
  final String iapSeasonPassId;
  final String iapPremiumBundleId;
  final String kakaoMapKey;
  final String googleMapsApiKey;

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;
  bool get requiresSupabase => isStaging || isProduction;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get hasValidSupabaseUrl {
    final uri = Uri.tryParse(supabaseUrl);
    if (!hasSupabase || uri == null || uri.scheme.isEmpty || uri.host.isEmpty) {
      return false;
    }
    if (isProduction && uri.scheme != 'https') {
      return false;
    }
    return uri.scheme == 'https' || uri.scheme == 'http';
  }

  bool get hasGoogleAuth =>
      googleWebClientId.isNotEmpty ||
      googleAndroidClientId.isNotEmpty ||
      googleIosClientId.isNotEmpty ||
      googleServerClientId.isNotEmpty;
  bool get hasGoogleOAuthClient =>
      googleWebClientId.isNotEmpty || googleServerClientId.isNotEmpty;
  static bool _looksLikeGoogleOAuthClientId(String value) {
    const suffix = '.apps.googleusercontent.com';
    return value.endsWith(suffix) && value.length > suffix.length;
  }

  bool get hasValidGoogleOAuthClientIds =>
      _looksLikeGoogleOAuthClientId(googleWebClientId) &&
      _looksLikeGoogleOAuthClientId(googleAndroidClientId) &&
      _looksLikeGoogleOAuthClientId(googleIosClientId) &&
      _looksLikeGoogleOAuthClientId(googleServerClientId);

  String get expectedGoogleReversedIosClientId {
    const suffix = '.apps.googleusercontent.com';
    if (!googleIosClientId.endsWith(suffix)) {
      return '';
    }
    final clientPrefix = googleIosClientId.substring(
      0,
      googleIosClientId.length - suffix.length,
    );
    return clientPrefix.isEmpty
        ? ''
        : 'com.googleusercontent.apps.$clientPrefix';
  }

  bool get hasMatchingGoogleIosReversedClientId =>
      expectedGoogleReversedIosClientId.isNotEmpty &&
      googleReversedIosClientId == expectedGoogleReversedIosClientId;

  bool get hasProductionGoogleOAuthConfig =>
      hasValidGoogleOAuthClientIds &&
      hasMatchingGoogleIosReversedClientId &&
      authRedirectScheme == 'fuelarena' &&
      authRedirectHost == 'login-callback';
  bool get canUseMockRepositories => isDev && !hasSupabase;
  String get authRedirectUri => '$authRedirectScheme://$authRedirectHost';
  bool get hasRewardedAds =>
      rewardedAndroidUnitId.isNotEmpty || rewardedIosUnitId.isNotEmpty;
  bool get hasNativeAds =>
      nativeAndroidUnitId.isNotEmpty || nativeIosUnitId.isNotEmpty;
  bool get hasMaps => kakaoMapKey.isNotEmpty || googleMapsApiKey.isNotEmpty;

  String get modeLabel => switch (environment) {
        AppEnvironment.dev => 'dev',
        AppEnvironment.staging => 'staging',
        AppEnvironment.production => 'production',
      };
}

class _DevMock extends AppConfig {
  const _DevMock()
      : super(
          environment: AppEnvironment.dev,
          supabaseUrl: '',
          supabaseAnonKey: '',
          googleWebClientId: '',
          googleAndroidClientId: '',
          googleIosClientId: '',
          googleServerClientId: '',
          googleReversedIosClientId: '',
          authRedirectScheme: 'fuelarena',
          authRedirectHost: 'login-callback',
          adMobAndroidAppId: '',
          adMobIosAppId: '',
          rewardedAndroidUnitId: '',
          rewardedIosUnitId: '',
          nativeAndroidUnitId: '',
          nativeIosUnitId: '',
          interstitialAndroidUnitId: '',
          interstitialIosUnitId: '',
          iapPremiumMonthlyId: 'fuel_arena_premium_monthly',
          iapPremiumYearlyId: 'fuel_arena_premium_yearly',
          iapSeasonPassId: 'fuel_arena_season_pass',
          iapPremiumBundleId: 'fuel_arena_premium_bundle',
          kakaoMapKey: '',
          googleMapsApiKey: '',
        );
}
