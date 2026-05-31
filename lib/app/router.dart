import 'package:go_router/go_router.dart';

import '../features/ads/presentation/reward_ad_mock_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/drive/presentation/drive_result_screen.dart';
import '../features/drive/presentation/drive_start_screen.dart';
import '../features/drive/presentation/safety_drive_screen.dart';
import '../features/fairness/presentation/fairness_center_screen.dart';
import '../features/home/presentation/main_shell_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/rewards/presentation/reward_wallet_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/sponsor/presentation/sponsor_challenge_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/vehicle/presentation/vehicle_register_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/vehicle-register',
      builder: (context, state) => const VehicleRegisterScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) {
        final tab = state.uri.queryParameters['tab'];
        final initialIndex = switch (tab) {
          'battle' => 1,
          'ranking' => 2,
          'season' => 3,
          'profile' => 4,
          _ => 0,
        };
        return MainShellScreen(initialIndex: initialIndex);
      },
    ),
    GoRoute(
      path: '/drive/start',
      builder: (context, state) => const DriveStartScreen(),
    ),
    GoRoute(
      path: '/drive/safety',
      builder: (context, state) => const SafetyDriveScreen(),
    ),
    GoRoute(
      path: '/drive/result',
      builder: (context, state) => const DriveResultScreen(),
    ),
    GoRoute(
      path: '/ads/reward',
      builder: (context, state) => const RewardAdMockScreen(),
    ),
    GoRoute(
      path: '/premium',
      builder: (context, state) => const PremiumScreen(),
    ),
    GoRoute(
      path: '/sponsor',
      builder: (context, state) => const SponsorChallengeScreen(),
    ),
    GoRoute(
      path: '/rewards',
      builder: (context, state) => const RewardWalletScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (context, state) => const StatsScreen(),
    ),
    GoRoute(
      path: '/fairness',
      builder: (context, state) => const FairnessCenterScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
  ],
);
