class UserProfile {
  const UserProfile({
    required this.id,
    this.email = '',
    required this.nickname,
    required this.avatarUrl,
    required this.tier,
    required this.totalScore,
    required this.seasonScore,
    required this.currentStreak,
    required this.bestStreak,
    this.representativeVehicleId = '',
    required this.representativeVehicleName,
    required this.isPremium,
    this.isAdmin = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String email;
  final String nickname;
  final String avatarUrl;
  final String tier;
  final int totalScore;
  final int seasonScore;
  final int currentStreak;
  final int bestStreak;
  final String representativeVehicleId;
  final String representativeVehicleName;
  final bool isPremium;
  final bool isAdmin;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: '${json['id'] ?? ''}',
      email: '${json['email'] ?? ''}',
      nickname: '${json['nickname'] ?? 'Driver'}',
      avatarUrl: '${json['avatar_url'] ?? ''}',
      tier: '${json['tier'] ?? 'Bronze III'}',
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      seasonScore: (json['season_score'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      bestStreak: (json['best_streak'] as num?)?.toInt() ?? 0,
      representativeVehicleId: '${json['representative_vehicle_id'] ?? ''}',
      representativeVehicleName: '${json['representative_vehicle_name'] ?? ''}',
      isPremium: json['is_premium'] == true,
      isAdmin: json['is_admin'] == true,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar_url': avatarUrl,
        'tier': tier,
        'total_score': totalScore,
        'season_score': seasonScore,
        'current_streak': currentStreak,
        'best_streak': bestStreak,
        'representative_vehicle_id': representativeVehicleId,
        'representative_vehicle_name': representativeVehicleName,
        'is_premium': isPremium,
        'is_admin': isAdmin,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class AppConsent {
  const AppConsent({
    required this.userId,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.locationAccepted,
    required this.personalizedAdsAccepted,
    required this.marketingAccepted,
    required this.updatedAt,
  });

  final String userId;
  final bool termsAccepted;
  final bool privacyAccepted;
  final bool locationAccepted;
  final bool personalizedAdsAccepted;
  final bool marketingAccepted;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() => {
        'user_id': userId,
        'terms_accepted': termsAccepted,
        'privacy_accepted': privacyAccepted,
        'location_accepted': locationAccepted,
        'personalized_ads_accepted': personalizedAdsAccepted,
        'marketing_accepted': marketingAccepted,
        'updated_at': updatedAt.toIso8601String(),
      };
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.manufacturer,
    required this.modelName,
    required this.modelYear,
    required this.fuelType,
    this.displacement,
    required this.vehicleClass,
    required this.nickname,
    this.imageUrl = '',
    required this.isPrimary,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String userId;
  final String manufacturer;
  final String modelName;
  final int modelYear;
  final String fuelType;
  final int? displacement;
  final String vehicleClass;
  final String nickname;
  final String imageUrl;
  final bool isPrimary;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: '${json['id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      manufacturer: '${json['manufacturer'] ?? ''}',
      modelName: '${json['model_name'] ?? ''}',
      modelYear: (json['model_year'] as num?)?.toInt() ?? DateTime.now().year,
      fuelType: '${json['fuel_type'] ?? ''}',
      displacement: (json['displacement'] as num?)?.toInt(),
      vehicleClass: '${json['vehicle_class'] ?? ''}',
      nickname: '${json['nickname'] ?? ''}',
      imageUrl: '${json['image_url'] ?? ''}',
      isPrimary: json['is_primary'] != false,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'manufacturer': manufacturer,
        'model_name': modelName,
        'model_year': modelYear,
        'fuel_type': fuelType,
        'displacement': displacement,
        'vehicle_class': vehicleClass,
        'nickname': nickname,
        'image_url': imageUrl,
        'is_primary': isPrimary,
        'created_at': createdAt?.toIso8601String(),
        'updated_at': updatedAt?.toIso8601String(),
      };
}

class DriveSession {
  const DriveSession({
    required this.id,
    this.userId = '',
    required this.vehicleId,
    required this.startedAt,
    this.endedAt,
    required this.duration,
    required this.distanceKm,
    this.fuelUsedLiters = 0,
    required this.averageFuelEfficiency,
    this.sourceType = 'mock',
    this.driveContext = 'commute',
    required this.status,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String vehicleId;
  final DateTime startedAt;
  final DateTime? endedAt;
  final Duration duration;
  final double distanceKm;
  final double fuelUsedLiters;
  final double averageFuelEfficiency;
  final String sourceType;
  final String driveContext;
  final String status;
  final DateTime? createdAt;

  int get durationSeconds => duration.inSeconds;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'vehicle_id': vehicleId,
        'started_at': startedAt.toIso8601String(),
        'ended_at': endedAt?.toIso8601String(),
        'duration_seconds': durationSeconds,
        'distance_km': distanceKm,
        'fuel_used_liters': fuelUsedLiters,
        'average_efficiency': averageFuelEfficiency,
        'source_type': sourceType,
        'drive_context': driveContext,
        'status': status,
        'created_at': createdAt?.toIso8601String(),
      };
}

class DrivePoint {
  const DrivePoint({
    required this.id,
    required this.driveSessionId,
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.accuracy,
    required this.recordedAt,
  });

  final String id;
  final String driveSessionId;
  final double latitude;
  final double longitude;
  final double speedKmh;
  final double accuracy;
  final DateTime recordedAt;

  Map<String, dynamic> toPrivateJson() => {
        'id': id,
        'drive_session_id': driveSessionId,
        'latitude': latitude,
        'longitude': longitude,
        'speed_kmh': speedKmh,
        'accuracy': accuracy,
        'recorded_at': recordedAt.toIso8601String(),
      };
}

class DriveScore {
  const DriveScore({
    this.id = '',
    this.driveSessionId = '',
    this.userId = '',
    required this.totalScore,
    required this.efficiencyScore,
    required this.stabilityScore,
    required this.classPercentile,
    this.fuelEfficiencyScore = 0,
    required this.accelerationPenalty,
    required this.brakingPenalty,
    required this.idlePenalty,
    required this.distanceBonus,
    required this.consistencyBonus,
    required this.verificationStatus,
    this.createdAt,
  });

  final String id;
  final String driveSessionId;
  final String userId;
  final int totalScore;
  final int efficiencyScore;
  final int stabilityScore;
  final int classPercentile;
  final int fuelEfficiencyScore;
  final int accelerationPenalty;
  final int brakingPenalty;
  final int idlePenalty;
  final int distanceBonus;
  final int consistencyBonus;
  final String verificationStatus;
  final DateTime? createdAt;

  factory DriveScore.fromJson(Map<String, dynamic> json) {
    return DriveScore(
      id: '${json['id'] ?? ''}',
      driveSessionId: '${json['drive_session_id'] ?? ''}',
      userId: '${json['user_id'] ?? ''}',
      totalScore: (json['total_score'] as num?)?.toInt() ?? 0,
      efficiencyScore: (json['efficiency_score'] as num?)?.toInt() ?? 0,
      stabilityScore: (json['stability_score'] as num?)?.toInt() ?? 0,
      classPercentile: (json['class_percentile'] as num?)?.toInt() ?? 0,
      fuelEfficiencyScore: (json['fuel_efficiency_score'] as num?)?.toInt() ?? 0,
      accelerationPenalty: (json['acceleration_penalty'] as num?)?.toInt() ?? 0,
      brakingPenalty: (json['braking_penalty'] as num?)?.toInt() ?? 0,
      idlePenalty: (json['idle_penalty'] as num?)?.toInt() ?? 0,
      distanceBonus: (json['distance_bonus'] as num?)?.toInt() ?? 0,
      consistencyBonus: (json['consistency_bonus'] as num?)?.toInt() ?? 0,
      verificationStatus: '${json['verification_status'] ?? 'pending_review'}',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}'),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'drive_session_id': driveSessionId,
        'user_id': userId,
        'total_score': totalScore,
        'efficiency_score': efficiencyScore,
        'stability_score': stabilityScore,
        'class_percentile': classPercentile,
        'fuel_efficiency_score': fuelEfficiencyScore,
        'acceleration_penalty': accelerationPenalty,
        'braking_penalty': brakingPenalty,
        'idle_penalty': idlePenalty,
        'distance_bonus': distanceBonus,
        'consistency_bonus': consistencyBonus,
        'verification_status': verificationStatus,
        'created_at': createdAt?.toIso8601String(),
      };
}

class RankingEntry {
  const RankingEntry({
    required this.rank,
    required this.previousRank,
    required this.nickname,
    required this.tier,
    required this.score,
    required this.vehicleClass,
    required this.fuelType,
    required this.isCurrentUser,
  });

  final int rank;
  final int previousRank;
  final String nickname;
  final String tier;
  final int score;
  final String vehicleClass;
  final String fuelType;
  final bool isCurrentUser;
}

class Battle {
  const Battle({
    required this.id,
    this.createdBy = '',
    required this.title,
    required this.battleType,
    required this.status,
    required this.ruleType,
    required this.startAt,
    required this.endAt,
    this.wagerTemplate = '비금전 보상',
    this.participants = const [],
    required this.myScore,
    required this.opponentScore,
    required this.opponentNickname,
    required this.rewardSummary,
    this.createdAt,
  });

  final String id;
  final String createdBy;
  final String title;
  final String battleType;
  final String status;
  final String ruleType;
  final DateTime startAt;
  final DateTime endAt;
  final String wagerTemplate;
  final List<BattleParticipant> participants;
  final int myScore;
  final int opponentScore;
  final String opponentNickname;
  final String rewardSummary;
  final DateTime? createdAt;
}

class BattleParticipant {
  const BattleParticipant({
    required this.userId,
    required this.nickname,
    required this.score,
    required this.result,
  });

  final String userId;
  final String nickname;
  final int score;
  final String result;
}

class Season {
  const Season({
    required this.id,
    required this.name,
    this.description = '',
    this.startAt,
    required this.currentLeague,
    required this.seasonScore,
    required this.promotionTargetScore,
    required this.endsAt,
    this.status = 'active',
    this.theme = 'neon_efficiency',
    required this.rewardProgress,
  });

  final String id;
  final String name;
  final String description;
  final DateTime? startAt;
  final String currentLeague;
  final int seasonScore;
  final int promotionTargetScore;
  final DateTime endsAt;
  final String status;
  final String theme;
  final double rewardProgress;
}

class SeasonMission {
  const SeasonMission({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
    required this.rewardXp,
    required this.isWeekly,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
  final int rewardXp;
  final bool isWeekly;
}

class MissionProgress {
  const MissionProgress({
    required this.id,
    required this.userId,
    required this.missionId,
    required this.progress,
    required this.target,
    required this.rewardClaimed,
  });

  final String id;
  final String userId;
  final String missionId;
  final int progress;
  final int target;
  final bool rewardClaimed;
}

class Badge {
  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.rarity,
  });

  final String id;
  final String name;
  final String description;
  final String rarity;
}

class UserBadge {
  const UserBadge({
    required this.userId,
    required this.badgeId,
    required this.earnedAt,
    required this.equipped,
  });

  final String userId;
  final String badgeId;
  final DateTime earnedAt;
  final bool equipped;
}

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;
}

class UserAchievement {
  const UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.completed,
  });

  final String userId;
  final String achievementId;
  final int progress;
  final bool completed;
}

class Rival {
  const Rival({
    required this.id,
    required this.nickname,
    required this.scoreGap,
    required this.message,
  });

  final String id;
  final String nickname;
  final int scoreGap;
  final String message;
}

class Rivalry {
  const Rivalry({
    required this.id,
    required this.userId,
    required this.rivalUserId,
    required this.scoreGap,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String rivalUserId;
  final int scoreGap;
  final DateTime updatedAt;
}

class Crew {
  const Crew({
    required this.id,
    required this.name,
    required this.description,
    required this.memberCount,
    required this.weeklyScore,
  });

  final String id;
  final String name;
  final String description;
  final int memberCount;
  final int weeklyScore;
}

class CrewMember {
  const CrewMember({
    required this.crewId,
    required this.userId,
    required this.nickname,
    required this.role,
    required this.weeklyContribution,
  });

  final String crewId;
  final String userId;
  final String nickname;
  final String role;
  final int weeklyContribution;
}

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.isRead,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool isRead;
}

class Sponsor {
  const Sponsor({
    required this.id,
    required this.name,
    required this.logoUrl,
    required this.description,
    required this.isActive,
  });

  final String id;
  final String name;
  final String logoUrl;
  final String description;
  final bool isActive;
}

class SponsorChallenge {
  const SponsorChallenge({
    required this.id,
    required this.sponsorName,
    required this.title,
    required this.description,
    required this.rewardSummary,
    required this.endsAt,
  });

  final String id;
  final String sponsorName;
  final String title;
  final String description;
  final String rewardSummary;
  final DateTime endsAt;
}

class Advertisement {
  const Advertisement({
    required this.id,
    this.adType = 'native',
    required this.placement,
    this.title = '',
    this.description = '',
    this.sponsorId = '',
    this.imageUrl = '',
    this.ctaLabel = '',
    this.isActive = true,
    this.startsAt,
    this.endsAt,
    required this.rewardType,
    required this.label,
  });

  final String id;
  final String adType;
  final String placement;
  final String title;
  final String description;
  final String sponsorId;
  final String imageUrl;
  final String ctaLabel;
  final bool isActive;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String rewardType;
  final String label;
}

class AdReward {
  const AdReward({
    required this.id,
    required this.title,
    required this.description,
    required this.claimed,
  });

  final String id;
  final String title;
  final String description;
  final bool claimed;
}

class Coupon {
  const Coupon({
    required this.id,
    required this.title,
    required this.description,
    required this.expiresAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime expiresAt;
}

class UserCoupon {
  const UserCoupon({
    required this.id,
    required this.userId,
    required this.couponId,
    required this.status,
    required this.issuedAt,
    this.usedAt,
  });

  final String id;
  final String userId;
  final String couponId;
  final String status;
  final DateTime issuedAt;
  final DateTime? usedAt;
}

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    this.title = '',
    this.description = '',
    this.planType = 'monthly',
    required this.name,
    required this.priceLabel,
    required this.benefits,
    this.productId = '',
    required this.isRecommended,
  });

  final String id;
  final String title;
  final String description;
  final String planType;
  final String name;
  final String priceLabel;
  final List<String> benefits;
  final String productId;
  final bool isRecommended;
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.userId,
    required this.planId,
    required this.status,
    required this.startedAt,
    this.renewsAt,
  });

  final String id;
  final String userId;
  final String planId;
  final String status;
  final DateTime startedAt;
  final DateTime? renewsAt;
}

class FraudReview {
  const FraudReview({
    required this.id,
    required this.driveSessionId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String driveSessionId;
  final String reason;
  final String status;
  final DateTime createdAt;
}

class ReportItem {
  const ReportItem({
    required this.id,
    required this.reporterId,
    required this.targetType,
    required this.targetId,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String reporterId;
  final String targetType;
  final String targetId;
  final String reason;
  final String status;
  final DateTime createdAt;
}

class AdminMetric {
  const AdminMetric({
    required this.id,
    required this.label,
    required this.value,
    this.unit,
    this.healthy = true,
  });

  final String id;
  final String label;
  final String value;
  final String? unit;
  final bool healthy;
}

class HomeSnapshot {
  const HomeSnapshot({
    required this.profile,
    required this.vehicle,
    required this.activeBattle,
    required this.todayMission,
    required this.season,
    required this.rival,
    required this.latestDriveScore,
    required this.sponsorChallenge,
  });

  final UserProfile profile;
  final Vehicle vehicle;
  final Battle activeBattle;
  final SeasonMission todayMission;
  final Season season;
  final Rival rival;
  final DriveScore latestDriveScore;
  final SponsorChallenge sponsorChallenge;
}
