import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fuel_arena/core/errors/app_error.dart';
import 'package:fuel_arena/core/utils/formatters.dart';
import 'package:fuel_arena/core/utils/input_validators.dart';
import 'package:fuel_arena/shared/models/fuel_arena_models.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';
import 'package:fuel_arena/shared/services/app_logger.dart';
import 'package:fuel_arena/shared/services/app_services.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    resetMockFuelArenaState();
  });

  test('FuelEfficiencyFormatter uses km/kWh for electric vehicles', () {
    const formatter = FuelEfficiencyFormatter();

    expect(formatter.unitForFuelLeague('electric'), 'km/kWh');
    expect(formatter.metricLabelForFuelLeague('electric'), '평균 효율');
    expect(formatter.formatResultLine(6.7, 'electric'), '평균 효율 6.7km/kWh');
    expect(formatter.formatResultLine(17.2, 'gasoline'), '평균 연비 17.2km/L');
  });

  test('InputValidators reject placeholder and short support text', () {
    expect(InputValidators.supportTitle('test'), isNotNull);
    expect(InputValidators.supportTitle('주행 오류'), isNull);
    expect(InputValidators.supportBody('짧음'), isNotNull);
    expect(InputValidators.supportBody('주행 결과 점수가 이상하게 표시돼요.'), isNull);
    expect(InputValidators.couponCode('SAVE-2026'), isNull);
    expect(InputValidators.couponCode('bad code!'), isNotNull);
  });

  test('InputValidators enforce fuel amount ranges by fuel league', () {
    expect(InputValidators.positiveFuelAmount('0', fuelLeague: 'electric'),
        isNotNull);
    expect(InputValidators.positiveFuelAmount('12.4', fuelLeague: 'electric'),
        isNull);
    expect(InputValidators.positiveFuelAmount('251', fuelLeague: 'electric'),
        isNotNull);
    expect(InputValidators.positiveFuelAmount('55', fuelLeague: 'gasoline'),
        isNull);
    expect(InputValidators.positiveFuelAmount('201', fuelLeague: 'gasoline'),
        isNotNull);
  });

  test('ErrorMapper returns Korean user-safe copy by exception type', () {
    const mapper = ErrorMapper();

    expect(
      mapper.titleFor(const PermissionException('위치 권한을 확인해 주세요.')),
      '권한이 필요해요',
    );
    expect(
      mapper.titleFor(const AuthException('로그인 세션이 만료됐어요.')),
      '다시 로그인해주세요',
    );
    expect(
      mapper.titleFor(const NetworkException('네트워크가 불안정해요.')),
      '인터넷 연결이 불안정해요',
    );
    expect(
      mapper.titleFor(const AdException('광고 로드 실패')),
      '광고를 불러올 수 없어요',
    );
    expect(
      mapper.messageFor(const NetworkException('')),
      '네트워크 연결을 확인하고 다시 시도해주세요.',
    );
    expect(
      mapper.messageFor(const AdException('')),
      '기본 보상은 유지됩니다. 잠시 후 다시 시도해주세요.',
    );
    expect(
      mapper.messageFor(StateError('로그인이 필요합니다.')),
      '로그인이 필요합니다.',
    );
    expect(
      mapper.messageFor(UnsupportedError('초기 버전은 Google 로그인만 지원합니다.')),
      '초기 버전은 Google 로그인만 지원합니다.',
    );
    expect(mapper.messageFor(Object()), '잠시 후 다시 시도해주세요.');
  });

  test('Analytics sanitizer removes raw location properties', () {
    final safe = sanitizedAnalyticsProperties({
      'screen': 'drive_result',
      'latitude': 37.5,
      'longitude': 127.0,
      'drive_points': [1, 2, 3],
      'coarse_region': '서울',
    });

    expect(safe.containsKey('latitude'), isFalse);
    expect(safe.containsKey('longitude'), isFalse);
    expect(safe.containsKey('drive_points'), isFalse);
    expect(safe['coarse_region'], '서울');
  });

  test('MockAnalyticsRepository stores sanitized events', () async {
    final repository = MockAnalyticsRepository();

    await repository.track('drive_finished', properties: {
      'distance_km': 12.4,
      'location_latitude': 37.5,
    });
    await repository.identify('user-001', properties: {
      'nickname': 'ApexDriver',
      'longitude': 127.0,
    });
    await repository.setUserProperty('latitude', 37.5);
    await repository.setUserProperty('tier', 'Gold III');

    expect(repository.events.first['event'], 'drive_finished');
    expect(repository.events.first.containsKey('location_latitude'), isFalse);
    expect(repository.events.first['distance_km'], 12.4);
    expect(repository.events[1]['event'], 'identify');
    expect(repository.events[1].containsKey('longitude'), isFalse);
    expect(repository.events[1]['nickname'], 'ApexDriver');
    expect(
      repository.events.where((event) => event['key'] == 'latitude'),
      isEmpty,
    );
    expect(repository.events.last['key'], 'tier');
  });

  test('AppLogger sanitizes structured log context', () {
    final context = sanitizedLogContext({
      'screen': 'drive_result',
      'latitude': 37.5,
      'nested': {
        'longitude': 127.0,
        'session_id': 'drive-session-001',
        'authorization': 'Bearer secret-token',
      },
      'points': [
        {'drive_points': 'raw', 'distance_km': 4.3}
      ],
      'message': 'access_token=secret-value',
    });

    expect(context.containsKey('latitude'), isFalse);
    expect(context['screen'], 'drive_result');
    expect(context['message'], contains('[redacted]'));
    expect(context['nested'], {'session_id': 'drive-session-001'});
    expect(context['points'], [
      {'distance_km': 4.3}
    ]);
  });

  test('AppLogger writes structured records through sink', () {
    final records = <AppLogRecord>[];
    final logger = AppLogger(sink: records.add);

    logger.error(
      'Supabase failed with secret=abc123',
      error: StateError('authorization=token-value'),
      stackTrace: StackTrace.current,
      context: {'session_id': 'drive-session-001'},
    );

    expect(records, hasLength(1));
    expect(records.single.level, AppLogLevel.error);
    expect(records.single.message, contains('[redacted]'));
    expect(records.single.errorType, 'StateError');
    expect(records.single.errorMessage, contains('[redacted]'));
    expect(records.single.context['session_id'], 'drive-session-001');
  });

  test('Korean font is bundled for Flutter web rendering', () {
    final typography = File('lib/design_system/app_typography.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final pubspec = File('pubspec.yaml')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final font = File('assets/fonts/NotoSansKR-VF.ttf');

    expect(typography, contains("static const fontFamily = 'NotoSansKR'"));
    expect(typography, isNot(contains("static const fontFamily = 'Sora'")));
    expect(pubspec, contains('family: NotoSansKR'));
    expect(pubspec, contains('assets/fonts/NotoSansKR-VF.ttf'));
    expect(font.existsSync(), isTrue);
    expect(font.lengthSync(), greaterThan(1000000));
  });

  test('Production drive finish never falls back to mock score', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(repositories, contains('this.allowMockFallback = true'));
    expect(repositories, contains('if (!allowMockFallback)'));
    expect(
        repositories, contains('Error.throwWithStackTrace(error, stackTrace)'));
    expect(repositories, contains('_finishDriveSessionFallback'));
    expect(
      providers,
      contains(
          'SupabaseDriveRepository(allowMockFallback: !config.isProduction)'),
    );
  });

  test('Production subscription start never activates mock premium', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final verifyPurchase = File('supabase/functions/verify_purchase/index.ts')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(
      repositories,
      contains("throw StateError('스토어 결제 검증이 필요합니다.')"),
    );
    expect(repositories, contains('class SupabaseSubscriptionRepository'));
    expect(repositories, contains('final bool allowMockFallback;'));
    expect(
      providers,
      contains(
        'SupabaseSubscriptionRepository(allowMockFallback: !config.isProduction)',
      ),
    );
    expect(verifyPurchase, contains('requireSecret("APP_STORE_BUNDLE_ID")'));
    expect(verifyPurchase, contains('GOOGLE_PLAY_PACKAGE_NAME'));
    expect(verifyPurchase, isNot(contains('optionalString(body.packageName)')));
    expect(
      verifyPurchase,
      isNot(contains(
        'Deno.env.get("APP_STORE_BUNDLE_ID") ?? "com.fuelarena.fuel_arena"',
      )),
    );
  });

  test('Production premium plans never fall back to mock catalog', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(repositories, contains('class SupabasePremiumRepository'));
    expect(repositories, contains('final bool allowMockFallback;'));
    expect(repositories, contains('return allowMockFallback'));
    expect(repositories, contains('? _fallback.getPlans()'));
    expect(repositories, contains(': const <SubscriptionPlan>[]'));
    expect(repositories, contains('if (!allowMockFallback)'));
    expect(repositories, contains('_subscriptionPlanSortRank'));
    expect(repositories, contains("'monthly' => 0"));
    expect(repositories, contains("'yearly' => 1"));
    expect(repositories, contains("'season_pass' => 2"));
    expect(repositories, contains("'bundle' => 3"));
    expect(
      repositories,
      contains('allowMockFallback: allowMockFallback'),
    );
    expect(
      providers,
      contains(
        'SupabasePremiumRepository(allowMockFallback: !config.isProduction)',
      ),
    );
  });

  test('Subscription product seed includes all release IAP product ids', () {
    final sql = File(
      'supabase/migrations/202606060021_subscription_product_completion.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');

    for (final productId in [
      'fuel_arena_premium_monthly',
      'fuel_arena_premium_yearly',
      'fuel_arena_season_pass',
      'fuel_arena_premium_bundle',
    ]) {
      expect(sql, contains("'$productId'"));
      expect(repositories, contains("productId: '$productId'"));
    }
    expect(sql, contains("'season_pass'"));
    expect(sql, contains("'bundle'"));
  });

  test('Premium purchase UI exposes all store plans and restore flow', () {
    final source = File('lib/features/premium/presentation/premium_screen.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(source, contains('for (final plan in items)'));
    expect(source, contains('_PremiumPlanCard'));
    expect(source, contains('_planIdByProductId'));
    expect(source, contains('_planIdForProductId(purchase.productID)'));
    expect(source, contains('InAppPurchase.instance.restorePurchases()'));
    expect(source, contains('시즌패스 시작하기'));
    expect(source, contains('번들 시작하기'));
    expect(source, contains('프리미엄 시작하기'));
    expect(source, contains('구매 복원은 Android 또는 iOS에서 진행할 수 있어요.'));
    expect(source, contains('구매 복원을 요청했어요. 스토어 내역을 확인합니다.'));
    expect(source, contains('프리미엄이 활성화됐어요.'));
    expect(source, contains('구매 영수증을 검증하지 못했어요.'));
    expect(source, isNot(contains('紐삵')));
    expect(source, isNot(contains('?ㅽ')));
    expect(source, isNot(contains('寃곗')));
  });

  test('Production ad reward never grants without ad verification', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(repositories, contains('allowClientRewardGrant'));
    expect(repositories, contains('rewardAdsConfigured'));
    expect(repositories, contains("eq('key', 'reward_ad_daily_limit')"));
    expect(repositories, contains(".from('advertisements')"));
    expect(repositories, contains('return const <Advertisement>[];'));
    expect(
        repositories, contains('if (ads.isEmpty && allowClientRewardGrant)'));
    expect(repositories, contains('int _boundedRewardAdLimit(Object? value)'));
    expect(
      repositories,
      contains("throw StateError('광고 시청 검증이 필요합니다.')"),
    );
    expect(
      repositories,
      contains("throw StateError('리워드 광고 설정이 필요합니다.')"),
    );
    expect(repositories, isNot(contains('由ъ')));
    expect(repositories, isNot(contains('愿묎')));
    expect(
      repositories,
      contains('if (!allowClientRewardGrant && !verifiedByAdSdk)'),
    );
    expect(
      repositories,
      contains('watchRewardAd({bool verifiedByAdSdk = false})'),
    );
    expect(
      providers,
      contains('rewardAdsConfigured: config.hasRewardedAds'),
    );
    final rewardService = File('lib/shared/services/admob_reward_service.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    expect(rewardService, contains('MobileAds.instance.initialize()'));
    expect(rewardService, contains('RewardedAd.load'));
    expect(rewardService, contains('onUserEarnedReward'));
    expect(rewardService, contains('kIsWeb'));
    expect(
      File('lib/features/ads/presentation/reward_ad_screen.dart')
          .readAsStringSync(encoding: utf8)
          .replaceAll('\r\n', '\n'),
      contains('verifiedByAdSdk: verifiedByAdSdk'),
    );
    expect(
      File('lib/features/drive/presentation/drive_result_screen.dart')
          .readAsStringSync(encoding: utf8)
          .replaceAll('\r\n', '\n'),
      contains('verifiedByAdSdk: verifiedByAdSdk'),
    );
  });

  test('Production user scoped repositories never show mock user data', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(repositories, contains('class SupabaseProfileRepository'));
    expect(repositories, contains('class SupabaseStatsRepository'));
    expect(repositories,
        contains('allowMockFallback ? _fallback.getAchievements() : const []'));
    expect(repositories,
        contains('allowMockFallback ? _fallback.getBadges() : const []'));
    expect(repositories, contains("throw StateError('로그인이 필요합니다.')"));
    expect(repositories, contains("throw StateError('프로필을 찾을 수 없습니다.')"));
    expect(
      providers,
      contains(
        'SupabaseProfileRepository(allowMockFallback: !config.isProduction)',
      ),
    );
    expect(
      providers,
      contains(
        'SupabaseStatsRepository(allowMockFallback: !config.isProduction)',
      ),
    );
  });

  test('Production operational repositories never show mock operational data',
      () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final fairnessSettings = File(
      'supabase/migrations/202606060022_fairness_guidelines_settings.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    for (final className in [
      'SupabaseSponsorRepository',
      'SupabaseCouponRepository',
      'SupabaseNotificationRepository',
      'SupabaseSupportRepository',
      'SupabaseReportRepository',
      'SupabasePrivacyRequestRepository',
      'SupabaseCrewRepository',
      'SupabaseAdminRepository',
      'SupabaseFairnessRepository',
    ]) {
      expect(repositories, contains('class $className'));
      expect(providers, contains(className));
    }

    for (final providerToken in [
      'sponsorRepositoryProvider',
      'couponRepositoryProvider',
      'notificationRepositoryProvider',
      'supportRepositoryProvider',
      'reportRepositoryProvider',
      'privacyRequestRepositoryProvider',
      'crewRepositoryProvider',
      'adminRepositoryProvider',
      'fairnessRepositoryProvider',
      'allowMockFallback: !config.isProduction',
    ]) {
      expect(providers, contains(providerToken));
    }
    expect(repositories, contains(': const <SponsorChallenge>[]'));
    expect(repositories, contains(': const <Coupon>[]'));
    expect(repositories, contains("eq('key', 'fairness_guidelines')"));
    expect(repositories, contains('allowMockFallback'));
    expect(repositories, contains('_fallback.getGuidelines()'));
    expect(
      repositories,
      contains(': const <String>[]'),
    );
    expect(fairnessSettings, contains("'fairness_guidelines'"));
    expect(fairnessSettings, contains('공정성 센터 공개 가이드 문구'));
    expect(repositories, contains("throw StateError('로그인이 필요합니다.')"));
    expect(repositories, contains("throw StateError('관리자 권한이 필요합니다.')"));
  });

  test('Production core experience repositories never show mock home data', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    for (final token in [
      'class SupabaseHomeRepository',
      'class SupabaseSeasonRepository',
      'class SupabaseDriveRepository',
      '_emptyBattle()',
      '_emptySeason(',
      '_emptySeasonMission()',
      '_emptyDriveScore(userId)',
      "throw StateError('프로필을 찾을 수 없습니다.')",
      "throw StateError('대표 차량을 먼저 설정해주세요.')",
    ]) {
      expect(repositories, contains(token));
    }

    expect(
      providers,
      contains(
          'SupabaseHomeRepository(allowMockFallback: !config.isProduction)'),
    );
    expect(
      providers,
      contains(
          'SupabaseSeasonRepository(allowMockFallback: !config.isProduction)'),
    );
    expect(
      providers,
      contains(
          'SupabaseDriveRepository(allowMockFallback: !config.isProduction)'),
    );
  });

  test('Production auth and consent repositories never fall back to mock', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    for (final token in [
      'class UnavailableAuthRepository',
      'class UnavailableConsentRepository',
      'class SupabaseConsentRepository',
      "return StateError('인증 설정을 완료해야 합니다.')",
      "return StateError('동의 저장소 설정을 완료해야 합니다.')",
      "throw StateError('로그인이 필요합니다.')",
      'final bool allowMockFallback;',
      'class AuthRedirectInProgressException implements Exception',
      'signInWithIdToken(',
      'signInWithOAuth(',
      'Uri.base.origin',
      '_client.auth.signOut()',
      '_accountDeletionRequiresPrivacyRequest',
      "StateError('계정 삭제는 개인정보 설정에서 요청해야 합니다.')",
    ]) {
      expect(repositories, contains(token));
    }
    expect(
      repositories,
      isNot(contains(
          'Future<void> deleteAccount() async {\n    await signOut();')),
    );

    for (final token in [
      'if (config.canUseMockRepositories)',
      'return MockAuthRepository();',
      'return const UnavailableAuthRepository();',
      'SupabaseConsentRepository(allowMockFallback: config.isDev)',
      'return config.canUseMockRepositories',
      ': const UnavailableConsentRepository()',
    ]) {
      expect(providers, contains(token));
    }
  });

  test('Supabase Google web auth bypasses Google SDK initialization', () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');

    expect(repositories,
        contains('Future<UserProfile> _startSupabaseOAuthRedirect()'));
    expect(
      repositories,
      contains(
        'if (kIsWeb) {\n'
        '      return _startSupabaseOAuthRedirect();\n'
        '    }\n\n'
        '    await _initializeGoogleSignIn();',
      ),
    );
    expect(
      repositories,
      contains(
        'if (!kIsWeb) {\n'
        '        await _initializeGoogleSignIn();\n'
        '        await _googleSignIn.signOut();\n'
        '      }',
      ),
    );
  });

  test('Supabase bootstrap keeps PKCE deep link session recovery explicit', () {
    final bootstrap = File('lib/app/bootstrap.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    expect(
      bootstrap,
      contains('authOptions: const FlutterAuthClientOptions('),
    );
    expect(bootstrap, contains('authFlowType: AuthFlowType.pkce'));
    expect(bootstrap, contains('detectSessionInUri: true'));
  });

  test('Production vehicle catalog repository never falls back to mock asset',
      () {
    final repositories =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');

    for (final token in [
      'class SupabaseVehicleCatalogRepository',
      'final bool allowMockFallback;',
      'if (!allowMockFallback) {\n        rethrow;',
      "throw StateError('로그인이 필요합니다.')",
      'class SupabaseLeagueRepository',
      'allowMockFallback: allowMockFallback',
    ]) {
      expect(repositories, contains(token));
    }

    for (final token in [
      'SupabaseVehicleCatalogRepository(',
      'allowMockFallback: !config.isProduction',
      'SupabaseLeagueRepository(allowMockFallback: !config.isProduction)',
    ]) {
      expect(providers, contains(token));
    }
  });

  test('AppRemoteConfig parses public app settings safely', () {
    final config = AppRemoteConfig.fromSettingsMap({
      'reward_ad_daily_limit': {'value': 5},
      'reward_ads_enabled': {'value': false},
      'new_user_ad_protection_days': {'value': '7'},
      'season_ending_soon_days': {'value': 5},
      'official_drive_min_distance_km': {'value': '2.5'},
      'official_drive_min_duration_seconds': {'value': 240},
      'abnormal_speed_kmh': {'value': 160},
      'allow_custom_vehicle_official_ranking': {'value': true},
      'split_plug_in_hybrid_league': {'value': false},
      'friendly_battle_enabled': {'value': true},
      'premium_price_label': {'text': '연 49,000원'},
      'coupons_enabled': {'value': false},
    });

    expect(config.rewardAdDailyLimit, 5);
    expect(config.rewardAdsEnabled, isFalse);
    expect(config.newUserAdProtectionDays, 7);
    expect(config.officialDriveMinDistanceKm, 2.5);
    expect(config.officialDriveMinDurationSeconds, 240);
    expect(config.abnormalSpeedKmh, 160);
    expect(config.allowCustomVehicleOfficialRanking, isTrue);
    expect(config.splitPlugInHybridLeague, isFalse);
    expect(config.premiumPriceLabel, '연 49,000원');
    expect(config.couponsEnabled, isFalse);
  });

  test('AppRemoteConfig falls back for out-of-range settings', () {
    final config = AppRemoteConfig.fromSettingsMap({
      'reward_ad_daily_limit': {'value': 99},
      'new_user_ad_protection_days': {'value': -1},
      'season_ending_soon_days': {'value': 0},
      'official_drive_min_distance_km': {'value': 0},
      'official_drive_min_duration_seconds': {'value': 20},
      'abnormal_speed_kmh': {'value': 400},
      'premium_price_label': {'text': ''},
    });

    expect(config.rewardAdDailyLimit, 3);
    expect(config.newUserAdProtectionDays, 3);
    expect(config.seasonEndingSoonDays, 3);
    expect(config.officialDriveMinDistanceKm, 1.0);
    expect(config.officialDriveMinDurationSeconds, 180);
    expect(config.abnormalSpeedKmh, 180);
    expect(config.premiumPriceLabel, '월 4,900원');
  });

  test('Production remote config never falls back to default settings', () {
    final services = File('lib/shared/services/app_services.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final rewardAdScreen =
        File('lib/features/ads/presentation/reward_ad_screen.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final rewardWalletScreen =
        File('lib/features/rewards/presentation/reward_wallet_screen.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');

    expect(services, contains('allowDefaultFallback'));
    expect(services, contains('if (rows.isEmpty && !allowDefaultFallback)'));
    expect(services, contains('if (!allowDefaultFallback)'));
    expect(services, contains('rethrow'));
    expect(
      providers,
      contains('allowDefaultFallback: !config.isProduction'),
    );
    expect(rewardAdScreen, contains('remoteConfig.when'));
    expect(rewardAdScreen, contains('리워드 광고 운영 설정을 불러오지 못했어요.'));
    expect(rewardAdScreen, contains('ref.invalidate(appRemoteConfigProvider)'));
    expect(rewardAdScreen, isNot(contains('asData?.value')));
    expect(rewardWalletScreen, contains('remoteConfig.when'));
    expect(rewardWalletScreen, contains('쿠폰 운영 설정을 불러오지 못했어요.'));
    expect(
      rewardWalletScreen,
      contains('ref.invalidate(appRemoteConfigProvider)'),
    );
    expect(rewardWalletScreen, isNot(contains('orElse: () => true')));
  });

  test('MockConsentRepository stores current consent and audit logs', () async {
    final repository = MockConsentRepository();

    final consent = await repository.saveConsent(
      termsAccepted: true,
      privacyAccepted: true,
      locationAccepted: true,
      personalizedAdsAccepted: true,
      marketingAccepted: false,
    );
    final current = await repository.getConsent();

    expect(consent.termsAccepted, isTrue);
    expect(current.personalizedAdsAccepted, isTrue);
    expect(current.marketingAccepted, isFalse);
    expect(repository.debugConsentLogs.single.userId, mockProfile.id);
  });

  test('LocalStateService stores latest drive result summary by session',
      () async {
    SharedPreferences.setMockInitialValues({});
    final service = LocalStateService();

    await service.saveLatestDriveResultSummary(
      sessionId: 'drive-session-001',
      duration: const Duration(minutes: 7, seconds: 12),
      distanceKm: 4.36,
      averageEfficiency: 16.8,
      fuelUsedLiters: 0.26,
    );

    final summary =
        await service.getLatestDriveResultSummary('drive-session-001');
    expect(summary, isNotNull);
    expect(summary!.duration.inSeconds, 432);
    expect(summary.distanceKm, 4.36);
    expect(summary.averageEfficiency, 16.8);
    expect(await service.getLatestDriveResultSummary('other-session'), isNull);

    await service.clearLatestDriveResultSummary('drive-session-001');
    expect(
        await service.getLatestDriveResultSummary('drive-session-001'), isNull);
  });

  test('AppSessionService signOut clears user scoped local hints', () async {
    SharedPreferences.setMockInitialValues({});
    final authRepository = MockAuthRepository();
    final localState = LocalStateService();
    final secureStorage = _MemorySecureStorageService();
    final service = AppSessionService(
      authRepository: authRepository,
      localState: localState,
      secureStorage: secureStorage,
    );

    await localState.saveActiveDriveSession('drive-session-001');
    await localState.markConsentCompleted();
    await localState.markVehicleSetupCompleted();
    await localState.saveRecentRankingFilter('전기차 리그');
    await localState.saveRecentPrimaryVehicle('vehicle-001');
    await localState.saveLatestDriveResultSummary(
      sessionId: 'drive-session-001',
      duration: const Duration(minutes: 4),
      distanceKm: 2.1,
      averageEfficiency: 15.4,
    );
    final offlineQueue = OfflineQueueService(localState: localState);
    await offlineQueue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-sign-out-001',
        driveSessionId: 'drive-session-001',
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);
    await offlineQueue.rememberDriveSessionMapping(
      'local-drive-sign-out',
      'server-drive-sign-out',
    );
    await localState.setString(
      'offline_queue_corrupt_backup',
      jsonEncode({
        'raw': 'raw drive_points payload with latitude and longitude',
      }),
    );
    await secureStorage.writeSessionHint(mockProfile.id);

    await service.signOut();

    expect(await authRepository.currentUser(), isNull);
    expect(await localState.getBool('consent_completed'), isFalse);
    expect(await localState.getBool('vehicle_setup_completed'), isFalse);
    expect(await localState.getString('active_drive_session_id'), isEmpty);
    expect(await localState.getString('recent_ranking_filter'), isEmpty);
    expect(await localState.getString('recent_primary_vehicle_id'), isEmpty);
    expect(
      await localState.getLatestDriveResultSummary('drive-session-001'),
      isNull,
    );
    expect(await offlineQueue.pendingItems(), isEmpty);
    expect(await offlineQueue.resolveDriveSessionId('local-drive-sign-out'),
        'local-drive-sign-out');
    expect(await offlineQueue.corruptQueueBackup(), isEmpty);
    expect(await secureStorage.readSessionHint(), isNull);
  });

  test('AppSessionService signOut clears local hints even when auth fails',
      () async {
    SharedPreferences.setMockInitialValues({});
    final authRepository = _FailingSignOutAuthRepository();
    final localState = LocalStateService();
    final secureStorage = _MemorySecureStorageService();
    final service = AppSessionService(
      authRepository: authRepository,
      localState: localState,
      secureStorage: secureStorage,
    );

    await localState.saveActiveDriveSession('drive-session-remote-fail');
    await localState.markConsentCompleted();
    await localState.markVehicleSetupCompleted();
    await localState.saveRecentRankingFilter('가솔린 리그');
    await localState.saveRecentPrimaryVehicle('vehicle-remote-fail');
    await localState.saveLatestDriveResultSummary(
      sessionId: 'drive-session-remote-fail',
      duration: const Duration(minutes: 5),
      distanceKm: 3.2,
      averageEfficiency: 14.8,
    );
    final offlineQueue = OfflineQueueService(localState: localState);
    await offlineQueue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-sign-out-remote-fail',
        driveSessionId: 'drive-session-remote-fail',
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);
    await offlineQueue.rememberDriveSessionMapping(
      'local-drive-remote-fail',
      'server-drive-remote-fail',
    );
    await localState.setString(
      'offline_queue_corrupt_backup',
      jsonEncode({'raw': 'stale private payload'}),
    );
    await secureStorage.writeSessionHint(mockProfile.id);

    await expectLater(service.signOut(), throwsStateError);

    expect(await localState.getBool('consent_completed'), isFalse);
    expect(await localState.getBool('vehicle_setup_completed'), isFalse);
    expect(await localState.getString('active_drive_session_id'), isEmpty);
    expect(await localState.getString('recent_ranking_filter'), isEmpty);
    expect(await localState.getString('recent_primary_vehicle_id'), isEmpty);
    expect(
      await localState.getLatestDriveResultSummary(
        'drive-session-remote-fail',
      ),
      isNull,
    );
    expect(await offlineQueue.pendingItems(), isEmpty);
    expect(await offlineQueue.resolveDriveSessionId('local-drive-remote-fail'),
        'local-drive-remote-fail');
    expect(await offlineQueue.corruptQueueBackup(), isEmpty);
    expect(await secureStorage.readSessionHint(), isNull);
  });

  test('Logout screens invalidate shared user scoped provider caches', () {
    final providers = File('lib/shared/providers/repository_providers.dart')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final profileScreen =
        File('lib/features/profile/presentation/profile_screen.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');
    final settingsScreen =
        File('lib/features/settings/presentation/settings_screen.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');

    for (final token in [
      'void invalidateUserScopedSessionProviders(WidgetRef ref)',
      'restoredSessionProvider',
      'appConsentProvider',
      'homeSnapshotProvider',
      'primaryVehicleProvider',
      'vehiclesProvider',
      'profileProvider',
      'badgesProvider',
      'achievementsProvider',
      'couponsProvider',
      'notificationsProvider',
      'supportTicketsProvider',
      'privacyRequestsProvider',
      'myCrewProvider',
      'crewMembersProvider',
    ]) {
      expect(providers, contains(token));
    }
    expect(
        profileScreen, contains('invalidateUserScopedSessionProviders(ref)'));
    expect(
        settingsScreen, contains('invalidateUserScopedSessionProviders(ref)'));
    expect(settingsScreen,
        isNot(contains('ref.invalidate(restoredSessionProvider)')));
  });

  test('AppSessionService restore records recovered auth session hint',
      () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_completed': true,
    });
    final authRepository = MockAuthRepository();
    final localState = LocalStateService();
    final secureStorage = _MemorySecureStorageService();
    final service = AppSessionService(
      authRepository: authRepository,
      localState: localState,
      secureStorage: secureStorage,
    );

    final session = await service.restore();

    expect(session.user?.id, mockProfile.id);
    expect(session.onboardingCompleted, isTrue);
    expect(session.consentCompleted, isTrue);
    expect(await secureStorage.readSessionHint(), mockProfile.id);
  });

  test('AppSessionService restore hydrates completed profile flags', () async {
    SharedPreferences.setMockInitialValues({});
    final authRepository = MockAuthRepository()
      ..debugSetProfile(
        mockProfile.copyWith(
          onboardingCompleted: true,
          consentCompleted: true,
          vehicleSetupCompleted: true,
        ),
      );
    final localState = LocalStateService();
    final secureStorage = _MemorySecureStorageService();
    final service = AppSessionService(
      authRepository: authRepository,
      localState: localState,
      secureStorage: secureStorage,
    );

    final session = await service.restore();

    expect(session.onboardingCompleted, isTrue);
    expect(session.consentCompleted, isTrue);
    expect(session.vehicleSetupCompleted, isTrue);
    expect(await localState.getBool('onboarding_completed'), isTrue);
    expect(await localState.getBool('consent_completed'), isTrue);
    expect(await localState.getBool('vehicle_setup_completed'), isTrue);
  });

  test('AppSessionService restore continues when session hint write fails',
      () async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'consent_completed': true,
    });
    final service = AppSessionService(
      authRepository: MockAuthRepository(),
      localState: LocalStateService(),
      secureStorage: _FailingSecureStorageService(),
    );

    final session = await service.restore();

    expect(session.user?.id, mockProfile.id);
    expect(session.consentCompleted, isTrue);
  });

  test('AppSessionService rememberLogin ignores session hint write failure',
      () async {
    final service = AppSessionService(
      authRepository: MockAuthRepository(),
      localState: LocalStateService(),
      secureStorage: _FailingSecureStorageService(),
    );

    await expectLater(service.rememberLogin(mockProfile), completes);
  });

  test('DrivePoint private JSON keeps mock location flag private', () {
    final point = DrivePoint(
      id: 'point-001',
      driveSessionId: 'drive-001',
      latitude: 37.5,
      longitude: 127.0,
      speedKmh: 42,
      accuracy: 8,
      recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      isMocked: true,
    );

    final json = point.toPrivateJson();
    expect(json['is_mocked'], isTrue);
    expect(json['drive_session_id'], 'drive-001');
    expect(json['latitude'], 37.5);
    expect(DrivePoint.fromPrivateJson(json).isMocked, isTrue);
  });

  test('SyncService uploads queued drive point batches when online', () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _RecordingDriveRepository();
    await queue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-001',
        driveSessionId: 'drive-001',
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: true, label: '온라인'),
    );

    final uploaded = await sync.uploadPending();
    expect(uploaded, 1);
    expect(repository.recordedPoints.single.driveSessionId, 'drive-001');
    expect(await queue.pendingItems(), isEmpty);
  });

  test('SyncService uploads local drive session before remapped points',
      () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _RecordingDriveRepository();
    final localSession = DriveSession(
      id: 'local-drive-001',
      vehicleId: mockVehicle.id,
      startedAt: DateTime.utc(2026, 6, 6),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      sourceType: 'local',
      status: 'recording',
    );
    await queue.enqueueDriveSession(localSession);
    await queue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-001',
        driveSessionId: localSession.id,
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: true, label: '온라인'),
    );

    final uploaded = await sync.uploadPending();
    expect(uploaded, 2);
    expect(repository.uploadedSessions.single.id, 'server-local-drive-001');
    expect(
      repository.recordedPoints.single.driveSessionId,
      'server-local-drive-001',
    );
    expect(await queue.pendingItems(), isEmpty);
  });

  test('SyncService persists local drive session mapping after point failure',
      () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _FlakyDriveRepository();
    final localSession = DriveSession(
      id: 'local-drive-002',
      vehicleId: mockVehicle.id,
      startedAt: DateTime.utc(2026, 6, 6),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      sourceType: 'local',
      status: 'recording',
    );
    await queue.enqueueDriveSession(localSession);
    await queue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-002',
        driveSessionId: localSession.id,
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: true, label: '온라인'),
    );

    expect(await sync.uploadPending(), 1);
    expect(await queue.resolveDriveSessionId(localSession.id),
        'server-local-drive-002');
    expect(await queue.pendingItems(), hasLength(1));
    expect(repository.recordedPoints, isEmpty);

    expect(await sync.uploadPending(), 1);
    expect(
      repository.recordedPoints.single.driveSessionId,
      'server-local-drive-002',
    );
    expect(await queue.pendingItems(), isEmpty);
  });

  test('SyncService records local sync success and failure logs', () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _FlakyDriveRepository();
    final syncLogs = _RecordingLocalSyncLogRepository();
    final localSession = DriveSession(
      id: 'local-drive-log-001',
      vehicleId: mockVehicle.id,
      startedAt: DateTime.utc(2026, 6, 6),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      sourceType: 'local',
      status: 'recording',
    );
    await queue.enqueueDriveSession(localSession);
    await queue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-log-001',
        driveSessionId: localSession.id,
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      syncLogRepository: syncLogs,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: true, label: '온라인'),
    );

    expect(await sync.uploadPending(), 1);
    expect(syncLogs.entries, hasLength(2));
    expect(syncLogs.entries[0].itemType, 'drive_session');
    expect(syncLogs.entries[0].status, 'uploaded');
    expect(syncLogs.entries[1].itemType, 'drive_points');
    expect(syncLogs.entries[1].status, 'failed');
    expect(syncLogs.entries[1].errorMessage, contains('temporary point'));
    expect(syncLogs.entries[1].errorMessage, isNot(contains('latitude')));
    expect(syncLogs.entries[1].errorMessage, isNot(contains('longitude')));
  });

  test('SyncService discards malformed and unsupported queued items with logs',
      () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _RecordingDriveRepository();
    final syncLogs = _RecordingLocalSyncLogRepository();

    await queue.enqueue(
      OfflineQueueItem(
        id: 'bad-drive-points',
        type: 'drive_points',
        payload: {
          'points': 'broken-payload',
          'latitude': 37.5,
          'longitude': 127.0,
        },
        createdAt: DateTime.utc(2026, 6, 6, 2),
      ),
    );
    await queue.enqueue(
      OfflineQueueItem(
        id: 'unknown-sync-item',
        type: 'legacy_debug_item',
        payload: {'drive_points': 'raw-private-data'},
        createdAt: DateTime.utc(2026, 6, 6, 2, 1),
      ),
    );

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      syncLogRepository: syncLogs,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: true, label: '온라인'),
    );

    expect(await sync.uploadPending(), 0);
    expect(await queue.pendingItems(), isEmpty);
    expect(repository.recordedPoints, isEmpty);
    expect(syncLogs.entries, hasLength(2));
    expect(syncLogs.entries.map((entry) => entry.status),
        everyElement('discarded'));
    expect(syncLogs.entries[0].itemType, 'drive_points');
    expect(syncLogs.entries[0].errorMessage, contains('손상된 주행 포인트'));
    expect(syncLogs.entries[1].itemType, 'legacy_debug_item');
    expect(syncLogs.entries[1].errorMessage, contains('지원하지 않는 동기화 항목'));
    for (final entry in syncLogs.entries) {
      expect(entry.errorMessage, isNot(contains('latitude')));
      expect(entry.errorMessage, isNot(contains('longitude')));
      expect(entry.errorMessage, isNot(contains('drive_points')));
    }
  });

  test('OfflineQueueService caps pending items and keeps newest entries',
      () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());

    for (var i = 0; i < 205; i += 1) {
      await queue.enqueue(
        OfflineQueueItem(
          id: 'item-${i.toString().padLeft(3, '0')}',
          type: 'drive_session',
          payload: {'index': i},
          createdAt: DateTime.utc(2026, 6, 6, 0, i),
        ),
      );
    }

    final items = await queue.pendingItems();
    expect(items, hasLength(200));
    expect(items.first.id, 'item-005');
    expect(items.last.id, 'item-204');
  });

  test('OfflineQueueService quarantines corrupted queue storage', () async {
    SharedPreferences.setMockInitialValues({
      'offline_queue': 'not-json',
    });
    final localState = LocalStateService();
    final queue = OfflineQueueService(localState: localState);

    expect(await queue.pendingItems(), isEmpty);
    expect(await localState.getString('offline_queue'), '[]');

    final backup = jsonDecode(await queue.corruptQueueBackup()) as Map;
    expect(backup['reason'], 'decode_error');
    expect(backup['raw'], 'not-json');

    await queue.enqueue(
      OfflineQueueItem(
        id: 'recovered-item',
        type: 'drive_session',
        payload: {'id': 'local-drive-recovered'},
        createdAt: DateTime.utc(2026, 6, 6, 3),
      ),
    );
    expect((await queue.pendingItems()).single.id, 'recovered-item');
  });

  test('OfflineQueueService preserves valid items from partially bad queue',
      () async {
    final validItem = OfflineQueueItem(
      id: 'valid-queued-session',
      type: 'drive_session',
      payload: {'id': 'local-drive-valid'},
      createdAt: DateTime.utc(2026, 6, 6, 4),
    );
    SharedPreferences.setMockInitialValues({
      'offline_queue': jsonEncode([
        validItem.toJson(),
        'broken-row',
        {'id': '', 'type': 'drive_points', 'payload': {}},
      ]),
    });
    final localState = LocalStateService();
    final queue = OfflineQueueService(localState: localState);

    final items = await queue.pendingItems();
    expect(items.map((item) => item.id), ['valid-queued-session']);

    final stored = jsonDecode(await localState.getString('offline_queue'));
    expect(stored, isA<List>());
    expect(stored, hasLength(1));
    expect((stored as List).single['id'], 'valid-queued-session');

    final backup = jsonDecode(await queue.corruptQueueBackup()) as Map;
    expect(backup['reason'], 'invalid_items');
    expect('${backup['raw']}', contains('broken-row'));
  });

  test('SyncService keeps queued drive points while offline', () async {
    SharedPreferences.setMockInitialValues({});
    final queue = OfflineQueueService(localState: LocalStateService());
    final repository = _RecordingDriveRepository();
    await queue.enqueueDrivePoints([
      DrivePoint(
        id: 'point-001',
        driveSessionId: 'drive-001',
        latitude: 37.5,
        longitude: 127.0,
        speedKmh: 24,
        accuracy: 7,
        recordedAt: DateTime.utc(2026, 6, 6, 1, 2, 3),
      ),
    ]);

    final sync = SyncService(
      networkStatus: NetworkStatusService(),
      offlineQueue: queue,
      driveRepository: repository,
      networkSnapshotLoader: () async =>
          const NetworkSnapshot(isOnline: false, label: '오프라인'),
    );

    expect(await sync.uploadPending(), 0);
    expect(repository.recordedPoints, isEmpty);
    expect(await queue.pendingItems(), hasLength(1));
  });

  test('MockSupportRepository creates and lists support tickets', () async {
    final repository = MockSupportRepository();

    final ticket = await repository.createSupportTicket(
      category: '주행 기록 문제',
      title: '점수 검토 요청',
      description: '주행 결과가 평소보다 낮게 표시돼서 검토가 필요합니다.',
    );
    final tickets = await repository.listMyTickets();

    expect(ticket.status, 'open');
    expect(tickets.first.title, '점수 검토 요청');
  });

  test('MockSupportRepository stores user and admin ticket messages', () async {
    final repository = MockSupportRepository();

    final ticket = await repository.createSupportTicket(
      category: '점수/랭킹 문제',
      title: '랭킹 반영 문의',
      description: '검증 완료 주행이 랭킹에 반영되지 않아 확인이 필요합니다.',
    );
    await repository.addMessage(
      ticket.id,
      '추가로 같은 현상이 어제 주행에서도 발생했습니다.',
    );
    await repository.addMessage(
      ticket.id,
      '운영자가 기록 상태를 확인했고 재집계를 진행했습니다.',
      isAdminReply: true,
    );
    final messages = await repository.listMessages(ticket.id);
    final detail = await repository.getTicketDetail(ticket.id);

    expect(messages, hasLength(2));
    expect(messages.where((item) => item.isAdminReply), hasLength(1));
    expect(messages.where((item) => !item.isAdminReply), hasLength(1));
    expect(detail?.status, 'review');
  });

  test('MockPrivacyRequestRepository creates and updates requests', () async {
    final repository = MockPrivacyRequestRepository();

    final request = await repository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'data_download',
        description: '내 계정 데이터 다운로드를 요청합니다.',
      ),
    );
    final updated =
        await repository.updateRequestStatus(request.id, 'completed');
    final requests = await repository.listMyRequests();

    expect(request.requestType, 'data_download');
    expect(updated?.status, 'completed');
    expect(requests.single.id, request.id);

    final withdrawal = await repository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'consent_withdrawal',
        description: '마케팅과 광고 동의 철회를 요청합니다.',
      ),
    );

    expect(withdrawal.requestType, 'consent_withdrawal');
    expect(repository.debugRequests, hasLength(2));
  });

  test(
      'MockPrivacyRequestRepository prevents duplicate active privacy requests',
      () async {
    final repository = MockPrivacyRequestRepository();

    final first = await repository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'account_deletion',
        description: 'Fuel Arena 계정 삭제와 탈퇴 처리를 요청합니다.',
      ),
    );

    await expectLater(
      repository.createRequest(
        const PrivacyRequestSubmission(
          requestType: 'account_deletion',
          description: '같은 유형의 요청을 다시 접수합니다.',
        ),
      ),
      throwsA(
        isA<ActivePrivacyRequestException>().having(
          (error) => error.request.id,
          'active request id',
          first.id,
        ),
      ),
    );
    expect(repository.debugRequests, hasLength(1));

    await repository.updateRequestStatus(first.id, 'completed');
    final second = await repository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'account_deletion',
        description: '처리 완료 후 다시 계정 삭제 요청을 접수합니다.',
      ),
    );

    expect(second.id, isNot(first.id));
    expect(repository.debugRequests, hasLength(2));
  });

  test('Vehicle catalog asset meets production seed minimums', () {
    final file = File('assets/data/vehicle_catalog_kr_seed.json');
    final data = jsonDecode(
            file.readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n'))
        as Map<String, dynamic>;
    final manufacturers = data['manufacturers'] as List;
    final models = data['models'] as List;
    final years = data['years'] as List;
    final variants = data['variants'] as List;
    final verifiedVariants =
        variants.where((item) => item['is_verified'] == true).toList();

    expect(manufacturers.length, greaterThanOrEqualTo(20));
    expect(models.length, greaterThanOrEqualTo(120));
    expect(years.length, greaterThanOrEqualTo(1500));
    expect(variants.length, greaterThanOrEqualTo(3000));
    expect(verifiedVariants.length, greaterThanOrEqualTo(2000));
    expect(
      manufacturers.map((item) => item['name_ko']),
      containsAll(['현대', '기아', '테슬라', 'BMW', '폴스타']),
    );
    expect(
      variants
          .where((item) => item['fuel_league'] == 'electric')
          .every((item) => item['efficiency_unit'] == 'km/kWh'),
      isTrue,
    );
    expect(
      variants
          .where((item) => item['fuel_league'] != 'electric')
          .every((item) => item['efficiency_unit'] == 'km/L'),
      isTrue,
    );
    expect(
      variants
          .where((item) =>
              '${item['trim_name']}'.contains('스탠다드') ||
              '${item['trim_name']}'.contains('프리미엄') ||
              '${item['trim_name']}'.contains('스마트') ||
              '${item['trim_name']}'.contains('모던') ||
              '${item['trim_name']}'.contains('인스퍼레이션') ||
              '${item['trim_name']}'.contains('프레스티지') ||
              '${item['trim_name']}'.contains('시그니처') ||
              '${item['trim_name']}'.contains('N Line') ||
              '${item['trim_name']}'.contains('N라인'))
          .toList(),
      isNotEmpty,
    );
    expect(
      verifiedVariants.every((item) =>
          (item['displacement_cc'] is num || item['battery_kwh'] is num) &&
          '${item['transmission']}'.isNotEmpty),
      isTrue,
    );
  });

  test('Admin dashboard metrics migration exposes admin-only RPC', () {
    final sql = File(
      'supabase/migrations/202606060014_admin_dashboard_metrics.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql, contains('get_admin_dashboard_metrics'));
    expect(sql, contains('public.is_admin_user()'));
    expect(
        sql,
        contains(
            'grant execute on function public.get_admin_dashboard_metrics() to authenticated'));
  });

  test('Report operations migration keeps admin review policies', () {
    final sql = File(
      'supabase/migrations/202606060015_report_operations.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql, contains('reports_admin_select'));
    expect(sql, contains('reports_admin_update'));
    expect(sql, contains('public.is_admin_user()'));
  });

  test('Support ticket operations migration tracks replies and status', () {
    final sql = File(
      'supabase/migrations/202606060016_support_ticket_operations.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql, contains('is_admin_reply'));
    expect(sql, contains('support_tickets_status_check'));
    expect(sql, contains('support_tickets_status_updated_at_idx'));
    expect(sql, contains('support_ticket_messages_admin_reply_idx'));
  });

  test('Privacy request operations migration protects user requests', () {
    final sql = File(
      'supabase/migrations/202606060017_privacy_request_operations.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql, contains('privacy_requests'));
    expect(sql, contains('privacy_requests_self_select_or_admin'));
    expect(sql, contains('privacy_requests_self_insert'));
    expect(sql, contains('privacy_requests_admin_update'));
    expect(sql, contains('privacy_requests_active_type_uidx'));
    expect(sql, contains('account_deletion'));
  });

  test('Consent audit migration indexes current operations', () {
    final sql = File(
      'supabase/migrations/202606060018_consent_audit_indexes.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql, contains('consent_logs_user_id_created_at_idx'));
    expect(sql, contains('consent_logs_created_at_idx'));
  });

  test('Reward and subscription RLS migration protects release tables', () {
    final sql = File(
      'supabase/migrations/202606060019_reward_subscription_rls.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(sql,
        contains('alter table public.ad_rewards enable row level security'));
    expect(
        sql,
        contains(
            'alter table public.subscription_plans enable row level security'));
    expect(sql, contains('ad_rewards_self_select'));
    expect(sql, contains('ad_rewards_admin_select'));
    expect(sql, contains('subscription_plans_public_read'));
    expect(sql, contains('subscription_plans_admin_write'));
  });

  test('Profile self-write hardening blocks score and admin escalation', () {
    final sql = File(
      'supabase/migrations/202606060023_profile_self_write_hardening.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n').toLowerCase();

    expect(sql, contains('revoke insert on public.profiles'));
    expect(sql, contains('revoke update on public.profiles'));
    expect(sql, contains('coalesce(is_admin, false) = false'));
    expect(sql, contains('coalesce(is_premium, false) = false'));
    expect(sql, contains('coalesce(season_score, 0) = 0'));

    final insertColumns = _profileGrantColumns(sql, 'insert');
    final updateColumns = _profileGrantColumns(sql, 'update');
    for (final sensitiveColumn in [
      'tier',
      'total_score',
      'season_score',
      'current_streak',
      'best_streak',
      'is_premium',
      'is_admin',
      'created_at',
    ]) {
      expect(insertColumns, isNot(contains(sensitiveColumn)));
      expect(updateColumns, isNot(contains(sensitiveColumn)));
    }
  });

  test('Google profile repair preserves user-owned public profile fields', () {
    final repository =
        File('lib/shared/repositories/fuel_arena_repositories.dart')
            .readAsStringSync(encoding: utf8)
            .replaceAll('\r\n', '\n');

    expect(
      repository,
      contains(
          'final preservedNickname = existingProfile.nickname.trim().isEmpty'),
    );
    expect(repository, contains('? nickname'));
    expect(repository, contains(': existingProfile.nickname'));
    expect(repository, contains('final preservedEmail ='));
    expect(repository, contains('? existingProfile.email'));
    expect(repository, contains(': email.trim()'));
    expect(
      repository,
      contains(
          'final preservedAvatarUrl = existingProfile.avatarUrl.trim().isEmpty'),
    );
    expect(repository, contains('? avatarUrl.trim()'));
    expect(repository, contains(': existingProfile.avatarUrl'));
    expect(repository, contains("'nickname': preservedNickname"));
    expect(repository, contains("'email': preservedEmail"));
    expect(repository,
        contains("updateProfile['avatar_url'] = preservedAvatarUrl"));
  });

  test('Supabase schema validator is wired into CI', () {
    final workflow = File('.github/workflows/flutter_ci.yml')
        .readAsStringSync(encoding: utf8)
        .replaceAll('\r\n', '\n');
    final validator = File('tool/validate_supabase_schema.dart');

    expect(validator.existsSync(), isTrue);
    expect(workflow, contains('dart run tool/validate_supabase_schema.dart'));
  });

  test('Edge-only RPC grants keep service role functions off client roles', () {
    final sql = File(
      'supabase/migrations/202606060020_edge_only_rpc_grants.sql',
    ).readAsStringSync(encoding: utf8).replaceAll('\r\n', '\n');

    expect(
      sql,
      contains(
        'revoke all on function public.recompute_rankings(text) from authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.recompute_rankings(text) to service_role',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.claim_mission_reward(uuid, uuid) from authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.claim_mission_reward(uuid, uuid) to service_role',
      ),
    );
  });
}

Set<String> _profileGrantColumns(String sql, String verb) {
  final match = RegExp(
    'grant\\s+$verb\\s*\\(([\\s\\S]*?)\\)\\s+on\\s+public\\.profiles\\s+to\\s+authenticated',
    caseSensitive: false,
  ).firstMatch(sql);
  final body = match?.group(1);
  if (body == null) {
    return const {};
  }
  return body
      .split(',')
      .map((column) => column.trim().replaceAll(RegExp(r'\s+'), ' '))
      .where((column) => column.isNotEmpty)
      .toSet();
}

class _MemorySecureStorageService extends SecureStorageService {
  String? _sessionHint;

  @override
  Future<void> writeSessionHint(String value) async {
    _sessionHint = value;
  }

  @override
  Future<String?> readSessionHint() async => _sessionHint;

  @override
  Future<void> clearSessionHint() async {
    _sessionHint = null;
  }
}

class _FailingSecureStorageService extends SecureStorageService {
  @override
  Future<void> writeSessionHint(String value) async {
    throw StateError('secure storage unavailable');
  }
}

class _FailingSignOutAuthRepository extends MockAuthRepository {
  @override
  Future<void> signOut() async {
    throw StateError('remote sign out failed');
  }
}

class _SyncLogEntry {
  const _SyncLogEntry({
    required this.itemId,
    required this.itemType,
    required this.status,
    this.errorMessage,
  });

  final String itemId;
  final String itemType;
  final String status;
  final String? errorMessage;
}

class _RecordingLocalSyncLogRepository implements LocalSyncLogRepository {
  final entries = <_SyncLogEntry>[];

  @override
  Future<void> recordQueueItem({
    required OfflineQueueItem item,
    required String status,
    String? errorMessage,
  }) async {
    entries.add(
      _SyncLogEntry(
        itemId: item.id,
        itemType: item.type,
        status: status,
        errorMessage: errorMessage,
      ),
    );
  }
}

class _RecordingDriveRepository implements DriveRepository {
  final recordedPoints = <DrivePoint>[];
  final uploadedSessions = <DriveSession>[];

  @override
  Future<void> recordDrivePoints(List<DrivePoint> points) async {
    recordedPoints.addAll(points);
  }

  @override
  Future<List<DriveSession>> listDriveSessions({int limit = 20}) async {
    return mockDriveSessions.take(limit).toList();
  }

  @override
  Future<List<DriveScore>> listDriveScores({int limit = 20}) async {
    return mockDriveScores.take(limit).toList();
  }

  @override
  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) async {
    return mockDriveScore;
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() async => mockVehicle;

  @override
  Future<SeasonMission> getTodayMission() async => mockMissions.first;

  @override
  Future<DriveSession> startDriveSession() async {
    return DriveSession(
      id: 'drive-001',
      vehicleId: mockVehicle.id,
      startedAt: DateTime.utc(2026, 6, 6),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      status: 'recording',
    );
  }

  @override
  Future<DriveSession> uploadQueuedDriveSession(DriveSession session) async {
    final uploaded = DriveSession(
      id: 'server-${session.id}',
      userId: mockProfile.id,
      vehicleId: session.vehicleId,
      startedAt: session.startedAt,
      endedAt: session.endedAt,
      duration: session.duration,
      distanceKm: session.distanceKm,
      fuelUsedLiters: session.fuelUsedLiters,
      averageFuelEfficiency: session.averageFuelEfficiency,
      sourceType: 'geolocator',
      driveContext: session.driveContext,
      status: session.status,
      createdAt: DateTime.utc(2026, 6, 6, 1),
    );
    uploadedSessions.add(uploaded);
    return uploaded;
  }
}

class _FlakyDriveRepository extends _RecordingDriveRepository {
  var failNextPointUpload = true;

  @override
  Future<void> recordDrivePoints(List<DrivePoint> points) async {
    if (failNextPointUpload) {
      failNextPointUpload = false;
      throw StateError('temporary point upload failure');
    }
    await super.recordDrivePoints(points);
  }
}
