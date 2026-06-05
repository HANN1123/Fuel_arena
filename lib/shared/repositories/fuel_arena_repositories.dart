import 'package:uuid/uuid.dart';

import '../models/fuel_arena_models.dart';

const _uuid = Uuid();

abstract class AuthRepository {
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  });

  Future<UserProfile?> getCurrentUser();

  Future<void> signOut();

  Future<void> deleteAccount();
}

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser = mockProfile;

  @override
  Future<UserProfile?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _currentUser;
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _currentUser = UserProfile(
      id: _uuid.v4(),
      email: email,
      nickname: nickname.isEmpty ? 'NeonDriver' : nickname,
      avatarUrl: '',
      tier: 'Bronze I',
      totalScore: 0,
      seasonScore: 0,
      currentStreak: 0,
      bestStreak: 0,
      representativeVehicleName: '',
      isPremium: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return _currentUser!;
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    _currentUser = mockProfile;
    return mockProfile;
  }

  @override
  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    _currentUser = null;
  }

  @override
  Future<void> deleteAccount() async {
    await signOut();
  }
}

class SupabaseAuthRepository implements AuthRepository {
  final MockAuthRepository _fallback = MockAuthRepository();

  @override
  Future<UserProfile?> getCurrentUser() {
    return _fallback.getCurrentUser();
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) {
    return _fallback.loginWithEmail(email: email, password: password);
  }

  @override
  Future<UserProfile> signUp({
    required String email,
    required String password,
    required String nickname,
  }) {
    return _fallback.signUp(email: email, password: password, nickname: nickname);
  }

  @override
  Future<void> signOut() => _fallback.signOut();

  @override
  Future<void> deleteAccount() => _fallback.deleteAccount();
}

abstract class VehicleRepository {
  Future<List<Vehicle>> listVehicles();

  Future<Vehicle?> getPrimaryVehicle();

  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  });

  Future<Vehicle> updateVehicle(Vehicle vehicle);

  Future<void> deleteVehicle(String vehicleId);

  Future<void> setPrimaryVehicle(String vehicleId);
}

class MockVehicleRepository implements VehicleRepository {
  Vehicle? _vehicle = mockVehicle;

  @override
  Future<List<Vehicle>> listVehicles() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return [
      if (_vehicle != null) _vehicle!,
      ...mockGarage.where((vehicle) => vehicle.id != _vehicle?.id),
    ];
  }

  @override
  Future<Vehicle?> getPrimaryVehicle() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _vehicle;
  }

  @override
  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _vehicle = Vehicle(
      id: _uuid.v4(),
      userId: mockProfile.id,
      manufacturer: manufacturer,
      modelName: modelName,
      modelYear: modelYear,
      fuelType: fuelType,
      vehicleClass: vehicleClass,
      nickname: nickname,
      isPrimary: true,
    );
    return _vehicle!;
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _vehicle = vehicle;
    return vehicle;
  }

  @override
  Future<void> deleteVehicle(String vehicleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    if (_vehicle?.id == vehicleId) {
      _vehicle = mockGarage.first;
    }
  }

  @override
  Future<void> setPrimaryVehicle(String vehicleId) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    _vehicle = mockGarage.firstWhere(
      (vehicle) => vehicle.id == vehicleId,
      orElse: () => mockVehicle,
    );
  }
}

class SupabaseVehicleRepository implements VehicleRepository {
  final MockVehicleRepository _fallback = MockVehicleRepository();

  @override
  Future<List<Vehicle>> listVehicles() => _fallback.listVehicles();

  @override
  Future<Vehicle?> getPrimaryVehicle() {
    return _fallback.getPrimaryVehicle();
  }

  @override
  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  }) {
    return _fallback.saveVehicle(
      manufacturer: manufacturer,
      modelName: modelName,
      modelYear: modelYear,
      fuelType: fuelType,
      vehicleClass: vehicleClass,
      nickname: nickname,
    );
  }

  @override
  Future<Vehicle> updateVehicle(Vehicle vehicle) => _fallback.updateVehicle(vehicle);

  @override
  Future<void> deleteVehicle(String vehicleId) => _fallback.deleteVehicle(vehicleId);

  @override
  Future<void> setPrimaryVehicle(String vehicleId) => _fallback.setPrimaryVehicle(vehicleId);
}

abstract class HomeRepository {
  Future<HomeSnapshot> getHomeSnapshot();
}

class MockHomeRepository implements HomeRepository {
  @override
  Future<HomeSnapshot> getHomeSnapshot() async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return HomeSnapshot(
      profile: mockProfile,
      vehicle: mockVehicle,
      activeBattle: mockBattles.first,
      todayMission: mockMissions.first,
      season: mockSeason,
      rival: mockRival,
      latestDriveScore: mockDriveScore,
      sponsorChallenge: mockSponsorChallenge,
    );
  }
}

class SupabaseHomeRepository implements HomeRepository {
  final MockHomeRepository _fallback = MockHomeRepository();

  @override
  Future<HomeSnapshot> getHomeSnapshot() {
    return _fallback.getHomeSnapshot();
  }
}

abstract class DriveRepository {
  Future<Vehicle> getRepresentativeVehicle();

  Future<SeasonMission> getTodayMission();

  Future<DriveSession> startDriveSession();

  Future<DriveScore> finishDriveSession();
}

class MockDriveRepository implements DriveRepository {
  @override
  Future<DriveScore> finishDriveSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    return mockDriveScore;
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mockVehicle;
  }

  @override
  Future<SeasonMission> getTodayMission() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return mockMissions.first;
  }

  @override
  Future<DriveSession> startDriveSession() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return DriveSession(
      id: _uuid.v4(),
      vehicleId: mockVehicle.id,
      startedAt: DateTime.now(),
      duration: Duration.zero,
      distanceKm: 0,
      averageFuelEfficiency: 0,
      status: 'recording',
    );
  }
}

class SupabaseDriveRepository implements DriveRepository {
  final MockDriveRepository _fallback = MockDriveRepository();

  @override
  Future<DriveScore> finishDriveSession() {
    return _fallback.finishDriveSession();
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() {
    return _fallback.getRepresentativeVehicle();
  }

  @override
  Future<SeasonMission> getTodayMission() {
    return _fallback.getTodayMission();
  }

  @override
  Future<DriveSession> startDriveSession() {
    return _fallback.startDriveSession();
  }
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getRankings(String scope);
}

class MockRankingRepository implements RankingRepository {
  @override
  Future<List<RankingEntry>> getRankings(String scope) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return [...mockRankings]..sort((a, b) => a.rank.compareTo(b.rank));
  }
}

class SupabaseRankingRepository implements RankingRepository {
  final MockRankingRepository _fallback = MockRankingRepository();

  @override
  Future<List<RankingEntry>> getRankings(String scope) {
    return _fallback.getRankings(scope);
  }
}

abstract class BattleRepository {
  Future<List<Battle>> getBattles();
}

class MockBattleRepository implements BattleRepository {
  @override
  Future<List<Battle>> getBattles() async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    return mockBattles;
  }
}

class SupabaseBattleRepository implements BattleRepository {
  final MockBattleRepository _fallback = MockBattleRepository();

  @override
  Future<List<Battle>> getBattles() {
    return _fallback.getBattles();
  }
}

abstract class SeasonRepository {
  Future<Season> getCurrentSeason();

  Future<List<SeasonMission>> getMissions();
}

class MockSeasonRepository implements SeasonRepository {
  @override
  Future<Season> getCurrentSeason() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return mockSeason;
  }

  @override
  Future<List<SeasonMission>> getMissions() async {
    await Future<void>.delayed(const Duration(milliseconds: 280));
    return mockMissions;
  }
}

class SupabaseSeasonRepository implements SeasonRepository {
  final MockSeasonRepository _fallback = MockSeasonRepository();

  @override
  Future<Season> getCurrentSeason() {
    return _fallback.getCurrentSeason();
  }

  @override
  Future<List<SeasonMission>> getMissions() {
    return _fallback.getMissions();
  }
}

abstract class ProfileRepository {
  Future<UserProfile> getProfile();

  Future<List<Badge>> getBadges();

  Future<List<Achievement>> getAchievements();
}

class MockProfileRepository implements ProfileRepository {
  @override
  Future<List<Achievement>> getAchievements() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockAchievements;
  }

  @override
  Future<List<Badge>> getBadges() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockBadges;
  }

  @override
  Future<UserProfile> getProfile() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockProfile;
  }
}

class SupabaseProfileRepository implements ProfileRepository {
  final MockProfileRepository _fallback = MockProfileRepository();

  @override
  Future<List<Achievement>> getAchievements() {
    return _fallback.getAchievements();
  }

  @override
  Future<List<Badge>> getBadges() {
    return _fallback.getBadges();
  }

  @override
  Future<UserProfile> getProfile() {
    return _fallback.getProfile();
  }
}

abstract class AdsRepository {
  Future<bool> isRewardAdAvailable();

  Future<AdReward> watchRewardAd();

  Future<int> getDailyRewardAdLimit();

  Future<List<Advertisement>> getNativeAdCards();
}

class MockAdsRepository implements AdsRepository {
  @override
  Future<int> getDailyRewardAdLimit() async => 3;

  @override
  Future<List<Advertisement>> getNativeAdCards() async => mockAds;

  @override
  Future<bool> isRewardAdAvailable() async => true;

  @override
  Future<AdReward> watchRewardAd() async {
    await Future<void>.delayed(const Duration(seconds: 1));
    return const AdReward(
      id: 'reward-xp-double',
      title: '시즌 XP 2배',
      description: '이번 주행 보상이 두 배로 적용됐어요.',
      claimed: true,
    );
  }
}

class SupabaseAdsRepository implements AdsRepository {
  final MockAdsRepository _fallback = MockAdsRepository();

  @override
  Future<int> getDailyRewardAdLimit() {
    return _fallback.getDailyRewardAdLimit();
  }

  @override
  Future<List<Advertisement>> getNativeAdCards() {
    return _fallback.getNativeAdCards();
  }

  @override
  Future<bool> isRewardAdAvailable() {
    return _fallback.isRewardAdAvailable();
  }

  @override
  Future<AdReward> watchRewardAd() {
    return _fallback.watchRewardAd();
  }
}

abstract class PremiumRepository {
  Future<List<SubscriptionPlan>> getPlans();
}

class MockPremiumRepository implements PremiumRepository {
  @override
  Future<List<SubscriptionPlan>> getPlans() async => mockPlans;
}

class SupabasePremiumRepository implements PremiumRepository {
  final MockPremiumRepository _fallback = MockPremiumRepository();

  @override
  Future<List<SubscriptionPlan>> getPlans() {
    return _fallback.getPlans();
  }
}

abstract class SubscriptionRepository {
  Future<List<SubscriptionPlan>> getPlans();

  Future<bool> startSubscription(String planId);
}

class MockSubscriptionRepository implements SubscriptionRepository {
  @override
  Future<List<SubscriptionPlan>> getPlans() async => mockPlans;

  @override
  Future<bool> startSubscription(String planId) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return true;
  }
}

class SupabaseSubscriptionRepository implements SubscriptionRepository {
  final MockSubscriptionRepository _fallback = MockSubscriptionRepository();

  @override
  Future<List<SubscriptionPlan>> getPlans() {
    return _fallback.getPlans();
  }

  @override
  Future<bool> startSubscription(String planId) {
    return _fallback.startSubscription(planId);
  }
}

abstract class SponsorRepository {
  Future<List<SponsorChallenge>> getChallenges();
}

class MockSponsorRepository implements SponsorRepository {
  @override
  Future<List<SponsorChallenge>> getChallenges() async => mockSponsorChallenges;
}

class SupabaseSponsorRepository implements SponsorRepository {
  final MockSponsorRepository _fallback = MockSponsorRepository();

  @override
  Future<List<SponsorChallenge>> getChallenges() {
    return _fallback.getChallenges();
  }
}

abstract class FairnessRepository {
  Future<List<String>> getGuidelines();
}

class MockFairnessRepository implements FairnessRepository {
  @override
  Future<List<String>> getGuidelines() async => const [
        '차종과 연료 타입별 보정 계수를 적용합니다.',
        '정확한 위치 경로는 공개 랭킹에 노출하지 않습니다.',
        '비정상 급가속, 급제동, GPS 이상 기록은 검증 대기 상태가 됩니다.',
        '최종 점수는 서버 검증 후 랭킹에 반영됩니다.',
      ];
}

class SupabaseFairnessRepository implements FairnessRepository {
  final MockFairnessRepository _fallback = MockFairnessRepository();

  @override
  Future<List<String>> getGuidelines() {
    return _fallback.getGuidelines();
  }
}

abstract class StatsRepository {
  Future<List<AdminMetric>> getUserStats();
}

class MockStatsRepository implements StatsRepository {
  @override
  Future<List<AdminMetric>> getUserStats() async => const [
        AdminMetric(id: 'avg-efficiency', label: '평균 연비', value: '18.4', unit: 'km/L'),
        AdminMetric(id: 'verified-drives', label: '검증 주행', value: '20', unit: '회'),
        AdminMetric(id: 'class-top', label: '동급 백분위', value: '18', unit: '%'),
        AdminMetric(id: 'streak', label: '연속 주행', value: '5', unit: '일'),
      ];
}

class SupabaseStatsRepository implements StatsRepository {
  final MockStatsRepository _fallback = MockStatsRepository();

  @override
  Future<List<AdminMetric>> getUserStats() => _fallback.getUserStats();
}

abstract class CouponRepository {
  Future<List<Coupon>> listCoupons();

  Future<UserCoupon> issueCoupon(String couponId);
}

class MockCouponRepository implements CouponRepository {
  @override
  Future<UserCoupon> issueCoupon(String couponId) async => UserCoupon(
        id: _uuid.v4(),
        userId: mockProfile.id,
        couponId: couponId,
        status: 'issued',
        issuedAt: DateTime.now(),
      );

  @override
  Future<List<Coupon>> listCoupons() async => mockCoupons;
}

class SupabaseCouponRepository implements CouponRepository {
  final MockCouponRepository _fallback = MockCouponRepository();

  @override
  Future<UserCoupon> issueCoupon(String couponId) => _fallback.issueCoupon(couponId);

  @override
  Future<List<Coupon>> listCoupons() => _fallback.listCoupons();
}

abstract class NotificationRepository {
  Future<List<NotificationItem>> listNotifications();

  Future<void> markRead(String notificationId);
}

class MockNotificationRepository implements NotificationRepository {
  @override
  Future<List<NotificationItem>> listNotifications() async => mockNotifications;

  @override
  Future<void> markRead(String notificationId) async {}
}

class SupabaseNotificationRepository implements NotificationRepository {
  final MockNotificationRepository _fallback = MockNotificationRepository();

  @override
  Future<List<NotificationItem>> listNotifications() => _fallback.listNotifications();

  @override
  Future<void> markRead(String notificationId) => _fallback.markRead(notificationId);
}

abstract class CrewRepository {
  Future<Crew> getMyCrew();

  Future<List<CrewMember>> listMembers();
}

class MockCrewRepository implements CrewRepository {
  @override
  Future<Crew> getMyCrew() async => const Crew(
        id: 'crew-001',
        name: 'Neon Commuters',
        description: '출퇴근 효율을 경쟁하는 크루',
        memberCount: 8,
        weeklyScore: 18420,
      );

  @override
  Future<List<CrewMember>> listMembers() async => mockCrewMembers;
}

class SupabaseCrewRepository implements CrewRepository {
  final MockCrewRepository _fallback = MockCrewRepository();

  @override
  Future<Crew> getMyCrew() => _fallback.getMyCrew();

  @override
  Future<List<CrewMember>> listMembers() => _fallback.listMembers();
}

abstract class AdminRepository {
  Future<List<AdminMetric>> getMetrics();
}

class MockAdminRepository implements AdminRepository {
  @override
  Future<List<AdminMetric>> getMetrics() async => mockAdminMetrics;
}

class SupabaseAdminRepository implements AdminRepository {
  final MockAdminRepository _fallback = MockAdminRepository();

  @override
  Future<List<AdminMetric>> getMetrics() => _fallback.getMetrics();
}

final mockProfile = UserProfile(
  id: 'user-001',
  email: 'driver@fuelarena.net',
  nickname: 'ApexDriver',
  avatarUrl: '',
  tier: 'Gold III',
  totalScore: 128420,
  seasonScore: 2842,
  currentStreak: 5,
  bestStreak: 13,
  representativeVehicleId: 'vehicle-001',
  representativeVehicleName: 'Phantom R-Spec',
  isPremium: false,
  isAdmin: true,
);

final mockVehicle = Vehicle(
  id: 'vehicle-001',
  userId: mockProfile.id,
  manufacturer: 'Hyundai',
  modelName: 'Avante Hybrid',
  modelYear: 2024,
  fuelType: 'Hybrid',
  vehicleClass: '준중형',
  nickname: '출퇴근 머신',
  isPrimary: true,
);

const mockDriveScore = DriveScore(
  totalScore: 984,
  efficiencyScore: 93,
  stabilityScore: 88,
  classPercentile: 18,
  accelerationPenalty: -12,
  brakingPenalty: -8,
  idlePenalty: -4,
  distanceBonus: 42,
  consistencyBonus: 31,
  verificationStatus: 'verified',
);

final mockRankings = [
  const RankingEntry(
    rank: 1,
    previousRank: 2,
    nickname: 'EcoBlade',
    tier: 'Diamond I',
    score: 3910,
    vehicleClass: '준중형',
    fuelType: 'Hybrid',
    isCurrentUser: false,
  ),
  const RankingEntry(
    rank: 2,
    previousRank: 1,
    nickname: 'BlueTorque',
    tier: 'Diamond II',
    score: 3722,
    vehicleClass: '중형',
    fuelType: 'Diesel',
    isCurrentUser: false,
  ),
  const RankingEntry(
    rank: 3,
    previousRank: 5,
    nickname: 'VoltRunner',
    tier: 'Platinum I',
    score: 3512,
    vehicleClass: 'SUV',
    fuelType: 'Electric',
    isCurrentUser: false,
  ),
  RankingEntry(
    rank: 18,
    previousRank: 21,
    nickname: mockProfile.nickname,
    tier: mockProfile.tier,
    score: mockProfile.seasonScore,
    vehicleClass: mockVehicle.vehicleClass,
    fuelType: mockVehicle.fuelType,
    isCurrentUser: true,
  ),
  const RankingEntry(
    rank: 19,
    previousRank: 17,
    nickname: 'NightCruise',
    tier: 'Gold III',
    score: 2811,
    vehicleClass: '준중형',
    fuelType: 'Gasoline',
    isCurrentUser: false,
  ),
  ...List.generate(45, (index) {
    final rank = index < 14 ? index + 4 : index + 20;
    final names = ['GreenLine', 'EcoPulse', 'QuietTorque', 'FuelBlade', 'CityRunner'];
    final classes = ['준중형', '중형', 'SUV', '소형', '전기'];
    final fuels = ['Hybrid', 'Gasoline', 'Diesel', 'Electric', 'LPG'];
    return RankingEntry(
      rank: rank,
      previousRank: rank + (index.isEven ? 1 : -1),
      nickname: '${names[index % names.length]}${index + 1}',
      tier: rank < 10 ? 'Platinum II' : 'Gold IV',
      score: 2780 - (index * 23),
      vehicleClass: classes[index % classes.length],
      fuelType: fuels[index % fuels.length],
      isCurrentUser: false,
    );
  }),
];

final mockBattles = [
  Battle(
    id: 'battle-001',
    title: '퇴근길 효율전',
    battleType: '1:1 배틀',
    status: '진행 중',
    ruleType: '최고 효율 점수',
    startAt: DateTime.now().subtract(const Duration(hours: 2)),
    endAt: DateTime.now().add(const Duration(hours: 8)),
    myScore: 984,
    opponentScore: 1008,
    opponentNickname: 'NightCruise',
    rewardSummary: '시즌 XP 120',
  ),
  Battle(
    id: 'battle-002',
    title: '커피 내기 없는 커피런',
    battleType: '공개 매칭',
    status: '모집 중',
    ruleType: '주간 평균 연비',
    startAt: DateTime.now(),
    endAt: DateTime.now().add(const Duration(days: 3)),
    myScore: 0,
    opponentScore: 0,
    opponentNickname: '공개 참가자',
    rewardSummary: '배지 조각 3개',
  ),
  Battle(
    id: 'battle-003',
    title: '크루 점심길 미션',
    battleType: '그룹 배틀',
    status: '추천',
    ruleType: '팀 평균 안정 점수',
    startAt: DateTime.now(),
    endAt: DateTime.now().add(const Duration(days: 1)),
    myScore: 0,
    opponentScore: 0,
    opponentNickname: 'Crew Match',
    rewardSummary: '쿠폰 응모권',
  ),
  ...List.generate(
    5,
    (index) => Battle(
      id: 'battle-${(index + 4).toString().padLeft(3, '0')}',
      title: ['아침 출근 효율전', '주말 도심 챌린지', '동급 하이브리드전', '크루 안정 주행전', '퇴근길 재대결'][index],
      battleType: index.isEven ? '공개 매칭' : '1:1 배틀',
      status: index == 4 ? '종료' : '모집 중',
      ruleType: index.isEven ? '최고 효율 점수' : '평균 안정 점수',
      startAt: DateTime.now().subtract(Duration(hours: index)),
      endAt: DateTime.now().add(Duration(days: index + 1)),
      myScore: index == 4 ? 942 : 0,
      opponentScore: index == 4 ? 918 : 0,
      opponentNickname: ['EcoPulse', 'BlueTorque', 'GreenLine', 'VoltRunner', 'NightCruise'][index],
      rewardSummary: index.isEven ? '시즌 XP ${80 + index * 20}' : '배지 조각 ${index + 1}개',
    ),
  ),
];

final mockSeason = Season(
  id: 'season-001',
  name: 'Neon Efficiency Season',
  currentLeague: 'Gold League',
  seasonScore: 2842,
  promotionTargetScore: 3000,
  endsAt: DateTime.now().add(const Duration(days: 18)),
  rewardProgress: 0.68,
);

final mockMissions = [
  const SeasonMission(
    id: 'mission-001',
    title: '급가속 없이 12km 주행',
    description: '안정 주행 점수를 올리고 시즌 XP를 획득하세요.',
    progress: 8,
    target: 12,
    rewardXp: 120,
    isWeekly: false,
  ),
  const SeasonMission(
    id: 'mission-002',
    title: '동급 상위 20% 3회 달성',
    description: '주간 챌린지 보상으로 한정 배지 조각을 획득합니다.',
    progress: 1,
    target: 3,
    rewardXp: 360,
    isWeekly: true,
  ),
  ...List.generate(
    8,
    (index) => SeasonMission(
      id: 'mission-${(index + 3).toString().padLeft(3, '0')}',
      title: ['광고 보상 1회 선택', '배틀 참가', '15km 이상 주행', '급제동 없이 주행', '랭킹 확인', '쿠폰 챌린지 참가', '크루 점수 기여', '공정성 기준 확인'][index],
      description: '주행과 경쟁 루프를 따라 시즌 XP를 획득하세요.',
      progress: index % 3,
      target: 3 + index % 4,
      rewardXp: 90 + index * 30,
      isWeekly: index.isOdd,
    ),
  ),
];

const mockRival = Rival(
  id: 'rival-001',
  nickname: 'NightCruise',
  scoreGap: 24,
  message: '라이벌이 앞서가고 있어요',
);

final mockSponsorChallenge = SponsorChallenge(
  id: 'sponsor-001',
  sponsorName: 'Charge Lab',
  title: '도심 효율 챌린지',
  description: '오늘 15km 이상 주행하고 동급 대비 상위 30% 안에 들어보세요.',
  rewardSummary: '쿠폰 응모권 1장',
  endsAt: DateTime.now().add(const Duration(days: 2)),
);

final mockSponsorChallenges = [
  mockSponsorChallenge,
  ...List.generate(
    4,
    (index) => SponsorChallenge(
      id: 'sponsor-${(index + 2).toString().padLeft(3, '0')}',
      sponsorName: ['Clean Bay', 'Fuel Mate', 'Eco Tire', 'Drive Cafe'][index],
      title: ['세차 쿠폰 챌린지', '연비 상위권 보너스', '타이어 점검 미션', '퇴근길 커피 리워드'][index],
      description: '검증된 주행과 동급 대비 성과를 달성하면 쿠폰 응모권을 지급합니다.',
      rewardSummary: '쿠폰 응모권 ${index + 1}장',
      endsAt: DateTime.now().add(Duration(days: index + 3)),
    ),
  ),
];

final mockBadges = <Badge>[
  const Badge(
    id: 'badge-001',
    name: '연비 검투사',
    description: '첫 배틀 승리',
    rarity: 'Rare',
  ),
  const Badge(
    id: 'badge-002',
    name: '정속 장인',
    description: '안정 점수 90점 이상',
    rarity: 'Epic',
  ),
  const Badge(
    id: 'badge-003',
    name: '시즌 질주',
    description: '7일 연속 주행',
    rarity: 'Gold',
  ),
  ...List.generate(
    17,
    (index) => Badge(
      id: 'badge-${(index + 4).toString().padLeft(3, '0')}',
      name: ['추월자', '효율 장인', '안전 모드', '도심 챔피언'][index % 4],
      description: 'Fuel Arena 경쟁 루프에서 획득하는 배지입니다.',
      rarity: ['Common', 'Rare', 'Epic', 'Gold'][index % 4],
    ),
  ),
];

final mockAchievements = <Achievement>[
  const Achievement(
    id: 'achievement-001',
    title: '첫 검증 완료',
    description: '검증된 주행 기록 1회 달성',
    progress: 1,
    target: 1,
  ),
  const Achievement(
    id: 'achievement-002',
    title: '라이벌 추월',
    description: '라이벌 순위 10회 추월',
    progress: 4,
    target: 10,
  ),
  ...List.generate(
    13,
    (index) => Achievement(
      id: 'achievement-${(index + 3).toString().padLeft(3, '0')}',
      title: ['주행 루틴', '배틀 루틴', '미션 루틴', '보상 루틴'][index % 4],
      description: '실제 앱 흐름을 반복하며 성장하는 업적입니다.',
      progress: index + 1,
      target: 10 + index,
    ),
  ),
];

const mockAds = [
  Advertisement(
    id: 'ad-001',
    placement: 'drive_result',
    rewardType: 'season_xp_double',
    label: '광고 보고 시즌 XP 2배 받기',
  ),
];

const mockPlans = [
  SubscriptionPlan(
    id: 'premium-monthly',
    name: 'Fuel Arena Premium',
    priceLabel: '월 4,900원',
    benefits: [
      '광고 제거',
      '고급 통계',
      '라이벌 분석',
      '동급 차량 상세 비교',
      '시즌패스 추가 보상',
    ],
    isRecommended: true,
  ),
];

final mockGarage = [
  mockVehicle,
  Vehicle(
    id: 'vehicle-002',
    userId: mockProfile.id,
    manufacturer: 'Kia',
    modelName: 'K5',
    modelYear: 2023,
    fuelType: 'Gasoline',
    vehicleClass: '중형',
    nickname: '고속 안정형',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-003',
    userId: mockProfile.id,
    manufacturer: 'Hyundai',
    modelName: 'Ioniq 5',
    modelYear: 2024,
    fuelType: 'Electric',
    vehicleClass: '전기',
    nickname: '전기 질주',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-004',
    userId: mockProfile.id,
    manufacturer: 'Kia',
    modelName: 'Sportage',
    modelYear: 2022,
    fuelType: 'Hybrid',
    vehicleClass: 'SUV',
    nickname: '패밀리 아레나',
    isPrimary: false,
  ),
  Vehicle(
    id: 'vehicle-005',
    userId: mockProfile.id,
    manufacturer: 'Toyota',
    modelName: 'Prius',
    modelYear: 2023,
    fuelType: 'Hybrid',
    vehicleClass: '준중형',
    nickname: '효율의 정석',
    isPrimary: false,
  ),
];

final mockDriveSessions = List.generate(
  20,
  (index) => DriveSession(
    id: 'drive-${(index + 1).toString().padLeft(3, '0')}',
    userId: mockProfile.id,
    vehicleId: mockVehicle.id,
    startedAt: DateTime.now().subtract(Duration(days: index, minutes: index * 7)),
    endedAt: DateTime.now().subtract(Duration(days: index)).add(const Duration(minutes: 38)),
    duration: Duration(minutes: 24 + index),
    distanceKm: 12.4 + index,
    fuelUsedLiters: 0.8 + index * 0.04,
    averageFuelEfficiency: 16.2 + (index % 5),
    status: index % 6 == 0 ? 'pending_review' : 'verified',
  ),
);

final mockDriveScores = List.generate(
  20,
  (index) => DriveScore(
    id: 'score-${(index + 1).toString().padLeft(3, '0')}',
    driveSessionId: 'drive-${(index + 1).toString().padLeft(3, '0')}',
    userId: mockProfile.id,
    totalScore: 880 + index * 7,
    efficiencyScore: 82 + index % 12,
    stabilityScore: 78 + index % 16,
    classPercentile: 18 + index % 20,
    fuelEfficiencyScore: 84 + index % 10,
    accelerationPenalty: -8 - index % 6,
    brakingPenalty: -5 - index % 5,
    idlePenalty: -2 - index % 4,
    distanceBonus: 24 + index,
    consistencyBonus: 18 + index % 9,
    verificationStatus: index % 6 == 0 ? 'pending_review' : 'verified',
  ),
);

final mockCoupons = List.generate(
  10,
  (index) => Coupon(
    id: 'coupon-${(index + 1).toString().padLeft(3, '0')}',
    title: ['세차 쿠폰 응모권', '커피 리워드', '충전 포인트', '정비 할인'][index % 4],
    description: '스폰서 챌린지 완료 보상입니다.',
    expiresAt: DateTime.now().add(Duration(days: 7 + index)),
  ),
);

final mockNotifications = List.generate(
  15,
  (index) => NotificationItem(
    id: 'notification-${(index + 1).toString().padLeft(3, '0')}',
    title: ['랭킹 추월', '배틀 결과', '시즌 보상', '공정성 검증'][index % 4],
    body: ['오늘 3명을 추월했어요.', '퇴근길 효율전 결과가 확정됐어요.', '시즌 XP 보상이 도착했어요.', '검증 완료 후 랭킹에 반영됩니다.'][index % 4],
    createdAt: DateTime.now().subtract(Duration(hours: index + 1)),
    isRead: index.isEven,
  ),
);

const mockCrewMembers = [
  CrewMember(crewId: 'crew-001', userId: 'user-001', nickname: 'ApexDriver', role: 'owner', weeklyContribution: 2842),
  CrewMember(crewId: 'crew-001', userId: 'user-002', nickname: 'NightCruise', role: 'member', weeklyContribution: 2811),
  CrewMember(crewId: 'crew-001', userId: 'user-003', nickname: 'EcoBlade', role: 'member', weeklyContribution: 3910),
  CrewMember(crewId: 'crew-001', userId: 'user-004', nickname: 'BlueTorque', role: 'member', weeklyContribution: 3722),
  CrewMember(crewId: 'crew-001', userId: 'user-005', nickname: 'VoltRunner', role: 'member', weeklyContribution: 3512),
  CrewMember(crewId: 'crew-001', userId: 'user-006', nickname: 'GreenLine', role: 'member', weeklyContribution: 2660),
  CrewMember(crewId: 'crew-001', userId: 'user-007', nickname: 'EcoPulse', role: 'member', weeklyContribution: 2544),
  CrewMember(crewId: 'crew-001', userId: 'user-008', nickname: 'FuelBlade', role: 'member', weeklyContribution: 2491),
];

const mockAdminMetrics = [
  AdminMetric(id: 'dau', label: 'DAU', value: '12.4', unit: 'K'),
  AdminMetric(id: 'mau', label: 'MAU', value: '118', unit: 'K'),
  AdminMetric(id: 'drives', label: '총 주행 수', value: '482', unit: 'K'),
  AdminMetric(id: 'completion', label: '평균 주행 완료율', value: '87', unit: '%'),
  AdminMetric(id: 'battles', label: '배틀 생성 수', value: '18.2', unit: 'K'),
  AdminMetric(id: 'season', label: '시즌 참여율', value: '72', unit: '%'),
  AdminMetric(id: 'ranking', label: '랭킹 참여율', value: '81', unit: '%'),
  AdminMetric(id: 'ad_view', label: '광고 시청률', value: '34', unit: '%'),
  AdminMetric(id: 'ad_complete', label: '광고 완료율', value: '92', unit: '%'),
  AdminMetric(id: 'premium', label: '프리미엄 전환율', value: '6.8', unit: '%'),
  AdminMetric(id: 'season_pass', label: '시즌패스 구매율', value: '4.1', unit: '%'),
  AdminMetric(id: 'coupon_download', label: '쿠폰 다운로드 수', value: '9.4', unit: 'K'),
  AdminMetric(id: 'coupon_use', label: '쿠폰 사용률', value: '38', unit: '%'),
  AdminMetric(id: 'sponsor', label: '스폰서 챌린지 참여율', value: '21', unit: '%'),
  AdminMetric(id: 'fraud', label: '부정 기록 감지 수', value: '128', unit: '건', healthy: false),
  AdminMetric(id: 'reports', label: '신고 처리율', value: '94', unit: '%'),
];
