import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fuel_arena/app/app_config.dart';
import 'package:fuel_arena/app/router.dart';
import 'package:fuel_arena/features/auth/presentation/login_screen.dart';
import 'package:fuel_arena/features/admin/presentation/admin_vehicle_catalog_screen.dart';
import 'package:fuel_arena/features/admin/presentation/admin_widgets.dart';
import 'package:fuel_arena/features/onboarding/presentation/onboarding_screen.dart';
import 'package:fuel_arena/features/setup/presentation/additional_setup_intro_screen.dart';
import 'package:fuel_arena/features/vehicle/presentation/vehicle_register_screen.dart';
import 'package:fuel_arena/features/vehicle/presentation/vehicle_setup_screen.dart';
import 'package:fuel_arena/features/drive/presentation/drive_history_screen.dart';
import 'package:fuel_arena/features/drive/presentation/drive_start_screen.dart';
import 'package:fuel_arena/features/home/presentation/main_shell_screen.dart';
import 'package:fuel_arena/features/home/presentation/home_screen.dart';
import 'package:fuel_arena/features/drive/presentation/drive_result_screen.dart';
import 'package:fuel_arena/features/drive/presentation/safety_drive_screen.dart';
import 'package:fuel_arena/features/ranking/presentation/ranking_screen.dart';
import 'package:fuel_arena/features/ranking/presentation/ranking_detail_screen.dart';
import 'package:fuel_arena/features/battle/presentation/battle_screen.dart';
import 'package:fuel_arena/features/common/presentation/flow_screens.dart';
import 'package:fuel_arena/features/season/presentation/season_screen.dart';
import 'package:fuel_arena/features/premium/presentation/premium_screen.dart';
import 'package:fuel_arena/features/profile/presentation/profile_screen.dart';
import 'package:fuel_arena/features/rewards/presentation/reward_wallet_screen.dart';
import 'package:fuel_arena/features/sponsor/presentation/sponsor_challenge_screen.dart';
import 'package:fuel_arena/features/stats/presentation/stats_screen.dart';
import 'package:fuel_arena/features/notifications/presentation/notifications_screen.dart';
import 'package:fuel_arena/features/settings/presentation/settings_screen.dart';
import 'package:fuel_arena/features/support/presentation/support_screens.dart';
import 'package:fuel_arena/shared/models/fuel_arena_models.dart';
import 'package:fuel_arena/shared/providers/repository_providers.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';
import 'package:fuel_arena/shared/services/app_services.dart';
import 'package:fuel_arena/shared/widgets/app_scaffold.dart';
import 'package:fuel_arena/shared/widgets/navigation.dart';
import 'package:fuel_arena/shared/widgets/state_views.dart';
import 'package:fuel_arena/shared/widgets/widgets.dart'
    show
        BattleCard,
        DriveResultHeader,
        LockedPremiumCard,
        SafetyModePanel,
        VerificationStatusBanner;

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp(
      theme: ThemeData.dark(useMaterial3: true),
      home: Scaffold(body: child),
    ),
  );
}

Widget _wrapRouter(GoRouter router) {
  return ProviderScope(
    child: MaterialApp.router(
      theme: ThemeData.dark(useMaterial3: true),
      routerConfig: router,
    ),
  );
}

class _RouteSmokeCase {
  const _RouteSmokeCase(this.location, this.expectedText);

  final String location;
  final String expectedText;
}

Future<void> _seedDriveResultSummary({
  String sessionId = 'local-session',
  Duration duration = const Duration(minutes: 12, seconds: 18),
  double distanceKm = 4.36,
  double averageEfficiency = 16.8,
}) {
  return LocalStateService().saveLatestDriveResultSummary(
    sessionId: sessionId,
    duration: duration,
    distanceKm: distanceKm,
    averageEfficiency: averageEfficiency,
    fuelUsedLiters: distanceKm / averageEfficiency,
  );
}

class _ImmediateVehicleCatalogRepository extends MockVehicleCatalogRepository {
  const _ImmediateVehicleCatalogRepository();

  static const _manufacturers = [
    VehicleManufacturer(
      id: 'm-hyundai',
      nameKo: '현대',
      nameEn: 'Hyundai',
      country: 'KR',
      isPopular: true,
      modelCount: 24,
      minYear: 2008,
      maxYear: 2026,
    ),
    VehicleManufacturer(
      id: 'm-kia',
      nameKo: '기아',
      nameEn: 'Kia',
      country: 'KR',
      isPopular: true,
      modelCount: 22,
      minYear: 2008,
      maxYear: 2026,
    ),
    VehicleManufacturer(
      id: 'm-bmw',
      nameKo: 'BMW',
      nameEn: 'BMW',
      country: 'DE',
      isPopular: true,
      modelCount: 18,
      minYear: 2008,
      maxYear: 2026,
    ),
  ];

  static const _models = [
    VehicleModel(
      id: 'model-hyundai-avante-test',
      manufacturerId: 'm-hyundai',
      nameKo: '아반떼',
      nameEn: 'Avante',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드', 'LPG'],
      isPopular: true,
      sortOrder: 10,
    ),
    VehicleModel(
      id: 'model-hyundai-kona-test',
      manufacturerId: 'm-hyundai',
      nameKo: '코나',
      nameEn: 'Kona',
      bodyType: 'SUV',
      availableFuelTypes: ['가솔린', '하이브리드', '전기차'],
      sortOrder: 20,
    ),
    VehicleModel(
      id: 'model-hyundai-ioniq5-test',
      manufacturerId: 'm-hyundai',
      nameKo: '아이오닉 5',
      nameEn: 'IONIQ 5',
      bodyType: '전기 SUV',
      availableFuelTypes: ['전기차'],
      sortOrder: 30,
    ),
    VehicleModel(
      id: 'model-kia-013-k3',
      manufacturerId: 'm-kia',
      nameKo: 'K3',
      nameEn: 'K3',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '디젤'],
      sortOrder: 10,
    ),
    VehicleModel(
      id: 'model-kia-k3-gt-kr',
      manufacturerId: 'm-kia',
      nameKo: 'K3 GT',
      nameEn: 'K3 GT',
      bodyType: '고성능 해치백',
      availableFuelTypes: ['가솔린'],
      sortOrder: 11,
    ),
    VehicleModel(
      id: 'model-bmw-3series-test',
      manufacturerId: 'm-bmw',
      nameKo: '3시리즈',
      nameEn: '3 Series',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '디젤', '플러그인 하이브리드'],
      sortOrder: 10,
    ),
  ];

  static final _years = [
    for (var year = 2026; year >= 2023; year -= 1)
      VehicleModelYear(
        id: 'year-hyundai-avante-test-$year',
        modelId: 'model-hyundai-avante-test',
        year: year,
      ),
    for (var year = 2026; year >= 2023; year -= 1)
      VehicleModelYear(
        id: 'year-hyundai-kona-test-$year',
        modelId: 'model-hyundai-kona-test',
        year: year,
      ),
    for (var year = 2026; year >= 2023; year -= 1)
      VehicleModelYear(
        id: 'year-hyundai-ioniq5-test-$year',
        modelId: 'model-hyundai-ioniq5-test',
        year: year,
      ),
    for (var year = 2024; year >= 2012; year -= 1)
      VehicleModelYear(
        id: 'year-kia-k3-$year',
        modelId: 'model-kia-013-k3',
        year: year,
      ),
    for (var year = 2024; year >= 2018; year -= 1)
      VehicleModelYear(
        id: 'year-kia-k3-gt-$year',
        modelId: 'model-kia-k3-gt-kr',
        year: year,
      ),
  ];

  static const _variants = [
    VehicleVariant(
      id: 'variant-kia-k3-2024-16-ivt',
      modelYearId: 'year-kia-k3-2024',
      manufacturerName: '기아',
      modelName: 'K3',
      year: 2024,
      trimName: '1.6 가솔린',
      engineName: 'Smartstream G1.6',
      fuelType: '가솔린',
      displacementCc: 1598,
      drivetrain: 'FWD',
      transmission: 'IVT',
      officialEfficiency: 15.2,
      efficiencyUnit: 'km/L',
      vehicleClass: '준중형',
      fuelLeague: 'gasoline',
      sortOrder: 10,
    ),
    VehicleVariant(
      id: 'variant-kia-k3-gt-2024-16t-7dct',
      modelYearId: 'year-kia-k3-gt-2024',
      manufacturerName: '기아',
      modelName: 'K3 GT',
      year: 2024,
      trimName: '1.6T 가솔린 DCT',
      engineName: 'Gamma 1.6 T-GDi',
      fuelType: '가솔린',
      displacementCc: 1591,
      drivetrain: 'FWD',
      transmission: '7단 DCT',
      officialEfficiency: 12.1,
      efficiencyUnit: 'km/L',
      vehicleClass: '스포츠',
      fuelLeague: 'gasoline',
      sortOrder: 10,
    ),
  ];

  @override
  Future<List<VehicleManufacturer>> listManufacturers({
    String? country,
    String? keyword,
  }) async {
    final normalizedCountry = country?.trim().toUpperCase() ?? '';
    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    return _manufacturers.where((item) {
      final countryMatches = normalizedCountry.isEmpty ||
          (normalizedCountry == 'IMPORT'
              ? item.country != 'KR'
              : item.country == normalizedCountry);
      final keywordMatches = normalizedKeyword.isEmpty ||
          item.nameKo.toLowerCase().contains(normalizedKeyword) ||
          item.nameEn.toLowerCase().contains(normalizedKeyword);
      return countryMatches && keywordMatches;
    }).toList();
  }

  @override
  Future<List<VehicleModel>> listModels(
    String manufacturerId, {
    String? keyword,
  }) async {
    final normalizedKeyword = keyword?.trim().toLowerCase() ?? '';
    return _models.where((item) {
      final keywordMatches = normalizedKeyword.isEmpty ||
          item.nameKo.toLowerCase().contains(normalizedKeyword) ||
          item.nameEn.toLowerCase().contains(normalizedKeyword);
      return item.manufacturerId == manufacturerId && keywordMatches;
    }).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  @override
  Future<List<VehicleModelYear>> listYears(String modelId) async {
    return _years.where((item) => item.modelId == modelId).toList()
      ..sort((a, b) => b.year.compareTo(a.year));
  }

  @override
  Future<List<VehicleVariant>> listVariants(String modelYearId) async {
    return _variants.where((item) => item.modelYearId == modelYearId).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }
}

class _RedirectingAuthRepository extends MockAuthRepository {
  @override
  Future<UserProfile> signInWithGoogle() async {
    throw const AuthRedirectInProgressException();
  }
}

class _StagedGoogleAuthRepository extends MockAuthRepository {
  _StagedGoogleAuthRepository(this._loginProfile, {UserProfile? initialUser})
      : _currentUser = initialUser;

  final UserProfile _loginProfile;
  UserProfile? _currentUser;

  @override
  Future<UserProfile?> currentUser() async => _currentUser;

  @override
  Future<UserProfile?> getCurrentUser() async => _currentUser;

  @override
  Future<UserProfile> signInWithGoogle() async {
    _currentUser = _loginProfile.copyWith(
      authProvider: 'google',
      updatedAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<UserProfile> ensureProfileAfterGoogleLogin() async {
    return _currentUser ?? await signInWithGoogle();
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
  }
}

class _RecordingGoogleAuthRepository extends MockAuthRepository {
  _RecordingGoogleAuthRepository(
    UserProfile profile, {
    UserProfile? initialUser,
  }) {
    debugSetProfile(initialUser ?? profile);
  }

  var signedOut = false;

  @override
  Future<void> signOut() async {
    signedOut = true;
    await super.signOut();
  }
}

void main() {
  setUp(() {
    resetMockFuelArenaState();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Onboarding CTA 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const OnboardingScreen()));
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
  });

  testWidgets('LoginScreen Google only CTA 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const LoginScreen()));
    expect(find.text('Google로 시작하기'), findsOneWidget);
    expect(find.text('약관 보기'), findsOneWidget);
    expect(find.text('개인정보 보기'), findsOneWidget);
    expect(find.text('위치정보 보기'), findsOneWidget);
    expect(find.textContaining('이메일'), findsNothing);
    expect(find.textContaining('비밀번호'), findsNothing);
  });

  testWidgets('LoginScreen shows dev mock badge only for mock auth',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(const AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: LoginScreen()),
        ),
      ),
    );

    expect(find.text('dev mock 로그인'), findsOneWidget);
  });

  testWidgets('LoginScreen opens public legal documents before login',
      (tester) async {
    final router = createAppRouter(initialLocation: '/auth/login');
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pumpAndSettle();

    final privacyLink = find.widgetWithText(TextButton, '개인정보 보기');
    await tester.ensureVisible(privacyLink);
    final button = tester.widget<TextButton>(privacyLink);
    expect(button.onPressed, isNotNull);
    button.onPressed?.call();
    await tester.pumpAndSettle();

    expect(find.text('개인정보 처리방침'), findsWidgets);
    expect(find.text('필요한 데이터만 수집하고 공개 범위를 제한합니다'), findsOneWidget);
    expect(find.text('Google로 시작하기'), findsNothing);
  });

  testWidgets('LoginScreen shows Google OAuth redirect progress',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider
              .overrideWithValue(_RedirectingAuthRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: LoginScreen()),
        ),
      ),
    );

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Google 로그인 화면으로 이동 중입니다.'), findsOneWidget);
    expect(find.text('Google 로그인 설정이 필요합니다.'), findsNothing);
  });

  testWidgets(
      'LoginScreen refreshes stale signed-out session after Google login',
      (tester) async {
    final authRepository = _StagedGoogleAuthRepository(
      mockProfile.copyWith(
        consentCompleted: false,
        vehicleSetupCompleted: false,
      ),
    );
    final router = createAppRouter(initialLocation: '/drive/start');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(authRepository),
          secureStorageServiceProvider
              .overrideWithValue(_MemorySecureStorageService()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('로그인 필요'), findsOneWidget);

    await tester.tap(find.text('로그인 화면으로 이동'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/consent');
    expect(find.text('서비스 이용약관'), findsOneWidget);
    expect(find.text('로그인 필요'), findsNothing);
  });

  testWidgets('LoginScreen routes consented profile to setup', (tester) async {
    final authRepository = _StagedGoogleAuthRepository(
      mockProfile.copyWith(
        consentCompleted: true,
        vehicleSetupCompleted: false,
      ),
    );
    final router = createAppRouter(initialLocation: '/auth/login');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(authRepository),
          secureStorageServiceProvider
              .overrideWithValue(_MemorySecureStorageService()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/setup');
    expect(find.text('차량 설정하기'), findsOneWidget);
  });

  testWidgets('LoginScreen routes completed profile to home', (tester) async {
    final authRepository = _StagedGoogleAuthRepository(
      mockProfile.copyWith(
        consentCompleted: true,
        vehicleSetupCompleted: true,
      ),
    );
    final router = createAppRouter(initialLocation: '/auth/login');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(authRepository),
          secureStorageServiceProvider
              .overrideWithValue(_MemorySecureStorageService()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );

    await tester.tap(find.text('Google로 시작하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
    expect(find.text('로그인 필요'), findsNothing);
    expect(find.text('필수 동의 필요'), findsNothing);
  });

  testWidgets('Additional setup intro 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const AdditionalSetupIntroScreen()));
    expect(find.text('차량 설정하기'), findsOneWidget);
    expect(find.text('나중에 할게요'), findsOneWidget);
  });

  testWidgets('AdminStatusBadge localizes internal status codes',
      (tester) async {
    await tester
        .pumpWidget(_wrap(const AdminStatusBadge(status: 'pending_review')));

    expect(find.text('검수 대기'), findsOneWidget);
    expect(find.text('pending_review'), findsNothing);
  });

  testWidgets('VerificationStatusBanner shows accurate Korean status',
      (tester) async {
    await tester.pumpWidget(_wrap(const Column(
      children: [
        VerificationStatusBanner(status: 'verified'),
        VerificationStatusBanner(status: 'pending_review'),
        VerificationStatusBanner(status: 'rejected'),
      ],
    )));

    expect(find.text('검증 완료되어 랭킹에 반영됩니다'), findsOneWidget);
    expect(find.text('검증 대기 중인 기록입니다'), findsOneWidget);
    expect(find.text('검증 기준을 통과하지 못해 랭킹에는 반영되지 않습니다'), findsOneWidget);
  });

  testWidgets('VehicleRegister stepper 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const VehicleRegisterScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('차량 설정'), findsOneWidget);
    expect(find.text('제조사 검색'), findsOneWidget);
    expect(find.textContaining('차량을 선택하면 리그가 자동으로 계산됩니다'), findsWidgets);
  });

  testWidgets('VehicleSetupScreen year picker selects model year',
      (tester) async {
    VehicleModelRangeChoice? selected;
    const model = VehicleModel(
      id: 'model-hyundai-001-kr',
      manufacturerId: 'm-hyundai',
      nameKo: '아반떼',
      bodyType: '세단',
      availableFuelTypes: ['가솔린', '하이브리드', 'LPG'],
    );
    final years = [
      for (var year = 2026; year >= 2008; year -= 1)
        VehicleModelYear(
          id: 'year-hyundai-001-kr-$year',
          modelId: 'model-hyundai-001-kr',
          year: year,
        ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          body: VehicleModelRangePickerField(
            model: model,
            modelRanges: buildVehicleModelRanges(years),
            onTap: () async {
              selected = await showVehicleModelRangePicker(
                tester.element(find.byType(VehicleModelRangePickerField)),
                model: model,
                modelRanges: buildVehicleModelRanges(years),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    expect(find.text('아반떼 2026년식'), findsOneWidget);
    expect(find.textContaining('2026년식'), findsWidgets);

    await tester.tap(find.text('아반떼 2026년식'));
    await tester.pumpAndSettle();

    expect(selected?.label, '2026년식');
    expect(selected?.representativeYear.year, 2026);
  });

  testWidgets('VehicleSetupScreen filters manufacturers by domestic/import',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(
            const _ImmediateVehicleCatalogRepository(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: VehicleSetupScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('전체'), findsOneWidget);
    expect(find.text('국산'), findsWidgets);
    expect(find.text('수입'), findsWidgets);
    expect(find.text('현대'), findsWidgets);

    await tester.tap(find.text('수입').first);
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('BMW'), findsWidgets);
    expect(find.text('현대'), findsNothing);
  });

  testWidgets('VehicleSetupScreen filters models by body type', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(
            const _ImmediateVehicleCatalogRepository(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: VehicleSetupScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('현대').first);
    await tester.pumpAndSettle();

    expect(find.text('세단'), findsWidgets);
    expect(find.text('SUV'), findsWidgets);
    expect(find.text('아반떼'), findsWidgets);
    expect(find.text('코나'), findsWidgets);
    expect(find.text('아이오닉 5'), findsWidgets);
    expect(find.textContaining('가솔린 · 하이브리드 · LPG'), findsWidgets);

    await tester.tap(find.text('SUV').first);
    await tester.pumpAndSettle();

    expect(find.text('코나'), findsWidgets);
    expect(find.text('아반떼'), findsNothing);
    expect(find.text('아이오닉 5'), findsNothing);
  });

  testWidgets('VehicleSetupScreen separates K3 GT by engine and transmission',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(
            const _ImmediateVehicleCatalogRepository(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: VehicleSetupScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('기아').first);
    await tester.pumpAndSettle();

    expect(find.text('K3'), findsWidgets);
    expect(find.text('K3 GT'), findsWidgets);
    expect(find.textContaining('세대'), findsNothing);

    await tester.tap(find.text('K3 GT').first);
    await tester.pumpAndSettle();

    expect(find.text('기준 연식 선택'), findsWidgets);
    expect(find.textContaining('세대'), findsNothing);

    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();

    expect(find.text('K3 GT 2024년식'), findsOneWidget);
    expect(find.textContaining('엔진/미션 기준 파워트레인 선택'), findsWidgets);
    expect(find.textContaining('세대'), findsNothing);

    await tester.tap(find.text('K3 GT 2024년식'));
    await tester.pumpAndSettle();

    expect(find.text('1.6T 가솔린 DCT'), findsOneWidget);
    expect(find.textContaining('Gamma 1.6 T-GDi · 7단 DCT'), findsOneWidget);
    expect(find.textContaining('스마트'), findsNothing);
    expect(find.textContaining('모던'), findsNothing);
    expect(find.textContaining('인스퍼레이션'), findsNothing);
    expect(find.textContaining('인치'), findsNothing);
  });

  testWidgets('VehicleSetupScreen shows retryable save failure',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(
            const _ImmediateVehicleCatalogRepository(),
          ),
          userVehicleRepositoryProvider
              .overrideWithValue(_FailingUserVehicleRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: VehicleSetupScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('기아').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('K3 GT').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('K3 GT 2024년식'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('1.6T 가솔린 DCT'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('이 차량으로 시작하기'));
    await tester.tap(find.text('이 차량으로 시작하기'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('차량 설정을 저장하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('CustomVehicleRequestScreen submits pending review vehicle',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/custom',
      routes: [
        GoRoute(
          path: '/custom',
          builder: (context, state) =>
              const CustomVehicleRequestScreen(initialManufacturer: '현대'),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('홈 이동 완료')),
          ),
        ),
        GoRoute(
          path: '/setup/vehicle',
          builder: (context, state) => const VehicleSetupScreen(),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('차량 직접 입력'), findsOneWidget);

    await tester.enterText(find.byType(TextField).at(1), '테스트 모델');
    await tester.enterText(find.byType(TextField).at(2), '2026');
    await tester.enterText(find.byType(TextField).at(3), '1.6 테스트 파워트레인');
    await tester.enterText(find.byType(TextField).at(4), '검토 차량');
    await tester.ensureVisible(find.text('검토 요청 제출'));
    await tester.tap(find.text('검토 요청 제출'));
    await tester.pumpAndSettle();

    final userVehicles = await MockUserVehicleRepository().listUserVehicles();
    expect(
      userVehicles.where((item) => item.verificationStatus == 'pendingReview'),
      isNotEmpty,
    );
    expect(find.text('홈 이동 완료'), findsOneWidget);
  });

  testWidgets('CustomVehicleRequestScreen shows retryable save failure',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider
              .overrideWithValue(const _FailingVehicleCatalogRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(
            body: CustomVehicleRequestScreen(initialManufacturer: '현대'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.enterText(find.byType(TextField).at(1), '테스트 모델');
    await tester.enterText(find.byType(TextField).at(2), '2026');
    await tester.enterText(find.byType(TextField).at(3), '1.6 터보');
    await tester.ensureVisible(find.text('검토 요청 제출'));
    await tester.tap(find.text('검토 요청 제출'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('차량 검토 요청을 접수하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('HomeScreen vehicle empty state 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('ApexDriver'), findsWidgets);
    expect(find.text('아직 참가 중인 리그가 없어요'), findsWidgets);
    expect(find.text('차량 설정하기'), findsWidgets);
  });

  testWidgets('HomeScreen primary vehicle data 렌더링', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const HomeScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.textContaining('가솔린 준중형 리그'), findsWidgets);
    expect(find.text('주행 시작하기'), findsOneWidget);
  });

  testWidgets('MainShellScreen 홈 탭 본문이 함께 렌더링된다', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.binding.setSurfaceSize(const Size(1080, 1920));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const MainShellScreen(),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('홈'), findsWidgets);
    expect(find.textContaining('ApexDriver'), findsWidgets);
    expect(find.text('주행 시작하기'), findsOneWidget);
  });

  testWidgets('Core user routes render body content through app router',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const routes = [
      _RouteSmokeCase('/home', '주행 시작하기'),
      _RouteSmokeCase('/home?tab=battle', '새 배틀 만들기'),
      _RouteSmokeCase('/home?tab=ranking', '내 차량은'),
      _RouteSmokeCase('/home?tab=season', '일일 미션'),
      _RouteSmokeCase('/home?tab=profile', '대표 차량'),
      _RouteSmokeCase('/setup/vehicle', '제조사 검색'),
      _RouteSmokeCase('/drive/start', '주행 준비'),
      _RouteSmokeCase('/drive/history', '주행 기록'),
      _RouteSmokeCase('/drive/analysis/drive-001', '공개 제한'),
      _RouteSmokeCase('/ranking/detail', '상위 랭커'),
      _RouteSmokeCase('/battle/create', '현금 없이'),
      _RouteSmokeCase('/battle/detail/battle-001', '정산 기준'),
      _RouteSmokeCase('/battle/result/battle-001', '배틀 결과'),
      _RouteSmokeCase('/sponsor', '선택형 챌린지'),
      _RouteSmokeCase('/rewards', '보상은 지갑에'),
      _RouteSmokeCase('/stats', '숫자로 보는'),
      _RouteSmokeCase('/fairness', '점수는 공정하게'),
      _RouteSmokeCase('/settings', '권한과 데이터'),
      _RouteSmokeCase('/legal/terms', '연비 경쟁을 안전하고 공정하게'),
      _RouteSmokeCase('/legal/privacy', '필요한 데이터만 수집하고'),
      _RouteSmokeCase('/legal/location', '위치는 주행 검증에만'),
      _RouteSmokeCase('/legal/account-deletion', '삭제 요청은 운영 큐에서'),
      _RouteSmokeCase('/settings/vehicles', '차량 추가'),
      _RouteSmokeCase('/notifications', '전체 읽음 처리'),
      _RouteSmokeCase('/support', '문의 접수'),
      _RouteSmokeCase('/premium', '더 깊게 분석하고'),
    ];

    for (final route in routes) {
      resetMockFuelArenaState(withPrimaryVehicle: true);
      SharedPreferences.setMockInitialValues({});
      final router = createAppRouter(initialLocation: route.location);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(AppConfig.devMock()),
            restoredSessionProvider
                .overrideWith((ref) async => _sessionState()),
          ],
          child: MaterialApp.router(
            theme: ThemeData.dark(useMaterial3: true),
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull, reason: route.location);
      expect(
        find.textContaining(route.expectedText, findRichText: true),
        findsWidgets,
        reason: route.location,
      );

      router.dispose();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    }
  });

  testWidgets('Protected app routes require restored login session',
      (tester) async {
    final router = createAppRouter(initialLocation: '/drive/start');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          restoredSessionProvider
              .overrideWith((ref) async => _signedOutSessionState()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('로그인 필요'), findsOneWidget);
    expect(find.text('Google 로그인 후 이용할 수 있어요'), findsOneWidget);

    await tester.tap(find.text('로그인 화면으로 이동'));
    await tester.pumpAndSettle();

    expect(find.text('Google로 시작하기'), findsOneWidget);
  });

  testWidgets('Private app routes require completed consent', (tester) async {
    final router = createAppRouter(initialLocation: '/home');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          restoredSessionProvider
              .overrideWith((ref) async => _noConsentSessionState()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('필수 동의 필요'), findsOneWidget);
    expect(
      find.text('연비 경쟁을 시작하기 전에 필수 동의가 필요해요'),
      findsOneWidget,
    );
    expect(find.textContaining('주행 시작하기', findRichText: true), findsNothing);

    await tester.tap(find.text('동의 화면으로 이동'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/consent');
  });

  testWidgets(
      'Consent completion refreshes restored session before setup route',
      (tester) async {
    final authRepository = MockAuthRepository()
      ..debugSetProfile(mockProfile.copyWith(consentCompleted: false));
    final router = createAppRouter(initialLocation: '/consent');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(authRepository),
          consentRepositoryProvider.overrideWithValue(MockConsentRepository()),
          secureStorageServiceProvider
              .overrideWithValue(_MemorySecureStorageService()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('추가 설정으로 이동'));
    await tester.tap(find.text('추가 설정으로 이동'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/setup');
    expect(find.text('차량 설정하기'), findsOneWidget);
    expect(find.text('필수 동의 필요'), findsNothing);
  });

  testWidgets('Consent screen shows retryable save failure', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          consentRepositoryProvider
              .overrideWithValue(const _FailingConsentRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: ConsentScreen()),
        ),
      ),
    );

    await tester.ensureVisible(find.text('추가 설정으로 이동'));
    await tester.tap(find.text('추가 설정으로 이동'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(
      find.text('동의 저장을 완료하지 못했어요. 연결 상태를 확인하고 다시 시도해 주세요.'),
      findsOneWidget,
    );
    expect(find.text('다시 시도'), findsOneWidget);
  });

  testWidgets('Admin app routes require admin session', (tester) async {
    final router = createAppRouter(initialLocation: '/admin');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          restoredSessionProvider
              .overrideWith((ref) async => _nonAdminSessionState()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('관리자 권한 필요'), findsOneWidget);
    expect(find.text('운영 대시보드는 관리자만 이용할 수 있어요'), findsOneWidget);
    expect(find.textContaining('시스템 개요', findRichText: true), findsNothing);

    await tester.tap(find.text('홈으로 이동'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, '/home');
  });

  testWidgets('DriveResultScreen score display 렌더링', (tester) async {
    await _seedDriveResultSummary();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryVehicleProvider.overrideWith((ref) async => mockVehicle),
          driveRepositoryProvider.overrideWithValue(MockDriveRepository()),
          adsRepositoryProvider.overrideWithValue(MockAdsRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: DriveResultScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('랭킹 확인'), findsOneWidget);
  });

  testWidgets('DriveResultScreen resolves local drive session before finish',
      (tester) async {
    final queue = OfflineQueueService(localState: LocalStateService());
    await queue.rememberDriveSessionMapping(
      'local-drive-result-001',
      'server-drive-result-001',
    );
    final repository = _RecordingFinishDriveRepository();
    await _seedDriveResultSummary(sessionId: 'local-drive-result-001');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryVehicleProvider.overrideWith((ref) async => mockVehicle),
          driveRepositoryProvider.overrideWithValue(repository),
          adsRepositoryProvider.overrideWithValue(MockAdsRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(
            body: DriveResultScreen(sessionId: 'local-drive-result-001'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(repository.finishedSessionId, 'server-drive-result-001');
  });

  testWidgets(
      'DriveResultScreen missing local summary shows recovery without finish',
      (tester) async {
    final repository = _RecordingFinishDriveRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryVehicleProvider.overrideWith((ref) async => mockVehicle),
          driveRepositoryProvider.overrideWithValue(repository),
          adsRepositoryProvider.overrideWithValue(MockAdsRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(
            body: DriveResultScreen(sessionId: 'missing-local-summary-001'),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text('주행 결과 기록이 없어요'), findsOneWidget);
    expect(find.text('주행 시작하기'), findsOneWidget);
    expect(repository.finishedSessionId, isNull);
  });

  testWidgets('DriveResultScreen fits 390px mobile width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _seedDriveResultSummary();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryVehicleProvider.overrideWith((ref) async => mockVehicle),
          driveRepositoryProvider.overrideWithValue(MockDriveRepository()),
          adsRepositoryProvider.overrideWithValue(MockAdsRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: DriveResultScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));

    expect(tester.takeException(), isNull);
    expect(find.byType(DriveResultHeader), findsOneWidget);
  });

  testWidgets('DriveStartScreen readiness error shows retry state',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          primaryVehicleProvider.overrideWith((ref) async => mockVehicle),
          driveRepositoryProvider.overrideWithValue(_FailingDriveRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: DriveStartScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(find.text('일시적인 문제가 발생했어요'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);
    expect(find.byType(LoadingSkeletonView), findsNothing);
  });

  testWidgets('DriveHistoryScreen opens analysis route', (tester) async {
    final router = GoRouter(
      initialLocation: '/drive/history',
      routes: [
        GoRoute(
          path: '/drive/history',
          builder: (context, state) => const DriveHistoryScreen(),
        ),
        GoRoute(
          path: '/drive/analysis/:sessionId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('분석 화면 ${state.pathParameters['sessionId']}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.textContaining('최근 주행'), findsWidgets);

    await tester.tap(find.text('880 PTS'));
    await tester.pumpAndSettle();
    expect(find.text('분석 화면 drive-001'), findsOneWidget);
  });

  testWidgets('DriveAnalysisScreen links to review request', (tester) async {
    final router = GoRouter(
      initialLocation: '/drive/analysis/drive-002',
      routes: [
        GoRoute(
          path: '/drive/analysis/:sessionId',
          builder: (context, state) => DriveAnalysisScreen(
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/support/review-request/:driveId',
          builder: (context, state) => Scaffold(
            body: Center(
              child: Text('검토 요청 ${state.pathParameters['driveId']}'),
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('점수 분석'), findsOneWidget);

    await tester.ensureVisible(find.text('이 기록 검토 요청'));
    await tester.tap(find.text('이 기록 검토 요청'));
    await tester.pumpAndSettle();
    expect(find.text('검토 요청 drive-002'), findsOneWidget);
  });

  testWidgets('SafetyDriveScreen confirms finish inline without popup', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SafetyDriveScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('안전 모드'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.text('주행 종료'));
    await tester.pump();

    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('한 번 더 눌러 종료'), findsOneWidget);
    expect(find.textContaining('팝업 없이'), findsOneWidget);
  });

  testWidgets('RankingScreen list 렌더링', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const RankingScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('랭킹'), findsOneWidget);
    expect(find.textContaining('가솔린 리그'), findsWidgets);
  });

  testWidgets('RankingDetailScreen renders league detail and privacy copy',
      (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const RankingDetailScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('랭킹 상세'), findsOneWidget);
    expect(find.text('상위 랭커'), findsOneWidget);
    expect(find.text('내 주변 순위'), findsOneWidget);
    expect(find.textContaining('정확한 위치'), findsOneWidget);
  });

  testWidgets('BattleScreen vehicle empty state 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const BattleScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('차량 설정이 필요해요'), findsWidgets);
  });

  testWidgets('BattleScreen list 렌더링', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const BattleScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('새 배틀 만들기'), findsOneWidget);
    expect(find.textContaining('가솔린 준중형 리그'), findsWidgets);
  });

  testWidgets('Battle detail renders battle by id', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(
      _wrap(const BattleDetailScreen(battleId: 'battle-001')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(BattleCard), findsOneWidget);
    expect(find.text('VS'), findsOneWidget);
  });

  testWidgets('Battle result settles pending battle', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(
      _wrap(const BattleResultScreen(battleId: 'battle-001')),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('배틀 정산 요청'), findsOneWidget);
    await tester.tap(find.text('배틀 정산 요청'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('배틀 정산을 완료했어요.'), findsOneWidget);
    expect(find.text('복수전 신청'), findsOneWidget);
  });

  testWidgets('Battle detail missing id shows empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(const BattleDetailScreen(battleId: 'missing-battle')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('배틀 정보를 찾지 못했어요'), findsOneWidget);
  });

  testWidgets('Sponsor detail missing id shows empty state', (tester) async {
    await tester.pumpWidget(
      _wrap(const SponsorChallengeDetailScreen(challengeId: 'missing-sponsor')),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('챌린지를 찾을 수 없어요'), findsOneWidget);
  });

  testWidgets('CrewScreen crew summary and member contribution 렌더링',
      (tester) async {
    await tester.pumpWidget(_wrap(const CrewScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('크루 배틀 만들기'), findsOneWidget);
    expect(find.text('Neon Commuters'), findsOneWidget);
    expect(find.text('ApexDriver'), findsOneWidget);
    expect(find.textContaining('기여'), findsWidgets);
  });

  testWidgets('RivalScreen renders ranking based rivals', (tester) async {
    await tester.pumpWidget(_wrap(const RivalScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('내 위치'), findsOneWidget);
    expect(find.text('추월 목표'), findsOneWidget);
    expect(find.text('배틀 만들기'), findsOneWidget);
  });

  testWidgets('SeasonScreen mission display 렌더링', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const SeasonScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('시즌패스 보상 트랙'), findsOneWidget);
  });

  testWidgets('PremiumScreen benefit display 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const PremiumScreen()));
    await tester.pumpAndSettle();
    expect(find.text('프리미엄'), findsWidgets);
    expect(find.text('Fuel Arena 프리미엄'), findsOneWidget);
    expect(find.text('Fuel Arena 프리미엄 연간'), findsOneWidget);
    expect(find.text('Fuel Arena 시즌패스'), findsOneWidget);
    expect(find.text('Fuel Arena 프리미엄 번들'), findsOneWidget);
    expect(find.text('프리미엄 시작하기'), findsNWidgets(2));
    expect(find.text('시즌패스 시작하기'), findsOneWidget);
    expect(find.text('번들 시작하기'), findsOneWidget);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('Premium and safety badges use Korean product labels',
      (tester) async {
    await tester.pumpWidget(_wrap(Column(
      children: [
        const SafetyModePanel(),
        LockedPremiumCard(
          title: '고급 분석 잠금',
          description: '프리미엄으로 세부 기록을 확인하세요.',
          onTap: () {},
        ),
      ],
    )));

    expect(find.text('안전 모드'), findsOneWidget);
    expect(find.text('프리미엄'), findsOneWidget);
    expect(find.text('Safety Mode'), findsNothing);
    expect(find.text('Premium'), findsNothing);
  });

  testWidgets('StatsScreen user metrics 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const StatsScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('고급 통계'), findsOneWidget);
    expect(find.text('평균 연비'), findsOneWidget);
    expect(find.text('검증 주행'), findsOneWidget);
  });

  testWidgets('StatsScreen empty state starts first drive', (tester) async {
    final router = GoRouter(
      initialLocation: '/stats',
      routes: [
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsScreen(),
        ),
        GoRoute(
          path: '/drive/start',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('주행 시작 화면')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statsRepositoryProvider.overrideWithValue(_EmptyStatsRepository()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('주행 기록이 아직 없어요'), findsOneWidget);

    await tester.tap(find.text('첫 주행 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('주행 시작 화면'), findsOneWidget);
  });

  testWidgets('RewardWalletScreen empty coupons links to reward ad',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/rewards',
      routes: [
        GoRoute(
          path: '/rewards',
          builder: (context, state) => const RewardWalletScreen(),
        ),
        GoRoute(
          path: '/ads/reward',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('리워드 광고 화면')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          couponRepositoryProvider.overrideWithValue(_EmptyCouponRepository()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('사용 가능한 쿠폰이 없어요'), findsOneWidget);

    await tester.tap(find.text('리워드 광고 보기'));
    await tester.pumpAndSettle();
    expect(find.text('리워드 광고 화면'), findsOneWidget);
  });

  testWidgets('RewardWalletScreen issues selected coupon', (tester) async {
    final repository = _RecordingCouponRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          couponRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: RewardWalletScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('쿠폰 받기'), findsWidgets);

    await tester.tap(find.text('쿠폰 받기').first);
    await tester.pumpAndSettle();

    expect(repository.issuedCouponIds, contains(mockCoupons.first.id));
    expect(find.text('발급 완료'), findsOneWidget);
  });

  testWidgets('RewardWalletScreen blocks coupon issuing on remote config error',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRemoteConfigRepositoryProvider
              .overrideWithValue(_FailingRemoteConfigRepository()),
          couponRepositoryProvider.overrideWithValue(
            _RecordingCouponRepository(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: RewardWalletScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('쿠폰 운영 설정을 불러오지 못했어요.'), findsOneWidget);
    expect(find.text('쿠폰 받기'), findsNothing);
  });

  testWidgets('SponsorChallengeScreen empty state starts drive',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/sponsor',
      routes: [
        GoRoute(
          path: '/sponsor',
          builder: (context, state) => const SponsorChallengeScreen(),
        ),
        GoRoute(
          path: '/drive/start',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('스폰서 주행 시작')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sponsorRepositoryProvider.overrideWithValue(
            _EmptySponsorRepository(),
          ),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('참여 가능한 챌린지가 없어요'), findsOneWidget);

    await tester.tap(find.text('주행 시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('스폰서 주행 시작'), findsOneWidget);
  });

  testWidgets('PremiumScreen empty plans shows support CTA', (tester) async {
    final router = GoRouter(
      initialLocation: '/premium',
      routes: [
        GoRoute(
          path: '/premium',
          builder: (context, state) => const PremiumScreen(),
        ),
        GoRoute(
          path: '/support/contact',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('고객지원 문의 화면')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          premiumRepositoryProvider
              .overrideWithValue(_EmptyPremiumRepository()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('요금제를 확인할 수 없어요'), findsOneWidget);

    await tester.tap(find.text('고객지원 문의'));
    await tester.pumpAndSettle();
    expect(find.text('고객지원 문의 화면'), findsOneWidget);
  });

  testWidgets('ProfileScreen badges and achievements 렌더링', (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const ProfileScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('프로필'), findsOneWidget);
    expect(find.text('대표 배지'), findsOneWidget);
    expect(find.text('업적'), findsOneWidget);
    expect(find.text('로그아웃'), findsOneWidget);
    expect(find.text('Google 계정 세션'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Google 계정 세션')).dy,
      lessThan(tester.getTopLeft(find.text('대표 차량')).dy),
    );
  });

  testWidgets('ProfileScreen signs out and returns to Google login',
      (tester) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    final authRepository = _RecordingGoogleAuthRepository(
      mockProfile.copyWith(
        consentCompleted: true,
        vehicleSetupCompleted: true,
      ),
      initialUser: mockProfile.copyWith(
        consentCompleted: true,
        vehicleSetupCompleted: true,
      ),
    );
    final router = createAppRouter(initialLocation: '/home?tab=profile');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.devMock()),
          authRepositoryProvider.overrideWithValue(authRepository),
          restoredSessionProvider.overrideWith((ref) async => _sessionState()),
          secureStorageServiceProvider
              .overrideWithValue(_MemorySecureStorageService()),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logoutButton = find.byIcon(Icons.logout_rounded);
    await tester.ensureVisible(logoutButton);
    await tester.tap(logoutButton);
    await tester.pumpAndSettle();

    expect(authRepository.signedOut, isTrue);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('OtherUserProfileScreen renders public ranking profile',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const OtherUserProfileScreen(userId: 'user-nightcruise')),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('공개 프로필'), findsOneWidget);
    expect(find.text('NightCruise'), findsOneWidget);
    expect(find.text('공개 제한'), findsOneWidget);
    expect(find.textContaining('원본 주행 포인트'), findsOneWidget);
  });

  testWidgets('OtherUserProfileScreen missing user shows recovery',
      (tester) async {
    await tester.pumpWidget(
      _wrap(const OtherUserProfileScreen(userId: 'missing-user')),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('공개 프로필을 찾을 수 없어요'), findsOneWidget);
    expect(find.text('랭킹으로 돌아가기'), findsOneWidget);
  });

  testWidgets(
      'OtherUserProfileScreen back falls back to ranking tab on deep link',
      (tester) async {
    final router = GoRouter(
      initialLocation: '/profile/user-nightcruise',
      routes: [
        GoRoute(
          path: '/profile/:userId',
          builder: (context, state) => OtherUserProfileScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => Text(
            '랭킹 복구 화면 ${state.uri.queryParameters['tab'] ?? ''}',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('공개 프로필'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('랭킹 복구 화면 ranking'), findsOneWidget);
  });

  testWidgets('NotificationsScreen read actions and held state 렌더링',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restoredSessionProvider.overrideWith((ref) async => _sessionState()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: NotificationsScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('알림'), findsOneWidget);
    expect(find.text('전체 읽음 처리'), findsOneWidget);
    expect(find.textContaining('주행 중 보류됨'), findsWidgets);
  });

  testWidgets('NotificationsScreen opens target route and marks read',
      (tester) async {
    final repository = _RecordingNotificationRepository([
      NotificationItem(
        id: 'notification-open-001',
        title: '테스트 알림',
        body: '배틀 결과가 확정됐어요.',
        createdAt: DateTime(2026),
        isRead: false,
        notificationType: 'battle_result',
        targetRoute: '/target',
      ),
    ]);
    final analytics = _RecordingAnalyticsRepository();
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/target',
          builder: (context, state) => const Scaffold(
            body: Text('도착 화면'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restoredSessionProvider.overrideWith((ref) async => _sessionState()),
          notificationRepositoryProvider.overrideWithValue(repository),
          analyticsRepositoryProvider.overrideWithValue(analytics),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('테스트 알림'));
    await tester.pumpAndSettle();

    expect(repository.readIds, contains('notification-open-001'));
    expect(find.text('도착 화면'), findsOneWidget);
    expect(
      analytics.events,
      contains(
        allOf(
          containsPair('event', 'notification_opened'),
          containsPair('notification_type', 'battle_result'),
          containsPair('target_route', '/target'),
        ),
      ),
    );
  });

  testWidgets('NotificationsScreen hides notifications during active drive',
      (tester) async {
    final repository = _RecordingNotificationRepository([
      NotificationItem(
        id: 'notification-held-001',
        title: '숨겨야 하는 알림',
        body: '주행 중에는 표시하지 않습니다.',
        createdAt: DateTime(2026),
        isRead: false,
        targetRoute: '/target',
      ),
    ]);
    final router = GoRouter(
      initialLocation: '/notifications',
      routes: [
        GoRoute(
          path: '/notifications',
          builder: (context, state) => const NotificationsScreen(),
        ),
        GoRoute(
          path: '/drive/safety',
          builder: (context, state) => const Scaffold(
            body: Text('주행 화면'),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          restoredSessionProvider.overrideWith(
            (ref) async => _sessionState(activeDriveSessionId: 'drive-777'),
          ),
          notificationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          theme: ThemeData.dark(useMaterial3: true),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('주행 중에는 알림을 표시하지 않아요'), findsOneWidget);
    expect(find.text('숨겨야 하는 알림'), findsNothing);
    expect(repository.readIds, isEmpty);

    await tester.tap(find.text('주행 화면으로 돌아가기'));
    await tester.pumpAndSettle();
    expect(find.text('주행 화면'), findsOneWidget);
  });

  testWidgets('SettingsScreen shows privacy and support entries',
      (tester) async {
    await tester.pumpWidget(_wrap(const SettingsScreen()));
    await tester.pump();
    expect(find.text('설정'), findsOneWidget);
    expect(find.text('권한과 데이터'), findsOneWidget);
    expect(find.text('고객지원과 신고'), findsOneWidget);
  });

  testWidgets('PrivacySettingsScreen creates data request', (tester) async {
    await tester.pumpWidget(_wrap(const PrivacySettingsScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('데이터와 동의 관리'), findsOneWidget);
    expect(find.text('요청 내역'), findsOneWidget);
    expect(find.text('동의 철회 요청'), findsOneWidget);

    await tester.tap(find.text('요청').first);
    await tester.pumpAndSettle();
    expect(find.text('데이터 다운로드'), findsOneWidget);

    await tester.tap(find.text('요청 접수'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('개인정보 요청을 접수했어요.'), findsOneWidget);
    expect(find.text('데이터 다운로드'), findsOneWidget);
    expect(find.text('접수'), findsWidgets);
  });

  testWidgets('PrivacySettingsScreen blocks duplicate active privacy request',
      (tester) async {
    final repository = MockPrivacyRequestRepository();
    await repository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'data_download',
        description: '내 계정 데이터 다운로드를 요청합니다.',
      ),
    );

    await tester.pumpWidget(_wrap(const PrivacySettingsScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('이미 접수된 요청이 진행 중입니다.'), findsOneWidget);
    expect(find.text('진행 중'), findsOneWidget);

    await tester.tap(find.text('진행 중'));
    await tester.pumpAndSettle();

    expect(
      find.text('이미 진행 중인 개인정보 요청이 있어요. 요청 내역에서 상태를 확인해 주세요.'),
      findsOneWidget,
    );
    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.debugRequests, hasLength(1));
  });

  testWidgets('PrivacySettingsScreen requires account deletion confirmation',
      (tester) async {
    await tester.pumpWidget(_wrap(const PrivacySettingsScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('계정 삭제 요청'));
    await tester.tap(find.text('요청').at(2));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('계정 삭제'),
      ),
      findsWidgets,
    );
    expect(find.text('계속하려면 확인 문구를 직접 입력해 주세요.'), findsOneWidget);
    expect(find.text('계정 삭제 요청 접수'), findsOneWidget);

    await tester.tap(find.text('계정 삭제 요청 접수'));
    await tester.pumpAndSettle();

    expect(find.textContaining('정확히 "계정 삭제"'), findsOneWidget);
    expect(MockPrivacyRequestRepository().debugRequests, isEmpty);

    await tester.enterText(find.byType(TextFormField).last, '계정 삭제');
    await tester.tap(find.text('계정 삭제 요청 접수'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    final requests = MockPrivacyRequestRepository().debugRequests;
    expect(requests, hasLength(1));
    expect(requests.single.requestType, 'account_deletion');
    expect(find.text('개인정보 요청을 접수했어요.'), findsOneWidget);
  });

  testWidgets('AdsSettingsScreen saves consent preference', (tester) async {
    await tester.pumpWidget(_wrap(const AdsSettingsScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('맞춤형 광고 동의'), findsOneWidget);

    await tester.tap(find.text('맞춤형 광고 동의'));
    await tester.pumpAndSettle();

    expect(find.text('광고 동의 설정을 저장했어요.'), findsOneWidget);
  });

  testWidgets('SafetyModeSettingsScreen locks driving safeguards', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const SafetyModeSettingsScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('주행 중 알림 보류'), findsOneWidget);
    expect(find.text('주행 중 광고 차단'), findsOneWidget);

    await tester.ensureVisible(find.text('종료 버튼 확인 단계'));
    await tester.tap(find.text('종료 버튼 확인 단계'));
    await tester.pumpAndSettle();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('safety_confirm_end'), isFalse);
  });

  testWidgets('VehicleManagementScreen deletes representative vehicle', (
    tester,
  ) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const VehicleManagementScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.widgetWithText(OutlinedButton, '삭제').first);
    await tester.tap(find.widgetWithText(OutlinedButton, '삭제').first);
    await tester.pumpAndSettle();
    expect(find.text('차량을 삭제할까요?'), findsOneWidget);

    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('삭제'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('대표 차량이 없어요'), findsOneWidget);
    expect(find.textContaining('차량을 삭제했어요'), findsOneWidget);
  });

  testWidgets('VehicleManagementScreen changes representative vehicle', (
    tester,
  ) async {
    resetMockFuelArenaState(withPrimaryVehicle: true);
    await tester.pumpWidget(_wrap(const VehicleManagementScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('대표 지정').first);
    await tester.tap(find.text('대표 지정').first);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('대표 차량을 변경했어요'), findsOneWidget);
  });

  testWidgets('HelpCenterScreen support entry 렌더링', (tester) async {
    await tester.pumpWidget(_wrap(const HelpCenterScreen()));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('고객지원'), findsOneWidget);
    expect(find.text('문의 접수'), findsOneWidget);
    expect(find.text('자주 묻는 질문'), findsOneWidget);
    expect(find.text('FAQ 보기'), findsNothing);
    expect(find.text('내 문의'), findsOneWidget);
  });

  testWidgets('FAQScreen renders recovery actions', (tester) async {
    await tester.pumpWidget(_wrap(const FAQScreen()));
    await tester.pump();

    expect(find.text('자주 묻는 질문'), findsWidgets);
    expect(find.text('FAQ'), findsNothing);
    expect(find.text('검토 요청하기'), findsOneWidget);
    expect(find.text('쿠폰 문제로 문의'), findsOneWidget);
    expect(find.text('새 문의 접수'), findsOneWidget);
  });

  testWidgets('FAQScreen opens support contact with category', (tester) async {
    final router = GoRouter(
      initialLocation: '/support/faq',
      routes: [
        GoRoute(
          path: '/support/faq',
          builder: (context, state) => const FAQScreen(),
        ),
        GoRoute(
          path: '/support/contact',
          builder: (context, state) => ContactSupportScreen(
            initialCategory:
                state.uri.queryParameters['category'] ?? '주행 기록 문제',
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('쿠폰 문제로 문의'));
    await tester.tap(find.text('쿠폰 문제로 문의'));
    await tester.pumpAndSettle();

    expect(find.text('문의 접수'), findsOneWidget);
    expect(find.text('쿠폰 문제'), findsOneWidget);
  });

  testWidgets('ReportDriveRecordScreen keeps target drive id 렌더링',
      (tester) async {
    await tester
        .pumpWidget(_wrap(const ReportDriveRecordScreen(driveId: 'drive-001')));
    await tester.pump();
    expect(find.textContaining('주행 기록 신고'), findsOneWidget);
    expect(find.textContaining('drive-001'), findsOneWidget);
    expect(find.text('접수하기'), findsOneWidget);
  });

  testWidgets('ReviewRequestScreen submits ticket and report queue item', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: '/review',
      routes: [
        GoRoute(
          path: '/review',
          builder: (context, state) =>
              const ReviewRequestScreen(driveId: 'drive-review-001'),
        ),
        GoRoute(
          path: '/support/ticket/:ticketId',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('검토 요청 접수 완료')),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(_wrapRouter(router));
    await tester.pump();

    expect(find.text('검토 요청'), findsOneWidget);
    expect(find.textContaining('drive-review-001'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).at(1),
      '검증 보류 상태가 오래 유지되어 랭킹 반영 기준을 확인하고 싶습니다.',
    );
    await tester.ensureVisible(find.text('검토 요청 제출'));
    await tester.tap(find.text('검토 요청 제출'));
    await tester.pumpAndSettle();

    expect(find.text('검토 요청 접수 완료'), findsOneWidget);
    expect(
      MockReportRepository()
          .debugReports
          .where((item) => item.targetType == 'drive_review_request'),
      isNotEmpty,
    );
  });

  testWidgets('SupportTicketDetailScreen renders admin reply', (tester) async {
    final repository = MockSupportRepository();
    final ticket = await repository.createSupportTicket(
      category: '주행 기록 문제',
      title: '점수 확인 요청',
      description: '주행 결과 점수가 평소보다 낮게 표시되어 확인이 필요합니다.',
    );
    await repository.addMessage(
      ticket.id,
      '기록을 검토했고 GPS 품질 문제는 확인되지 않았습니다.',
      isAdminReply: true,
    );

    await tester.pumpWidget(_wrap(SupportTicketDetailScreen(
      ticketId: ticket.id,
    )));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('문의 상세'), findsOneWidget);
    expect(find.text('점수 확인 요청'), findsOneWidget);
    expect(find.text('운영자 답변'), findsOneWidget);
    expect(find.textContaining('GPS 품질 문제'), findsOneWidget);
  });

  testWidgets('AdminVehicleCatalogScreen catalog management 렌더링',
      (tester) async {
    await tester.pumpWidget(_wrap(const AdminVehicleCatalogScreen()));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(find.text('차량 카탈로그 운영'), findsOneWidget);
    expect(find.text('운영 카탈로그'), findsOneWidget);
    expect(find.text('Admin Catalog'), findsNothing);
    expect(find.text('제조사 검색'), findsOneWidget);
    expect(find.text('CSV 가져오기'), findsOneWidget);
  });

  testWidgets('AdminVehicleCatalogScreen renders custom vehicle review queue',
      (tester) async {
    final repository = const MockVehicleCatalogRepository();
    final vehicle =
        (await tester.runAsync(() => repository.createCustomVehicleRequest(
              manufacturer: '기타',
              modelName: '테스트 모델',
              year: 2026,
              trimName: '1.6 터보',
              fuelType: '가솔린',
              vehicleClass: '준중형',
              memo: '관리자 검수 테스트',
            )))!;
    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vehicleCatalogRepositoryProvider.overrideWithValue(repository),
          profileRepositoryProvider.overrideWithValue(MockProfileRepository()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(useMaterial3: true),
          home: const Scaffold(body: AdminVehicleCatalogScreen()),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(find.textContaining('관리자 검수 테스트'), findsOneWidget);
    expect(find.textContaining(vehicle.id), findsWidgets);
    expect(find.text('승인'), findsOneWidget);
    expect(find.text('반려'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen records admin action', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const AdminDashboardScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('관리자'), findsWidgets);
    expect(find.text('운영 대시보드'), findsOneWidget);
    expect(find.text('시스템 개요'), findsWidgets);
    expect(find.text('ADMIN'), findsNothing);
    expect(find.text('Operations Dashboard'), findsNothing);
    expect(find.text('System Overview'), findsNothing);

    await tester.tap(find.byTooltip('운영 액션').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('상태 변경').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('운영 로그에 기록'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen updates privacy request status',
      (tester) async {
    final privacyRepository = MockPrivacyRequestRepository();
    final request = await privacyRepository.createRequest(
      const PrivacyRequestSubmission(
        requestType: 'account_deletion',
        description: 'Fuel Arena 계정 삭제와 탈퇴 처리를 요청합니다.',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const AdminDashboardScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('개인정보 요청').first);
    await tester.pumpAndSettle();

    expect(find.text('계정 삭제'), findsOneWidget);
    expect(find.text(request.id), findsOneWidget);

    await tester.tap(find.byTooltip('운영 액션').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토 시작'));
    await tester.pumpAndSettle();

    expect(privacyRepository.debugRequests.single.status, 'review');
    expect(find.textContaining('검토 시작 작업을 완료했어요'), findsOneWidget);

    await tester.tap(find.byTooltip('운영 액션').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('보류 처리'));
    await tester.pumpAndSettle();

    expect(privacyRepository.debugRequests.single.status, 'rejected');
  });

  testWidgets('AdminDashboardScreen resolves report queue item',
      (tester) async {
    final reportRepository = MockReportRepository();
    final report = await reportRepository.createReport(
      const ReportRequest(
        targetType: 'drive_review_request',
        targetId: 'drive-review-admin-001',
        reason: '랭킹 반영 기준 검토가 필요합니다.',
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1440, 1800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(_wrap(const AdminDashboardScreen()));
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('신고/이의제기').first);
    await tester.pumpAndSettle();

    expect(find.text('주행 기록 이의제기'), findsOneWidget);
    expect(find.text(report.id), findsOneWidget);

    await tester.tap(find.byTooltip('운영 액션').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('검토 완료'));
    await tester.pumpAndSettle();

    expect(reportRepository.debugReports.single.status, 'resolved');
    expect(find.textContaining('검토 완료 작업을 완료했어요'), findsOneWidget);
  });

  Future<void> pumpMobileShellAtWidth(
    WidgetTester tester,
    double width, {
    Key key = const ValueKey('mobile-child'),
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MobileViewportShell(
            child: SizedBox(key: key, width: double.infinity, height: 80),
          ),
        ),
      ),
    );
  }

  testWidgets('MobileViewportShell keeps 390px design width', (tester) async {
    const key = ValueKey('mobile-390-child');
    await pumpMobileShellAtWidth(tester, AppScaffold.mobileDesignWidth,
        key: key);
    expect(
      tester.getSize(find.byKey(key)).width,
      AppScaffold.mobileDesignWidth,
    );
  });

  testWidgets('MobileViewportShell keeps 430px max width', (tester) async {
    const key = ValueKey('mobile-430-child');
    await pumpMobileShellAtWidth(tester, AppScaffold.mobileMaxWidth, key: key);
    expect(tester.getSize(find.byKey(key)).width, AppScaffold.mobileMaxWidth);
  });

  testWidgets('MobileViewportShell caps desktop preview width', (tester) async {
    const key = ValueKey('mobile-desktop-child');
    await pumpMobileShellAtWidth(tester, 1920, key: key);
    expect(tester.getSize(find.byKey(key)).width, AppScaffold.mobileMaxWidth);
  });

  testWidgets('AppScaffold limits body, app bar and bottom bar on desktop',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1920, 1080));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const bodyKey = ValueKey('limited-body');
    const appBarKey = ValueKey('limited-app-bar');
    const bottomKey = ValueKey('limited-bottom-bar');

    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(
          scrollable: false,
          padding: EdgeInsets.zero,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: SizedBox(
              key: appBarKey,
              width: double.infinity,
              height: 56,
            ),
          ),
          bottomNavigationBar: SizedBox(
            key: bottomKey,
            width: double.infinity,
            height: 64,
          ),
          child: SizedBox(
            key: bodyKey,
            width: double.infinity,
            height: 80,
          ),
        ),
      ),
    );

    expect(
        tester.getSize(find.byKey(bodyKey)).width, AppScaffold.mobileMaxWidth);
    expect(tester.getSize(find.byKey(appBarKey)).width,
        AppScaffold.mobileMaxWidth);
    expect(tester.getSize(find.byKey(bottomKey)).width,
        AppScaffold.mobileMaxWidth);
  });

  testWidgets('AppScaffold uses viewport width below mobile max',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(356, 744));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const bodyKey = ValueKey('narrow-body');
    const appBarKey = ValueKey('narrow-app-bar');
    const bottomKey = ValueKey('narrow-bottom-bar');

    await tester.pumpWidget(
      const MaterialApp(
        home: AppScaffold(
          scrollable: false,
          padding: EdgeInsets.zero,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(56),
            child: SizedBox(
              key: appBarKey,
              width: double.infinity,
              height: 56,
            ),
          ),
          bottomNavigationBar: SizedBox(
            key: bottomKey,
            width: double.infinity,
            height: 64,
          ),
          child: SizedBox(
            key: bodyKey,
            width: double.infinity,
            height: 80,
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byKey(bodyKey)).width, 356);
    expect(tester.getSize(find.byKey(appBarKey)).width, 356);
    expect(tester.getSize(find.byKey(bottomKey)).width, 356);
  });

  testWidgets('MainBottomNavigation keeps all tabs visible on narrow mobile',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(356, 744));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(
          bottomNavigationBar: MainBottomNavigation(
            currentIndex: 4,
            onTap: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final label in ['홈', '배틀', '랭킹', '시즌', '프로필']) {
      expect(find.text(label), findsOneWidget);
      final rect = tester.getRect(find.text(label));
      expect(rect.left, greaterThanOrEqualTo(0));
      expect(rect.right, lessThanOrEqualTo(356));
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('AdminViewportShell keeps desktop work width on small viewport',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('admin-child');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminViewportShell(
            child: SizedBox(key: key, width: double.infinity, height: 80),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(key)).width, AppScaffold.adminMinWidth);
  });

  testWidgets('AdminViewportShell uses full desktop width', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const key = ValueKey('admin-desktop-child');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AdminViewportShell(
            child: SizedBox(key: key, width: double.infinity, height: 80),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byKey(key)).width, 1440);
  });
}

class _EmptyStatsRepository implements StatsRepository {
  @override
  Future<List<AdminMetric>> getUserStats() async => const [];
}

class _RecordingFinishDriveRepository extends MockDriveRepository {
  String? finishedSessionId;

  @override
  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) {
    finishedSessionId = sessionId;
    return super.finishDriveSession(
      sessionId: sessionId,
      distanceKm: distanceKm,
      duration: duration,
      averageEfficiency: averageEfficiency,
      fuelUsedLiters: fuelUsedLiters,
    );
  }
}

class _FailingDriveRepository implements DriveRepository {
  @override
  Future<Vehicle> getRepresentativeVehicle() async {
    throw StateError('drive readiness unavailable');
  }

  @override
  Future<SeasonMission> getTodayMission() async {
    throw StateError('mission unavailable');
  }

  @override
  Future<DriveSession> startDriveSession() async {
    throw StateError('drive session unavailable');
  }

  @override
  Future<DriveSession> uploadQueuedDriveSession(DriveSession session) async {
    throw StateError('queued drive session unavailable');
  }

  @override
  Future<void> recordDrivePoints(List<DrivePoint> points) async {
    throw StateError('drive point upload unavailable');
  }

  @override
  Future<List<DriveSession>> listDriveSessions({int limit = 20}) async {
    throw StateError('drive sessions unavailable');
  }

  @override
  Future<List<DriveScore>> listDriveScores({int limit = 20}) async {
    throw StateError('drive scores unavailable');
  }

  @override
  Future<DriveScore> finishDriveSession({
    String? sessionId,
    double? distanceKm,
    Duration? duration,
    double? averageEfficiency,
    double? fuelUsedLiters,
  }) async {
    throw StateError('drive finish unavailable');
  }
}

class _FailingUserVehicleRepository extends MockUserVehicleRepository {
  @override
  Future<UserVehicle> addUserVehicleFromVariant(
    String variantId,
    String nickname,
    bool isPrimary,
  ) async {
    throw StateError('vehicle save unavailable');
  }
}

class _FailingVehicleCatalogRepository extends MockVehicleCatalogRepository {
  const _FailingVehicleCatalogRepository();

  @override
  Future<UserVehicle> createCustomVehicleRequest({
    required String manufacturer,
    required String modelName,
    required int year,
    required String trimName,
    required String fuelType,
    required String vehicleClass,
    String nickname = '',
    String memo = '',
  }) async {
    throw StateError('custom vehicle save unavailable');
  }
}

class _EmptyCouponRepository implements CouponRepository {
  @override
  Future<UserCoupon> issueCoupon(String couponId) async => UserCoupon(
        id: 'empty-user-coupon',
        userId: mockProfile.id,
        couponId: couponId,
        status: 'issued',
        issuedAt: DateTime(2026),
      );

  @override
  Future<List<Coupon>> listCoupons() async => const [];
}

class _FailingConsentRepository implements ConsentRepository {
  const _FailingConsentRepository();

  @override
  Future<AppConsent> getConsent() async => AppConsent(
        userId: mockProfile.id,
        termsAccepted: false,
        privacyAccepted: false,
        locationAccepted: false,
        personalizedAdsAccepted: false,
        marketingAccepted: false,
        updatedAt: DateTime(2026),
      );

  @override
  Future<AppConsent> saveConsent({
    required bool termsAccepted,
    required bool privacyAccepted,
    required bool locationAccepted,
    required bool personalizedAdsAccepted,
    required bool marketingAccepted,
  }) async {
    throw StateError('consent save unavailable');
  }
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

RestoredSessionState _sessionState({
  String activeDriveSessionId = '',
  UserProfile? user,
}) {
  return RestoredSessionState(
    user: user ?? mockProfile,
    onboardingCompleted: true,
    consentCompleted: true,
    vehicleSetupCompleted: true,
    activeDriveSessionId: activeDriveSessionId,
    recentRankingFilter: '내 리그',
    recentPrimaryVehicleId: mockVehicle.id,
  );
}

RestoredSessionState _nonAdminSessionState() {
  return _sessionState(user: mockProfile.copyWith(isAdmin: false));
}

RestoredSessionState _noConsentSessionState() {
  return RestoredSessionState(
    user: mockProfile.copyWith(consentCompleted: false),
    onboardingCompleted: true,
    consentCompleted: false,
    vehicleSetupCompleted: false,
    activeDriveSessionId: '',
    recentRankingFilter: '',
    recentPrimaryVehicleId: '',
  );
}

RestoredSessionState _signedOutSessionState() {
  return const RestoredSessionState(
    user: null,
    onboardingCompleted: true,
    consentCompleted: false,
    vehicleSetupCompleted: false,
    activeDriveSessionId: '',
    recentRankingFilter: '',
    recentPrimaryVehicleId: '',
  );
}

class _RecordingNotificationRepository implements NotificationRepository {
  _RecordingNotificationRepository(List<NotificationItem> items)
      : _items = items;

  var _items = <NotificationItem>[];
  final readIds = <String>[];
  var allRead = false;

  @override
  Future<List<NotificationItem>> listNotifications() async => _items;

  @override
  Future<void> markAllRead() async {
    allRead = true;
    _items = _items.map((item) => item.copyWith(isRead: true)).toList();
  }

  @override
  Future<void> markRead(String notificationId) async {
    readIds.add(notificationId);
    _items = _items
        .map((item) =>
            item.id == notificationId ? item.copyWith(isRead: true) : item)
        .toList();
  }
}

class _RecordingAnalyticsRepository implements AnalyticsRepository {
  final events = <Map<String, Object?>>[];

  @override
  Future<void> identify(
    String userId, {
    Map<String, Object?> properties = const {},
  }) async {
    events.add({'event': 'identify', 'user_id': userId, ...properties});
  }

  @override
  Future<void> setUserProperty(String key, Object? value) async {
    events.add({'event': 'set_user_property', 'key': key, 'value': value});
  }

  @override
  Future<void> track(
    String eventName, {
    Map<String, Object?> properties = const {},
  }) async {
    events.add({'event': eventName, ...properties});
  }
}

class _RecordingCouponRepository implements CouponRepository {
  final issuedCouponIds = <String>[];

  @override
  Future<UserCoupon> issueCoupon(String couponId) async {
    issuedCouponIds.add(couponId);
    return UserCoupon(
      id: 'issued-$couponId',
      userId: mockProfile.id,
      couponId: couponId,
      status: 'issued',
      issuedAt: DateTime(2026),
    );
  }

  @override
  Future<List<Coupon>> listCoupons() async => mockCoupons.take(1).toList();
}

class _FailingRemoteConfigRepository implements AppRemoteConfigRepository {
  @override
  Future<AppRemoteConfig> getConfig() async {
    throw StateError('remote config unavailable');
  }
}

class _EmptySponsorRepository implements SponsorRepository {
  @override
  Future<List<SponsorChallenge>> getChallenges() async => const [];
}

class _EmptyPremiumRepository implements PremiumRepository {
  @override
  Future<List<SubscriptionPlan>> getPlans() async => const [];
}
