import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fuel_arena/app/app_config.dart';
import 'package:fuel_arena/app/bootstrap.dart';
import 'package:fuel_arena/app/fuel_arena_app.dart';
import 'package:fuel_arena/features/splash/presentation/splash_screen.dart';
import 'package:fuel_arena/shared/providers/repository_providers.dart';
import 'package:fuel_arena/shared/repositories/fuel_arena_repositories.dart';
import 'package:fuel_arena/shared/services/app_services.dart';

void main() {
  testWidgets('Fuel Arena app starts at splash screen', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FuelArenaApp(
          bootstrap: BootstrapResult(
            config: AppConfig.devMock(),
            supabaseInitialized: false,
            configurationError: null,
          ),
        ),
      ),
    );

    expect(find.text('FUEL ARENA'), findsOneWidget);
    expect(find.text('연비로 증명해'), findsOneWidget);
  });

  testWidgets('Fuel Arena app shows production configuration error', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FuelArenaApp(
          bootstrap: BootstrapResult(
            config: AppConfig(
              environment: AppEnvironment.production,
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
            ),
            supabaseInitialized: false,
            configurationError:
                'production 모드에서는 SUPABASE_URL과 SUPABASE_ANON_KEY가 필요합니다.',
          ),
        ),
      ),
    );

    expect(find.text('설정 오류'), findsOneWidget);
    expect(find.text('앱을 시작할 수 없어요'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsOneWidget);
    expect(find.textContaining('운영/스테이징 빌드'), findsOneWidget);
    expect(find.textContaining('개발 모드는 Supabase 없이'), findsNothing);
  });

  testWidgets('SplashScreen shows retry when session restore fails', (
    tester,
  ) async {
    final service = _FailingRestoreSessionService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionServiceProvider.overrideWithValue(service),
        ],
        child: const MaterialApp(home: SplashScreen()),
      ),
    );

    await tester.pump(const Duration(milliseconds: 1300));
    await tester.pump();

    expect(service.attempts, 1);
    expect(find.text('앱 시작 상태를 확인하지 못했어요.'), findsOneWidget);
    expect(find.text('다시 시도'), findsOneWidget);

    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    expect(service.attempts, 2);
  });
}

class _FailingRestoreSessionService extends AppSessionService {
  _FailingRestoreSessionService()
      : super(
          authRepository: MockAuthRepository(),
          localState: LocalStateService(),
          secureStorage: SecureStorageService(),
        );

  var attempts = 0;

  @override
  Future<RestoredSessionState> restore() async {
    attempts += 1;
    throw StateError('session restore unavailable');
  }
}
