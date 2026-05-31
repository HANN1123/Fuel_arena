import 'package:uuid/uuid.dart';

import '../models/fuel_arena_models.dart';

const _uuid = Uuid();

abstract class AuthRepository {
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  });

  Future<UserProfile?> getCurrentUser();
}

class MockAuthRepository implements AuthRepository {
  UserProfile? _currentUser = mockProfile;

  @override
  Future<UserProfile?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return _currentUser;
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
}

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<UserProfile?> getCurrentUser() {
    throw UnimplementedError('TODO: Supabase Auth 연동');
  }

  @override
  Future<UserProfile> loginWithEmail({
    required String email,
    required String password,
  }) {
    throw UnimplementedError('TODO: Supabase Auth 연동');
  }
}

abstract class VehicleRepository {
  Future<Vehicle?> getPrimaryVehicle();

  Future<Vehicle> saveVehicle({
    required String manufacturer,
    required String modelName,
    required int modelYear,
    required String fuelType,
    required String vehicleClass,
    required String nickname,
  });
}

class MockVehicleRepository implements VehicleRepository {
  Vehicle? _vehicle = mockVehicle;

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
}

class SupabaseVehicleRepository implements VehicleRepository {
  @override
  Future<Vehicle?> getPrimaryVehicle() {
    throw UnimplementedError('TODO: Supabase vehicles 연동');
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
    throw UnimplementedError('TODO: Supabase vehicles 연동');
  }
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
  @override
  Future<HomeSnapshot> getHomeSnapshot() {
    throw UnimplementedError('TODO: Supabase 홈 집계 연동');
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
  @override
  Future<DriveScore> finishDriveSession() {
    throw UnimplementedError('TODO: Edge Function 점수 계산 연동');
  }

  @override
  Future<Vehicle> getRepresentativeVehicle() {
    throw UnimplementedError('TODO: Supabase vehicles 연동');
  }

  @override
  Future<SeasonMission> getTodayMission() {
    throw UnimplementedError('TODO: Supabase missions 연동');
  }

  @override
  Future<DriveSession> startDriveSession() {
    throw UnimplementedError('TODO: Supabase drive_sessions 연동');
  }
}

abstract class RankingRepository {
  Future<List<RankingEntry>> getRankings(String scope);
}

class MockRankingRepository implements RankingRepository {
  @override
  Future<List<RankingEntry>> getRankings(String scope) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return mockRankings;
  }
}

class SupabaseRankingRepository implements RankingRepository {
  @override
  Future<List<RankingEntry>> getRankings(String scope) {
    throw UnimplementedError('TODO: Supabase rankings 연동');
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
  @override
  Future<List<Battle>> getBattles() {
    throw UnimplementedError('TODO: Supabase battles 연동');
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
  @override
  Future<Season> getCurrentSeason() {
    throw UnimplementedError('TODO: Supabase seasons 연동');
  }

  @override
  Future<List<SeasonMission>> getMissions() {
    throw UnimplementedError('TODO: Supabase season_missions 연동');
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
  @override
  Future<List<Achievement>> getAchievements() {
    throw UnimplementedError('TODO: Supabase achievements 연동');
  }

  @override
  Future<List<Badge>> getBadges() {
    throw UnimplementedError('TODO: Supabase badges 연동');
  }

  @override
  Future<UserProfile> getProfile() {
    throw UnimplementedError('TODO: Supabase profiles 연동');
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
  @override
  Future<int> getDailyRewardAdLimit() {
    throw UnimplementedError('TODO: 광고 보상 정책 연동');
  }

  @override
  Future<List<Advertisement>> getNativeAdCards() {
    throw UnimplementedError('TODO: 광고 메타데이터 연동');
  }

  @override
  Future<bool> isRewardAdAvailable() {
    throw UnimplementedError('TODO: 광고 SDK 연동');
  }

  @override
  Future<AdReward> watchRewardAd() {
    throw UnimplementedError('TODO: 광고 SDK 연동');
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
  @override
  Future<List<SubscriptionPlan>> getPlans() {
    throw UnimplementedError('TODO: 구독 상태 및 플랜 연동');
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
  @override
  Future<List<SubscriptionPlan>> getPlans() {
    throw UnimplementedError('TODO: 인앱결제 플랜 연동');
  }

  @override
  Future<bool> startSubscription(String planId) {
    throw UnimplementedError('TODO: 인앱결제 SDK 연동');
  }
}

abstract class SponsorRepository {
  Future<List<SponsorChallenge>> getChallenges();
}

class MockSponsorRepository implements SponsorRepository {
  @override
  Future<List<SponsorChallenge>> getChallenges() async => [
        mockSponsorChallenge,
      ];
}

class SupabaseSponsorRepository implements SponsorRepository {
  @override
  Future<List<SponsorChallenge>> getChallenges() {
    throw UnimplementedError('TODO: Supabase sponsor_challenges 연동');
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
  @override
  Future<List<String>> getGuidelines() {
    throw UnimplementedError('TODO: 공정성 정책 CMS 연동');
  }
}

final mockProfile = UserProfile(
  id: 'user-001',
  nickname: 'ApexDriver',
  avatarUrl: '',
  tier: 'Gold III',
  totalScore: 128420,
  seasonScore: 2842,
  currentStreak: 5,
  bestStreak: 13,
  representativeVehicleName: 'Phantom R-Spec',
  isPremium: false,
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

const mockBadges = [
  Badge(
    id: 'badge-001',
    name: '연비 검투사',
    description: '첫 배틀 승리',
    rarity: 'Rare',
  ),
  Badge(
    id: 'badge-002',
    name: '정속 장인',
    description: '안정 점수 90점 이상',
    rarity: 'Epic',
  ),
  Badge(
    id: 'badge-003',
    name: '시즌 질주',
    description: '7일 연속 주행',
    rarity: 'Gold',
  ),
];

const mockAchievements = [
  Achievement(
    id: 'achievement-001',
    title: '첫 검증 완료',
    description: '검증된 주행 기록 1회 달성',
    progress: 1,
    target: 1,
  ),
  Achievement(
    id: 'achievement-002',
    title: '라이벌 추월',
    description: '라이벌 순위 10회 추월',
    progress: 4,
    target: 10,
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
