import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fuel_arena/app/app_config.dart';
import 'package:fuel_arena/features/auth/presentation/login_screen.dart';
import 'package:fuel_arena/features/auth/presentation/auth_diagnostics_screen.dart';
import 'package:fuel_arena/shared/providers/repository_providers.dart';

void main() {
  group('Login & Diagnostics Widget Tests', () {
    testWidgets('LoginScreenHasOnlyGoogleButton', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(const AppConfig.devMock()),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );

      // Verify there are no email or password input fields
      expect(find.byType(TextField), findsNothing);
      expect(find.byType(TextFormField), findsNothing);

      // Verify Google login button is present
      expect(find.text('Google로 시작하기'), findsOneWidget);
    });

    testWidgets('DiagnosticsScreenIsHiddenInProduction', (tester) async {
      final prodConfig = AppConfig(
        environment: AppEnvironment.production,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon-key',
        googleWebClientId: 'web.apps.googleusercontent.com',
        googleAndroidClientId: 'android.apps.googleusercontent.com',
        googleIosClientId: 'ios.apps.googleusercontent.com',
        googleServerClientId: 'server.apps.googleusercontent.com',
        googleReversedIosClientId: 'com.googleusercontent.apps.ios',
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

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(prodConfig),
          ],
          child: const MaterialApp(
            home: AuthDiagnosticsScreen(),
          ),
        ),
      );

      // Access Denied should be displayed in production mode
      expect(find.text('접근 권한이 없습니다.'), findsOneWidget);
      expect(find.text('인증 개발자 진단'), findsNothing);
    });
  });
}
