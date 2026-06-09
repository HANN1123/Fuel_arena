import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../models/fuel_arena_models.dart';
import '../repositories/fuel_arena_repositories.dart';
import '../services/admob_reward_service.dart';
import '../services/app_services.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.canUseMockRepositories) {
    return MockAuthRepository();
  }
  if (config.canUseMockAuthRepository) {
    return MockAuthRepository();
  }
  if (config.hasSupabase) {
    return SupabaseGoogleAuthRepository(
      googleWebClientId: config.googleWebClientId,
      googleAndroidClientId: config.googleAndroidClientId,
      googleIosClientId: config.googleIosClientId,
      googleServerClientId: config.googleServerClientId,
      redirectUri: config.authRedirectUri,
    );
  }
  return const UnavailableAuthRepository();
});

final localStateServiceProvider = Provider<LocalStateService>((ref) {
  return LocalStateService();
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final appSessionServiceProvider = Provider<AppSessionService>((ref) {
  return AppSessionService(
    authRepository: ref.watch(authRepositoryProvider),
    localState: ref.watch(localStateServiceProvider),
    secureStorage: ref.watch(secureStorageServiceProvider),
  );
});

final consentRepositoryProvider = Provider<ConsentRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.hasSupabase) {
    return SupabaseConsentRepository(allowMockFallback: config.isDev);
  }
  return config.canUseMockRepositories
      ? MockConsentRepository()
      : const UnavailableConsentRepository();
});

final restoredSessionProvider = FutureProvider<RestoredSessionState>((ref) {
  return ref.watch(appSessionServiceProvider).restore();
});

final authStateProvider = StreamProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = FutureProvider<UserProfile?>((ref) {
  return ref.watch(authRepositoryProvider).currentUser();
});

void invalidateUserScopedSessionProviders(WidgetRef ref) {
  ref
    ..invalidate(restoredSessionProvider)
    ..invalidate(authStateProvider)
    ..invalidate(currentUserProvider)
    ..invalidate(appConsentProvider)
    ..invalidate(offlineQueueItemsProvider)
    ..invalidate(homeSnapshotProvider)
    ..invalidate(primaryVehicleProvider)
    ..invalidate(vehiclesProvider)
    ..invalidate(battlesProvider)
    ..invalidate(seasonProvider)
    ..invalidate(seasonMissionsProvider)
    ..invalidate(profileProvider)
    ..invalidate(badgesProvider)
    ..invalidate(achievementsProvider)
    ..invalidate(couponsProvider)
    ..invalidate(notificationsProvider)
    ..invalidate(supportTicketsProvider)
    ..invalidate(privacyRequestsProvider)
    ..invalidate(myCrewProvider)
    ..invalidate(crewMembersProvider);
}

final networkStatusServiceProvider = Provider<NetworkStatusService>((ref) {
  return NetworkStatusService();
});

final networkStatusProvider = StreamProvider<NetworkSnapshot>((ref) {
  return ref.watch(networkStatusServiceProvider).watch();
});

final offlineQueueServiceProvider = Provider<OfflineQueueService>((ref) {
  return OfflineQueueService(localState: ref.watch(localStateServiceProvider));
});

final offlineQueueItemsProvider = FutureProvider<List<OfflineQueueItem>>((ref) {
  return ref.watch(offlineQueueServiceProvider).pendingItems();
});

final localSyncLogRepositoryProvider = Provider<LocalSyncLogRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseLocalSyncLogRepository()
      : const NoopLocalSyncLogRepository();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(
    networkStatus: ref.watch(networkStatusServiceProvider),
    offlineQueue: ref.watch(offlineQueueServiceProvider),
    driveRepository: ref.watch(driveRepositoryProvider),
    syncLogRepository: ref.watch(localSyncLogRepositoryProvider),
  );
});

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseAnalyticsRepository()
      : MockAnalyticsRepository();
});

final appRemoteConfigRepositoryProvider =
    Provider<AppRemoteConfigRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseAppRemoteConfigRepository(
          allowDefaultFallback: !config.isProduction,
        )
      : const MockAppRemoteConfigRepository();
});

final appRemoteConfigProvider = FutureProvider<AppRemoteConfig>((ref) {
  return ref.watch(appRemoteConfigRepositoryProvider).getConfig();
});

final appConsentProvider = FutureProvider<AppConsent>((ref) {
  return ref.watch(consentRepositoryProvider).getConsent();
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseVehicleRepository()
      : MockVehicleRepository();
});

final vehicleCatalogRepositoryProvider =
    Provider<VehicleCatalogRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseVehicleCatalogRepository(
          allowMockFallback: !config.isProduction,
        )
      : const MockVehicleCatalogRepository();
});

final userVehicleRepositoryProvider = Provider<UserVehicleRepository>((ref) {
  final catalogRepository = ref.watch(vehicleCatalogRepositoryProvider);
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseUserVehicleRepository(catalogRepository: catalogRepository)
      : MockUserVehicleRepository(catalogRepository: catalogRepository);
});

final leagueRepositoryProvider = Provider<LeagueRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseLeagueRepository(allowMockFallback: !config.isProduction)
      : MockLeagueRepository();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseHomeRepository(allowMockFallback: !config.isProduction)
      : MockHomeRepository();
});

final driveRepositoryProvider = Provider<DriveRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseDriveRepository(allowMockFallback: !config.isProduction)
      : MockDriveRepository();
});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseRankingRepository()
      : MockRankingRepository();
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase
      ? SupabaseBattleRepository()
      : MockBattleRepository();
});

final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseSeasonRepository(allowMockFallback: !config.isProduction)
      : MockSeasonRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseProfileRepository(allowMockFallback: !config.isProduction)
      : MockProfileRepository();
});

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseAdsRepository(
          allowClientRewardGrant: !config.isProduction,
          rewardAdsConfigured: config.hasRewardedAds,
        )
      : MockAdsRepository();
});

final rewardedAdServiceProvider = Provider<RewardedAdService>((ref) {
  return const RewardedAdService();
});

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabasePremiumRepository(allowMockFallback: !config.isProduction)
      : MockPremiumRepository();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseSubscriptionRepository(allowMockFallback: !config.isProduction)
      : MockSubscriptionRepository();
});

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseSponsorRepository(allowMockFallback: !config.isProduction)
      : MockSponsorRepository();
});

final fairnessRepositoryProvider = Provider<FairnessRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseFairnessRepository(allowMockFallback: !config.isProduction)
      : MockFairnessRepository();
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseStatsRepository(allowMockFallback: !config.isProduction)
      : MockStatsRepository();
});

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseCouponRepository(allowMockFallback: !config.isProduction)
      : MockCouponRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseNotificationRepository(allowMockFallback: !config.isProduction)
      : MockNotificationRepository();
});

final supportRepositoryProvider = Provider<SupportRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseSupportRepository(allowMockFallback: !config.isProduction)
      : MockSupportRepository();
});

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseReportRepository(allowMockFallback: !config.isProduction)
      : MockReportRepository();
});

final privacyRequestRepositoryProvider =
    Provider<PrivacyRequestRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabasePrivacyRequestRepository(
          allowMockFallback: !config.isProduction,
        )
      : MockPrivacyRequestRepository();
});

final crewRepositoryProvider = Provider<CrewRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseCrewRepository(allowMockFallback: !config.isProduction)
      : MockCrewRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final config = ref.watch(appConfigProvider);
  return config.hasSupabase
      ? SupabaseAdminRepository(allowMockFallback: !config.isProduction)
      : MockAdminRepository();
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>((ref) {
  return ref.watch(homeRepositoryProvider).getHomeSnapshot();
});

final primaryVehicleProvider = FutureProvider<Vehicle?>((ref) {
  return ref.watch(vehicleRepositoryProvider).getPrimaryVehicle();
});

final vehiclesProvider = FutureProvider<List<Vehicle>>((ref) {
  return ref.watch(vehicleRepositoryProvider).listVehicles();
});

class VehicleManufacturerQuery {
  const VehicleManufacturerQuery({
    this.keyword = '',
    this.country = '',
  });

  final String keyword;
  final String country;

  @override
  bool operator ==(Object other) {
    return other is VehicleManufacturerQuery &&
        other.keyword == keyword &&
        other.country == country;
  }

  @override
  int get hashCode => Object.hash(keyword, country);
}

final vehicleManufacturersProvider =
    FutureProvider.family<List<VehicleManufacturer>, VehicleManufacturerQuery>(
        (ref, query) {
  return ref.watch(vehicleCatalogRepositoryProvider).listManufacturers(
        keyword: query.keyword,
        country: query.country,
      );
});

final vehicleModelsProvider =
    FutureProvider.family<List<VehicleModel>, String>((ref, manufacturerId) {
  return ref.watch(vehicleCatalogRepositoryProvider).listModels(manufacturerId);
});

final vehicleYearsProvider =
    FutureProvider.family<List<VehicleModelYear>, String>((ref, modelId) {
  return ref.watch(vehicleCatalogRepositoryProvider).listYears(modelId);
});

final vehicleVariantsProvider =
    FutureProvider.family<List<VehicleVariant>, String>((ref, modelYearId) {
  return ref.watch(vehicleCatalogRepositoryProvider).listVariants(modelYearId);
});

final customVehicleReviewRequestsProvider =
    FutureProvider.family<List<CustomVehicleReviewRequest>, String>(
        (ref, status) {
  return ref
      .watch(vehicleCatalogRepositoryProvider)
      .listCustomVehicleReviewRequests(status: status);
});

final rankingEntriesProvider =
    FutureProvider.family<List<RankingEntry>, String>((ref, scope) {
  return ref.watch(rankingRepositoryProvider).getRankings(scope);
});

final publicRankingProfileProvider =
    FutureProvider.family<RankingEntry?, String>((ref, userId) {
  return ref.watch(rankingRepositoryProvider).getPublicEntryByUserId(userId);
});

final battlesProvider = FutureProvider<List<Battle>>((ref) {
  return ref.watch(battleRepositoryProvider).getBattles();
});

final battleDetailProvider = FutureProvider.family<Battle?, String>(
  (ref, battleId) =>
      ref.watch(battleRepositoryProvider).getBattleById(battleId),
);

final seasonProvider = FutureProvider<Season>((ref) {
  return ref.watch(seasonRepositoryProvider).getCurrentSeason();
});

final seasonMissionsProvider = FutureProvider<List<SeasonMission>>((ref) {
  return ref.watch(seasonRepositoryProvider).getMissions();
});

final profileProvider = FutureProvider<UserProfile>((ref) {
  return ref.watch(profileRepositoryProvider).getProfile();
});

final badgesProvider = FutureProvider<List<Badge>>((ref) {
  return ref.watch(profileRepositoryProvider).getBadges();
});

final achievementsProvider = FutureProvider<List<Achievement>>((ref) {
  return ref.watch(profileRepositoryProvider).getAchievements();
});

final sponsorChallengesProvider = FutureProvider<List<SponsorChallenge>>((ref) {
  return ref.watch(sponsorRepositoryProvider).getChallenges();
});

final couponsProvider = FutureProvider<List<Coupon>>((ref) {
  return ref.watch(couponRepositoryProvider).listCoupons();
});

final notificationsProvider = FutureProvider<List<NotificationItem>>((ref) {
  return ref.watch(notificationRepositoryProvider).listNotifications();
});

final supportTicketsProvider = FutureProvider<List<SupportTicket>>((ref) {
  return ref.watch(supportRepositoryProvider).listMyTickets();
});

final supportTicketDetailProvider =
    FutureProvider.family<SupportTicket?, String>((ref, ticketId) {
  return ref.watch(supportRepositoryProvider).getTicketDetail(ticketId);
});

final supportTicketMessagesProvider =
    FutureProvider.family<List<SupportTicketMessage>, String>((ref, ticketId) {
  return ref.watch(supportRepositoryProvider).listMessages(ticketId);
});

final privacyRequestsProvider = FutureProvider<List<PrivacyRequest>>((ref) {
  return ref.watch(privacyRequestRepositoryProvider).listMyRequests();
});

final myCrewProvider = FutureProvider<Crew?>((ref) {
  return ref.watch(crewRepositoryProvider).getMyCrew();
});

final crewMembersProvider = FutureProvider<List<CrewMember>>((ref) {
  return ref.watch(crewRepositoryProvider).listMembers();
});

final adminMetricsProvider = FutureProvider<List<AdminMetric>>((ref) {
  return ref.watch(adminRepositoryProvider).getMetrics();
});

final adminRecordPageProvider =
    FutureProvider.family<AdminRecordPage, AdminRecordQuery>((ref, query) {
  return ref.watch(adminRepositoryProvider).getRecords(query);
});
