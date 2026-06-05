import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/ads/presentation/reward_ad_mock_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/common/presentation/flow_screens.dart';
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
      path: '/auth/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/auth/signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: '/consent',
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/permissions',
      builder: (context, state) => const PermissionIntroScreen(),
    ),
    GoRoute(
      path: '/vehicle/register',
      builder: (context, state) => const VehicleRegisterScreen(),
    ),
    GoRoute(
      path: '/vehicle/complete',
      builder: (context, state) => const VehicleCompleteScreen(),
    ),
    GoRoute(
      path: '/login',
      redirect: (context, state) => '/auth/login',
    ),
    GoRoute(
      path: '/vehicle-register',
      redirect: (context, state) => '/vehicle/register',
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
      path: '/drive/result/:sessionId',
      builder: (context, state) => DriveResultScreen(
        sessionId: state.pathParameters['sessionId'] ?? 'mock-session',
      ),
    ),
    GoRoute(
      path: '/drive/result',
      redirect: (context, state) => '/drive/result/mock-session',
    ),
    GoRoute(
      path: '/drive/analysis/:sessionId',
      builder: (context, state) => FuelArenaInfoScreen(
        title: '주행 분석',
        subtitle: '${state.pathParameters['sessionId'] ?? 'mock-session'} 기록의 효율, 안정성, 동급 보정을 확인합니다.',
        icon: Icons.analytics_rounded,
        sections: const [
          InfoSection(title: '효율 분석', body: '평균 연비, 급가속 패널티, 공회전 패널티를 분리해 표시합니다.'),
          InfoSection(title: '안정 주행', body: '급제동과 속도 편차를 안정 점수에 반영합니다.'),
          InfoSection(title: '공개 제한', body: '정확한 GPS 경로는 공개 랭킹에 표시하지 않습니다.'),
        ],
      ),
    ),
    GoRoute(
      path: '/drive/history',
      builder: (context, state) => const FuelArenaInfoScreen(
        title: '주행 기록',
        subtitle: '최근 20개 mock 주행 세션과 검증 상태를 확인합니다.',
        icon: Icons.history_rounded,
        sections: [
          InfoSection(title: '최근 주행', body: '24.8km · 984점 · 검증 완료'),
          InfoSection(title: '지난 주행', body: '18.2km · 912점 · 랭킹 반영 완료'),
          InfoSection(title: '검토 대기', body: '비정상적으로 짧은 주행은 공정성 검토로 보류됩니다.'),
        ],
      ),
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
      path: '/ranking',
      redirect: (context, state) => '/home?tab=ranking',
    ),
    GoRoute(
      path: '/ranking/detail',
      builder: (context, state) => const FuelArenaInfoScreen(
        title: '랭킹 상세',
        subtitle: '동급, 지역, 연료 타입별 랭킹 기준과 내 주변 순위를 확인합니다.',
        icon: Icons.leaderboard_rounded,
        sections: [
          InfoSection(title: '공개 정보', body: '닉네임, 티어, 점수, 차급, 연료 타입만 공개합니다.'),
          InfoSection(title: '비공개 정보', body: '정확한 위치 경로와 개인 주행 상세는 본인만 볼 수 있습니다.'),
        ],
      ),
    ),
    GoRoute(
      path: '/battle',
      redirect: (context, state) => '/home?tab=battle',
    ),
    GoRoute(
      path: '/battle/create',
      builder: (context, state) => const BattleCreateScreen(),
    ),
    GoRoute(
      path: '/battle/detail/:battleId',
      builder: (context, state) => BattleDetailScreen(
        battleId: state.pathParameters['battleId'] ?? 'battle-001',
      ),
    ),
    GoRoute(
      path: '/battle/result/:battleId',
      builder: (context, state) => BattleResultScreen(
        battleId: state.pathParameters['battleId'] ?? 'battle-001',
      ),
    ),
    GoRoute(
      path: '/season',
      redirect: (context, state) => '/home?tab=season',
    ),
    GoRoute(
      path: '/season/pass',
      builder: (context, state) => const SeasonPassScreen(),
    ),
    GoRoute(
      path: '/mission',
      builder: (context, state) => const MissionScreen(),
    ),
    GoRoute(
      path: '/rivals',
      builder: (context, state) => const RivalScreen(),
    ),
    GoRoute(
      path: '/crew',
      builder: (context, state) => const CrewScreen(),
    ),
    GoRoute(
      path: '/profile',
      redirect: (context, state) => '/home?tab=profile',
    ),
    GoRoute(
      path: '/profile/badges',
      builder: (context, state) => const BadgeCollectionScreen(),
    ),
    GoRoute(
      path: '/profile/:userId',
      builder: (context, state) => OtherUserProfileScreen(
        userId: state.pathParameters['userId'] ?? 'user-001',
      ),
    ),
    GoRoute(
      path: '/sponsor',
      builder: (context, state) => const SponsorChallengeScreen(),
    ),
    GoRoute(
      path: '/sponsor/:challengeId',
      builder: (context, state) => SponsorChallengeDetailScreen(
        challengeId: state.pathParameters['challengeId'] ?? 'sponsor-001',
      ),
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
      path: '/settings/privacy',
      builder: (context, state) => const PrivacySettingsScreen(),
    ),
    GoRoute(
      path: '/settings/ads',
      builder: (context, state) => const AdsSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/safety',
      builder: (context, state) => const SafetyModeSettingsScreen(),
    ),
    GoRoute(
      path: '/settings/vehicles',
      builder: (context, state) => const VehicleManagementScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const AdminDashboardScreen(),
    ),
  ],
);
