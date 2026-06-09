import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'app_environment.dart';

export 'app_environment.dart';

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
    this.stagingAllowMockAuth = false,
    this.supportEmail = '',
    this.termsOfServiceUrl = '',
    this.privacyPolicyUrl = '',
    this.locationPolicyUrl = '',
  });

  factory AppConfig.fromEnvironment() {
    String readRaw(String key, [String fallback = '']) {
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

    final environment = AppEnvironment.parse(readRaw('APP_ENV', 'dev'));

    String readScoped(String key, [String fallback = '']) {
      final generic = readRaw(key, fallback);
      return readRaw('${key}_${environment.envSuffix}', generic);
    }

    String readFirst(List<String> keys, [String fallback = '']) {
      for (final key in keys) {
        final value = readRaw(key);
        if (value.isNotEmpty) {
          return value;
        }
      }
      return fallback;
    }

    return AppConfig(
      environment: environment,
      supabaseUrl: readScoped('SUPABASE_URL'),
      supabaseAnonKey: readScoped('SUPABASE_ANON_KEY'),
      googleWebClientId: readScoped('GOOGLE_WEB_CLIENT_ID'),
      googleAndroidClientId: readScoped('GOOGLE_ANDROID_CLIENT_ID'),
      stagingAllowMockAuth: readRaw('STAGING_ALLOW_MOCK_AUTH') == 'true',
      googleIosClientId: readScoped('GOOGLE_IOS_CLIENT_ID'),
      googleServerClientId: readScoped('GOOGLE_SERVER_CLIENT_ID'),
      googleReversedIosClientId: readScoped('GOOGLE_REVERSED_IOS_CLIENT_ID'),
      authRedirectScheme: readFirst(
        const ['AUTH_REDIRECT_SCHEME', 'APP_AUTH_REDIRECT_SCHEME'],
        'fuelarena',
      ),
      authRedirectHost: readFirst(
        const ['AUTH_REDIRECT_HOST', 'APP_AUTH_REDIRECT_HOST'],
        'login-callback',
      ),
      adMobAndroidAppId: readRaw('ADMOB_ANDROID_APP_ID'),
      adMobIosAppId: readRaw('ADMOB_IOS_APP_ID'),
      rewardedAndroidUnitId: readRaw('ADMOB_REWARDED_ANDROID_UNIT_ID'),
      rewardedIosUnitId: readRaw('ADMOB_REWARDED_IOS_UNIT_ID'),
      nativeAndroidUnitId: readRaw('ADMOB_NATIVE_ANDROID_UNIT_ID'),
      nativeIosUnitId: readRaw('ADMOB_NATIVE_IOS_UNIT_ID'),
      interstitialAndroidUnitId: readRaw('ADMOB_INTERSTITIAL_ANDROID_UNIT_ID'),
      interstitialIosUnitId: readRaw('ADMOB_INTERSTITIAL_IOS_UNIT_ID'),
      iapPremiumMonthlyId: readRaw(
        'IAP_PREMIUM_MONTHLY_ID',
        'fuel_arena_premium_monthly',
      ),
      iapPremiumYearlyId: readRaw(
        'IAP_PREMIUM_YEARLY_ID',
        'fuel_arena_premium_yearly',
      ),
      iapSeasonPassId: readRaw('IAP_SEASON_PASS_ID', 'fuel_arena_season_pass'),
      iapPremiumBundleId: readRaw(
        'IAP_PREMIUM_BUNDLE_ID',
        'fuel_arena_premium_bundle',
      ),
      kakaoMapKey: readRaw('KAKAO_MAP_KEY'),
      googleMapsApiKey: readRaw('GOOGLE_MAPS_API_KEY'),
      supportEmail: readRaw('SUPPORT_EMAIL'),
      termsOfServiceUrl: readFirst(
        const ['TERMS_OF_SERVICE_URL', 'PUBLIC_TERMS_URL'],
      ),
      privacyPolicyUrl: readFirst(
        const ['PRIVACY_POLICY_URL', 'PUBLIC_PRIVACY_POLICY_URL'],
      ),
      locationPolicyUrl: readFirst(
        const ['LOCATION_POLICY_URL', 'PUBLIC_LOCATION_NOTICE_URL'],
      ),
    );
  }

  static String _dartDefineValue(String key) {
    return switch (key) {
      'SUPABASE_URL' => const String.fromEnvironment('SUPABASE_URL'),
      'SUPABASE_URL_DEV' => const String.fromEnvironment('SUPABASE_URL_DEV'),
      'SUPABASE_URL_STAGING' =>
        const String.fromEnvironment('SUPABASE_URL_STAGING'),
      'SUPABASE_URL_PRODUCTION' =>
        const String.fromEnvironment('SUPABASE_URL_PRODUCTION'),
      'SUPABASE_ANON_KEY' => const String.fromEnvironment('SUPABASE_ANON_KEY'),
      'SUPABASE_ANON_KEY_DEV' =>
        const String.fromEnvironment('SUPABASE_ANON_KEY_DEV'),
      'SUPABASE_ANON_KEY_STAGING' =>
        const String.fromEnvironment('SUPABASE_ANON_KEY_STAGING'),
      'SUPABASE_ANON_KEY_PRODUCTION' =>
        const String.fromEnvironment('SUPABASE_ANON_KEY_PRODUCTION'),
      'APP_ENV' => const String.fromEnvironment('APP_ENV'),
      'GOOGLE_WEB_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
      'GOOGLE_WEB_CLIENT_ID_DEV' =>
        const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID_DEV'),
      'GOOGLE_WEB_CLIENT_ID_STAGING' =>
        const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID_STAGING'),
      'GOOGLE_WEB_CLIENT_ID_PRODUCTION' =>
        const String.fromEnvironment('GOOGLE_WEB_CLIENT_ID_PRODUCTION'),
      'GOOGLE_ANDROID_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID'),
      'GOOGLE_ANDROID_CLIENT_ID_DEV' =>
        const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID_DEV'),
      'GOOGLE_ANDROID_CLIENT_ID_STAGING' =>
        const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID_STAGING'),
      'GOOGLE_ANDROID_CLIENT_ID_PRODUCTION' =>
        const String.fromEnvironment('GOOGLE_ANDROID_CLIENT_ID_PRODUCTION'),
      'GOOGLE_IOS_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID'),
      'GOOGLE_IOS_CLIENT_ID_DEV' =>
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID_DEV'),
      'GOOGLE_IOS_CLIENT_ID_STAGING' =>
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID_STAGING'),
      'GOOGLE_IOS_CLIENT_ID_PRODUCTION' =>
        const String.fromEnvironment('GOOGLE_IOS_CLIENT_ID_PRODUCTION'),
      'GOOGLE_SERVER_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
      'GOOGLE_SERVER_CLIENT_ID_DEV' =>
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID_DEV'),
      'GOOGLE_SERVER_CLIENT_ID_STAGING' =>
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID_STAGING'),
      'GOOGLE_SERVER_CLIENT_ID_PRODUCTION' =>
        const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID_PRODUCTION'),
      'GOOGLE_REVERSED_IOS_CLIENT_ID' =>
        const String.fromEnvironment('GOOGLE_REVERSED_IOS_CLIENT_ID'),
      'GOOGLE_REVERSED_IOS_CLIENT_ID_DEV' =>
        const String.fromEnvironment('GOOGLE_REVERSED_IOS_CLIENT_ID_DEV'),
      'GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING' =>
        const String.fromEnvironment('GOOGLE_REVERSED_IOS_CLIENT_ID_STAGING'),
      'GOOGLE_REVERSED_IOS_CLIENT_ID_PRODUCTION' =>
        const String.fromEnvironment(
            'GOOGLE_REVERSED_IOS_CLIENT_ID_PRODUCTION'),
      'AUTH_REDIRECT_SCHEME' =>
        const String.fromEnvironment('AUTH_REDIRECT_SCHEME'),
      'AUTH_REDIRECT_HOST' =>
        const String.fromEnvironment('AUTH_REDIRECT_HOST'),
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
      'SUPPORT_EMAIL' => const String.fromEnvironment('SUPPORT_EMAIL'),
      'TERMS_OF_SERVICE_URL' =>
        const String.fromEnvironment('TERMS_OF_SERVICE_URL'),
      'PRIVACY_POLICY_URL' =>
        const String.fromEnvironment('PRIVACY_POLICY_URL'),
      'LOCATION_POLICY_URL' =>
        const String.fromEnvironment('LOCATION_POLICY_URL'),
      'PUBLIC_TERMS_URL' => const String.fromEnvironment('PUBLIC_TERMS_URL'),
      'PUBLIC_PRIVACY_POLICY_URL' =>
        const String.fromEnvironment('PUBLIC_PRIVACY_POLICY_URL'),
      'PUBLIC_LOCATION_NOTICE_URL' =>
        const String.fromEnvironment('PUBLIC_LOCATION_NOTICE_URL'),
      'STAGING_ALLOW_MOCK_AUTH' =>
        const String.fromEnvironment('STAGING_ALLOW_MOCK_AUTH'),
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
  final String supportEmail;
  final String termsOfServiceUrl;
  final String privacyPolicyUrl;
  final String locationPolicyUrl;

  bool get isDev => environment == AppEnvironment.dev;
  bool get isStaging => environment == AppEnvironment.staging;
  bool get isProduction => environment == AppEnvironment.production;
  bool get requiresSupabase => isStaging || isProduction;
  bool get hasSupabase => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  bool get isSupabaseConfigured => hasSupabase;
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

  final bool stagingAllowMockAuth;

  bool get hasMatchingGoogleIosReversedClientId =>
      expectedGoogleReversedIosClientId.isNotEmpty &&
      googleReversedIosClientId == expectedGoogleReversedIosClientId;

  bool get hasProductionGoogleOAuthConfig =>
      hasValidGoogleOAuthClientIds &&
      hasMatchingGoogleIosReversedClientId &&
      authRedirectScheme == 'fuelarena' &&
      authRedirectHost == 'login-callback';
  bool get isGoogleAuthConfigured =>
      (isDev || (isStaging && stagingAllowMockAuth))
          ? hasGoogleOAuthClient ||
              canUseMockRepositories ||
              canUseMockAuthRepository
          : hasProductionGoogleOAuthConfig;
  bool get canUseMockRepositories =>
      (isDev || (isStaging && stagingAllowMockAuth)) && !hasSupabase;
  bool get canUseMockAuthRepository =>
      (isDev || (isStaging && stagingAllowMockAuth)) &&
      !hasProductionGoogleOAuthConfig;
  String get authRedirectUri => '$authRedirectScheme://$authRedirectHost';
  String get repositoryMode {
    if (canUseMockRepositories || canUseMockAuthRepository) {
      return 'mock';
    }
    if (hasSupabase) {
      return 'supabase';
    }
    return 'unavailable';
  }

  bool get hasLegalUrls =>
      termsOfServiceUrl.isNotEmpty &&
      privacyPolicyUrl.isNotEmpty &&
      locationPolicyUrl.isNotEmpty;
  bool get hasRewardedAds =>
      rewardedAndroidUnitId.isNotEmpty || rewardedIosUnitId.isNotEmpty;
  bool get hasNativeAds =>
      nativeAndroidUnitId.isNotEmpty || nativeIosUnitId.isNotEmpty;
  bool get hasMaps => kakaoMapKey.isNotEmpty || googleMapsApiKey.isNotEmpty;

  String get modeLabel => environment.label;
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
          stagingAllowMockAuth: false,
          supportEmail: '',
          termsOfServiceUrl: '',
          privacyPolicyUrl: '',
          locationPolicyUrl: '',
        );
}
