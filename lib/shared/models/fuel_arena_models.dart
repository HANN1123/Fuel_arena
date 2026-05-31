class UserProfile {
  const UserProfile({
    required this.id,
    required this.nickname,
    required this.avatarUrl,
    required this.tier,
    required this.totalScore,
    required this.seasonScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.representativeVehicleName,
    required this.isPremium,
  });

  final String id;
  final String nickname;
  final String avatarUrl;
  final String tier;
  final int totalScore;
  final int seasonScore;
  final int currentStreak;
  final int bestStreak;
  final String representativeVehicleName;
  final bool isPremium;
}

class Vehicle {
  const Vehicle({
    required this.id,
    required this.userId,
    required this.manufacturer,
    required this.modelName,
    required this.modelYear,
    required this.fuelType,
    required this.vehicleClass,
    required this.nickname,
    required this.isPrimary,
  });

  final String id;
  final String userId;
  final String manufacturer;
  final String modelName;
  final int modelYear;
  final String fuelType;
  final String vehicleClass;
  final String nickname;
  final bool isPrimary;
}

class DriveSession {
  const DriveSession({
    required this.id,
    required this.vehicleId,
    required this.startedAt,
    required this.duration,
    required this.distanceKm,
    required this.averageFuelEfficiency,
    required this.status,
  });

  final String id;
  final String vehicleId;
  final DateTime startedAt;
  final Duration duration;
  final double distanceKm;
  final double averageFuelEfficiency;
  final String status;
}

class DriveScore {
  const DriveScore({
    required this.totalScore,
    required this.efficiencyScore,
    required this.stabilityScore,
    required this.classPercentile,
    required this.accelerationPenalty,
    required this.brakingPenalty,
    required this.idlePenalty,
    required this.distanceBonus,
    required this.consistencyBonus,
    required this.verificationStatus,
  });

  final int totalScore;
  final int efficiencyScore;
  final int stabilityScore;
  final int classPercentile;
  final int accelerationPenalty;
  final int brakingPenalty;
  final int idlePenalty;
  final int distanceBonus;
  final int consistencyBonus;
  final String verificationStatus;
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
    required this.title,
    required this.battleType,
    required this.status,
    required this.ruleType,
    required this.startAt,
    required this.endAt,
    required this.myScore,
    required this.opponentScore,
    required this.opponentNickname,
    required this.rewardSummary,
  });

  final String id;
  final String title;
  final String battleType;
  final String status;
  final String ruleType;
  final DateTime startAt;
  final DateTime endAt;
  final int myScore;
  final int opponentScore;
  final String opponentNickname;
  final String rewardSummary;
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
    required this.currentLeague,
    required this.seasonScore,
    required this.promotionTargetScore,
    required this.endsAt,
    required this.rewardProgress,
  });

  final String id;
  final String name;
  final String currentLeague;
  final int seasonScore;
  final int promotionTargetScore;
  final DateTime endsAt;
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
    required this.placement,
    required this.rewardType,
    required this.label,
  });

  final String id;
  final String placement;
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

class SubscriptionPlan {
  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.priceLabel,
    required this.benefits,
    required this.isRecommended,
  });

  final String id;
  final String name;
  final String priceLabel;
  final List<String> benefits;
  final bool isRecommended;
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
