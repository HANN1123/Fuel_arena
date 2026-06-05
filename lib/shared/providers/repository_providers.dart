import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_config.dart';
import '../models/fuel_arena_models.dart';
import '../repositories/fuel_arena_repositories.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseAuthRepository() : MockAuthRepository();
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseVehicleRepository() : MockVehicleRepository();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseHomeRepository() : MockHomeRepository();
});

final driveRepositoryProvider = Provider<DriveRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseDriveRepository() : MockDriveRepository();
});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseRankingRepository() : MockRankingRepository();
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseBattleRepository() : MockBattleRepository();
});

final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseSeasonRepository() : MockSeasonRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseProfileRepository() : MockProfileRepository();
});

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseAdsRepository() : MockAdsRepository();
});

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabasePremiumRepository() : MockPremiumRepository();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseSubscriptionRepository() : MockSubscriptionRepository();
});

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseSponsorRepository() : MockSponsorRepository();
});

final fairnessRepositoryProvider = Provider<FairnessRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseFairnessRepository() : MockFairnessRepository();
});

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseStatsRepository() : MockStatsRepository();
});

final couponRepositoryProvider = Provider<CouponRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseCouponRepository() : MockCouponRepository();
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseNotificationRepository() : MockNotificationRepository();
});

final crewRepositoryProvider = Provider<CrewRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseCrewRepository() : MockCrewRepository();
});

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return ref.watch(appConfigProvider).hasSupabase ? SupabaseAdminRepository() : MockAdminRepository();
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

final rankingEntriesProvider =
    FutureProvider.family<List<RankingEntry>, String>((ref, scope) {
  return ref.watch(rankingRepositoryProvider).getRankings(scope);
});

final battlesProvider = FutureProvider<List<Battle>>((ref) {
  return ref.watch(battleRepositoryProvider).getBattles();
});

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

final adminMetricsProvider = FutureProvider<List<AdminMetric>>((ref) {
  return ref.watch(adminRepositoryProvider).getMetrics();
});
