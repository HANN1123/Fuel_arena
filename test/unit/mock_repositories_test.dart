import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_arena/app/app_config.dart';
import 'package:fuel_arena/shared/models/fuel_arena_models.dart';
import 'package:fuel_arena/shared/providers/repository_providers.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';
import 'package:fuel_arena/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    resetMockFuelArenaState();
  });

  test('MockAuthRepository supports Google sign in', () async {
    final repository = MockAuthRepository();
    final user = await repository.signInWithGoogle();
    expect(user.id, mockProfile.id);
    expect(user.authProvider, 'google');
    expect(user.lastLoginAt, isNotNull);
    expect(repository.isGoogleAuthConfigured(), isTrue);
  });

  test('MockAuthRepository emits auth state changes', () async {
    final repository = MockAuthRepository();
    final states = repository.authStateChanges().take(2).toList();

    await repository.signOut();

    expect(await states, [isNotNull, isNull]);
  });

  test('AuthRepository deleteAccountRequest creates privacy queue item',
      () async {
    final repository = MockAuthRepository();

    await repository.deleteAccountRequest();

    final requests = MockPrivacyRequestRepository().debugRequests;
    expect(requests, hasLength(1));
    expect(requests.single.requestType, 'account_deletion');
  });

  test('AuthRepository deleteAccount requires privacy request queue', () async {
    final repository = MockAuthRepository();

    await expectLater(
      repository.deleteAccount(),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          '계정 삭제는 개인정보 설정에서 요청해야 합니다.',
        ),
      ),
    );

    expect(await repository.currentUser(), isNotNull);
  });

  test('MockVehicleRepository saves and lists vehicles', () async {
    final repository = MockVehicleRepository();
    final vehicle = await repository.saveVehicle(
      manufacturer: 'Hyundai',
      modelName: 'Avante Hybrid',
      modelYear: 2024,
      fuelType: 'Hybrid',
      vehicleClass: '준중형',
      nickname: '테스트 차량',
    );
    expect(vehicle.nickname, '테스트 차량');
    expect(await repository.getPrimaryVehicle(), isNotNull);
    expect(vehicle.leagueKey, 'hybrid');
  });

  test('MockVehicleRepository clears representative vehicle on delete',
      () async {
    final repository = MockVehicleRepository();
    final vehicle = await repository.saveVehicle(
      manufacturer: 'Hyundai',
      modelName: 'Avante',
      modelYear: 2024,
      fuelType: 'Gasoline',
      vehicleClass: '준중형',
      nickname: '삭제 테스트 차량',
    );

    await repository.deleteVehicle(vehicle.id);
    final profile = await MockAuthRepository().currentUser();

    expect(await repository.getPrimaryVehicle(), isNull);
    expect(profile?.representativeVehicleId, isEmpty);
    expect(profile?.representativeVehicleName, isEmpty);
    expect(profile?.selectedFuelLeague, isEmpty);
    expect(profile?.vehicleSetupCompleted, isFalse);
  });

  test('MockVehicleRepository updates profile when primary changes', () async {
    final repository = MockVehicleRepository();
    final target = mockGarage.last;

    await repository.setPrimaryVehicle(target.id);
    final profile = await MockAuthRepository().currentUser();

    expect(await repository.getPrimaryVehicle(), target);
    expect(profile?.representativeVehicleId, target.id);
    expect(profile?.representativeVehicleName, target.displayName);
    expect(profile?.selectedFuelLeague, target.leagueKey);
    expect(profile?.vehicleSetupCompleted, isTrue);
  });

  test('Vehicle catalog follows manufacturer model year variant path',
      () async {
    final repository = const MockVehicleCatalogRepository();

    final manufacturers = await repository.listManufacturers(keyword: '현대');
    final hyundai = manufacturers.firstWhere((item) => item.id == 'm-hyundai');

    expect(hyundai.modelCount, greaterThan(0));
    expect(hyundai.minYear, lessThanOrEqualTo(2015));
    expect(hyundai.maxYear, greaterThanOrEqualTo(2026));

    final models = await repository.listModels(hyundai.id, keyword: '아반떼');
    final avante =
        models.firstWhere((item) => item.id == 'model-hyundai-001-kr');
    final years = await repository.listYears(avante.id);
    final year2026 = years.firstWhere((item) => item.year == 2026);
    final variants = await repository.listVariants(year2026.id);
    final gasoline = variants.firstWhere(
        (item) => item.id == 'variant-hyundai-avante-2026-gasoline');

    expect(gasoline.breadcrumb, '현대 > 아반떼 > 2026년식 > 1.6 가솔린');
    expect(
      gasoline.specSummary,
      '1598cc · Smartstream G1.6 · IVT · 15.0 km/L',
    );
    expect(gasoline.fuelLeague, 'gasoline');
    expect(gasoline.vehicleClass, '준중형');
  });

  test('Vehicle manufacturer catalog filters domestic and imported brands',
      () async {
    final repository = const MockVehicleCatalogRepository();

    final domestic = await repository.listManufacturers(country: 'KR');
    final imported = await repository.listManufacturers(country: 'IMPORT');

    expect(domestic, isNotEmpty);
    expect(imported, isNotEmpty);
    expect(domestic.every((item) => item.country == 'KR'), isTrue);
    expect(imported.every((item) => item.country != 'KR'), isTrue);
    expect(domestic.map((item) => item.nameKo), contains('현대'));
    expect(imported.map((item) => item.nameKo), contains('BMW'));
  });

  test('Vehicle catalog exposes 2015+ powertrain choices without sales trims',
      () async {
    final repository = const MockVehicleCatalogRepository();

    final manufacturers = await repository.listManufacturers(keyword: '현대');
    final hyundai = manufacturers.firstWhere((item) => item.id == 'm-hyundai');
    final models = await repository.listModels(hyundai.id, keyword: '아반떼');
    final avante =
        models.firstWhere((item) => item.id == 'model-hyundai-001-kr');
    final years = await repository.listYears(avante.id);

    expect(years.map((item) => item.year), containsAll([2026, 2015]));

    final year2026 = years.firstWhere((item) => item.year == 2026);
    final variants = await repository.listVariants(year2026.id);
    final trimNames = variants.map((item) => item.trimName).toList();

    expect(trimNames, ['1.6 가솔린', '1.6 하이브리드', '1.6 LPi']);
    expect(trimNames.any((item) => item.contains('스마트')), isFalse);
    expect(trimNames.any((item) => item.contains('모던')), isFalse);
    expect(trimNames.any((item) => item.contains('인스퍼레이션')), isFalse);
    expect(trimNames.any((item) => item.contains('N Line')), isFalse);
    expect(trimNames.any((item) => item.contains('인치')), isFalse);
  });

  test('Vehicle catalog separates K3 and K3 GT by powertrain', () async {
    final repository = const MockVehicleCatalogRepository();

    final manufacturers = await repository.listManufacturers(keyword: '기아');
    final kia = manufacturers.firstWhere((item) => item.id == 'm-kia');
    final models = await repository.listModels(kia.id, keyword: 'K3');

    expect(models.map((item) => item.nameKo), containsAll(['K3', 'K3 GT']));

    final k3 = models.firstWhere((item) => item.nameKo == 'K3');
    expect(k3.availableFuelTypes, ['가솔린', '디젤']);
    final k3Years = await repository.listYears(k3.id);
    expect(k3Years.map((item) => item.year), containsAll([2024, 2015]));
    expect(k3Years.map((item) => item.year), isNot(contains(2014)));
    final k3Year2017 = k3Years.firstWhere((item) => item.year == 2017);
    final k3OldVariants = await repository.listVariants(k3Year2017.id);
    expect(
      k3OldVariants.map((item) => item.trimName),
      ['1.6 가솔린', '1.6 디젤'],
    );
    final k3OldGasoline = k3OldVariants
        .firstWhere((item) => item.id == 'variant-kia-k3-2017-16-gdi-6at');

    expect(k3OldGasoline.trimName, '1.6 가솔린');
    expect(
      k3OldGasoline.specSummary,
      '1591cc · Gamma 1.6 GDI · 자동 6단 · 14.3 km/L',
    );

    final k3OldDiesel = k3OldVariants
        .firstWhere((item) => item.id == 'variant-kia-k3-2017-16-diesel-7dct');
    expect(k3OldDiesel.trimName, '1.6 디젤');
    expect(
      k3OldDiesel.specSummary,
      '1582cc · U2 1.6 VGT 디젤 · 7단 DCT ISG · 19.1 km/L',
    );

    final k3Year2024 = k3Years.firstWhere((item) => item.year == 2024);
    final k3Variants = await repository.listVariants(k3Year2024.id);
    expect(k3Variants.map((item) => item.trimName), ['1.6 가솔린']);
    final k3Gasoline = k3Variants
        .firstWhere((item) => item.id == 'variant-kia-k3-2024-16-ivt');

    expect(k3Gasoline.trimName, '1.6 가솔린');
    expect(
      k3Gasoline.specSummary,
      '1598cc · Smartstream G1.6 · IVT · 15.2 km/L',
    );

    final k3Gt = models.firstWhere((item) => item.nameKo == 'K3 GT');
    final k3GtYears = await repository.listYears(k3Gt.id);
    expect(k3GtYears.map((item) => item.year), containsAll([2024, 2018]));
    expect(k3GtYears.map((item) => item.year), isNot(contains(2026)));

    final k3GtYear2020 = k3GtYears.firstWhere((item) => item.year == 2020);
    final k3Gt2020Variants = await repository.listVariants(k3GtYear2020.id);
    expect(
      k3Gt2020Variants.map((item) => item.trimName),
      ['1.6T 가솔린 수동', '1.6T 가솔린 DCT'],
    );

    final k3GtYear2024 = k3GtYears.firstWhere((item) => item.year == 2024);
    final k3GtVariants = await repository.listVariants(k3GtYear2024.id);
    final k3GtTurbo = k3GtVariants
        .firstWhere((item) => item.id == 'variant-kia-k3-gt-2024-16t-7dct');

    expect(k3GtTurbo.trimName, '1.6T 가솔린 DCT');
    expect(
      k3GtTurbo.specSummary,
      '1591cc · Gamma 1.6 T-GDi · 7단 DCT · 12.1 km/L',
    );
    expect(k3GtTurbo.vehicleClass, '스포츠');
  });

  test('User vehicle assignment updates active league', () async {
    final catalog = const MockVehicleCatalogRepository();
    final repository = MockUserVehicleRepository(catalogRepository: catalog);

    final vehicle = await repository.addUserVehicleFromVariant(
        'variant-hyundai-avante-2026-gasoline', '테스트 아반떼', true);
    final membership = await repository.assignLeagueForVehicle(vehicle.id);
    final primary = await MockVehicleRepository().getPrimaryVehicle();

    expect(primary?.nickname, '테스트 아반떼');
    expect(membership.fuelLeague, 'gasoline');
    expect(membership.vehicleClass, '준중형');
  });

  test('Custom catalog request stays pending review', () async {
    final repository = const MockVehicleCatalogRepository();
    final vehicle = await repository.createCustomVehicleRequest(
      manufacturer: '기타',
      modelName: '테스트 모델',
      year: 2026,
      trimName: '수동 입력',
      fuelType: '전기차',
      vehicleClass: '소형',
    );

    expect(vehicle.verificationStatus, 'pendingReview');
    expect(vehicle.fuelLeague, 'electric');
    expect(vehicle.variant?.isVerified, isFalse);

    final reviewQueue = await repository.listCustomVehicleReviewRequests(
        status: 'pending_review');
    expect(reviewQueue, hasLength(1));
    expect(reviewQueue.single.userVehicleId, vehicle.id);
    expect(reviewQueue.single.fuelLeague, 'electric');

    final approved = await repository.reviewCustomVehicleRequest(
      requestId: reviewQueue.single.id,
      decision: 'approve',
      reviewNote: '공식 리그 반영 승인',
    );
    expect(approved?.status, 'approved');

    final userVehicles = await MockUserVehicleRepository().listUserVehicles();
    expect(userVehicles.map((item) => item.id), contains(vehicle.id));
    expect(
      userVehicles
          .singleWhere((item) => item.id == vehicle.id)
          .verificationStatus,
      'verified',
    );

    final notifications =
        await MockNotificationRepository().listNotifications();
    expect(notifications.first.notificationType, 'vehicle_review');
    expect(notifications.first.targetRoute, '/settings/vehicles');
    expect(notifications.first.title, contains('검수가 완료'));
  });

  test('Custom catalog review rejects unknown decisions', () async {
    final repository = const MockVehicleCatalogRepository();
    final vehicle = await repository.createCustomVehicleRequest(
      manufacturer: '기타',
      modelName: '테스트 모델',
      year: 2026,
      trimName: '수동 입력',
      fuelType: '가솔린',
      vehicleClass: '준중형',
    );

    final reviewQueue = await repository.listCustomVehicleReviewRequests(
        status: 'pending_review');
    expect(reviewQueue.single.userVehicleId, vehicle.id);

    await expectLater(
      repository.reviewCustomVehicleRequest(
        requestId: reviewQueue.single.id,
        decision: 'hold',
      ),
      throwsArgumentError,
    );
  });

  test('Ranking filters by selected fuel league', () async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    final rankings = await MockRankingRepository().getRankings('내 리그');

    expect(rankings, isNotEmpty);
    expect(rankings.every((entry) => entry.leagueKey == mockVehicle.leagueKey),
        isTrue);
  });

  test('Ranking repository returns public profile entry by user id', () async {
    final repository = MockRankingRepository();

    final entry = await repository.getPublicEntryByUserId('user-nightcruise');

    expect(entry?.nickname, 'NightCruise');
    expect(entry?.userId, 'user-nightcruise');
    expect(await repository.getPublicEntryByUserId('missing-user'), isNull);
  });

  test('Battle mock data keeps same league conditions', () async {
    final battle = (await MockBattleRepository().getBattles()).first;

    expect(battle.requiredFuelLeague, 'gasoline');
    expect(battle.requiredVehicleClass, '준중형');
    expect(battle.isFriendlyCrossLeague, isFalse);
  });

  test('Battle repository creates non-cash league battle', () async {
    final repository = MockBattleRepository();
    final battle = await repository.createBattle(
      title: '가솔린 준중형 공개 배틀',
      battleType: '공개 매칭',
      ruleType: '최고 효율 점수',
      duration: const Duration(hours: 24),
      rewardSummary: '시즌 XP 120 · 배지 조각 2개',
      requiredFuelLeague: 'gasoline',
      requiredVehicleClass: '준중형',
    );

    expect(battle.title, contains('공개 배틀'));
    expect(battle.wagerTemplate, 'non_cash_reward');
    expect(battle.requiredFuelLeague, 'gasoline');
    expect(battle.endAt.isAfter(battle.startAt), isTrue);
    expect((await repository.getBattleById(battle.id))?.id, battle.id);

    final settled = await repository.settleBattle(
      battleId: battle.id,
      myScore: 950,
      opponentScore: 920,
    );
    expect(settled.status, 'completed');
    expect((await repository.getBattleById(battle.id))?.status, 'completed');
  });

  test('MockCrewRepository returns crew summary and members', () async {
    final repository = MockCrewRepository();

    final crew = await repository.getMyCrew();
    final members = await repository.listMembers();

    expect(crew?.name, 'Neon Commuters');
    expect(members, isNotEmpty);
    expect(members.first.nickname, 'ApexDriver');
  });

  test('MockReportRepository creates report items', () async {
    final repository = MockReportRepository();

    final report = await repository.createReport(
      const ReportRequest(
        targetType: 'drive_session',
        targetId: 'drive-001',
        reason: '검증이 필요한 주행 기록입니다.',
      ),
    );

    expect(report.targetType, 'drive_session');
    expect(report.targetId, 'drive-001');
    expect(report.status, 'open');
    expect(repository.debugReports.first.id, report.id);

    final updated = await repository.updateReportStatus(report.id, 'resolved');

    expect(updated?.status, 'resolved');
    expect(repository.debugReports.first.status, 'resolved');
  });

  test('Fuel league helper normalizes Korean and English fuel types', () {
    expect(FuelLeague.keyForFuelType('가솔린'), 'gasoline');
    expect(FuelLeague.keyForFuelType('Electric'), 'electric');
    expect(FuelLeague.leagueLabel('gasoline', '준중형'), '가솔린 준중형 리그');
  });

  test('Production config requires Google auth values', () {
    const config = AppConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://example.supabase.co',
      supabaseAnonKey: 'anon',
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

    expect(config.isProduction, isTrue);
    expect(config.hasSupabase, isTrue);
    expect(config.hasValidSupabaseUrl, isTrue);
    expect(config.hasGoogleAuth, isFalse);
    expect(config.hasGoogleOAuthClient, isFalse);
    expect(config.hasProductionGoogleOAuthConfig, isFalse);
  });

  test('Production config requires complete Google OAuth client set', () {
    final androidOnly = _testConfig(
      environment: AppEnvironment.production,
      googleAndroidClientId: 'android-client.apps.googleusercontent.com',
      googleWebClientId: '',
      googleServerClientId: '',
    );
    final webClient = _testConfig(
      environment: AppEnvironment.production,
      googleWebClientId: 'web-client.apps.googleusercontent.com',
      googleServerClientId: '',
    );
    final serverClient = _testConfig(
      environment: AppEnvironment.production,
      googleWebClientId: '',
      googleServerClientId: 'server-client.apps.googleusercontent.com',
    );
    final fullGoogleOAuth = _testConfig(
      environment: AppEnvironment.production,
      googleWebClientId: 'web-client.apps.googleusercontent.com',
      googleAndroidClientId: 'android-client.apps.googleusercontent.com',
      googleIosClientId: 'ios-client.apps.googleusercontent.com',
      googleServerClientId: 'server-client.apps.googleusercontent.com',
      googleReversedIosClientId: 'com.googleusercontent.apps.ios-client',
    );
    final wrongReversedIosClient = _testConfig(
      environment: AppEnvironment.production,
      googleWebClientId: 'web-client.apps.googleusercontent.com',
      googleAndroidClientId: 'android-client.apps.googleusercontent.com',
      googleIosClientId: 'ios-client.apps.googleusercontent.com',
      googleServerClientId: 'server-client.apps.googleusercontent.com',
      googleReversedIosClientId: 'com.googleusercontent.apps.other-ios-client',
    );
    final malformedClientId = _testConfig(
      environment: AppEnvironment.production,
      googleWebClientId: 'web-client',
      googleAndroidClientId: 'android-client.apps.googleusercontent.com',
      googleIosClientId: 'ios-client.apps.googleusercontent.com',
      googleServerClientId: 'server-client.apps.googleusercontent.com',
      googleReversedIosClientId: 'com.googleusercontent.apps.ios-client',
    );

    expect(androidOnly.hasGoogleAuth, isTrue);
    expect(androidOnly.hasGoogleOAuthClient, isFalse);
    expect(androidOnly.hasProductionGoogleOAuthConfig, isFalse);
    expect(webClient.hasGoogleOAuthClient, isTrue);
    expect(webClient.hasProductionGoogleOAuthConfig, isFalse);
    expect(serverClient.hasGoogleOAuthClient, isTrue);
    expect(serverClient.hasProductionGoogleOAuthConfig, isFalse);
    expect(
      fullGoogleOAuth.expectedGoogleReversedIosClientId,
      'com.googleusercontent.apps.ios-client',
    );
    expect(fullGoogleOAuth.hasValidGoogleOAuthClientIds, isTrue);
    expect(fullGoogleOAuth.hasProductionGoogleOAuthConfig, isTrue);
    expect(
        wrongReversedIosClient.hasMatchingGoogleIosReversedClientId, isFalse);
    expect(wrongReversedIosClient.hasProductionGoogleOAuthConfig, isFalse);
    expect(malformedClientId.hasValidGoogleOAuthClientIds, isFalse);
    expect(malformedClientId.hasProductionGoogleOAuthConfig, isFalse);
  });

  test('Supabase Google auth requires token and platform client on native', () {
    final client =
        SupabaseClient('https://example.supabase.co', 'public-anon-key');

    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);

    expect(
      SupabaseGoogleAuthRepository(
        client: client,
        googleAndroidClientId: 'android-client.apps.googleusercontent.com',
      ).isGoogleAuthConfigured(),
      isFalse,
    );
    expect(
      SupabaseGoogleAuthRepository(
        client: client,
        googleServerClientId: 'server-client.apps.googleusercontent.com',
      ).isGoogleAuthConfigured(),
      isFalse,
    );
    expect(
      SupabaseGoogleAuthRepository(
        client: client,
        googleAndroidClientId: 'android-client.apps.googleusercontent.com',
        googleServerClientId: 'server-client.apps.googleusercontent.com',
      ).isGoogleAuthConfigured(),
      isTrue,
    );

    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    expect(
      SupabaseGoogleAuthRepository(
        client: client,
        googleAndroidClientId: 'android-client.apps.googleusercontent.com',
        googleServerClientId: 'server-client.apps.googleusercontent.com',
      ).isGoogleAuthConfigured(),
      isFalse,
    );
    expect(
      SupabaseGoogleAuthRepository(
        client: client,
        googleIosClientId: 'ios-client.apps.googleusercontent.com',
        googleServerClientId: 'server-client.apps.googleusercontent.com',
      ).isGoogleAuthConfigured(),
      isTrue,
    );
  });

  test('AppConfig validates Supabase URL by environment', () {
    final devLocal = _testConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: 'http://127.0.0.1:54321',
    );
    final prodHttps = _testConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'https://example.supabase.co',
    );
    final prodHttp = _testConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'http://example.supabase.co',
    );
    final malformed = _testConfig(
      environment: AppEnvironment.production,
      supabaseUrl: 'not-a-url',
    );

    expect(devLocal.hasValidSupabaseUrl, isTrue);
    expect(prodHttps.hasValidSupabaseUrl, isTrue);
    expect(prodHttp.hasValidSupabaseUrl, isFalse);
    expect(malformed.hasSupabase, isTrue);
    expect(malformed.hasValidSupabaseUrl, isFalse);
  });

  test('AppConfig permits mock repositories only in dev without Supabase', () {
    final devWithoutSupabase = _testConfig(
      environment: AppEnvironment.dev,
      supabaseUrl: '',
    );
    final stagingWithoutSupabase = _testConfig(
      environment: AppEnvironment.staging,
      supabaseUrl: '',
    );
    final productionWithoutSupabase = _testConfig(
      environment: AppEnvironment.production,
      supabaseUrl: '',
    );

    expect(devWithoutSupabase.requiresSupabase, isFalse);
    expect(devWithoutSupabase.canUseMockRepositories, isTrue);
    expect(stagingWithoutSupabase.requiresSupabase, isTrue);
    expect(stagingWithoutSupabase.canUseMockRepositories, isFalse);
    expect(productionWithoutSupabase.requiresSupabase, isTrue);
    expect(productionWithoutSupabase.canUseMockRepositories, isFalse);
  });

  test('Dev auth provider keeps mock login when only Google values exist', () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          _testConfig(
            environment: AppEnvironment.dev,
            supabaseUrl: '',
            googleWebClientId: 'web-client.apps.googleusercontent.com',
            googleAndroidClientId: 'android-client.apps.googleusercontent.com',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authRepositoryProvider), isA<MockAuthRepository>());
  });

  test('Dev auth provider uses mock when Supabase exists but Google is missing',
      () {
    final container = ProviderContainer(
      overrides: [
        appConfigProvider.overrideWithValue(
          _testConfig(
            environment: AppEnvironment.dev,
            supabaseUrl: 'https://example.supabase.co',
            googleWebClientId: '',
            googleAndroidClientId: '',
            googleIosClientId: '',
            googleServerClientId: '',
            googleReversedIosClientId: '',
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authRepositoryProvider), isA<MockAuthRepository>());
  });

  test('SupabaseRuntimeConfig refuses invalid client URLs', () {
    const local = SupabaseRuntimeConfig(
      url: 'http://127.0.0.1:54321',
      anonKey: 'anon',
      environment: 'dev',
    );
    const productionHttp = SupabaseRuntimeConfig(
      url: 'http://example.supabase.co',
      anonKey: 'anon',
      environment: 'production',
    );
    const productionHttps = SupabaseRuntimeConfig(
      url: 'https://example.supabase.co',
      anonKey: 'anon',
      environment: 'production',
    );

    expect(local.canCreateClient, isTrue);
    expect(productionHttp.canCreateClient, isFalse);
    expect(productionHttps.canCreateClient, isTrue);
  });

  test('MockDriveRepository finishes with verified score', () async {
    final repository = MockDriveRepository();
    final session = await repository.startDriveSession();
    final score = await repository.finishDriveSession(
      sessionId: session.id,
      distanceKm: 3.2,
      duration: const Duration(minutes: 5, seconds: 20),
      averageEfficiency: 17.4,
      fuelUsedLiters: 0.18,
    );
    expect(session.status, 'recording');
    expect(score.driveSessionId, session.id);
    expect(score.totalScore, greaterThan(0));
  });

  test('MockDriveRepository lists recent sessions with matching scores',
      () async {
    final repository = MockDriveRepository();
    final sessions = await repository.listDriveSessions(limit: 3);
    final scores = await repository.listDriveScores(limit: 3);

    expect(sessions, hasLength(3));
    expect(scores, hasLength(3));
    expect(scores.map((score) => score.driveSessionId),
        contains(sessions.first.id));
    expect(sessions.first.distanceKm, greaterThan(0));
  });

  test('MockAdsRepository returns reward', () async {
    final repository = MockAdsRepository();
    expect(await repository.isRewardAdAvailable(), isTrue);
    final reward = await repository.watchRewardAd();
    expect(reward.claimed, isTrue);
  });

  test('MockCouponRepository issues user coupon', () async {
    final repository = MockCouponRepository();
    final coupon = (await repository.listCoupons()).first;
    final issued = await repository.issueCoupon(coupon.id);

    expect(issued.couponId, coupon.id);
    expect(issued.status, 'issued');
    expect(issued.userId, mockProfile.id);
  });

  test('MockSubscriptionRepository verifies purchase payload', () async {
    final repository = MockSubscriptionRepository();
    final result = await repository.verifyPurchase(
      const PurchaseVerificationRequest(
        provider: 'mock',
        productId: 'fuel_arena_premium_monthly',
        purchaseToken: 'mock_purchase_token',
        transactionId: 'mock-transaction-001',
        planId: 'premium-monthly',
      ),
    );

    expect(result.verified, isTrue);
    expect(result.premiumActive, isTrue);
    expect(result.planId, 'premium-monthly');
  });

  test('MockAdminRepository paginates and filters operation records', () async {
    final repository = MockAdminRepository();
    const firstQuery = AdminRecordQuery(
      section: 'Drive Sessions',
      page: 0,
      pageSize: 5,
    );
    final firstPage = await repository.getRecords(firstQuery);
    final secondPage = await repository.getRecords(
      firstQuery.copyWith(page: 1),
    );
    final blockedPage = await repository.getRecords(
      firstQuery.copyWith(status: 'blocked'),
    );

    expect(firstPage.items, hasLength(5));
    expect(firstPage.hasNext, isTrue);
    expect(secondPage.items.first.id, isNot(firstPage.items.first.id));
    expect(blockedPage.items.every((item) => item.status == 'blocked'), isTrue);
  });

  test('MockAdminRepository records admin action logs', () async {
    final repository = MockAdminRepository();
    final page = await repository.getRecords(
      const AdminRecordQuery(section: 'Drive Sessions', pageSize: 1),
    );

    final log = await repository.recordAction(
      AdminActionRequest(
        section: 'Drive Sessions',
        action: '상태 변경',
        record: page.items.first,
      ),
    );

    expect(log.action, '상태 변경');
    expect(log.targetId, page.items.first.id);
    expect(repository.debugActionLogs.first.id, log.id);
  });

  test('MockAdminRepository returns privacy request records from review queue',
      () async {
    final privacyRepository = MockPrivacyRequestRepository();
    final request = await privacyRepository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'data_delete',
        description: '불필요한 주행 기록 삭제를 요청합니다.',
      ),
    );
    final adminRepository = MockAdminRepository();

    final openPage = await adminRepository.getRecords(
      const AdminRecordQuery(section: 'Privacy Requests', status: 'open'),
    );
    final completedPage = await adminRepository.getRecords(
      const AdminRecordQuery(section: 'Privacy Requests', status: 'completed'),
    );

    expect(openPage.items, hasLength(1));
    expect(openPage.items.single.id, request.id);
    expect(openPage.items.single.title, '데이터 삭제');
    expect(openPage.items.single.description, contains('주행 기록 삭제'));
    expect(completedPage.items, isEmpty);
  });

  test('MockAdminRepository returns report records from review queue',
      () async {
    final reportRepository = MockReportRepository();
    final report = await reportRepository.createReport(
      const ReportRequest(
        targetType: 'drive_review_request',
        targetId: 'drive-review-009',
        reason: '랭킹 반영 기준 검토가 필요합니다.',
      ),
    );
    final adminRepository = MockAdminRepository();

    final openPage = await adminRepository.getRecords(
      const AdminRecordQuery(section: 'Reports', status: 'open'),
    );
    final resolvedPage = await adminRepository.getRecords(
      const AdminRecordQuery(section: 'Reports', status: 'resolved'),
    );

    expect(openPage.items, hasLength(1));
    expect(openPage.items.single.id, report.id);
    expect(openPage.items.single.title, '주행 기록 이의제기');
    expect(openPage.items.single.metadata['target_id'], 'drive-review-009');
    expect(resolvedPage.items, isEmpty);
  });
}

AppConfig _testConfig({
  required AppEnvironment environment,
  String supabaseUrl = 'https://example.supabase.co',
  String googleWebClientId = 'web-client',
  String googleAndroidClientId = '',
  String googleIosClientId = '',
  String googleServerClientId = '',
  String googleReversedIosClientId = '',
}) {
  return AppConfig(
    environment: environment,
    supabaseUrl: supabaseUrl,
    supabaseAnonKey: 'anon',
    googleWebClientId: googleWebClientId,
    googleAndroidClientId: googleAndroidClientId,
    googleIosClientId: googleIosClientId,
    googleServerClientId: googleServerClientId,
    googleReversedIosClientId: googleReversedIosClientId,
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
