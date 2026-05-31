import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/fuel_arena_models.dart';
import '../repositories/fuel_arena_repositories.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return MockAuthRepository();
});

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  return MockVehicleRepository();
});

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return MockHomeRepository();
});

final driveRepositoryProvider = Provider<DriveRepository>((ref) {
  return MockDriveRepository();
});

final rankingRepositoryProvider = Provider<RankingRepository>((ref) {
  return MockRankingRepository();
});

final battleRepositoryProvider = Provider<BattleRepository>((ref) {
  return MockBattleRepository();
});

final seasonRepositoryProvider = Provider<SeasonRepository>((ref) {
  return MockSeasonRepository();
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return MockProfileRepository();
});

final adsRepositoryProvider = Provider<AdsRepository>((ref) {
  return MockAdsRepository();
});

final premiumRepositoryProvider = Provider<PremiumRepository>((ref) {
  return MockPremiumRepository();
});

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  return MockSubscriptionRepository();
});

final sponsorRepositoryProvider = Provider<SponsorRepository>((ref) {
  return MockSponsorRepository();
});

final fairnessRepositoryProvider = Provider<FairnessRepository>((ref) {
  return MockFairnessRepository();
});

final homeSnapshotProvider = FutureProvider<HomeSnapshot>((ref) {
  return ref.watch(homeRepositoryProvider).getHomeSnapshot();
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
