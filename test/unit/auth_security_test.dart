import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/app/app_config.dart';
import 'package:fuel_arena/app/startup_checks.dart';
import 'package:fuel_arena/core/utils/safe_logger.dart';

void main() {
  group('Auth Security & Configuration Invariants', () {
    test('productionNeverUsesMockAuthRepository', () {
      final config = AppConfig(
        environment: AppEnvironment.production,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
        googleWebClientId: '123456.apps.googleusercontent.com',
        googleAndroidClientId: '123456.apps.googleusercontent.com',
        googleIosClientId: '123456.apps.googleusercontent.com',
        googleServerClientId: '123456.apps.googleusercontent.com',
        googleReversedIosClientId: 'com.googleusercontent.apps.123456',
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
        iapPremiumMonthlyId: '',
        iapPremiumYearlyId: '',
        iapSeasonPassId: '',
        iapPremiumBundleId: '',
        kakaoMapKey: '',
        googleMapsApiKey: '',
        stagingAllowMockAuth: false,
      );

      expect(config.canUseMockAuthRepository, isFalse);
      expect(config.canUseMockRepositories, isFalse);
      expect(config.repositoryMode, equals('supabase'));
    });

    test('devMissingGoogleConfigUsesMockAuthRepository', () {
      final config = AppConfig(
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
        iapPremiumMonthlyId: '',
        iapPremiumYearlyId: '',
        iapSeasonPassId: '',
        iapPremiumBundleId: '',
        kakaoMapKey: '',
        googleMapsApiKey: '',
        stagingAllowMockAuth: false,
      );

      expect(config.canUseMockAuthRepository, isTrue);
      expect(config.canUseMockRepositories, isTrue);
      expect(config.repositoryMode, equals('mock'));
    });

    test('stagingMissingGoogleConfigBlocksStartup', () {
      final config = AppConfig(
        environment: AppEnvironment.staging,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
        googleWebClientId: '', // missing config
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
        iapPremiumMonthlyId: '',
        iapPremiumYearlyId: '',
        iapSeasonPassId: '',
        iapPremiumBundleId: '',
        kakaoMapKey: '',
        googleMapsApiKey: '',
        stagingAllowMockAuth:
            false, // mock auth not allowed in staging by default
      );

      final error = StartupChecks.validate(config);
      expect(error, isNotNull);
      expect(error!.developerMessage,
          contains('Web/Android/iOS/Server Google OAuth 클라이언트'));
    });

    test('stagingAllowMockAuthEnablesMockRepository', () {
      final config = AppConfig(
        environment: AppEnvironment.staging,
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
        iapPremiumMonthlyId: '',
        iapPremiumYearlyId: '',
        iapSeasonPassId: '',
        iapPremiumBundleId: '',
        kakaoMapKey: '',
        googleMapsApiKey: '',
        stagingAllowMockAuth: true, // explicit override allowed
      );

      expect(config.canUseMockAuthRepository, isTrue);
      expect(config.canUseMockRepositories, isTrue);
      expect(config.repositoryMode, equals('mock'));
    });

    test('SafeLoggerMasksTokensAndSensitiveData', () {
      final rawJwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final rawGoogleClientId = '12345678-abcdef.apps.googleusercontent.com';
      final rawAccessToken = 'accessToken';

      expect(SafeLogger.mask(rawJwt), startsWith('eyJhb...[REDACTED]'));
      expect(SafeLogger.mask(rawGoogleClientId),
          equals('123456...apps.googleusercontent.com'));
      expect(SafeLogger.mask(rawAccessToken), equals('[REDACTED_TOKEN]'));
    });
  });
}
