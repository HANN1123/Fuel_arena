import 'package:go_router/go_router.dart';

import 'auth_required_route.dart';
import '../features/ads/presentation/reward_ad_screen.dart';
import '../features/admin/presentation/admin_vehicle_catalog_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/common/presentation/flow_screens.dart';
import '../features/drive/presentation/drive_history_screen.dart';
import '../features/drive/presentation/drive_result_screen.dart';
import '../features/drive/presentation/drive_start_screen.dart';
import '../features/drive/presentation/safety_drive_screen.dart';
import '../features/fairness/presentation/fairness_center_screen.dart';
import '../features/home/presentation/main_shell_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/premium/presentation/premium_screen.dart';
import '../features/ranking/presentation/ranking_detail_screen.dart';
import '../features/rewards/presentation/reward_wallet_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/setup/presentation/additional_setup_intro_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/sponsor/presentation/sponsor_challenge_screen.dart';
import '../features/stats/presentation/stats_screen.dart';
import '../features/support/presentation/support_screens.dart';
import '../features/vehicle/presentation/vehicle_register_screen.dart';
import '../features/vehicle/presentation/vehicle_setup_screen.dart';

GoRouter createAppRouter({String initialLocation = '/splash'}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/splash',
      ),
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
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/consent',
        builder: (context, state) => const AuthRequiredRoute(
          requireConsent: false,
          child: ConsentScreen(),
        ),
      ),
      GoRoute(
        path: '/legal/:document',
        builder: (context, state) => LegalDocumentScreen(
          document: state.pathParameters['document'] ?? 'privacy',
        ),
      ),
      GoRoute(
        path: '/permissions',
        builder: (context, state) =>
            const AuthRequiredRoute(child: PermissionIntroScreen()),
      ),
      GoRoute(
        path: '/permissions/location',
        builder: (context, state) =>
            const AuthRequiredRoute(child: LocationPermissionScreen()),
      ),
      GoRoute(
        path: '/permissions/notification',
        builder: (context, state) =>
            const AuthRequiredRoute(child: NotificationPermissionScreen()),
      ),
      GoRoute(
        path: '/permissions/denied',
        builder: (context, state) => PermissionDeniedScreen(
          type: state.uri.queryParameters['type'] ?? 'location',
        ),
      ),
      GoRoute(
        path: '/permissions/settings-guide',
        builder: (context, state) => PermissionSettingsGuideScreen(
          type: state.uri.queryParameters['type'] ?? 'location',
        ),
      ),
      GoRoute(
        path: '/setup',
        builder: (context, state) =>
            const AuthRequiredRoute(child: AdditionalSetupIntroScreen()),
      ),
      GoRoute(
        path: '/setup/vehicle',
        builder: (context, state) =>
            const AuthRequiredRoute(child: VehicleSetupScreen()),
      ),
      GoRoute(
        path: '/setup/vehicle/custom',
        builder: (context, state) => AuthRequiredRoute(
          child: CustomVehicleRequestScreen(
            initialManufacturer:
                state.uri.queryParameters['manufacturer'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/vehicle/register',
        builder: (context, state) =>
            const AuthRequiredRoute(child: VehicleRegisterScreen()),
      ),
      GoRoute(
        path: '/vehicle/complete',
        builder: (context, state) =>
            const AuthRequiredRoute(child: VehicleSetupCompleteScreen()),
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
          return AuthRequiredRoute(
            child: MainShellScreen(initialIndex: initialIndex),
          );
        },
      ),
      GoRoute(
        path: '/drive/start',
        builder: (context, state) =>
            const AuthRequiredRoute(child: DriveStartScreen()),
      ),
      GoRoute(
        path: '/drive/safety',
        builder: (context, state) =>
            const AuthRequiredRoute(child: SafetyDriveScreen()),
      ),
      GoRoute(
        path: '/drive/result/:sessionId',
        builder: (context, state) => AuthRequiredRoute(
          child: DriveResultScreen(
            sessionId: state.pathParameters['sessionId'] ?? 'local-session',
          ),
        ),
      ),
      GoRoute(
        path: '/drive/result',
        redirect: (context, state) => '/drive/result/local-session',
      ),
      GoRoute(
        path: '/drive/analysis/:sessionId',
        builder: (context, state) => AuthRequiredRoute(
          child: DriveAnalysisScreen(
            sessionId: state.pathParameters['sessionId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/drive/history',
        builder: (context, state) =>
            const AuthRequiredRoute(child: DriveHistoryScreen()),
      ),
      GoRoute(
        path: '/ads/reward',
        builder: (context, state) =>
            const AuthRequiredRoute(child: RewardAdScreen()),
      ),
      GoRoute(
        path: '/premium',
        builder: (context, state) =>
            const AuthRequiredRoute(child: PremiumScreen()),
      ),
      GoRoute(
        path: '/ranking',
        redirect: (context, state) => '/home?tab=ranking',
      ),
      GoRoute(
        path: '/ranking/detail',
        builder: (context, state) =>
            const AuthRequiredRoute(child: RankingDetailScreen()),
      ),
      GoRoute(
        path: '/battle',
        redirect: (context, state) => '/home?tab=battle',
      ),
      GoRoute(
        path: '/battle/create',
        builder: (context, state) =>
            const AuthRequiredRoute(child: BattleCreateScreen()),
      ),
      GoRoute(
        path: '/battle/detail/:battleId',
        builder: (context, state) => AuthRequiredRoute(
          child: BattleDetailScreen(
            battleId: state.pathParameters['battleId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/battle/result/:battleId',
        builder: (context, state) => AuthRequiredRoute(
          child: BattleResultScreen(
            battleId: state.pathParameters['battleId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/season',
        redirect: (context, state) => '/home?tab=season',
      ),
      GoRoute(
        path: '/season/pass',
        builder: (context, state) =>
            const AuthRequiredRoute(child: SeasonPassScreen()),
      ),
      GoRoute(
        path: '/mission',
        builder: (context, state) =>
            const AuthRequiredRoute(child: MissionScreen()),
      ),
      GoRoute(
        path: '/rivals',
        builder: (context, state) =>
            const AuthRequiredRoute(child: RivalScreen()),
      ),
      GoRoute(
        path: '/crew',
        builder: (context, state) =>
            const AuthRequiredRoute(child: CrewScreen()),
      ),
      GoRoute(
        path: '/profile',
        redirect: (context, state) => '/home?tab=profile',
      ),
      GoRoute(
        path: '/profile/badges',
        builder: (context, state) =>
            const AuthRequiredRoute(child: BadgeCollectionScreen()),
      ),
      GoRoute(
        path: '/profile/:userId',
        builder: (context, state) => OtherUserProfileScreen(
          userId: state.pathParameters['userId'] ?? '',
        ),
      ),
      GoRoute(
        path: '/sponsor',
        builder: (context, state) =>
            const AuthRequiredRoute(child: SponsorChallengeScreen()),
      ),
      GoRoute(
        path: '/sponsor/:challengeId',
        builder: (context, state) => AuthRequiredRoute(
          child: SponsorChallengeDetailScreen(
            challengeId: state.pathParameters['challengeId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/rewards',
        builder: (context, state) =>
            const AuthRequiredRoute(child: RewardWalletScreen()),
      ),
      GoRoute(
        path: '/stats',
        builder: (context, state) =>
            const AuthRequiredRoute(child: StatsScreen()),
      ),
      GoRoute(
        path: '/fairness',
        builder: (context, state) =>
            const AuthRequiredRoute(child: FairnessCenterScreen()),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) =>
            const AuthRequiredRoute(child: SettingsScreen()),
      ),
      GoRoute(
        path: '/settings/privacy',
        builder: (context, state) =>
            const AuthRequiredRoute(child: PrivacySettingsScreen()),
      ),
      GoRoute(
        path: '/settings/ads',
        builder: (context, state) =>
            const AuthRequiredRoute(child: AdsSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/safety',
        builder: (context, state) =>
            const AuthRequiredRoute(child: SafetyModeSettingsScreen()),
      ),
      GoRoute(
        path: '/settings/vehicles',
        builder: (context, state) =>
            const AuthRequiredRoute(child: VehicleManagementScreen()),
      ),
      GoRoute(
        path: '/settings/vehicles/add',
        builder: (context, state) =>
            const AuthRequiredRoute(child: VehicleAddScreen()),
      ),
      GoRoute(
        path: '/settings/vehicles/:vehicleId/edit',
        builder: (context, state) => AuthRequiredRoute(
          child: VehicleEditScreen(
            vehicleId: state.pathParameters['vehicleId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) =>
            const AuthRequiredRoute(child: NotificationsScreen()),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) =>
            const AuthRequiredRoute(child: HelpCenterScreen()),
      ),
      GoRoute(
        path: '/support/faq',
        builder: (context, state) =>
            const AuthRequiredRoute(child: FAQScreen()),
      ),
      GoRoute(
        path: '/support/contact',
        builder: (context, state) => AuthRequiredRoute(
          child: ContactSupportScreen(
            initialCategory:
                state.uri.queryParameters['category'] ?? '주행 기록 문제',
          ),
        ),
      ),
      GoRoute(
        path: '/support/ticket/:ticketId',
        builder: (context, state) => AuthRequiredRoute(
          child: SupportTicketDetailScreen(
            ticketId: state.pathParameters['ticketId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/support/report',
        builder: (context, state) =>
            const AuthRequiredRoute(child: ReportProblemScreen()),
      ),
      GoRoute(
        path: '/support/report-user/:userId',
        builder: (context, state) => AuthRequiredRoute(
          child: ReportUserScreen(
            userId: state.pathParameters['userId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/support/report-drive/:driveId',
        builder: (context, state) => AuthRequiredRoute(
          child: ReportDriveRecordScreen(
            driveId: state.pathParameters['driveId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/support/review-request',
        builder: (context, state) => AuthRequiredRoute(
          child: ReviewRequestScreen(
            driveId: state.uri.queryParameters['driveId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/support/review-request/:driveId',
        builder: (context, state) => AuthRequiredRoute(
          child: ReviewRequestScreen(
            driveId: state.pathParameters['driveId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) =>
            const AdminRequiredRoute(child: AdminDashboardScreen()),
      ),
      GoRoute(
        path: '/admin/vehicles',
        builder: (context, state) =>
            const AdminRequiredRoute(child: AdminVehicleCatalogScreen()),
      ),
    ],
  );
}

final appRouter = createAppRouter();
